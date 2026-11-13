import 'dart:math' as math;

import 'information_placement.dart';
import 'key_sounds.dart';
import 'widgets/wallpaper_background.dart';
import 'widgets/landscape_wallpaper.dart';
import 'widgets/video_wallpaper_background.dart';
import 'widgets/app_artwork_background.dart';
import 'providers/remote_panel_service.dart';
import 'providers/foreground_work.dart';
import 'providers/now_playing_service.dart';
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
import 'widgets/background_information.dart';
import 'providers/appearance_service.dart';
import 'theme/launcher_style.dart';
import 'tile_appearance.dart';
import 'package:flauncher/actions.dart';
import 'package:flauncher/custom_traversal_policy.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'widgets/home_section.dart';
import 'widgets/home_scroll_anchor.dart';
import 'widgets/home_scroll_motion.dart';
import 'widgets/app_content_row.dart';
import 'providers/app_channels_service.dart';
import 'feed_format.dart';

import 'package:flauncher/widgets/launcher_alternative_view.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'widgets/tile_paint_layer.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/widgets/continue_watching_row.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import 'models/category.dart';
import 'models/watch_next_program.dart';
import 'widgets/category_focus.dart';

class FLauncher extends StatefulWidget {
  const FLauncher({super.key});

  @override
  State<FLauncher> createState() => FLauncherState();
}

class FLauncherState extends State<FLauncher> {
  final GlobalKey<FocusAwareAppBarState> _appBarKey = GlobalKey();
  final _scrollController = HomeScrollController();
  final _categoryFocus = <int, CategoryFocusController>{};
  final _sectionKeys = <int, GlobalKey>{};
  final _watchFocus = CategoryFocusController();
  final _watchSectionKey = GlobalKey();
  final _feedFocus = <String, CategoryFocusController>{};
  final _feedKeys = <String, GlobalKey>{};
  String? _lastFeedKey;
  final _orderedFocus = <CategoryFocusController>[];
  int _focusRequest = 0;
  final _activeSectionId = ValueNotifier<int?>(null);
  int? _lastCategoryId;
  bool _lastWasWatchNext = false;
  ({double offset, GlobalKey? anchor, double? anchorTop})? _sectionPreviewOrigin;

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
      if (returningHome && mode == CardFocusMode.remember && _lastFeedKey != null) {
        final focus = _feedFocus[_lastFeedKey];
        if (focus != null && _orderedFocus.contains(focus) && focus.hasItems) {
          focus.rememberLast = true;
          final focused = await focus.focusEntry(isCurrent: isCurrent);
          if (!mounted || !isCurrent()) return;
          focus.rememberLast = false;
          if (focused) return;
        }
      }
      if (returningHome && mode == CardFocusMode.remember &&
          _lastWasWatchNext &&
          _orderedFocus.contains(_watchFocus) && _watchFocus.hasItems) {
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
      final emptySectionFocus = {
        for (final c in sections.whereType<Category>())
          if (c.applications.isEmpty) _categoryFocus[c.id],
      };
      final firstSection = _orderedFocus
          .where((c) => c.hasItems && !emptySectionFocus.contains(c))
          .firstOrNull;
      if (category == null && firstSection != null) {
        firstSection.rememberLast = false;
        final focused = await firstSection.focusEntry(isCurrent: isCurrent);
        if (!mounted || !isCurrent()) return;
        firstSection.rememberLast = false;
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
      if (firstSection != null &&
          await firstSection.focusEntry(isCurrent: isCurrent)) {
        return;
      }
    }
    if (!isCurrent()) return;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _appBarKey.currentState?.focusSettings();
  }

  void _revealWatch() {
    _revealContent(_watchSectionKey, _watchFocus);
  }

  void _revealContent(GlobalKey key, CategoryFocusController focus) {
    if (!focus.hasFocus || ModalRoute.of(context)?.isCurrent == false) return;
    final geometry = _sectionGeometry(key);
    if (geometry == null) return;
    final (position: pos, :top, :height) = geometry;
    final style = context.read<AppearanceService?>()?.appearance ?? const TileAppearance();
    var offset = style.anchored ? top - pos.viewportDimension * style.sectionPosition : pos.pixels;
    if (top < offset) offset = top;
    if (top + height > offset + pos.viewportDimension) offset = top + height - pos.viewportDimension;
    revealHomeOffset(context, pos, offset);
  }

  ({ScrollPosition position, double top, double height})? _sectionGeometry(
    GlobalKey? key,
  ) {
    final sectionContext = key?.currentContext;
    if (sectionContext == null) return null;
    final box = sectionContext.findRenderObject();
    final outer = Scrollable.maybeOf(sectionContext);
    final viewport = outer?.context.findRenderObject();
    if (outer == null ||
        box is! RenderBox ||
        !box.hasSize ||
        viewport is! RenderBox) {
      return null;
    }
    final position = outer.position;
    return (
      position: position,
      top: box.localToGlobal(Offset.zero, ancestor: viewport).dy + position.pixels,
      height: box.size.height,
    );
  }

  void _revealSectionPreview(int sectionId, TileAppearance appearance) {
    final key = sectionId == ContinueWatchingSection.sectionId
        ? _watchSectionKey
        : _sectionKeys[sectionId];
    if (key == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          ModalRoute.isCurrentOf(context) == true ||
          context.read<LauncherState>().sectionPreviewId != sectionId) {
        return;
      }
      final geometry = _sectionGeometry(key);
      if (geometry == null) return;
      final (:position, :top, :height) = geometry;
      _sectionPreviewOrigin ??= _captureSectionPreviewOrigin(position);
      // A tall section previews its first screen of cards.
      final visibleHeight = math.min(height, position.viewportDimension);
      final preferred = appearance.anchored
          ? top - position.viewportDimension * appearance.sectionPosition
          : position.pixels;
      final offset = preferred.clamp(
        top + visibleHeight - position.viewportDimension,
        top,
      );
      revealHomeOffset(context, position, offset);
    });
  }

  ({double offset, GlobalKey? anchor, double? anchorTop}) _captureSectionPreviewOrigin(
    ScrollPosition position,
  ) {
    final anchor = _lastWasWatchNext
        ? _watchSectionKey
        : (_feedKeys[_lastFeedKey] ?? _sectionKeys[_lastCategoryId]);
    final geometry = _sectionGeometry(anchor);
    final offset = position.pixels;
    final visible = geometry != null &&
        geometry.top < offset + position.viewportDimension &&
        geometry.top + geometry.height > offset;
    return (
      offset: offset,
      anchor: visible ? anchor : null,
      anchorTop: visible ? geometry.top : null,
    );
  }

  void _restoreSectionPreviewOrigin() {
    if (_sectionPreviewOrigin == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || context.read<LauncherState>().sectionPreviewId != null) {
        return;
      }
      final origin = _sectionPreviewOrigin;
      _sectionPreviewOrigin = null;
      if (origin == null || !_scrollController.hasClients) return;
      final currentTop = _sectionGeometry(origin.anchor)?.top;
      final originalTop = origin.anchorTop;
      // Edits above the previous selection can move it in the scroll content.
      final offset = currentTop != null && originalTop != null
          ? origin.offset + currentTop - originalTop
          : origin.offset;
      revealHomeOffset(context, _scrollController.position, offset);
    });
  }

  void returnHome() {
    _sectionPreviewOrigin = null;
    context.read<LauncherState>().showLauncher();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusHomeEntry(returningHome: true);
    });
    // Home can arrive while the launcher is already visible and has no new frame.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Reveals the first card, optionally moving up if it already has focus.
  void focusFirstSectionCard({bool moveUp = false}) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final node = FocusManager.instance.primaryFocus;
    final focus = node?.context
        ?.getInheritedWidgetOfExactType<CategoryFocus>()?.controller;
    if (focus == null) return;
    final index = _orderedFocus.indexOf(focus);
    if (index < 0) return;

    if (moveUp && focus.nodeFor(focus.firstPackage) == node) {
      for (var previous = index - 1; previous >= 0; previous--) {
        final target = _orderedFocus[previous];
        final first = target.firstPackage;
        if (first == null ||
            first == HomeSection.emptyTileKey ||
            first == ContentPreviewRow.loadingFocusKey) {
          continue;
        }
        target.focusFirst();
        return;
      }
    }
    focus.focusFirst();
  }

  @override
  void dispose() {
    ++_focusRequest;
    _watchFocus.dispose();
    _activeSectionId.dispose();
    for (final controller in _categoryFocus.values) { controller.dispose(); }
    for (final controller in _feedFocus.values) { controller.dispose(); }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HomeKeySoundScope(child: Actions(
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
          Positioned.fill(child: Builder(builder: (context) =>
            context.watch<SettingsService>().backgroundSource == 'landscape'
                ? const SizedBox.shrink()
                : Selector<LauncherState, bool>(
                    selector: (_, state) => state.launcherVisible,
                    builder: (_, visible, _) => visible ? const BackgroundInformation() : const SizedBox.shrink(),
                  ),
          )),
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Consumer<AppsService>(
                  builder: (context, appsService, _) {
                    if (appsService.initialized) {
                      return InitialAppImages(showSkeletons: true, onReady: () async {
                        final focused = FocusManager.instance.primaryFocus?.context;
                        final alreadyNavigated = focused?.getInheritedWidgetOfExactType<CategoryFocus>() != null ||
                            focused?.findAncestorStateOfType<FocusAwareAppBarState>() != null;
                        if (!alreadyNavigated) await _focusHomeEntry();
                        if (context.mounted) context.read<ForegroundWork?>()?.homeReady();
                      }, child: Selector2<SettingsService, WatchNextService,
                          ({List<WatchNextProgram> programs, bool loading, int order})>(
                        selector: (_, settings, watchNext) {
                          final programs = ContinueWatchingRow.visiblePrograms(settings, appsService, watchNext);
                          return (
                            programs: programs,
                            loading: settings.showContinueWatching && programs.isEmpty &&
                                !watchNext.initialized && watchNext.hasPermission,
                            order: settings.continueWatchingOrder,
                          );
                        },
                        shouldRebuild: (previous, next) => previous.loading != next.loading ||
                            previous.order != next.order || !listEquals(previous.programs, next.programs),
                        builder: (context, watchNext, _) => LayoutBuilder(builder: (context, constraints) {
                          final sections = _sections(
                            appsService.launcherSections.where((s) => s is! Category || s.visible).toList(),
                            continueWatchingPrograms: watchNext.programs,
                            continueWatchingLoading: watchNext.loading,
                            continueWatchingOrder: watchNext.order,
                            viewportHeight: constraints.maxHeight,
                            viewportWidth: constraints.maxWidth,
                            previewId: context.select<LauncherState, int?>(
                              (state) => state.sectionPreviewId,
                            ),
                          );
                          return SingleChildScrollView(
                            controller: _scrollController,
                            physics: sections.singleTape
                                ? const NeverScrollableScrollPhysics()
                                : const ClampingScrollPhysics(),
                            padding: const EdgeInsets.only(top: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const NowPlayingCard(),
                                sections.child,
                              ],
                            ),
                          );
                        }),
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
  ));

  ({Widget child, bool singleTape}) _sections(
    List<LauncherSection> sections, {
    List<WatchNextProgram> continueWatchingPrograms = const [],
    bool continueWatchingLoading = false,
    int continueWatchingOrder = 0,
    required double viewportHeight,
    required double viewportWidth,
    required int? previewId,
  }) {
    final previousActive = _orderedFocus.where((focus) => focus.hasFocus).firstOrNull;
    final previousIndex = _orderedFocus.indexOf(previousActive ?? _watchFocus);
    final ids = sections.whereType<Category>().map((category) => category.id).toSet();
    _sectionKeys.removeWhere((id, _) => !ids.contains(id));
    for (final id in _categoryFocus.keys.where((id) => !ids.contains(id)).toList()) {
      final controller = _categoryFocus.remove(id)!;
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    }
    final appearanceService = context.watch<AppearanceService?>();
    final appearance = appearanceService?.appearance ?? const TileAppearance();
    var previewShift = Offset.zero;
    if (previewId != null && Directionality.of(context) == TextDirection.rtl) {
      final style = LauncherStyle.of(context);
      final safe = style.panelInsets(context);
      final panelEdge = style.settingsWidth +
          math.max(style.panelMargin, safe.right);
      if (panelEdge < viewportWidth) {
        previewShift = Offset(-panelEdge, 0);
      }
    }
    Offset previewOffset(int id) => previewId == id ? previewShift : Offset.zero;
    Widget contentSectionOpacity(int id, bool first, Widget child) =>
        HomeSectionOpacity(
          sectionId: id,
          activeSectionId: _activeSectionId,
          first: first,
          forceOpaque: previewId == id,
          inactiveOpacity: appearance.number('inactiveOpacity') ?? 1,
          child: child,
        );
    late final commonTileSize = () {
      final layout = HomeSection.layoutFor(
        context,
        availableWidth: viewportWidth,
        style: appearance,
        count: 1,
      ).layout;
      return Size(layout.width, layout.height);
    }();
    late final sourceCategories = context.read<AppsService>().categories;
    ({TileAppearance style, Size? size}) contentTiles(int id) {
      final service = appearanceService;
      final style = service?.tilesFor(id) ?? appearance;
      if (service == null || !style.contentAppTileStyle) {
        return (style: style, size: null);
      }
      final sourceId = style.contentAppTileSectionId;
      final source = sourceId == null
          ? null
          : sourceCategories.where((c) =>
              c.id == sourceId && c.id != id && !c.isAppChannels).firstOrNull;
      if (source == null) return (style: style, size: commonTileSize);

      final sourceStyle = service.tilesFor(source.id);
      final layoutStyle = service.category(source.id);
      final padding = sourceStyle.number('sectionPadding') ?? layoutStyle.padding;
      final layout = HomeSection.layoutFor(
        context,
        availableWidth: viewportWidth - 2 * padding,
        style: sourceStyle,
        count: 1,
        category: source,
        categoryStyle: layoutStyle,
      ).layout;
      return (
        style: service.tilesFor(id, contentSource: source),
        size: Size(layout.width, layout.height),
      );
    }
    _watchFocus.rememberLast = false;
    _watchFocus.reveal = _revealWatch;
    _watchFocus.leave = (direction, x) => _leaveSection(_watchFocus, direction, x);
    _watchFocus.onSelected = () {
      _lastFeedKey = null;
      _lastWasWatchNext = true;
      _activeSectionId.value = ContinueWatchingSection.sectionId;
      _scrollController.anchorTo(_watchSectionKey);
    };
    _scrollController.canPreserve = () => mounted &&
        ModalRoute.of(context)?.isCurrent != false &&
        context.read<LauncherState>().sectionPreviewId == null;
    List<Widget> children = [];
    _orderedFocus.clear();
    bool firstCategoryFound = false;
    bool cwInserted = false;
    bool hasFeedGroup = false;
    final showWatchNext = continueWatchingPrograms.isNotEmpty || continueWatchingLoading;
    final feeds = context.watch<AppChannelsService?>();
    final selectedFeeds = feeds == null ? <String>[] : context.watch<SettingsService>().selectedAppChannels;
    final activeFeedKeys = <String>{};

    Widget? appFeeds(Category category) {
      late final tiles = contentTiles(category.id);
      late final style = tiles.style;
      late final matchedSize = tiles.size;
      final hiddenPackages = selectedFeeds.isEmpty ? <String>{} : context.read<AppsService>().applications.where((a) => a.hidden).map((a) => a.packageName).toSet();
      final rows = <Widget>[];
      for (final key in selectedFeeds) {
        if (hiddenPackages.contains(key.split(':').first)) continue;
        final channel = feeds?.channels.where((c) => c.key == key && c.programs.isNotEmpty && !hiddenPackages.contains(c.packageName)).firstOrNull;
        if (channel == null && (feeds == null || feeds.initialized)) continue;
        final limit = feeds!.cardLimit;
        final available = channel?.programs ?? const <WatchNextProgram>[];
        final programs = available.length <= limit
            ? available
            : available.take(limit).toList(growable: false);
        activeFeedKeys.add(key);
        final focus = _feedFocus.putIfAbsent(key, CategoryFocusController.new);
        final sectionKey = _feedKeys.putIfAbsent(key, GlobalKey.new);
        focus.configure(channel == null ? const [ContentPreviewRow.loadingFocusKey]
            : programs.map((p) => p.id.toString()));
        focus.leave = (direction, x) => _leaveSection(focus, direction, x);
        focus.reveal = () => _revealContent(sectionKey, focus);
        focus.onSelected = () {
          _lastFeedKey = key;
          _lastWasWatchNext = false;
          _activeSectionId.value = category.id;
          _scrollController.anchorTo(sectionKey);
        };
        _orderedFocus.add(focus);
        final format = feeds.settings.appChannelFormat(key);
        rows.add(CategoryFocus(key: sectionKey, controller: focus,
          child: channel == null ? AppContentRow.loading(
            title: AppLocalizations.of(context)!.appChannelsTitle,
            appearance: style, appTileSize: matchedSize,
            aspectRatio: (format == FeedFormat.auto
                ? feeds.settings.appChannelFormat(key, detected: true)
                : format).aspectRatio,
          ) : AppContentRow(
            channel: channel, programs: programs, appearance: style,
            appTileSize: matchedSize,
          )));
      }
      if (rows.isEmpty) return null;
      return Container(key: const ValueKey('app-channels-group'),
        decoration: style.sectionDecoration(),
        padding: EdgeInsets.all(style.number('sectionPadding') ?? 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ...rows,
        ]));
    }

    void addWatchNext() {
      const id = ContinueWatchingSection.sectionId;
      final focusLoading = continueWatchingLoading;
      final (:style, :size) = contentTiles(id);
      children.add(CategoryFocus(
        key: _watchSectionKey,
        controller: _watchFocus,
        child: Transform.translate(
          offset: previewOffset(id),
          child: contentSectionOpacity(
            id,
            !firstCategoryFound,
            ContinueWatchingRow(
              isFirstSection: !firstCategoryFound,
              programs: continueWatchingPrograms,
              focusLoading: focusLoading,
              appearance: appearanceService == null ? null : style,
              appTileSize: size,
            ),
          ),
        ),
      ));
      cwInserted = true;
      if (continueWatchingPrograms.isNotEmpty || focusLoading) {
        _orderedFocus.add(_watchFocus);
        firstCategoryFound = true;
      }
    }

    int sectionIdx = 0;
    for (var section in sections) {
      if (showWatchNext && !cwInserted && sectionIdx == continueWatchingOrder) {
        addWatchNext();
      }

      final Key sectionKey = Key(section.id.toString());

      if (section is LauncherSpacer) {
        children.add(SizedBox(key: sectionKey, height: section.height.toDouble()));
        sectionIdx++;
        continue;
      }

      if (section is Category && section.isAppChannels) {
        final group = appFeeds(section);
        if (group != null) {
          children.add(Transform.translate(
            key: _sectionKeys.putIfAbsent(section.id, GlobalKey.new),
            offset: previewOffset(section.id),
            child: contentSectionOpacity(
              section.id,
              !firstCategoryFound && activeFeedKeys.isNotEmpty,
              group,
            ),
          ));
          hasFeedGroup = true;
          if (activeFeedKeys.isNotEmpty) firstCategoryFound = true;
        }
        sectionIdx++;
        continue;
      }

      Category category = section as Category;
      final focus = _categoryFocus.putIfAbsent(category.id, CategoryFocusController.new)
        ..rememberLast = false
        ..onSelected = () {
          _lastFeedKey = null;
          _activeSectionId.value = category.id;
          _lastCategoryId = category.id;
          _lastWasWatchNext = false;
          final key = _sectionKeys[category.id];
          if (key != null) _scrollController.anchorTo(key);
        }
        ..gap = appearance.horizontalGap
        ..configure(category.applications.isEmpty
            ? const [HomeSection.emptyTileKey]
            : category.applications.map((app) => app.packageName));
      Widget categoryWidget;

      // Pass isFirstSection only to the first category found
      bool isFirstSection = !firstCategoryFound;
      if (isFirstSection) firstCategoryFound = true;

      focus.gap = context.read<AppearanceService?>()?.tilesFor(category.id).horizontalGap ?? 16;
      focus.leave = (direction, x) => _leaveSection(focus, direction, x);
      _orderedFocus.add(focus);
      categoryWidget = HomeSection(key: sectionKey, category: category, first: isFirstSection,
        activeSectionId: _activeSectionId, previewed: previewId == category.id);

      children.add(Padding(
          key: _sectionKeys.putIfAbsent(category.id, GlobalKey.new),
          padding: EdgeInsets.symmetric(vertical: appearance.sectionGap / 2),
          child: Transform.translate(
            offset: previewOffset(category.id),
            child: CategoryFocus(controller: focus, child: categoryWidget),
          ),
      ));
      sectionIdx++;
    }

    if (showWatchNext && !cwInserted) addWatchNext();
    if (previewId != null) {
      _revealSectionPreview(previewId, appearance);
    } else {
      _restoreSectionPreviewOrigin();
    }

    for (final key in _feedFocus.keys.where((k) => !activeFeedKeys.contains(k)).toList()) {
      final removed = _feedFocus.remove(key)!;
      _feedKeys.remove(key);
      WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
    }

    if (previousActive != null && (!_orderedFocus.contains(previousActive) || !previousActive.hasItems)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
        final available = _orderedFocus.where((focus) => focus.hasItems).toList();
        if (available.isEmpty) { _appBarKey.currentState?.focusSettings(); }
        else { available[previousIndex.clamp(0, available.length - 1)].focusEntry(); }
      });
    }
    final categories = sections.whereType<Category>().where((c) => !c.isAppChannels).toList();
    final category = categories.length == 1 ? categories.single : null;
    final categoryStyle = category == null ? null : context.read<AppearanceService?>()?.category(category.id);
    final mode = categoryStyle?.resolvedLayout(category?.type == CategoryType.row) ??
        (category?.type == CategoryType.row ? 'row' : 'grid');
    final nowPlaying = context.watch<NowPlayingService?>();
    final hasNowPlaying = nowPlaying != null && context.watch<SettingsService>().showNowPlaying &&
        (nowPlaying.initialized || nowPlaying.failed) &&
        (nowPlaying.media != null || !nowPlaying.allowed || nowPlaying.failed);
    // Anchored sections keep extra vertical space for focus reveals. A lone
    // tape must not let wheel/drag input move it through that space.
    final singleTape = category != null &&
        (mode == 'row' || mode == 'rows' && categoryStyle?.rows == 1) &&
        !showWatchNext && !hasFeedGroup &&
        !hasNowPlaying;
    return (singleTape: singleTape, child: TilePaintLayer(child: Column(children: [
      if (appearance.anchored) SizedBox(height: viewportHeight * appearance.sectionPosition),
      ...children,
      if (appearance.anchored) SizedBox(height: viewportHeight),
    ])));
  }

  void _leaveSection(CategoryFocusController focus, AxisDirection direction, double x) {
    final index = _orderedFocus.indexOf(focus);
    if (index < 0) return;
    final step = direction == AxisDirection.down ? 1 : -1;
    var next = index + step;
    while (next >= 0 && next < _orderedFocus.length && !_orderedFocus[next].hasItems) {
      next += step;
    }
    if (next >= 0 && next < _orderedFocus.length) {
      final target = _orderedFocus[next];
      if (target.enter != null) { target.enter!(direction, x); }
      else { target.focusEntry(); }
    } else if (direction == AxisDirection.up) {
      _appBarKey.currentState?.focusSettings();
    }
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
    if (source == 'landscape') {
      final placement = InformationPlacement(
        context.watch<AppearanceService?>()?.appearance ?? const TileAppearance(), settings);
      final showInformation = context.watch<LauncherState>().launcherVisible && placement.hasBackground;
      return LandscapeWallpaper(
        informationLayer: showInformation ? const BackgroundInformation() : null,
        gradient: wallpaperService.gradient.gradient,
        brightness: settings.wallpaperBrightness,
        saturation: settings.wallpaperSaturation,
        dimming: settings.wallpaperDimming,
        memorySaver: settings.memorySaverEnabled,
      );
    }
    return WallpaperBackground(
      key: Key('background_${source}_${source == 'online' ? online?.version : wallpaperService.version}'),
      image: source == 'picture' && wallpaperService.video != null ? null : image,
      cacheStaticLayers: source == 'picture' && wallpaperService.video != null,
      gradient: wallpaperService.gradient.gradient,
      mode: settings.wallpaperFit,
      brightness: settings.wallpaperBrightness,
      saturation: settings.wallpaperSaturation,
      dimming: settings.wallpaperDimming,
      memorySaver: settings.memorySaverEnabled,
      artworkBuilder: source == 'picture' && wallpaperService.video != null
          ? (background) => VideoWallpaperBackground(file: wallpaperService.video!, background: background,
              enabled: context.watch<LauncherState>().launcherVisible,
              mode: settings.wallpaperFit, memorySaver: settings.memorySaverEnabled)
          : null,
    );
  }
  Widget _emptyState(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    final style = context.watch<AppearanceService?>()?.appearance ?? const TileAppearance();
    return Semantics(label: localizations.loading, child: ExcludeSemantics(
      child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 24),
        child: Column(children: [
          for (var i = 0; i < 3; i++)
            ContentPreviewRow.loading(title: ' ', style: style,
              aspectRatio: style.aspectRatio, reserveDescription: true),
        ])),
    ));
  }
}
