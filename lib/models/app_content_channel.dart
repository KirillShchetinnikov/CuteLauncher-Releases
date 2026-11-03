import 'package:flutter/foundation.dart';

import 'watch_next_program.dart';

class AppContentChannel {
  final int id;
  final String packageName;
  final String name;
  final String appName;
  final List<WatchNextProgram> programs;
  String get key => '$packageName:$id';
  AppContentChannel._(
    this.id,
    this.packageName,
    this.name,
    this.appName,
    this.programs,
  );

  factory AppContentChannel.fromMap(
    Map<dynamic, dynamic> map, {
    AppContentChannel? previous,
  }) {
    final old = {
      for (final program in previous?.programs ?? <WatchNextProgram>[])
        program.id: program,
    };
    final programs = ((map['programs'] as List?) ?? const [])
        .whereType<Map>()
        .take(20)
        .map((value) {
          final next = WatchNextProgram.fromMap(value);
          final existing = old[next.id];
          return existing != null && _sameProgram(existing, next)
              ? existing
              : next;
        })
        .toList();
    final next = AppContentChannel._(
      map['id'] as int,
      map['packageName'] as String,
      map['name'] as String,
      map['appName'] as String? ?? map['packageName'] as String,
      List.unmodifiable(programs),
    );
    if (previous != null &&
        next.id == previous.id &&
        next.packageName == previous.packageName &&
        next.name == previous.name &&
        next.appName == previous.appName &&
        listEquals(next.programs, previous.programs)) {
      return previous;
    }
    return next;
  }

  static bool _sameProgram(WatchNextProgram a, WatchNextProgram b) =>
      a.id == b.id &&
      a.packageName == b.packageName &&
      a.title == b.title &&
      a.description == b.description &&
      a.watchNextType == b.watchNextType &&
      a.lastEngagementTime == b.lastEngagementTime &&
      a.playbackPosition == b.playbackPosition &&
      a.duration == b.duration &&
      a.intentUri == b.intentUri &&
      a.posterArtUri == b.posterArtUri &&
      a.posterAspectRatio == b.posterAspectRatio;
}
