import 'package:flutter/foundation.dart';

import 'watch_next_program.dart';

class AppContentChannel {
  static const _programLimit = 50;

  final int id;
  final String packageName;
  final String name;
  final String appName;
  final bool hidden;
  final List<WatchNextProgram> programs;
  String get key => '$packageName:$id';
  AppContentChannel._(
    this.id,
    this.packageName,
    this.name,
    this.appName,
    this.hidden,
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
        .take(_programLimit)
        .map((value) {
          final next = WatchNextProgram.fromMap(
            value,
            feedSubtitle: _feedSubtitle(value),
          );
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
      map['hidden'] == true,
      List.unmodifiable(programs),
    );
    if (previous != null &&
        next.id == previous.id &&
        next.packageName == previous.packageName &&
        next.name == previous.name &&
        next.appName == previous.appName &&
        next.hidden == previous.hidden &&
        listEquals(next.programs, previous.programs)) {
      return previous;
    }
    return next;
  }

  static final _releaseYear = RegExp(r'^(\d{4})(?:$|-)');
  static final _ratingNumber = RegExp(r'^\d+(?:[.,]\d+)?$');
  static final _genreCode = RegExp(r'^[A-Z]+(?:_[A-Z]+)*$');

  static String? _feedSubtitle(Map<dynamic, dynamic> map) {
    final date = (map['releaseDate'] as String?)?.trim() ?? '';
    final year = _releaseYear.firstMatch(date)?.group(1);
    final rating = (map['reviewRating'] as String?)?.trim() ?? '';
    // TvContract review rating styles: stars (0), vote counts (1), percent (2).
    final ratingLabel = _ratingNumber.hasMatch(rating)
        ? switch (map['reviewRatingStyle']) {
            null || 0 => '★ $rating',
            2 => '$rating%',
            _ => null,
          }
        : null;
    final genre = (map['genre'] as String?)?.trim() ?? '';
    final genreLabel = _genreCode.hasMatch(genre)
        ? genre[0] + genre.substring(1).toLowerCase().replaceAll('_', ' ')
        : genre;
    final filmDetails = [
      if (year != null && year != '0000') year,
      ?ratingLabel,
      if (genreLabel.isNotEmpty) genreLabel,
    ];
    if (filmDetails.isNotEmpty) return filmDetails.join(' · ');

    final seconds = ((map['duration'] as int?) ?? 0) ~/ 1000;
    final author = (map['author'] as String?)?.trim() ?? '';
    final description = (map['description'] as String?)?.trim() ?? '';
    final title = (map['title'] as String?)?.trim() ?? '';
    final secondary = author.isEmpty ? description : author;
    final videoDetails = [
      if (seconds > 0) _videoTime(seconds),
      if (secondary.isNotEmpty &&
          secondary.toLowerCase() != title.toLowerCase())
        secondary,
    ];
    return videoDetails.isEmpty ? null : videoDetails.join(' · ');
  }

  static String _videoTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = seconds ~/ 60 % 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return hours == 0
        ? '$minutes:$rest'
        : '$hours:${minutes.toString().padLeft(2, '0')}:$rest';
  }

  static bool _sameProgram(WatchNextProgram a, WatchNextProgram b) =>
      a.id == b.id &&
      a.packageName == b.packageName &&
      a.title == b.title &&
      a.description == b.description &&
      a.feedSubtitle == b.feedSubtitle &&
      a.watchNextType == b.watchNextType &&
      a.lastEngagementTime == b.lastEngagementTime &&
      a.playbackPosition == b.playbackPosition &&
      a.duration == b.duration &&
      a.intentUri == b.intentUri &&
      a.posterArtUri == b.posterArtUri &&
      a.thumbnailUri == b.thumbnailUri &&
      a.posterAspectRatio == b.posterAspectRatio;
}
