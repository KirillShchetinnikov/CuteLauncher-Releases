import 'models/category.dart';

/// Names are stored in section appearance and shared with backups.
enum SectionIcon {
  allApps,
  tvApps,
  otherApps,
  favorites,
  appFeeds,
  continueWatching,
  movies,
  music,
  games,
  entertainment,
  liveTv,
  sports,
  news,
  tools,
  photos,
  folder,
  weather,
  reading,
  kids,
  smartHome,
  travel,
  podcasts;

  static final _byName = values.asNameMap();

  static SectionIcon? fromName(Object? value) =>
      value is String ? _byName[value] : null;

  static SectionIcon forCategory(Category? category) {
    return switch (category?.systemKey) {
      'all_apps' => allApps,
      'tv_apps' => tvApps,
      'other_apps' => otherApps,
      'favorites' => favorites,
      'app_channels' => appFeeds,
      _ => switch (category?.name) {
        'Movies & Shows' => movies,
        'Music' => music,
        'Games' => games,
        'Entertainment' => entertainment,
        'Live TV' => liveTv,
        'Sports' => sports,
        'News' => news,
        'Tools' => tools,
        _ => folder,
      },
    };
  }
}
