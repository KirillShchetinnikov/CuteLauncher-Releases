import 'package:flauncher/bridge_result.dart';
import 'service_lifecycle.dart';
import 'foreground_work.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'dart:io' show File;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../weather_sources.dart';
import '../city_search.dart';
import '../diagnostics_store.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import '../tile_appearance.dart';
import '../native_sync.dart';

class WeatherService extends ChangeNotifier with ServiceLifecycle, WidgetsBindingObserver {
  final FLauncherChannel _channel;
  final ForegroundWork? work;
  StreamSubscription<dynamic>? _subscription;
  Timer? _refreshTimer;
  DateTime? _lastResumeCheck;
  String? _lastJson;
  final SharedPreferences? _preferences;
  final DirectWeatherProvider _direct;
  WeatherConfiguration _configuration;
  WeatherFailure? _failure;
  bool _directBusy = false;
  bool _forceNextServerFetch = false;
  bool _hasKey = false;
  bool _credentialsPendingCheck = false;
  bool _locating = false;
  bool get locating => _locating;
  Future<List<Map<String, dynamic>>> searchCities(String query, String language) async =>
      (await _direct.citySearch.search(query, language: language))
          .map((city) => city.toMap()).toList();
  bool get canRefresh => _configuration.source == WeatherSource.breezy ||
      (_configuration.source == WeatherSource.customOpenMeteo && _configuration.server != null) ||
      (_configuration.hasLocation &&
       _configuration.source != WeatherSource.customOpenMeteo &&
       ((_configuration.source != WeatherSource.yandex && _configuration.source != WeatherSource.openWeather) || _hasKey));
  Future<void> locateAutomatically() async {
    if (_locating || isDisposed) return;
    _locating = true;
    notifyListeners();
    try {
      final result = await const BridgeChannel('cutelauncher/weather_location', preserveErrorCodes: true).invokeMapMethod<String, dynamic>('locate');
      if (isDisposed) return;
      final latitude = (result?['latitude'] as num?)?.toDouble();
      final longitude = (result?['longitude'] as num?)?.toDouble();
      if (!WeatherConfiguration(latitude: latitude, longitude: longitude).validCoordinates) {
        throw const WeatherException(WeatherFailure.coordinates);
      }
      await configure(_configuration.copyWith(locationMode: WeatherLocationMode.automatic,
        latitude: latitude, longitude: longitude));
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
  DateTime? _fetchedAt;
  WeatherConfiguration get configuration => _configuration;
  WeatherFailure? get failure => _failure;
  bool get loading => _directBusy;
  DateTime? get updatedAt => _updatedAt;
  bool get stale => _updatedAt != null &&
    (DateTime.now().difference(_updatedAt!) > Duration(minutes: _configuration.intervalMinutes) ||
      (_configuration.source == WeatherSource.customOpenMeteo && _failure == WeatherFailure.unavailable) ||
      ((_configuration.source == WeatherSource.gismeteo || _configuration.source == WeatherSource.auto) &&
        _failure != null));

  // The ordinary BridgeChannel records arguments/results for diagnostics.
  static const _weatherToken = MethodChannel('cutelauncher/weather_token');

  Future<bool> hasServerToken(Uri server) async {
    return await _weatherToken.invokeMethod<bool>('has', {'server': server.toString()}) ?? false;
  }

  Future<void> setServerToken(Uri server, String value) async {
    final token = value.trim();
    if (token.isNotEmpty && !isWeatherBearerToken(token)) {
      throw const WeatherException(WeatherFailure.authorization);
    }
    await _weatherToken.invokeMethod<void>('save', {'server': server.toString(), 'token': token});
    if (isDisposed || _configuration.source != WeatherSource.customOpenMeteo || _configuration.server != server) return;
    _credentialsChanged();
  }
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
    await const NativeSync().changed(selected == WeatherSource.yandex ? 'native_secret_weather_yandex' : 'native_secret_weather_openweather');
    if (selected == _configuration.source) {
      _hasKey = value.trim().isNotEmpty;
      _credentialsChanged();
    }
  }

  void _credentialsChanged() {
    _credentialsPendingCheck = true;
    _fetchGeneration++;
    _lastAttempt = null;
    _forceNextServerFetch = false;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _failure = _configuration.source != WeatherSource.customOpenMeteo && !_hasKey
        ? WeatherFailure.keyRequired : null;
    notifyListeners();
  }

  /// Shared location and update interval; source credentials and server URL stay saved.
  Future<void> selectSource(WeatherSource source) async {
    if (source == _configuration.source) return;
    await configure(_configuration.copyWith(source: source, sourceSelected: source != WeatherSource.auto));
  }

  Future<void> configure(WeatherConfiguration value) async {
    await _preferences?.setString(weatherConfigurationKey, jsonEncode(value.toJson()));
    if (value.source != _configuration.source || value.server != _configuration.server) {
      _credentialsPendingCheck = false;
    }
    _fetchGeneration++;
    _configuration = value;
    _weatherData = null;
    _lastJson = null;
    _lastAttempt = null;
    _updatedAt = null;
    _fetchedAt = null;
    _failure = null;
    await _readKeyPresence();
    if (value.source != WeatherSource.breezy && !canRefresh) {
      _failure = _configurationFailure(value);
    }
    notifyListeners();
    _startPeriodicTimer();
    await refresh();
  }

  WeatherFailure _configurationFailure(WeatherConfiguration config) =>
      config.source == WeatherSource.customOpenMeteo && config.server == null ? WeatherFailure.serverAddress :
      !config.hasLocation ? WeatherFailure.coordinates : WeatherFailure.keyRequired;
  Future<void> reloadConfiguration() async {
    final value = _loadConfiguration(_preferences);
    if (jsonEncode(value.toJson()) != jsonEncode(_configuration.toJson())) await configure(value);
  }

  WeatherData? _weatherData;
  bool _isBreezyInstalled = false;
  bool _initialized = false;
  int _fetchGeneration = 0;

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  static WeatherConfiguration _loadConfiguration(SharedPreferences? preferences) => preferences == null
      ? const WeatherConfiguration()
      : WeatherConfiguration.load(preferences.getString(weatherConfigurationKey));

  WeatherService(this._channel, {SharedPreferences? preferences, WeatherTransport? transport, CitySearch? citySearch, this.work})
      : _preferences = preferences,
        _configuration = _loadConfiguration(preferences),
        _direct = DirectWeatherProvider(transport ?? HttpWeatherTransport(), citySearch: citySearch) {
    if (!_isTest) {
      WidgetsBinding.instance.addObserver(this);
    }
    (work?.schedule(this, _init, delay: const Duration(seconds: 1)) ?? _init());
  }

  WeatherData? get weatherData => _weatherData;
  bool get isBreezyInstalled => _isBreezyInstalled;
  bool get initialized => _initialized;
  bool get hasWeather => _weatherData != null;

  Future<void> _init() async {
    if (isDisposed) return;
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
    if (isDisposed || !_foreground || _credentialsPendingCheck) return;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (!canRefresh) return;
    // 15-minute fallback timer in case a broadcast was missed while paused
    _refreshTimer = Timer.periodic(Duration(minutes: _configuration.source == WeatherSource.breezy ? 15 : _configuration.intervalMinutes), (_) {
      if ((_configuration.source == WeatherSource.gismeteo || _configuration.source == WeatherSource.auto) && work != null) {
        work!.schedule(this, _fetchLatest);
      } else {
        _fetchLatest();
      }
    });
  }

  bool get _requiresForegroundResult => _configuration.source == WeatherSource.customOpenMeteo ||
      _configuration.source == WeatherSource.gismeteo || _configuration.source == WeatherSource.auto;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isDisposed) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (_foreground && _directBusy && _requiresForegroundResult) {
        _fetchGeneration++;
        _lastAttempt = null;
      }
      _foreground = false;
      _refreshTimer?.cancel();
      _refreshTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _foreground = true;
      if (_initialized) {
        (work?.schedule(this, _checkWeatherOnResume, delay: const Duration(seconds: 1), maxAge: const Duration(minutes: 1)) ?? _checkWeatherOnResume());
      }
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
    if (_directBusy || !_foreground || _credentialsPendingCheck) return;
    final config = _configuration;
    final custom = config.source == WeatherSource.customOpenMeteo;
    final requiresForeground = _requiresForegroundResult;
    if (!canRefresh) {
      if (custom) _failure = _configurationFailure(config);
      return;
    }
    final identity = jsonEncode(config.toJson());
    if (_weatherData == null) {
      try {
        final cache = jsonDecode(_preferences?.getString('weather_cache') ?? '{}') as Map;
        final date = DateTime.tryParse(cache['fetchedAt'] as String? ?? '');
        if (cache['configuration'] == identity && date != null && !date.isAfter(DateTime.now()) && DateTime.now().difference(date).inHours < 24) {
          final data = Map<String, dynamic>.from(cache['data'] as Map);
          _weatherData = WeatherData.fromJson(data, referenceTime: date);
          _fetchedAt = date;
          _updatedAt = requiresForeground ? _observationUpdatedAt(data, date) : date;
        }
      } catch (_) {}
    }
    if (_fetchedAt != null && DateTime.now().difference(_fetchedAt!).inHours >= 24) {
      _weatherData = null;
      _updatedAt = null;
      _fetchedAt = null;
    }
    if (!force && _lastAttempt != null && DateTime.now().difference(_lastAttempt!) < const Duration(minutes: 5)) return;
    if (!force && _fetchedAt != null && DateTime.now().difference(_fetchedAt!) < Duration(minutes: config.intervalMinutes)) return;
    final generation = ++_fetchGeneration;
    bool isCurrent() => !isDisposed && generation == _fetchGeneration &&
        (!requiresForeground || _foreground);
    _directBusy = true;
    _lastAttempt = DateTime.now();
    notifyListeners();
    try {
      String? key;
      if (config.source == WeatherSource.yandex || config.source == WeatherSource.openWeather) {
        final file = await _keyFile(config.source);
        if (await file.exists()) key = await file.readAsString();
      }
      final token = custom ? await _weatherToken.invokeMethod<String>('read', {'server': config.server.toString()}) : null;
      if (!isCurrent()) return;
      final data = await _direct.fetch(config, key: key, bearerToken: token,
        forecastDays: custom ? TileAppearance.decode(_preferences?.getString(tileAppearanceKey)).forecastDays : 5,
        isCurrent: config.source == WeatherSource.auto ? isCurrent : null);
      if (!isCurrent()) return;
      final fetched = DateTime.now();
      _weatherData = WeatherData.fromJson(data, referenceTime: fetched);
      _fetchedAt = fetched;
      _updatedAt = requiresForeground ? _observationUpdatedAt(data, fetched) : fetched;
      _failure = null;
      await _preferences?.setString('weather_cache', jsonEncode({'configuration': identity, 'fetchedAt': fetched.toIso8601String(), 'data': data}));
    } on WeatherException catch (error, stack) {
      if (!isCurrent()) return;
      DiagnosticsStore.instance.recordException('weatherFetch', error, stack, reason: 'weather_${error.failure.name}');
      _failure = error.failure;
    } catch (error, stack) {
      if (!isCurrent()) return;
      DiagnosticsStore.instance.recordException('weatherFetch', custom ? const WeatherException(WeatherFailure.unavailable) : error, stack);
      _failure = WeatherFailure.unavailable;
    } finally {
      _directBusy = false;
      final force = _forceNextServerFetch && _configuration.source == WeatherSource.customOpenMeteo;
      _forceNextServerFetch = false;
      if (!isDisposed) {
        notifyListeners();
        if (generation != _fetchGeneration && _configuration.source != WeatherSource.breezy) await _fetchDirect(force: force);
      }
    }
  }

  DateTime _observationUpdatedAt(Map<String, dynamic> data, DateTime fetched) {
    final timestamp = data['timestamp'];
    return DateTime.tryParse(data['updatedAt'] as String? ?? '') ??
      (timestamp is int ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true) : fetched);
  }

  void _processWeatherJson(String jsonString) {
    if (isDisposed) return;
    if (jsonString == _lastJson && _weatherData != null) {
      return;
    }
    try {
      _weatherData = WeatherData.fromJsonString(jsonString);
      final timestamp = _weatherData?.timestamp;
      _updatedAt = timestamp == null ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
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
    final resumeUpdates = _credentialsPendingCheck;
    _credentialsPendingCheck = false;
    await _fetchLatest(force: true);
    if (resumeUpdates) _startPeriodicTimer();
    notifyListeners();
  }

  Future<void> refreshForecastDays() async {
    if (isDisposed || _configuration.source != WeatherSource.customOpenMeteo) return;
    _fetchGeneration++;
    _lastAttempt = null;
    _forceNextServerFetch = _directBusy;
    await _fetchDirect(force: true);
  }

  @override
  void dispose() {
    work?.cancel(this);
    if (!_isTest) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _refreshTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
