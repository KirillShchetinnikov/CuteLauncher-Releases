import '../diagnostics_store.dart';
import 'package:flutter/foundation.dart';

import '../bridge_result.dart';

/// One local selection shared by the settings list and application context menus.
/// No work is started until one of these views requests a refresh.
class BackgroundStartupService extends ChangeNotifier {
  static const _channel = BridgeChannel('cutelauncher/auto_launch');
  List<Map<dynamic, dynamic>> _apps = [];
  Set<String> _selected = {};
  Map<dynamic, dynamic> _outcomes = {};
  bool loaded = false, loading = false, saving = false, failed = false;
  bool _disposed = false;
  Future<void>? _refresh;

  List<Map<dynamic, dynamic>> get apps => _apps;
  bool selected(String app) => _selected.contains(app);
  String? outcome(String app) => _outcomes[app] as String?;
  bool available(String app) => _apps.any(
    (entry) => entry['packageName'] == app && entry['available'] == true,
  );

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() {
    if (_disposed || saving) return Future.value();
    return _refresh ??= _load().whenComplete(() => _refresh = null);
  }

  Future<void> _load() async {
    loading = true;
    _changed();
    try {
      final info = await _channel
          .invokeMapMethod<String, dynamic>('backgroundInfo')
          .timeout(const Duration(seconds: 10));
      if (info == null) throw StateError('Background startup unavailable');
      final apps = (info['apps'] as List).cast<Map<dynamic, dynamic>>();
      final selected = {
        for (final app in apps)
          if (app['selected'] == true) app['packageName'] as String,
      };
      if (_disposed) return;
      _apps = List.unmodifiable(apps);
      _selected = selected;
      _outcomes = info['outcomes'] as Map? ?? {};
      loaded = true;
      failed = false;
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'backgroundStartupService', diagnosticError, diagnosticStack,
      );
      if (!_disposed) failed = true;
    } finally {
      loading = false;
      _changed();
    }
  }

  Future<void> setSelected(String app, bool enabled) async {
    if (_disposed ||
        loading ||
        saving ||
        !loaded ||
        (enabled && !available(app) && !selected(app))) {
      return;
    }
    saving = true;
    _changed();
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('backgroundSetApp', {
            'app': app,
            'enabled': enabled,
          })
          .timeout(const Duration(seconds: 10));
      if (result == null || result['status'] != 'success') {
        throw StateError('Selection not saved');
      }
      final selected = (result['selected'] as List).cast<String>().toSet();
      if (_disposed) return;
      _selected = selected;
      _apps = List.unmodifiable([
        for (final entry in _apps)
          {...entry, 'selected': selected.contains(entry['packageName'])},
      ]);
      failed = false;
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'backgroundStartupService', diagnosticError, diagnosticStack,
      );
      if (!_disposed) failed = true;
    } finally {
      saving = false;
      _changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
