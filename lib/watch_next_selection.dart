import 'dart:convert';

import 'models/watch_next_program.dart';

const watchNextAppLimitsKey = 'watch_next_app_limits';

Map<String, int>? parseWatchNextAppLimits(String value) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is! Map || decoded.length > 1000) return null;
    final result = <String, int>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String ||
          (entry.key as String).isEmpty ||
          entry.value is! int ||
          entry.value < 0 ||
          entry.value > 10000) {
        return null;
      }
      result[entry.key as String] = entry.value as int;
    }
    return result;
  } catch (_) {
    return null;
  }
}

/// Preserve source order, filter hidden content, apply source caps, then total cap.
List<WatchNextProgram> selectWatchNextPrograms(
  Iterable<WatchNextProgram> programs, {
  required Set<String> hiddenIds,
  required Set<String> hiddenPackages,
  required Map<String, int> appLimits,
  required int totalLimit,
}) {
  final counts = <String, int>{};
  final result = <WatchNextProgram>[];
  for (final program in programs) {
    if (hiddenIds.contains('${program.id}') ||
        hiddenPackages.contains(program.packageName)) {
      continue;
    }
    final count = counts[program.packageName] ?? 0;
    final limit = appLimits[program.packageName] ?? 0;
    if (limit > 0 && count >= limit) continue;
    counts[program.packageName] = count + 1;
    result.add(program);
    if (totalLimit > 0 && result.length >= totalLimit) break;
  }
  return result;
}
