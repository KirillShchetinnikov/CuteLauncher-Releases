import 'package:flauncher/l10n/app_localizations.dart';

// Keep canonical preset names in backups and leave custom names untouched.
String localizedSectionName(String name, AppLocalizations l10n) => switch (name) {
  'All Apps' => l10n.allApplications,
  'TV Apps' => l10n.tvApps,
  'Non-TV Apps' => l10n.nonTvApps,
  'Movies & Shows' => l10n.moviesShows,
  'Music' => l10n.music,
  'Games' => l10n.games,
  'Entertainment' => l10n.entertainment,
  'Live TV' => l10n.liveTv,
  'Sports' => l10n.sports,
  'News' => l10n.news,
  'Tools' => l10n.tools,
  'Favorites' => l10n.favorites,
  'Custom...' => l10n.customSectionName,
  _ => name,
};
