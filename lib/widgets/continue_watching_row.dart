import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../actions.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart';
import '../models/watch_next_program.dart';
import '../providers/appearance_service.dart';
import '../providers/apps_service.dart';
import '../providers/settings_service.dart';
import '../providers/watch_next_service.dart';
import '../tile_appearance.dart';
import '../watch_next_selection.dart';
import 'app_content_row.dart';
import 'application_list_icon.dart';
import 'category_focus.dart';
import 'launcher_dialog.dart';
import 'watch_next_info_panel.dart';

class ContinueWatchingRow extends StatelessWidget {
  final bool isFirstSection;
  final bool focusLoading;
  final List<WatchNextProgram> programs;
  final TileAppearance? appearance;
  final Size? appTileSize;

  const ContinueWatchingRow({
    super.key,
    required this.programs,
    this.isFirstSection = true,
    this.focusLoading = false,
    this.appearance,
    this.appTileSize,
  });

  static List<WatchNextProgram> visiblePrograms(
    SettingsService settings,
    AppsService apps,
    WatchNextService watchNext,
  ) {
    if (!settings.showContinueWatching || !watchNext.hasPermission) return const [];
    final available = watchNext.programs;
    if (available.isEmpty) return const [];
    return selectWatchNextPrograms(
      available,
      hiddenIds: settings.hiddenWatchNextProgramIds.toSet(),
      hiddenPackages: {
        ...settings.hiddenWatchNextPackages,
        ...apps.applications.where((app) => app.hidden).map((app) => app.packageName),
      },
      appLimits: settings.watchNextAppLimits,
      totalLimit: settings.continueWatchingMaxItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final watchNext = context.read<WatchNextService>();
    final apps = context.read<AppsService>();
    CategoryFocus.maybeOf(context)?.configure(
      focusLoading ? const [ContentPreviewRow.loadingFocusKey]
          : programs.map((p) => p.id.toString()),
    );
    final style =
        appearance ??
        context.watch<AppearanceService?>()?.tilesFor(
          ContinueWatchingSection.sectionId,
        ) ??
        TileAppearance({'sectionTitles': settings.showCategoryTitles});
    final title = AppLocalizations.of(context)!.continueWatching;
    return Container(
      decoration: style.sectionDecoration(),
      padding: EdgeInsets.all(style.number('sectionPadding') ?? 0),
      child: programs.isEmpty
          ? ContentPreviewRow.loading(
              title: title,
              style: style,
              appTileSize: appTileSize,
              aspectRatio: 16 / 9,
              focusLoading: focusLoading,
              reserveDescription: settings.continueWatchingShowDescription,
            )
          : ContentPreviewRow(
              programs: programs,
              title: title,
              style: style,
              appTileSize: appTileSize,
              aspectRatio: 16 / 9,
              geometricEntry: false,
              reserveDescription: settings.continueWatchingShowDescription,
              card: (program, size) => WatchNextCard(
                program: program,
                appsService: apps,
                watchNextService: watchNext,
                handleUpNavigationToSettings: isFirstSection,
                style: style,
                size: size,
              ),
            ),
    );
  }
}

class WatchNextCard extends StatelessWidget {
  const WatchNextCard({
    super.key,
    required this.program,
    required this.appsService,
    required this.watchNextService,
    required this.handleUpNavigationToSettings,
    required this.style,
    required this.size,
  });

  final WatchNextProgram program;
  final AppsService appsService;
  final WatchNextService watchNextService;
  final bool handleUpNavigationToSettings;
  final TileAppearance style;
  final Size size;

  void _showDetails(BuildContext context) {
    final appIcon = appsService
        .getAppIcon(program.packageName)
        .catchError((Object _) => Uint8List(0));
    showLauncherDialog(
      context: context,
      builder: (_) => FutureBuilder<Uint8List>(
        future: appIcon,
        builder: (_, snapshot) => WatchNextInfoPanel(
          program: program,
          watchNextService: watchNextService,
          appsService: appsService,
          appIconBytes: snapshot.data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final theme = Theme.of(context);
    final package = program.packageName;
    final appName = package.isEmpty
        ? null
        : appsService.getApp(package)?.displayName.trim();
    final description = program.description.trim();
    final progress = program.duration > 0 && program.playbackPosition > 0
        ? (program.playbackPosition / program.duration).clamp(0.0, 1.0)
        : null;
    final hasPoster =
        program.posterArtUri.isNotEmpty || program.thumbnailUri.isNotEmpty;
    return ContentPreviewCard(
      program: program,
      title: program.displayTitle,
      style: style,
      size: size,
      posterRefreshes: hasPoster ? watchNextService.posterRefreshes : null,
      loadPoster: hasPoster ? () => watchNextService.poster(program) : null,
      invalidatePoster: () => watchNextService.evictPoster(program),
      onOpen: (_) async {
        await watchNextService.launch(program);
      },
      onDetails: _showDetails,
      onUp: handleUpNavigationToSettings
          ? () => Actions.invoke(context, const MoveFocusToSettingsIntent())
          : null,
      subtitle:
          settings.continueWatchingShowDescription &&
              description.isNotEmpty &&
              description.toLowerCase() != program.displayTitle.toLowerCase()
          ? description
          : null,
      progress: settings.continueWatchingShowProgress ? progress : null,
      artworkBadge: package.isEmpty
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withAlpha(255),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: ApplicationListIcon(
                        packageName: package,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        appName?.isNotEmpty == true ? appName! : package,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
