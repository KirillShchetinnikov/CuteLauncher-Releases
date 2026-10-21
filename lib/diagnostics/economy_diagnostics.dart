import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/memory_resources.dart';

/// Opt-in release measurements; absent from ordinary builds. No per-frame I/O.
class EconomyDiagnostics extends StatefulWidget {
  final Widget child;
  const EconomyDiagnostics({super.key, required this.child});

  @override
  State<EconomyDiagnostics> createState() => _EconomyDiagnosticsState();
}

class _EconomyDiagnosticsState extends State<EconomyDiagnostics> {
  final _frames = <FrameTiming>[];
  Timer? _timer;
  int _overflow = 0;

  void _collect(List<FrameTiming> frames) {
    for (final frame in frames) {
      if (_frames.length < 4096) {
        _frames.add(frame);
      } else {
        _overflow++;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addTimingsCallback(_collect);
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _report());
  }

  void _report() {
    final resources = context.read<MemoryResources>();
    final cache = PaintingBinding.instance.imageCache;
    final encoded = resources.encodedImages;
    final refresh = View.of(context).display.refreshRate;
    final budget = 1000000 / (refresh > 0 ? refresh : 60);
    Map<String, Object?> distribution(int Function(FrameTiming) select) {
      final values = _frames.map(select).toList()..sort();
      return {
        'p50_us': values.isEmpty ? null : values[values.length ~/ 2],
        'p95_us': values.isEmpty
            ? null
            : values[((values.length - 1) * .95).ceil()],
        'max_us': values.isEmpty ? null : values.last,
        'over_budget': values.where((value) => value > budget).length,
      };
    }

    final sample = <String, Object?>{
      'time': DateTime.now().toUtc().toIso8601String(),
      'economy': resources.economyEnabled,
      'foreground': resources.isForeground,
      'refresh_hz': refresh,
      'dpr': View.of(context).devicePixelRatio,
      'physical_width': View.of(context).physicalSize.width,
      'physical_height': View.of(context).physicalSize.height,
      'frames': _frames.length,
      'overflow': _overflow,
      'build': distribution((frame) => frame.buildDuration.inMicroseconds),
      'raster': distribution((frame) => frame.rasterDuration.inMicroseconds),
      'total': distribution((frame) => frame.totalSpan.inMicroseconds),
      'encoded_bytes': encoded.bytes,
      'encoded_entries': encoded.entries,
      'live': cache.liveImageCount,
      'pending': cache.pendingImageCount,
      'decoded_bytes': cache.currentSizeBytes,
      'decoded_entries': cache.currentSize,
      'activity': resources.cacheActivity,
    };
    debugPrint('CUTE_PERF ${jsonEncode(sample)}');
    _frames.clear();
    _overflow = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeTimingsCallback(_collect);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
