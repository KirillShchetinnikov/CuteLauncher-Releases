import 'dart:convert';

import 'service_lifecycle.dart';

import 'package:flutter/foundation.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/models/tv_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tv_inputs_configuration.dart';

class TvInputsService extends ChangeNotifier with ServiceLifecycle {
  final FLauncherChannel _channel;
  final SharedPreferences? preferences;
  final Listenable? settings;
  TvInputsConfiguration _configuration = const TvInputsConfiguration();
  TvInputsConfiguration get configuration => _configuration;
  String? _configurationValue;
  List<TvInput> _rawInputs = [];
  List<TvInput> _inputs = [];
  bool _initialized = false;

  TvInputsService(this._channel, {this.preferences, this.settings}) {
    _reloadConfiguration();
    settings?.addListener(_reloadConfiguration);
    _init();
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
    settings?.removeListener(_reloadConfiguration);
    super.dispose();
  }

  List<TvInput> get inputs => List.unmodifiable(_inputs);
  bool get hasInputs => _inputs.isNotEmpty;
  bool get initialized => _initialized;

  Future<void> _init() async {
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
    final List<Map<dynamic, dynamic>> rawInputs = await _channel.getTvInputs();
    if (isDisposed) return;
    _reloadConfiguration();
    _rawInputs = rawInputs.map(TvInput.fromMap).toList();
    _inputs = configuration.present(_rawInputs);
    notifyListeners();
  }

  Future<bool> switchInput(String id) async {
    return await _channel.launchTvInput(id);
  }
}
