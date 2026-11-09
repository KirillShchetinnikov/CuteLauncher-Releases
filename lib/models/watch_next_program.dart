class WatchNextProgram {
  final int id;
  final String packageName;
  final String title;
  final String description;
  final int watchNextType;
  final int lastEngagementTime;
  final int playbackPosition;
  final int duration;
  final String intentUri;
  final String posterArtUri;
  final String thumbnailUri;
  final double? posterAspectRatio;
  final String? feedSubtitle;
  String get displayTitle => title.trim().isEmpty ? description.trim() : title.trim();

  WatchNextProgram({
    required this.id,
    required this.packageName,
    required this.title,
    required this.description,
    required this.watchNextType,
    required this.lastEngagementTime,
    required this.playbackPosition,
    required this.duration,
    required this.intentUri,
    required this.posterArtUri,
    this.thumbnailUri = '',
    this.posterAspectRatio,
    this.feedSubtitle,
  });

  factory WatchNextProgram.fromMap(
    Map<dynamic, dynamic> map, {
    String? feedSubtitle,
  }) {
    return WatchNextProgram(
      id: map['id'] as int? ?? 0,
      packageName: map['packageName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      watchNextType: map['watchNextType'] as int? ?? 0,
      lastEngagementTime: map['lastEngagementTime'] as int? ?? 0,
      playbackPosition: map['playbackPosition'] as int? ?? 0,
      duration: map['duration'] as int? ?? 0,
      intentUri: map['intentUri'] as String? ?? '',
      posterArtUri: map['posterArtUri'] as String? ?? '',
      thumbnailUri: map['thumbnailUri'] as String? ?? '',
      posterAspectRatio: (map['posterAspectRatio'] as num?)?.toDouble(),
      feedSubtitle: feedSubtitle,
    );
  }
}
