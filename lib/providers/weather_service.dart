import 'package:flauncher/bridge_result.dart';
import 'service_lifecycle.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'dart:io' show File;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../weather_sources.dart';
import '../diagnostics_store.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flutter/widgets.dart';

class WeatherService extends ChangeNotifier with ServiceLifecycle, WidgetsBindingObserver {
  final FLauncherChannel _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _refreshTimer;
  DateTime? _lastResumeCheck;
  String? _lastJson;
  final SharedPreferences? _preferences;
  final DirectWeatherProvider _direct;
  WeatherConfiguration _configuration;
  WeatherFailure? _failure;
  bool _directBusy = false;
  bool _hasKey = false;
  bool _locating = false;
  bool get locating => _locating;
  Future<List<Map<String, dynamic>>> searchCities(String query) async {
    final result = await const BridgeChannel('cutelauncher/night', preserveErrorCodes: true).invokeListMethod<dynamic>(
      'cities', {'query': query, 'language': 'en'});
    return (result ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  bool get canRefresh => _configuration.source == WeatherSource.breezy ||
      (_configuration.hasLocation &&
       ((_configuration.source != WeatherSource.yandex && _configuration.source != WeatherSource.openWeather) || _hasKey));
  Future<void> locateAutomatically() async {
    if (_locating || isDisposed) return;
    _locating = true;
    notifyListeners();
    try {
      final result = await const BridgeChannel('cutelauncher/weather_location', preserveErrorCodes: true).invokeMapMethod<String, dynamic>('locate');
      if (isDisposed) return;
      final value = WeatherConfiguration(source: _configuration.source,
        location: _configuration.location, cityLatitude: _configuration.cityLatitude, cityLongitude: _configuration.cityLongitude,
        latitude: (result?['latitude'] as num?)?.toDouble(), longitude: (result?['longitude'] as num?)?.toDouble(),
        intervalMinutes: _configuration.intervalMinutes);
      if (!value.validCoordinates) throw const WeatherException(WeatherFailure.coordinates);
      await configure(value);
    } finally {
      _locating = false;
      if (!isDisposed) notifyListeners();
    }
  }
  Future<void> _readKeyPresence() async {
    final source = _configuration.source;
    final present = source == WeatherSource.yandex || source == WeatherSource.openWeather
        ? await hasApiKey(source: source) : false;
    if (!isDisposed && source == _configuration.source) _hasKey = present;
  }
  bool _foreground = true;
  DateTime? _lastAttempt;
  DateTime? _updatedAt;
  WeatherConfiguration get configuration => _configuration;
  WeatherFailure? get failure => _failure;
  bool get loading => _directBusy;
  DateTime? get updatedAt => _updatedAt;
  bool get stale => _updatedAt != null && DateTime.now().difference(_updatedAt!) > Duration(minutes: _configuration.intervalMinutes);
  Future<File> _keyFile(WeatherSource source) async {
    final name = source == WeatherSource.yandex ? 'weather-api-key' : 'weather-api-key-openweather';
    if (source != WeatherSource.yandex && source != WeatherSource.openWeather) {
      throw const WeatherException(WeatherFailure.keyRequired);
    }
    return File('${(await getApplicationSupportDirectory()).path}/$name');
  }
  Future<bool> hasApiKey({WeatherSource? source}) async {
    final file = await _keyFile(source ?? _configuration.source);
    return await file.exists() && (await file.readAsString()).trim().isNotEmpty;
  }
  Future<void> setApiKey(String value, {WeatherSource? source}) async {
    final selected = source ?? _configuration.source;
    final file = await _keyFile(selected);
    if (value.trim().isEmpty) { if (await file.exists()) await file.delete(); }
    else { await file.parent.create(recursive: true); await file.writeAsString(value.trim(), flush: true); }
    if (selected == _configuration.source) {
      _hasKey = value.trim().isNotEmpty;
      _fetchGeneration++;
      _lastAttempt = null;
      _updatedAt = null;
      _failure = _hasKey ? null : WeatherFailure.keyRequired;
      notifyListeners();
      _startPeriodicTimer();
    }
  }
  Future<void> configure(WeatherConfiguration value) async {
    await _preferences?.setString(weatherConfigurationKey, jsonEncode(value.toJson()));
    _fetchGeneration++;
    _configuration = value;
    _weatherData = null;
    _lastJson = null;
    _lastAttempt = null;
    _updatedAt = null;
    _failure = null;
    await _readKeyPresence();
    if (value.source != WeatherSource.breezy && !canRefresh) {
      _failure = value.hasLocation ? WeatherFailure.keyRequired : WeatherFailure.coordinates;
    }
    notifyListeners();
    _startPeriodicTimer();
    await refresh();
  }
  Future<void> reloadConfiguration() async {
    final value = WeatherConfiguration.decode(_preferences?.getString(weatherConfigurationKey));
    if (jsonEncode(value.toJson()) != jsonEncode(_configuration.toJson())) await configure(value);
  }

  WeatherData? _weatherData;
  bool _isBreezyInstalled = false;
  bool _initialized = false;
  int _fetchGeneration = 0;

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  WeatherService(this._channel, {SharedPreferences? preferences, WeatherTransport? transport})
      : _preferences = preferences,
        _configuration = WeatherConfiguration.decode(preferences?.getString(weatherConfigurationKey)),
        _direct = DirectWeatherProvider(transport ?? HttpWeatherTransport()) {
    if (!_isTest) {
      WidgetsBinding.instance.addObserver(this);
    }
    _init();
  }

  WeatherData? get weatherData => _weatherData;
  bool get isBreezyInstalled => _isBreezyInstalled;
  bool get initialized => _initialized;
  bool get hasWeather => _weatherData != null;

  Future<void> _init() async {
    try {
      await _readKeyPresence();
      await _fetchLatest();
      if (isDisposed) return;

      _subscription = _channel.addWeatherChangedListener((event) {
        if (_configuration.source == WeatherSource.breezy && event is String && event.isNotEmpty) {
          _processWeatherJson(event);
        }
      });
      _startPeriodicTimer();
    } catch (e, stack) {
      DiagnosticsStore.instance.recordException('weatherInitialize', e, stack);
      developer.log("Error initializing WeatherService", error: e, stackTrace: stack);
    } finally {
      if (!isDisposed) _initialized = true;
      notifyListeners();
    }
  }

  void _startPeriodicTimer() {
    if (isDisposed || !_foreground) return;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (!canRefresh) return;
    // 15-minute fallback timer in case a broadcast was missed while paused
    _refreshTimer = Timer.periodic(Duration(minutes: _configuration.source == WeatherSource.breezy ? 15 : _configuration.intervalMinutes), (_) => _fetchLatest());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isDisposed) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _foreground = false;
      _refreshTimer?.cancel();
      _refreshTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _checkWeatherOnResume();
      _startPeriodicTimer();
    }
  }

  Future<void> _checkWeatherOnResume() async {
    final now = DateTime.now();
    if (_lastResumeCheck != null && now.difference(_lastResumeCheck!).inSeconds < 60) {
      return;
    }
    _lastResumeCheck = now;
    await _fetchLatest();
  }

  Future<void> _fetchLatest({bool force = false}) async {
    if (isDisposed) return;
    if (_configuration.source != WeatherSource.breezy) {
      await _fetchDirect(force: force);
      return;
    }
    final generation = ++_fetchGeneration;
    try {
      final installed = await _channel.isBreezyWeatherInstalled();
      if (isDisposed || generation != _fetchGeneration) return;
      _isBreezyInstalled = installed;
      final latestJson = await _channel.getLatestWeatherData();
      if (isDisposed || generation != _fetchGeneration) return;
      if (latestJson != null && latestJson.isNotEmpty) {
        _processWeatherJson(latestJson);
      }
    } catch (e, stack) {
      DiagnosticsStore.instance.recordException('weatherFetch', e, stack);
      developer.log("Failed to fetch latest weather data", error: e, stackTrace: stack);
    }
  }

  Future<void> _fetchDirect({bool force = false}) async {
    if (_directBusy || !_foreground || !canRefresh) return;
    final config = _configuration;
    final identity = jsonEncode(config.toJson());
    if (_weatherData == null) {
      try {
        final cache = jsonDecode(_preferences?.getString('weather_cache') ?? '{}') as Map;
        final date = DateTime.tryParse(cache['fetchedAt'] as String? ?? '');
        if (cache['configuration'] == identity && date != null && !date.isAfter(DateTime.now()) && DateTime.now().difference(date).inHours < 24) {
          _weatherData = WeatherData.fromJson(Map<String, dynamic>.from(cache['data'] as Map));
          _updatedAt = date;
        }
      } catch (_) {}
    }
    if (_updatedAt != null && DateTime.now().difference(_updatedAt!).inHours >= 24) {
      _weatherData = null;
      _updatedAt = null;
    }
    if (!force && _lastAttempt != null && DateTime.now().difference(_lastAttempt!) < const Duration(minutes: 5)) return;
    if (!force && _updatedAt != null && DateTime.now().difference(_updatedAt!) < Duration(minutes: config.intervalMinutes)) return;
    final generation = ++_fetchGeneration;
    _directBusy = true;
    _lastAttempt = DateTime.now();
    notifyListeners();
    try {
      String? key;
      if (config.source == WeatherSource.yandex || config.source == WeatherSource.openWeather) {
        final file = await _keyFile(config.source);
        if (await file.exists()) key = await file.readAsString();
      }
      final data = await _direct.fetch(config, key: key);
      if (isDisposed || generation != _fetchGeneration) return;
      _weatherData = WeatherData.fromJson(data);
      _updatedAt = DateTime.now();
      _failure = null;
      await _preferences?.setString('weather_cache', jsonEncode({'configuration': identity, 'fetchedAt': _updatedAt!.toIso8601String(), 'data': data}));
    } on WeatherException catch (error, stack) {
      DiagnosticsStore.instance.recordException('weatherFetch', error, stack, reason: 'weather_${error.failure.name}');
      if (!isDisposed && generation == _fetchGeneration) _failure = error.failure;
    } catch (error, stack) {
      DiagnosticsStore.instance.recordException('weatherFetch', error, stack);
      if (!isDisposed && generation == _fetchGeneration) _failure = WeatherFailure.unavailable;
    } finally {
      _directBusy = false;
      if (!isDisposed) {
        notifyListeners();
        if (generation != _fetchGeneration && _configuration.source != WeatherSource.breezy) await _fetchDirect();
      }
    }
  }

  void _processWeatherJson(String jsonString) {
    if (isDisposed) return;
    if (jsonString == _lastJson && _weatherData != null) {
      return;
    }
    try {
      _weatherData = WeatherData.fromJsonString(jsonString);
      _lastJson = jsonString;
      notifyListeners();
    } catch (e, stack) {
      DiagnosticsStore.instance.recordException('weatherParse', e, stack);
      developer.log("Failed to parse weather JSON", error: e, stackTrace: stack);
    }
  }

  Future<bool> openBreezyWeather() async {
    if (_configuration.source != WeatherSource.breezy) { await refresh(); return true; }
    try {
      return await _channel.openBreezyWeather();
    } catch (e) {
      return false;
    }
  }

  Future<void> refresh() async {
    await _fetchLatest(force: true);
    notifyListeners();
  }

  @override
  void dispose() {
    if (!_isTest) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _refreshTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
