import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../flauncher_channel.dart';
import '../providers/memory_resources.dart';

/// A measurement of this process only. No device-wide or ADB data is used.
class LauncherMemorySnapshot {
  final int pssBytes;
  final int? rssBytes;
  final int? graphicsBytes;
  final DateTime measuredAt;

  const LauncherMemorySnapshot(
    this.pssBytes,
    this.rssBytes,
    this.graphicsBytes,
    this.measuredAt,
  );

  static int? validBytes(dynamic value) =>
      value is num && value.isFinite && value >= 0 ? value.toInt() : null;

  static LauncherMemorySnapshot? parse(
    Map<String, dynamic> value,
    DateTime now,
  ) {
    final pss = validBytes(value['pssBytes']);
    if (pss == null) return null;
    final time = validBytes(value['measuredAtMillis']);
    return LauncherMemorySnapshot(
      pss,
      validBytes(value['rssBytes']),
      validBytes(value['graphicsBytes']),
      time != null && time <= 8640000000000000
          ? DateTime.fromMillisecondsSinceEpoch(time)
          : now,
    );
  }
}

class LauncherMemoryPoint {
  final Duration elapsed;
  final int? bytes;
  const LauncherMemoryPoint(this.elapsed, this.bytes);
}

/// Page-owned, bounded sampling. Leaving the page never leaves a poll running.
class LauncherMemory extends ChangeNotifier {
  LauncherMemory({
    required this.resources,
    required this.channel,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    readCaches();
  }

  static const observationDuration = Duration(minutes: 1);
  static const sampleInterval = Duration(seconds: 5);
  static const maxPoints = 13;
  final MemoryResources resources;
  final FLauncherChannel channel;
  final DateTime Function() _now;
  LauncherMemorySnapshot? snapshot;
  int? deltaBytes;
  bool busy = false;
  bool failed = false;
  bool observing = false;
  bool _active = true;
  bool _disposed = false;
  int _generation = 0;
  int _observationGeneration = 0;
  Timer? _samples;
  Timer? _deadline;
  DateTime? _startedAt;
  final _points = <LauncherMemoryPoint>[];
  List<LauncherMemoryPoint> get points => List.unmodifiable(_points);
  late MemoryCacheStats encoded;
  late int decodedBytes;
  late int decodedLimit;
  late Map<MemoryCacheKind, MemoryCacheStats> breakdown;
  int get cacheBytes => encoded.bytes + decodedBytes;
  int? clearedCacheBefore;
  int? clearedCacheAfter;
  int? clearedProcessBefore;
  int? clearedProcessAfter;

  void readCaches() {
    encoded = resources.encodedImages;
    breakdown = resources.cacheBreakdown;
    decodedBytes = PaintingBinding.instance.imageCache.currentSizeBytes;
    decodedLimit = PaintingBinding.instance.imageCache.maximumSizeBytes;
  }

  bool get _canStart => !_disposed && _active && !busy;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<LauncherMemorySnapshot?> _collect() async {
    final generation = _generation;
    final observation = _observationGeneration;
    LauncherMemorySnapshot? next;
    try {
      next = LauncherMemorySnapshot.parse(
        await channel.getProcessMemoryUsage(),
        _now(),
      );
    } catch (_) {
      /* The previous valid snapshot remains visible. */
    }
    if (_disposed || !_active || generation != _generation) return null;
    failed = next == null;
    if (next != null) {
      deltaBytes = snapshot == null ? null : next.pssBytes - snapshot!.pssBytes;
      snapshot = next;
    }
    readCaches();
    if (observing && observation == _observationGeneration) {
      final elapsed = _now().difference(_startedAt!);
      _points.add(
        LauncherMemoryPoint(
          elapsed < Duration.zero
              ? Duration.zero
              : elapsed > observationDuration
              ? observationDuration
              : elapsed,
          next?.pssBytes,
        ),
      );
      if (_points.length > maxPoints) _points.removeAt(0);
    }
    _changed();
    return next;
  }

  Future<void> refresh() async {
    if (!_canStart) return;
    busy = true;
    _changed();
    try {
      await _collect();
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> clearCaches() async {
    if (!_canStart) return;
    busy = true;
    clearedCacheBefore = clearedCacheAfter = null;
    clearedProcessBefore = clearedProcessAfter = null;
    final generation = _generation;
    _changed();
    try {
      // Read a fresh baseline; a failed process read must not prevent clearing.
      final before = await _collect();
      if (_disposed || !_active || generation != _generation) return;
      readCaches();
      clearedCacheBefore = cacheBytes;
      clearedProcessBefore = before?.pssBytes;
      resources.clearRecoverableCaches();
      readCaches();
      clearedCacheAfter = cacheBytes;
      _changed(); // Cache result is immediate, independent of the native read.
      final after = await _collect();
      if (_disposed || !_active || generation != _generation) return;
      clearedProcessAfter = after?.pssBytes;
    } finally {
      busy = false;
      _changed();
    }
  }

  void startObservation() {
    if (!_canStart || observing) return;
    _points.clear();
    _observationGeneration++;
    _startedAt = _now();
    observing = true;
    _samples = Timer.periodic(sampleInterval, (_) => refresh());
    _deadline = Timer(observationDuration, stopObservation);
    unawaited(refresh());
  }

  void stopObservation() {
    _samples?.cancel();
    _deadline?.cancel();
    _samples = _deadline = null;
    if (!observing) return;
    observing = false;
    _observationGeneration++;
    _changed();
  }

  void setActive(bool active) {
    if (_disposed || _active == active) return;
    _active = active;
    if (!active) {
      _generation++;
      stopObservation();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _samples?.cancel();
    _deadline?.cancel();
    super.dispose();
  }
}
