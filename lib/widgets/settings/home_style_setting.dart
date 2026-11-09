import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../category_appearance.dart';
import '../../home_style_availability.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../providers/appearance_service.dart';
import '../../providers/apps_service.dart';
import '../../providers/settings_service.dart';
import 'inherited_setting.dart';

/// Checks mode dependencies without locking common fields for local overrides.
class HomeStyleSetting extends StatelessWidget {
  final int? categoryId;
  final String field;
  final Widget Function(bool enabled) builder;
  const HomeStyleSetting({
    super.key,
    this.categoryId,
    required this.field,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AppearanceService>();
    final settings = context.watch<SettingsService?>();
    final categories = context.watch<AppsService?>()?.categories;
    final configuredTargets = categoryId == null
        ? categories?.where((c) => c.visible).toList() ?? <Category>[]
        : categories?.where((c) => c.id == categoryId).toList() ?? <Category>[];
    final populated = configuredTargets
        .where((c) => c.applications.isNotEmpty)
        .toList();
    // Empty categories must not keep an ineffective global tile control active.
    // Their section title/background can still be visible and editable.
    final targets =
        categoryId == null &&
            !field.startsWith('section') &&
            field != 'inactiveOpacity' &&
            populated.isNotEmpty
        ? populated
        : configuredTargets;
    HomeStyleBlock? check(Category? c, {int? sectionId}) {
      final id = sectionId ?? categoryId ?? c?.id;
      final layout = id == null
          ? const CategoryAppearance()
          : service.category(id);
      return homeStyleBlock(
        field,
        id == null ? service.appearance : service.tilesFor(id),
        layout,
        legacyRow: c == null || c.type == CategoryType.row,
        legacyColumns: c?.columnsCount ?? 6,
        economy: settings?.memorySaverEnabled ?? false,
        legacyHiddenBorder: settings?.hideHighlightOutlineOnHomescreen ?? false,
      );
    }
    Category? contentSource(int id) {
      final sourceId = service.tilesFor(id).contentAppTileSectionId;
      return sourceId == null ? null : categories
          ?.where((c) => c.id == sourceId && c.id != id && !c.isAppChannels)
          .firstOrNull;
    }

    final results = targets.isEmpty
        ? [check(null)]
        : targets.map(check).toList();
    final watchNextApplies = categoryId == null &&
        (settings?.showContinueWatching ?? false) &&
        const {
          'size', 'radius', 'horizontalGap', 'labelSize', 'labelColor',
          'sectionTitles', 'sectionTitleAligned', 'sectionTitleSize',
          'sectionBackground', 'sectionOpacity', 'sectionRadius',
          'focusEffect', 'focusScale', 'focusLift', 'focusBorderStyle',
          'focusPulse', 'focusTransition',
        }.contains(field);
    if (watchNextApplies) {
      const id = ContinueWatchingSection.sectionId;
      final source = field == 'size' ? contentSource(id) : null;
      results.add(const {'labelSize', 'labelColor'}.contains(field)
          ? null
          : check(source, sectionId: source == null ? id : null));
    }
    if (categoryId == null &&
        field == 'size' &&
        configuredTargets.any(
          (c) => c.isAppChannels && service.tilesFor(c.id).contentAppTileStyle &&
              check(contentSource(c.id)) == null,
        ) &&
        settings?.selectedAppChannels.isNotEmpty == true) {
      results.add(null);
    }
    final enabled = results.contains(null);
    final l = AppLocalizations.of(context)!;
    final reasons = results.whereType<HomeStyleBlock>().toSet();
    final hasOverrides = categoryId == null && (
      targets.any((c) => ownsHomeStyleField(service.category(c.id), field)) ||
      watchNextApplies && ownsHomeStyleField(
        service.category(ContinueWatchingSection.sectionId), field,
      )
    );
    final hint = enabled
        ? reasons.isEmpty && !hasOverrides
              ? null
              : field == 'size'
              ? l.homeStyleAutoOnly
              : l.homeStylePartial
        : reasons.length > 1
        ? l.homeStyleUnavailable
        : switch (reasons.single) {
            HomeStyleBlock.columns => l.tileSizeFromColumns,
            HomeStyleBlock.rows => l.homeStyleNeedsRows,
            HomeStyleBlock.labels => l.homeStyleNeedsLabels,
            HomeStyleBlock.allLabels => l.homeStyleNeedsAllLabels,
            HomeStyleBlock.scale => l.homeStyleNeedsScale,
            HomeStyleBlock.lift => l.homeStyleNeedsLift,
            HomeStyleBlock.border => l.homeStyleNeedsBorder,
            HomeStyleBlock.title => l.homeStyleNeedsTitle,
            HomeStyleBlock.economy => l.homeStyleEconomy,
            HomeStyleBlock.opaque => l.homeStyleOpaque,
            HomeStyleBlock.transparent => l.homeStyleTransparent,
            HomeStyleBlock.singleColumn => l.homeStyleSingleColumn,
            HomeStyleBlock.sectionBackground => l.homeStyleNeedsSectionBackground,
          };
    return InheritedSetting(
      categoryId: categoryId,
      field: field,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          builder(enabled),
          if (!enabled && hint != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(hint),
            ),
        ],
      ),
    );
  }
}
