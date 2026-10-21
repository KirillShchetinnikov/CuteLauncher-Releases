import 'package:flutter/widgets.dart';
import 'service_lifecycle.dart';
import 'settings_service.dart';

class MemoryCacheStats {
  final int bytes;
  final int entries;
  const MemoryCacheStats(this.bytes, this.entries);
}

enum MemoryCacheKind { appIcons, appBanners, watchNextPosters, other }

class _Resource {
  final VoidCallback clear;
  final MemoryCacheStats Function() stats;
  final VoidCallback? resume;
  final void Function(bool)? configure;
  final Map<MemoryCacheKind, MemoryCacheStats> Function()? breakdown;
  final Map<String, int> Function()? activity;
  _Resource(this.clear, this.stats, this.resume, this.configure, this.breakdown, this.activity);
}

/// Tracks reconstructible caches only; never removes preferences or files.
class MemoryResources extends ChangeNotifier
    with ServiceLifecycle, WidgetsBindingObserver {
  final SettingsService? _settings;
  bool _economy = false;
  bool _profileInitialized = false;
  final _resources = <Object, _Resource>{};
  bool _foreground = true;
  bool get isForeground => _foreground;
  bool get economyEnabled => _economy;
  MemoryResources({this._settings}) {
    WidgetsBinding.instance.addObserver(this);
    _settings?.addListener(_updateProfile);
    _updateProfile();
  }
  void _updateProfile() {
    final enabled = _settings?.memorySaverEnabled ?? false;
    if (_profileInitialized && _economy == enabled) return;
    _profileInitialized = true;
    _economy = enabled;
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        enabled ? 16 * 1024 * 1024 : 50 * 1024 * 1024;
    PaintingBinding.instance.imageCache.maximumSize = enabled ? 64 : 100;
    for (final resource in _resources.values.toList()) {
      resource.configure?.call(enabled);
    }
    clearRecoverableCaches();
  }

  void register(Object owner,
      {required VoidCallback clear,
      required MemoryCacheStats Function() stats,
      VoidCallback? resume,
      void Function(bool)? configure,
      Map<MemoryCacheKind, MemoryCacheStats> Function()? breakdown,
      Map<String, int> Function()? activity}) {
    _resources[owner] = _Resource(clear, stats, resume, configure, breakdown, activity);
    configure?.call(_economy);
  }

  void unregister(Object owner) => _resources.remove(owner);
  Map<String, int> get cacheActivity {
    final result = <String, int>{};
    for (final resource in _resources.values) {
      for (final entry in (resource.activity?.call() ?? <String, int>{}).entries) {
        result.update(entry.key, (value) => value + entry.value, ifAbsent: () => entry.value);
      }
    }
    return result;
  }
  Map<MemoryCacheKind, MemoryCacheStats> get cacheBreakdown {
    final result = {for (final kind in MemoryCacheKind.values) kind: const MemoryCacheStats(0, 0)};
    for (final resource in _resources.values.toList()) {
      final parts = resource.breakdown?.call() ?? {MemoryCacheKind.other: resource.stats()};
      for (final entry in parts.entries) {
        final previous = result[entry.key]!;
        result[entry.key] = MemoryCacheStats(previous.bytes + entry.value.bytes,
            previous.entries + entry.value.entries);
      }
    }
    return Map.unmodifiable(result);
  }
  MemoryCacheStats get encodedImages => MemoryCacheStats(
        _resources.values
            .fold(0, (sum, resource) => sum + resource.stats().bytes),
        _resources.values
            .fold(0, (sum, resource) => sum + resource.stats().entries),
      );

  void clearRecoverableCaches() {
    if (isDisposed) return;
    for (final resource in _resources.values.toList()) {
      resource.clear();
    }
    PaintingBinding.instance.imageCache.clear();
    // Live image streams belong to mounted widgets; clearing their bookkeeping cannot free them.
    notifyListeners();
  }

  @override
  void didHaveMemoryPressure() => clearRecoverableCaches();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      final wasForeground = _foreground;
      _foreground = false;
      // Normal app switching keeps the bounded caches warm for instant return.
      // Economy mode and memory pressure still release reconstructible caches.
      if (wasForeground) {
        if (_economy) { clearRecoverableCaches(); } else { notifyListeners(); }
      }
    } else if (state == AppLifecycleState.resumed) {
      final wasForeground = _foreground;
      _foreground = true;
      if (!wasForeground) {
        for (final resource in _resources.values.toList()) {
          resource.resume?.call();
        }
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _settings?.removeListener(_updateProfile);
    WidgetsBinding.instance.removeObserver(this);
    _resources.clear();
    super.dispose();
  }
}
