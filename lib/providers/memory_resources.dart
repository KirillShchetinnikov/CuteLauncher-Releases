import 'package:flutter/widgets.dart';
import '../diagnostics_store.dart';
import '../home_tile_diagnostics.dart';
import '../launcher_image_cache.dart';
import '../poster_disk_cache.dart';
import 'service_lifecycle.dart';
import 'settings_service.dart';

class MemoryCacheStats {
  final int bytes;
  final int entries;
  const MemoryCacheStats(this.bytes, this.entries);
}

enum MemoryCacheKind { appIcons, appBanners, appChannelPosters, watchNextPosters, other }

class _Resource {
  final VoidCallback clear;
  final MemoryCacheStats Function() stats;
  final VoidCallback? resume;
  final void Function(bool)? configure;
  final Map<MemoryCacheKind, MemoryCacheStats> Function()? breakdown;
  final Map<String, int> Function()? activity;
  final Map<MemoryCacheKind, PosterDiskCache> disk;
  _Resource(this.clear, this.stats, this.resume, this.configure, this.breakdown, this.activity, this.disk);
}

/// Tracks reconstructible image caches. Disk eviction is separate from RAM cleanup.
class MemoryResources extends ChangeNotifier
    with ServiceLifecycle, WidgetsBindingObserver {
  final SettingsService? _settings;
  final bool secondaryEngine;
  final Map<MemoryCacheKind, PosterDiskCache> posterDisks;
  bool _economy = false;
  (int, int, int, int)? _budgets;
  final _resources = <Object, _Resource>{};
  bool _foreground = true;
  bool get isForeground => _foreground;
  bool get economyEnabled => _economy;
  MemoryResources({this._settings, this.secondaryEngine = false, this.posterDisks = const {}}) {
    WidgetsBinding.instance.addObserver(this);
    _settings?.addListener(_updateProfile);
    _updateProfile();
  }
  void _updateProfile() {
    final enabled = _settings?.memorySaverEnabled ?? false;
    for (final entry in posterDisks.entries) {
      final limit = entry.key == MemoryCacheKind.appChannelPosters ? MemoryLimit.feedDisk : MemoryLimit.watchDisk;
      entry.value.maximumBytes = (_settings?.memoryLimit(limit) ?? limit.normal) * 1024 * 1024;
    }
    int limit(MemoryLimit value) => _settings?.memoryLimit(value) ?? value.normal;
    final budgets = (limit(MemoryLimit.icons), limit(MemoryLimit.banners),
        limit(MemoryLimit.decodedApps), limit(MemoryLimit.decodedPosters));
    final modeChanged = _budgets == null || _economy != enabled;
    if (!modeChanged && budgets == _budgets) return;
    _budgets = budgets;
    _economy = enabled;
    configureLauncherImageCache(economy: enabled, secondaryEngine: secondaryEngine,
        applicationMiB: budgets.$3, posterMiB: budgets.$4);
    for (final resource in _resources.values.toList()) {
      resource.configure?.call(enabled);
    }
    if (modeChanged) _clearRecoverableCaches(HomeTileCacheClear.memoryProfile);
  }

  void register(Object owner,
      {required VoidCallback clear,
      required MemoryCacheStats Function() stats,
      VoidCallback? resume,
      void Function(bool)? configure,
      Map<MemoryCacheKind, MemoryCacheStats> Function()? breakdown,
      Map<MemoryCacheKind, PosterDiskCache> disk = const {},
      Map<String, int> Function()? activity}) {
    _resources[owner] = _Resource(clear, stats, resume, configure, breakdown, activity, disk);
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
  Map<MemoryCacheKind, PosterDiskCache> get _disks => {
      ...posterDisks,
      for (final resource in _resources.values) ...resource.disk,
    };

  bool get hasPosterDisks => _disks.isNotEmpty;

  Future<int?> clearDiskCaches() async {
    var freed = 0;
    for (final disk in _disks.values.toSet()) {
      final bytes = await disk.clear();
      if (bytes == null) return null;
      freed += bytes;
    }
    return freed;
  }

  Future<Map<MemoryCacheKind, MemoryCacheStats>> diskCacheBreakdown() async {
    final result = <MemoryCacheKind, MemoryCacheStats>{};
    for (final entry in _disks.entries) {
      final stats = await entry.value.stats();
      if (stats != null) result[entry.key] = MemoryCacheStats(stats.bytes, stats.entries);
    }
    return result;
  }
  MemoryCacheStats get encodedImages => MemoryCacheStats(
        _resources.values
            .fold(0, (sum, resource) => sum + resource.stats().bytes),
        _resources.values
            .fold(0, (sum, resource) => sum + resource.stats().entries),
      );

  void clearRecoverableCaches() => _clearRecoverableCaches(HomeTileCacheClear.manual);

  void _clearRecoverableCaches(HomeTileCacheClear reason) {
    if (isDisposed) return;
    if (DiagnosticsStore.instance.isRecording && !secondaryEngine) {
      DiagnosticsStore.instance.homeTiles.clearCaches(reason);
    }
    for (final resource in _resources.values.toList()) {
      resource.clear();
    }
    PaintingBinding.instance.imageCache.clear();
    // Live image streams belong to mounted widgets; clearing their bookkeeping cannot free them.
    notifyListeners();
  }

  @override
  void didHaveMemoryPressure() => _clearRecoverableCaches(HomeTileCacheClear.memoryPressure);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      final wasForeground = _foreground;
      _foreground = false;
      // A background transition may deliver both hidden and paused.
      if (wasForeground) {
        _traceLifecycle();
        if (_settings?.clearCachesOnBackground ?? _economy) {
          _clearRecoverableCaches(_economy ? HomeTileCacheClear.backgroundEconomy : HomeTileCacheClear.background);
        } else {
          notifyListeners();
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      final wasForeground = _foreground;
      _foreground = true;
      if (!wasForeground) {
        _traceLifecycle();
        for (final resource in _resources.values.toList()) {
          resource.resume?.call();
        }
        notifyListeners();
      }
    }
  }

  void _traceLifecycle() {
    if (DiagnosticsStore.instance.isRecording && !secondaryEngine) {
      DiagnosticsStore.instance.homeTiles.lifecycle(foreground: _foreground, economy: _economy);
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
