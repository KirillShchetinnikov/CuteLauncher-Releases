import 'widgets/wallpaper_background.dart';
import 'widgets/adaptive_landscape_background.dart';
import 'widgets/app_artwork_background.dart';
import 'providers/remote_panel_service.dart';
import 'providers/slideshow_service.dart';
/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */


import 'widgets/initial_app_images.dart';
import 'widgets/now_playing_card.dart';
import 'providers/appearance_service.dart';
import 'tile_appearance.dart';
import 'package:flauncher/actions.dart';
import 'package:flauncher/custom_traversal_policy.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'widgets/home_section.dart';

import 'package:flauncher/widgets/launcher_alternative_view.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flutter/material.dart';
import 'widgets/tile_paint_layer.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/widgets/continue_watching_row.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import 'models/category.dart';
import 'widgets/category_focus.dart';

class FLauncher extends StatefulWidget {
  const FLauncher({super.key});

  @override
  State<FLauncher> createState() => FLauncherState();
}

class FLauncherState extends State<FLauncher> {
  final GlobalKey<FocusAwareAppBarState> _appBarKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final _categoryFocus = <int, CategoryFocusController>{};
  final _watchFocus = CategoryFocusController();
  final _watchSectionKey = GlobalKey();
  final _orderedFocus = <CategoryFocusController>[];
  bool _startupApplied = false;
  int _focusRequest = 0;
  final _activeCategory = ValueNotifier<int?>(null);
  int? _lastCategoryId;
  bool _lastWasWatchNext = false;

  Future<void> _focusHomeEntry({bool returningHome = false}) async {
    final request = ++_focusRequest;
    final settings = context.read<SettingsService>();
    bool isCurrent() =>
        mounted &&
        request == _focusRequest &&
        ModalRoute.of(context)?.isCurrent != false;
    final mode = settings.cardFocusMode;
    final sections = context.read<AppsService>().launcherSections;
    if (mode != CardFocusMode.settings) {
      if (returningHome && mode == CardFocusMode.remember &&
          _lastWasWatchNext &&
          settings.showContinueWatching &&
          context.read<WatchNextService>().programs.isNotEmpty) {
        _watchFocus.rememberLast = mode == CardFocusMode.remember;
        final focused = await _watchFocus.focusEntry(isCurrent: isCurrent);
        if (!mounted || !isCurrent()) return;
        _watchFocus.rememberLast = false;
        if (focused) return;
        if (!isCurrent()) return;
      }
      Category? category;
      if (returningHome && mode == CardFocusMode.remember && _lastCategoryId != null) {
        category = sections
            .whereType<Category>()
            .where(
              (c) =>
                  c.id == _lastCategoryId &&
                  c.visible &&
                  c.applications.isNotEmpty,
            )
            .firstOrNull;
      }
      if (category == null && _orderedFocus.where((c) => c.hasItems).firstOrNull == _watchFocus) {
        _watchFocus.rememberLast = false;
        final focused = await _watchFocus.focusEntry(isCurrent: isCurrent);
        if (!mounted || !isCurrent()) return;
        _watchFocus.rememberLast = false;
        if (focused || !isCurrent()) return;
      }
      category ??= sections
          .whereType<Category>()
          .where((c) => c.visible && c.applications.isNotEmpty)
          .firstOrNull;
      if (category != null) {
        final controller = _categoryFocus[category.id];
        if (returningHome) {
          controller?.rememberLast = mode == CardFocusMode.remember;
        }
        final focused = await controller?.focusCategory(
          category,
          isCurrent: isCurrent,
        );
        if (!isCurrent()) return;
        if (!mounted) return;
        controller?.rememberLast = false;
        if (focused == true) return;
      }
    }
    if (!isCurrent()) return;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _appBarKey.currentState?.focusSettings();
  }

  void _revealWatch() {
    final sectionContext = _watchSectionKey.currentContext;
    if (sectionContext == null || !_watchFocus.hasFocus) return;
    final outer = Scrollable.maybeOf(sectionContext);
    final box = sectionContext.findRenderObject();
    final viewport = outer?.context.findRenderObject();
    if (outer == null || box is! RenderBox || viewport is! RenderBox) return;
    final style = context.read<AppearanceService?>()?.appearance ?? const TileAppearance();
    final pos = outer.position;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy + pos.pixels;
    var offset = style.anchored ? top - pos.viewportDimension * style.sectionPosition : pos.pixels;
    if (top < offset) offset = top;
    if (top + box.size.height > offset + pos.viewportDimension) offset = top + box.size.height - pos.viewportDimension;
    pos.animateTo(offset.clamp(pos.minScrollExtent, pos.maxScrollExtent),
        duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
  }

  void returnHome() {
    context.read<LauncherState>().showLauncher();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusHomeEntry(returningHome: true);
    });
    // Home can arrive while the launcher is already visible and has no new frame.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    ++_focusRequest;
    _watchFocus.dispose();
    _activeCategory.dispose();
    for (final controller in _categoryFocus.values) { controller.dispose(); }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Actions(
    actions: <Type, Action<Intent>>{
      MoveFocusToSettingsIntent: CallbackAction<MoveFocusToSettingsIntent>(
        onInvoke: (_) {
          _appBarKey.currentState?.focusSettings();
          return null;
        },
      ),
    },
    child: FocusTraversalGroup(
      policy: RowByRowTraversalPolicy(),
      child: Stack(
        children: [
          RepaintBoundary(
            child: Consumer<WallpaperService>(
              builder: (_, wallpaperService, _) => _wallpaper(context, wallpaperService)
            ),
          ),
          Consumer<LauncherState>(
            builder: (_, state, child) => Visibility(
              replacement: const Center(
                child: AlternativeLauncherView()
              ),
              visible: state.launcherVisible,
              child: child!
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: FocusAwareAppBar(
                key: _appBarKey,
                remotePanel: context.watch<RemotePanelService?>()?.previewActive == true
                    ? context.read<RemotePanelService>() : null,
              ),
              body: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Consumer<AppsService>(
                  builder: (context, appsService, _) {
                    if (appsService.initialized) {
                      if (!_startupApplied) {
                        _startupApplied = true;
                        if (context.read<SettingsService>().cardFocusMode != CardFocusMode.settings) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && ModalRoute.of(context)?.isCurrent != false) {
                              _focusHomeEntry();
                            }
                          });
                        }
                      }
                      return InitialAppImages(child: Selector<WatchNextService, bool>(
                        selector: (_, watchNext) => watchNext.programs.isNotEmpty,
                        builder: (context, hasContinuingPrograms, _) =>
                            Selector<SettingsService, ({bool show, int order})>(
                              selector: (_, settings) => (
                                show: settings.showContinueWatching,
                                order: settings.continueWatchingOrder,
                              ),
                              builder: (context, cwSettings, _) =>
                                  LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
                                    controller: _scrollController,
                                    physics: const ClampingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const NowPlayingCard(),
                                        _sections(
                                            appsService.launcherSections.where((s) => s is! Category || s.visible).toList(),
                                            continueWatchingActive:
                                                cwSettings.show &&
                                                hasContinuingPrograms,
                                            continueWatchingOrder:
                                                cwSettings.order,
                                            viewportHeight: constraints.maxHeight),
                                      ],
                                    ),
                                  )),
                            ),
                    ));
                    }
                    else {
                      return _emptyState(context);
                    }
                  }
                )
              )
            )
          )
        ]
      )
    ),
  );

  Widget _sections(
    List<LauncherSection> sections, {
    bool continueWatchingActive = false,
    int continueWatchingOrder = 0,
    required double viewportHeight,
  }) {
    final previousActive = _orderedFocus.where((focus) => focus.hasFocus).firstOrNull;
    final previousIndex = _orderedFocus.indexOf(previousActive ?? _watchFocus);
    final ids = sections.whereType<Category>().map((category) => category.id).toSet();
    for (final id in _categoryFocus.keys.where((id) => !ids.contains(id)).toList()) {
      final controller = _categoryFocus.remove(id)!;
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    }
    final appearance = context.watch<AppearanceService?>()?.appearance ?? const TileAppearance();
    _watchFocus.rememberLast = false;
    _watchFocus.reveal = _revealWatch;
    _watchFocus.onSelected = () {
      _lastWasWatchNext = true;
      _activeCategory.value = -1;
    };
    List<Widget> children = [];
    _orderedFocus.clear();
    bool firstCategoryFound = false;
    bool cwInserted = false;

    int sectionIdx = 0;
    for (var section in sections) {
      if (continueWatchingActive && !cwInserted && sectionIdx == continueWatchingOrder) {
        final bool isFirstSection = !firstCategoryFound;
        children.add(CategoryFocus(key: _watchSectionKey, controller: _watchFocus, child: ContinueWatchingRow(isFirstSection: isFirstSection)));
        _orderedFocus.add(_watchFocus);
        cwInserted = true;
        firstCategoryFound = true;
      }

      final Key sectionKey = Key(section.id.toString());

      if (section is LauncherSpacer) {
        children.add(SizedBox(key: sectionKey, height: section.height.toDouble()));
        sectionIdx++;
        continue;
      }

      Category category = section as Category;
      final focus = _categoryFocus.putIfAbsent(category.id, CategoryFocusController.new)
        ..rememberLast = false
        ..onSelected = () {
          _activeCategory.value = category.id;
          _lastCategoryId = category.id;
          _lastWasWatchNext = false;
        }
        ..gap = appearance.horizontalGap
        ..configure(category.applications.map((app) => app.packageName));
      Widget categoryWidget;

      // Pass isFirstSection only to the first category found
      bool isFirstSection = !firstCategoryFound;
      if (isFirstSection) firstCategoryFound = true;

      focus.gap = context.read<AppearanceService?>()?.tilesFor(category.id).horizontalGap ?? 16;
      focus.leave = (direction, x) {
        final index = _orderedFocus.indexOf(focus);
        final step = direction == AxisDirection.down ? 1 : -1;
        var next = index + step;
        while (next >= 0 && next < _orderedFocus.length && !_orderedFocus[next].hasItems) { next += step; }
        if (next >= 0 && next < _orderedFocus.length) {
          final target = _orderedFocus[next];
          if (target.enter != null) { target.enter!(direction, x); }
          else { target.focusEntry(); }
        } else if (direction == AxisDirection.up) {
          _appBarKey.currentState?.focusSettings();
        }
      };
      if (category.applications.isNotEmpty) _orderedFocus.add(focus);
      categoryWidget = HomeSection(key: sectionKey, category: category, first: isFirstSection, activeCategory: _activeCategory);

      children.add(Padding(
          key: sectionKey,
          padding: EdgeInsets.symmetric(vertical: appearance.sectionGap / 2),
          child: CategoryFocus(
              controller: focus,
              child: categoryWidget)
      ));
      sectionIdx++;
    }

    if (continueWatchingActive && !cwInserted) {
      final bool isFirstSection = !firstCategoryFound;
      children.add(CategoryFocus(key: _watchSectionKey, controller: _watchFocus, child: ContinueWatchingRow(isFirstSection: isFirstSection)));
      _orderedFocus.add(_watchFocus);
      cwInserted = true;
      firstCategoryFound = true;
    }

    if (previousActive != null && (!_orderedFocus.contains(previousActive) || !previousActive.hasItems)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
        final available = _orderedFocus.where((focus) => focus.hasItems).toList();
        if (available.isEmpty) { _appBarKey.currentState?.focusSettings(); }
        else { available[previousIndex.clamp(0, available.length - 1)].focusEntry(); }
      });
    }
    return TilePaintLayer(child: Column(children: [
      if (appearance.anchored) SizedBox(height: viewportHeight * appearance.sectionPosition),
      ...children,
      if (appearance.anchored) SizedBox(height: viewportHeight),
    ]));
  }

  Widget _wallpaper(BuildContext context, WallpaperService wallpaperService) {
    final online = context.watch<OnlineWallpaperService?>();
    final source = context.watch<SettingsService>().backgroundSource;
    final slideshow = context.watch<SlideshowService?>();
    final image = source == 'slideshow' ? slideshow?.image : source == 'online' ? online?.wallpaper : source == 'gradient' || source == 'landscape' ? null : wallpaperService.wallpaper;
    final settings = context.watch<SettingsService>();
    final artwork = context.read<AppearanceService?>()?.focusedAppImage;
    if (source == 'app' && artwork != null) {
      return AppArtworkBackground(images: artwork, gradient: wallpaperService.gradient.gradient,
        enabled: context.watch<LauncherState>().launcherVisible,
        brightness: settings.wallpaperBrightness, saturation: settings.wallpaperSaturation,
        dimming: settings.wallpaperDimming);
    }
    return WallpaperBackground(
      key: Key('background_${source}_${source == 'online' ? online?.version : wallpaperService.version}'),
      image: image,
      gradient: wallpaperService.gradient.gradient,
      mode: settings.wallpaperFit,
      brightness: settings.wallpaperBrightness,
      saturation: settings.wallpaperSaturation,
      dimming: settings.wallpaperDimming,
      memorySaver: settings.memorySaverEnabled,
      artwork: source == 'landscape' ? const AdaptiveLandscapeBackground() : null,
    );
  }
  Widget _emptyState(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(localizations.loading, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
