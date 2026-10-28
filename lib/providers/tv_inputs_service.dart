import 'dart:convert';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'service_lifecycle.dart';
import 'foreground_work.dart';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/models/tv_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tv_inputs_configuration.dart';

class TvInputsService extends ChangeNotifier
    with ServiceLifecycle, WidgetsBindingObserver {
  final FLauncherChannel _channel;
  final ForegroundWork? work;
  final SharedPreferences? preferences;
  final Listenable? settings;
  TvInputsConfiguration _configuration = const TvInputsConfiguration();
  TvInputsConfiguration get configuration => _configuration;
  String? _configurationValue;
  List<TvInput> _rawInputs = [];
  List<TvInput> _inputs = [];
  bool _initialized = false;
  static const _events = EventChannel('me.efesser.flauncher/event_tv_inputs');
  final Stream<dynamic>? changes;
  StreamSubscription<dynamic>? _subscription;
  Timer? _refreshTimer;
  int _generation = 0;

  TvInputsService(
    this._channel, {
    this.preferences,
    this.settings,
    this.changes,
    this.work,
  }) {
    _reloadConfiguration();
    settings?.addListener(_reloadConfiguration);
    WidgetsBinding.instance.addObserver(this);
    _listen();
    (work?.schedule(this, _init) ?? _init());
  }

  void _listen() {
    _subscription ??= (changes ?? _events.receiveBroadcastStream()).listen(
      (_) {
        if (isDisposed) return;
        _refreshTimer?.cancel();
        _refreshTimer = Timer(
          const Duration(milliseconds: 100),
          _refreshSafely,
        );
      },
      onError: (Object error) {
        debugPrint('TV input events unavailable: $error');
      },
    );
  }

  Future<void> _refreshSafely() async {
    try {
      await refreshInputs();
    } catch (error) {
      debugPrint('Unable to refresh TV inputs: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _listen();
      if (_initialized) {
        (work?.schedule(this, _refreshSafely, maxAge: const Duration(seconds: 5)) ?? _refreshSafely());
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _subscription?.cancel();
      _subscription = null;
      _refreshTimer?.cancel();
      _generation++;
    }
  }

  void _reloadConfiguration() {
    if (preferences == null) return;
    final value = preferences?.getString(tvInputsConfigurationKey);
    if (value == _configurationValue) return;
    _configurationValue = value;
    _configuration = TvInputsConfiguration.decode(value);
    _inputs = configuration.present(_rawInputs);
    notifyListeners();
  }

  List<TvInput> present(Iterable<TvInput> inputs) =>
      configuration.present(inputs);

  Future<void> configure(TvInputsConfiguration value) async {
    final valid = TvInputsConfiguration.parse(
      jsonDecode(value.encode()) as Map,
    );
    final encoded = valid.encode();
    final prefs = preferences;
    if (prefs != null &&
        !await prefs.setString(tvInputsConfigurationKey, encoded)) {
      throw StateError('Unable to save TV inputs');
    }
    if (isDisposed) return;
    _configuration = valid;
    _configurationValue = encoded;
    _inputs = configuration.present(_rawInputs);
    notifyListeners();
  }

  @override
  void dispose() {
    work?.cancel(this);
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _refreshTimer?.cancel();
    settings?.removeListener(_reloadConfiguration);
    super.dispose();
  }

  List<TvInput> get inputs => List.unmodifiable(_inputs);
  bool get hasInputs => _inputs.isNotEmpty;
  bool get initialized => _initialized;

  Future<void> _init() async {
    if (isDisposed) return;
    try {
      await refreshInputs();
    } catch (e) {
      debugPrint('Unable to load TV inputs: $e');
    }
    if (isDisposed) return;
    _initialized = true;
    notifyListeners();
  }

  Future<void> refreshInputs() async {
    if (isDisposed) return;
    final generation = ++_generation;
    final List<Map<dynamic, dynamic>> rawInputs = await _channel.getTvInputs();
    if (isDisposed || generation != _generation) return;
    _reloadConfiguration();
    _rawInputs = rawInputs.map(TvInput.fromMap).toList();
    _inputs = configuration.present(_rawInputs);
    notifyListeners();
  }

  Future<bool> switchInput(String id) async {
    return await _channel.launchTvInput(id);
  }
}
