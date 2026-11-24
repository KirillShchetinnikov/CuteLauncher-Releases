import 'dart:async';
import '../poster_queue.dart';
import '../launcher_image_cache.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../app_focus_color.dart';
import '../models/app_content_channel.dart';
import '../models/watch_next_program.dart';
import '../providers/app_channels_service.dart';
import '../providers/appearance_service.dart';
import '../providers/settings_service.dart';
import '../providers/foreground_work.dart';
import '../section_icons.dart';
import '../tile_appearance.dart';
import '../tile_image_geometry.dart';
import '../home_layout.dart';
import '../cover_memory_image.dart';
import '../image_limits.dart';
import '../theme/launcher_style.dart';
import 'action_notice.dart';
import 'appearance_surface.dart';
import 'app_card_keys.dart';
import 'category_focus.dart';
import 'content_card_label.dart';
import 'focus_keyboard_listener.dart';
import 'home_scroll_motion.dart';
import 'tile_paint_layer.dart';
import 'tile_artwork.dart';
import 'tile_theme_outline.dart';
import 'reordering_tile_viewport.dart';
import 'section_heading_icon.dart';
import 'home_skeleton.dart';

TextStyle? _previewTitleStyle(
  BuildContext context,
  TileAppearance style, {
  bool focused = false,
}) => style.contentAppTileStyle && style.contentUseSourceLabels
    ? LauncherStyle.of(context).tileLabelStyle(context, style, focused)
    : style.labelStyle;

class AppContentRow extends StatefulWidget {
  final AppContentChannel? channel;
  final String? loadingTitle;
  final double? loadingRatio;
  final List<WatchNextProgram> programs;
  final TileAppearance? appearance;
  final Size? appTileSize;
  final SectionIcon titleIcon;
  const AppContentRow({
    super.key,
    required this.channel,
    required this.programs,
    this.appearance,
    this.appTileSize,
    this.titleIcon = SectionIcon.appFeeds,
  }) : loadingTitle = null, loadingRatio = null;
  const AppContentRow.loading({super.key, required String title,
    required double aspectRatio, this.appearance, this.appTileSize,
    this.titleIcon = SectionIcon.appFeeds})
      : channel = null, programs = const [], loadingTitle = title,
        loadingRatio = aspectRatio;

  @override
  State<AppContentRow> createState() => _AppContentRowState();
}

class _AppContentRowState extends State<AppContentRow> {
  late List<WatchNextProgram> _displayed = widget.programs;

  @override
  void didUpdateWidget(AppContentRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(oldWidget.programs, widget.programs)) return;
    final focus = CategoryFocus.maybeOf(context);
    final previous = _displayed;
    _displayed = List.generate(widget.programs.length, (i) {
      final next = widget.programs[i];
      if (oldWidget.channel?.key != widget.channel?.key || i >= previous.length) {
        return next;
      }
      final old = previous[i];
      if (old.id == next.id &&
          old.posterArtUri == next.posterArtUri &&
          old.thumbnailUri == next.thumbnailUri &&
          old.intentUri == next.intentUri) {
        return next;
      }
      // Only a mounted slot can hand its current artwork to the next frame.
      final node = focus?.nodeFor(oldWidget.programs[i].id.toString());
      final card = node?.context?.findAncestorStateOfType<_ContentPreviewCardState>();
      return card?._posterBytes == null ? next : old;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<AppChannelsService>();
    final style =
        widget.appearance ??
        context.watch<AppearanceService?>()?.appearance ??
        const TileAppearance();
    final channel = widget.channel;
    if (channel == null) {
      return ContentPreviewRow.loading(title: widget.loadingTitle!, style: style,
        titleIcon: widget.titleIcon,
        aspectRatio: widget.loadingRatio!, appTileSize: widget.appTileSize,
        reserveDescription: true, focusLoading: true);
    }
    final aspectRatio = context.select<SettingsService, double>(
      (_) => service.formatFor(channel).aspectRatio,
    );
    return ContentPreviewRow(
      programs: widget.programs,
      displayedPrograms: _displayed,
      preload: (program, priority) => service.programPoster(program, priority: priority),
      title: '${channel.name} · ${channel.appName}',
      titleIcon: widget.titleIcon,
      style: style,
      appTileSize: widget.appTileSize,
      aspectRatio: aspectRatio,
      reserveDescription: true,
      card: (program, size) {
        final index = widget.programs.indexOf(program);
        final shown = _displayed[index];
        return ContentPreviewCard(
          program: program,
          title: shown.title,
          subtitle: shown.feedSubtitle,
          onReplacementReady: identical(shown, program) ? null : () {
            if (!mounted || index >= widget.programs.length ||
                !identical(widget.programs[index], program)) {
              return;
            }
            setState(() => _displayed[index] = program);
          },
          style: style,
          size: size,
          posterRefreshes: service.posterRefreshes,
          cachedPoster: () =>
              service.cachedPoster(shown.posterArtUri) ??
              service.cachedPoster(shown.thumbnailUri),
          loadPrioritizedPoster: (priority) => service.programPoster(program, priority: priority),
          invalidatePoster: () => service.evictPoster(program),
          observePoster: (bytes) =>
              service.observePoster(channel, program.id, bytes),
          onOpen: (context) async {
            final ok = await service.launch(shown);
            if (!ok && context.mounted) {
              showActionNotice(
                context,
                AppLocalizations.of(context)!.appChannelsLaunchFailed,
                error: true,
              );
            }
          },
        );
      },
    );
  }
}

class ContentPreviewRow extends StatefulWidget {
  static const loadingFocusKey = ':loading-content';

  const ContentPreviewRow({
    super.key,
    required this.programs,
    this.displayedPrograms,
    this.preload,
    required this.title,
    this.titleIcon,
    required this.style,
    required this.aspectRatio,
    required Widget Function(WatchNextProgram, Size) this.card,
    this.geometricEntry = true,
    this.reserveDescription = false,
    this.appTileSize,
  }) : focusLoading = false;

  const ContentPreviewRow.loading({
    super.key,
    required this.title,
    this.titleIcon,
    required this.style,
    required this.aspectRatio,
    this.reserveDescription = false,
    this.appTileSize,
    this.focusLoading = false,
  }) : programs = const [],
       displayedPrograms = null,
       preload = null,
       card = null,
       geometricEntry = false;

  final List<WatchNextProgram> programs;
  final List<WatchNextProgram>? displayedPrograms;
  final Future<Uint8List?> Function(WatchNextProgram, PosterPriority)? preload;
  final String title;
  final SectionIcon? titleIcon;
  final TileAppearance style;
  final double aspectRatio;
  final Widget Function(WatchNextProgram, Size)? card;
  final bool geometricEntry;
  final bool reserveDescription;
  final Size? appTileSize;
  final bool focusLoading;

  @override
  State<ContentPreviewRow> createState() => _ContentPreviewRowState();
}

class _ContentPreviewRowState extends State<ContentPreviewRow> {
  CategoryFocusController? _focus;
  double _extent = 240;
  double _horizontalInset = 32;
  final _bounds = GlobalKey();
  String? _pending;
  int _request = 0;
  int _preloadGeneration = 0;
  int _window = 0;
  int? _preloadStart;

  void _schedulePreload() {
    if (_focus?.hasFocus != true || widget.preload == null || _window <= 0) return;
    final index = widget.programs.indexWhere((p) => p.id.toString() == _focus?.selected.value);
    if (index < 0) return;
    final stride = math.max(1, _window ~/ 2);
    final start = index ~/ stride * stride;
    if (_preloadStart == start) return;
    _preloadStart = start;
    final generation = ++_preloadGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _preloadGeneration) unawaited(_warm(start, generation));
    });
  }

  Future<void> _warm(int start, int generation) async {
    bool active() => mounted && generation == _preloadGeneration &&
        _focus?.hasFocus == true && ModalRoute.of(context)?.isCurrent != false &&
        (WidgetsBinding.instance.lifecycleState == null ||
         WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);
    final end = math.min(widget.programs.length, start + _window);
    for (var i = start; i < end && active(); i++) {
      final program = widget.programs[i];
      if (_focus!.hasMountedPackage(program.id.toString()) ||
          (program.posterArtUri.isEmpty && program.thumbnailUri.isEmpty)) {
        continue;
      }
      await widget.preload!(program, () => active() ? 0 : -1);
    }
  }

  void _resetPreload() {
    ++_preloadGeneration;
    _preloadStart = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final focus = CategoryFocus.maybeOf(context);
    if (focus == _focus) return;
    _resetPreload();
    _disconnect();
    _focus = focus;
    focus?.materialize = _select;
    focus?.navigate = _navigate;
    focus?.enter = widget.geometricEntry ? _enter : null;
    focus?.selected.addListener(_revealSelection);
  }

  void _disconnect() {
    _focus?.materialize = null;
    _focus?.navigate = null;
    _focus?.enter = null;
    _focus?.selected.removeListener(_revealSelection);
  }

  Future<bool> _enter(AxisDirection direction, double x) {
    final box = _bounds.currentContext?.findRenderObject();
    final scroll = _focus?.scrollController;
    if (box is! RenderBox || widget.programs.isEmpty) {
      return Future.value(false);
    }
    final left = x - box.localToGlobal(Offset.zero).dx;
    final local = Directionality.of(context) == TextDirection.rtl
        ? box.size.width - left
        : left;
    final index =
        ((local -
                    _horizontalInset +
                    (scroll?.hasClients == true ? scroll!.offset : 0)) /
                _extent)
            .floor()
            .clamp(0, widget.programs.length - 1);
    return _select(widget.programs[index].id.toString());
  }

  double _offsetToReveal(ScrollPosition position, int index) {
    final start = index * _extent;
    final end = start + _extent - widget.style.horizontalGap;
    final offset = position.pixels;
    if (start < offset) return start;
    if (end > offset + position.viewportDimension) {
      return end - position.viewportDimension;
    }
    return offset;
  }

  void _revealSelection() {
    _schedulePreload();
    final focus = _focus!;
    final scroll = focus.scrollController;
    if (!scroll.hasClients || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final position = scroll.position;
    if (!position.hasContentDimensions) return;
    final index = widget.programs.indexWhere(
      (program) => program.id.toString() == focus.selected.value,
    );
    if (index >= 0) {
      revealHomeOffset(context, position, _offsetToReveal(position, index));
    }
  }

  Future<bool> _select(String id, {bool byArrow = false}) async {
    final request = ++_request;
    if (widget.focusLoading && id == ContentPreviewRow.loadingFocusKey) {
      return _focus?.focusMounted(id) ?? false;
    }
    final origin = FocusManager.instance.primaryFocus;
    final index = widget.programs.indexWhere((p) => p.id.toString() == id);
    final focus = _focus;
    if (index < 0 || focus == null) return false;
    final materializing = !focus.hasMountedPackage(id);
    if (materializing) setState(() => _pending = id);
    final scroll = focus.scrollController;
    // Home and section entry can restore a distant card immediately. An arrow
    // lets the requested card mount first, then the focus change scrolls to it.
    if (!byArrow && scroll.hasClients && scroll.position.hasContentDimensions) {
      final position = scroll.position;
      final offset = _offsetToReveal(
        position,
        index,
      ).clamp(position.minScrollExtent, position.maxScrollExtent);
      if ((offset - position.pixels).abs() > .5 ||
          position.isScrollingNotifier.value) {
        position.jumpTo(offset);
      }
    }
    if (!materializing) {
      if (_pending != null) setState(() => _pending = null);
      final alreadyFocused = focus.hasFocus && focus.lastPackage == id;
      final selected = focus.focusMounted(id);
      if (selected && alreadyFocused) focus.reveal?.call();
      return selected;
    }
    WidgetsBinding.instance.ensureVisualUpdate();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted ||
        request != _request ||
        ModalRoute.of(context)?.isCurrent == false ||
        FocusManager.instance.primaryFocus != origin &&
            origin?.context != null) {
      if (mounted && request == _request) setState(() => _pending = null);
      return false;
    }
    final alreadyFocused = focus.hasFocus && focus.lastPackage == id;
    final selected = focus.focusMounted(id);
    setState(() => _pending = null);
    // A new card reveals itself when focus is applied. Only an explicit return
    // to the already focused card needs a reveal here.
    if (selected && alreadyFocused) focus.reveal?.call();
    return selected;
  }

  bool _navigate(String id, AxisDirection direction) {
    final focus = _focus;
    if (focus == null) return false;
    if (direction == AxisDirection.up || direction == AxisDirection.down) {
      return false;
    }
    final index = widget.programs.indexWhere(
      (p) => p.id.toString() == (_pending ?? id),
    );
    final forward =
        (direction == AxisDirection.right) !=
        (Directionality.of(context) == TextDirection.rtl);
    final target = index + (forward ? 1 : -1);
    if (target >= 0 && target < widget.programs.length) {
      _select(widget.programs[target].id.toString(), byArrow: true);
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant ContentPreviewRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.programs, widget.programs)) {
      _resetPreload();
      _schedulePreload();
    }
    final focus = _focus;
    focus?.enter = widget.geometricEntry ? _enter : null;
    final last = focus?.lastPackage;
    final oldIndex = oldWidget.programs.indexWhere((p) => p.id.toString() == last);
    final nextIndex = widget.programs.indexWhere((p) => p.id.toString() == last);
    if (focus?.hasFocus == true &&
        last != null &&
        (nextIndex < 0 || widget.displayedPrograms != null && nextIndex != oldIndex) &&
        widget.programs.isNotEmpty) {
      final origin = FocusManager.instance.primaryFocus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final current = FocusManager.instance.primaryFocus;
        if (mounted && widget.programs.isNotEmpty &&
            ModalRoute.of(context)?.isCurrent != false &&
            (current == origin || current == null || current is FocusScopeNode)) {
          final target = widget.programs.any((p) => p.id.toString() == last)
              ? last : widget.programs[oldIndex.clamp(0, widget.programs.length - 1)].id.toString();
          final node = focus?.nodeFor(target);
          if (node != null && node.hasPrimaryFocus && focus?.lastPackage != target) {
            focus?.record(target, node);
          }
          _select(target);
        }
      });
    }
  }

  @override
  void dispose() {
    ++_request;
    _disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final window = widget.preload == null ? 0 : settings.memoryLimit(MemoryLimit.preload);
    if (_window != window) {
      _window = window;
      _resetPreload();
      _schedulePreload();
    }
    final launcherStyle = LauncherStyle.of(context);
    final card = widget.card;
    final style = widget.style;
    final appTiles = style.contentAppTileStyle;
    final matchedSize = appTiles ? widget.appTileSize : null;
    final ratio =
        matchedSize?.aspectRatio ??
        (appTiles ? style.aspectRatio : widget.aspectRatio);
    final showBelow =
        !appTiles || style.labels == 'all' && style.labelPosition == 'below';
    final singleLine = appTiles && !widget.reserveDescription;
    final textScaler = MediaQuery.textScalerOf(context);
    var textHeight = showBelow
        ? style.labelSize *
                  textScaler.scale(1) *
                  (singleLine ? 1.4 : 2.8) +
              (singleLine ? 8 : 12)
        : 0.0;
    if (appTiles && showBelow) {
      double lineHeight(TextStyle? textStyle) {
        final painter = TextPainter(
          text: TextSpan(style: DefaultTextStyle.of(context).style.merge(textStyle)),
          textDirection: Directionality.of(context),
          textScaler: textScaler,
        );
        final height = painter.preferredLineHeight;
        painter.dispose();
        return height;
      }
      final titleHeight = lineHeight(_previewTitleStyle(context, style));
      final descriptionHeight = singleLine ? 0.0 : lineHeight(style.labelStyle);
      textHeight = math.max(textHeight, 8 + titleHeight + descriptionHeight);
    }
    final height = style.tileSize * (ratio < 1 ? 1.5 : 1);
    final width = height * ratio;
    _extent = width + style.horizontalGap;
    _focus?.gap = style.horizontalGap;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: style.sectionGap / 2),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final layoutStyle = TileAppearance({
            ...style.values,
            'aspectRatio': ratio,
            'size': height,
          });
          double focusScale(double width) => launcherStyle.tileFocusScale(
            settings.themes,
            style,
            width: width,
            focused: true,
          );
          final result = HomeLayout.withFocusReserve(
            availableWidth: constraints.maxWidth,
            focusScale: focusScale,
            glow: style.focusBorderStyle() == 'glow',
            layoutForWidth: (width) => HomeLayout(
              mode: 'row',
              count: card == null ? 1 : widget.programs.length,
              availableWidth: width,
              labelHeight: textHeight,
              style: layoutStyle,
              fixedTileSize: matchedSize,
            ),
          );
          final layout = result.layout;
          _horizontalInset = result.horizontalInset;
          final scale = result.focusScale;
          final focusGrowth = layout.height * (scale - 1);
          final lift = style.focusEffect == 'lift' ? style.focusLift : 0.0;
          final topReserve = focusGrowth + lift + 2;
          final centered = appTiles && !showBelow;
          final topInset = style.compactSectionInset(
            math.max(8.0, topReserve),
            focusReserve: (centered ? focusGrowth / 2 : focusGrowth) + lift + 2,
          );
          final bottomInset = style.compactSectionInset(
            8,
            focusReserve: (centered ? focusGrowth / 2 : -textHeight) + 2,
          );
          _extent = layout.stepX;
          Widget placeholder(bool focused) => HomeSkeletonBlock(
              radius: launcherStyle.tileCorners(
                settings.themes,
                radius: style.number('radius'),
              ),
              focused: focused,
          );
          final tiles = SizedBox(
            key: _bounds,
            height: layout.height + textHeight + topInset + bottomInset,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _horizontalInset,
                topInset,
                _horizontalInset,
                bottomInset,
              ),
              child: card == null
                  ? HomeSkeletonRow(
                        width: layout.width, height: layout.height,
                        gap: layout.gapX, labelHeight: textHeight,
                        radius: launcherStyle.tileCorners(settings.themes,
                          radius: style.number('radius')),
                        card: (first) => first && widget.focusLoading
                            ? _FocusableLoadingCard(builder: placeholder)
                            : placeholder(false),
                    )
                  : Focus(
                    canRequestFocus: false,
                    onFocusChange: (focused) => focused ? _schedulePreload() : _resetPreload(),
                    child: ReorderingTileViewport(
                      rowLookaheadScreens: settings.memorySaverEnabled ? 0.3 : 1.0,
                      keyByPosition: widget.displayedPrograms != null,
                      layout: layout,
                      packages: widget.programs
                          .map((p) => p.id.toString())
                          .toList(),
                      controller: _focus!.scrollController,
                      selected: _focus?.lastPackage,
                      selection: _focus?.selected,
                      requested: _pending,
                      animate: false,
                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (_, i) => card(
                        widget.programs[i],
                        Size(layout.width, layout.height),
                      ),
                    )),
            ),
          );
          final showSelected = appTiles && style.labels == 'selected';
          final title = Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: style.number('sectionTitleSize')),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
          Widget selectedLabel(String? selectedId) {
            final index = widget.programs.indexWhere((p) => p.id.toString() == selectedId);
            final text = index < 0 ? '' :
                (widget.displayedPrograms ?? widget.programs)[index].displayTitle;
            final node = style.scrollContentLabels
                ? _focus?.nodeFor(selectedId)
                : null;
            if (node == null) {
              return ContentCardLabel(
                text,
                style: style.labelStyle,
                scroll: false,
              );
            }
            return ListenableBuilder(
              listenable: node,
              builder: (_, _) => ContentCardLabel(
                text,
                style: style.labelStyle,
                scroll: node.hasPrimaryFocus,
              ),
            );
          }

          Widget heading(String? selectedId) => Padding(
            padding: EdgeInsetsDirectional.only(
              start: style.sectionTitleAligned ? _horizontalInset : 16,
              end: style.sectionTitleAligned ? _horizontalInset : 0,
              bottom: 8,
            ),
            child: Row(
              children: [
                if (style.sectionTitles) ...[
                  if (widget.titleIcon case final icon? when style.sectionIcons) ...[
                    SectionHeadingIcon(icon),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: title),
                ],
                if (showSelected) ...[
                  if (style.sectionTitles)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('·', style: style.labelStyle),
                    ),
                  Expanded(child: selectedLabel(selectedId)),
                ],
              ],
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSelected && _focus != null)
                ValueListenableBuilder<String?>(
                  valueListenable: _focus!.selected,
                  builder: (_, selected, _) => heading(selected),
                )
              else if (style.sectionTitles || showSelected)
                heading(null),
              tiles,
            ],
          );
        },
      ),
    );
  }
}

class _FocusableLoadingCard extends StatefulWidget {
  const _FocusableLoadingCard({required this.builder});

  final Widget Function(bool focused) builder;

  @override
  State<_FocusableLoadingCard> createState() => _FocusableLoadingCardState();
}

class _FocusableLoadingCardState extends State<_FocusableLoadingCard> {
  final _node = FocusNode(debugLabel: 'Home loading card');
  CategoryFocusController? _focus;
  static const _key = ContentPreviewRow.loadingFocusKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final focus = CategoryFocus.maybeOf(context);
    if (focus == _focus) return;
    _focus?.unregister(_key, _node);
    _focus = focus;
    _focus?.register(_key, _node);
  }

  @override
  void dispose() {
    _focus?.unregister(_key, _node);
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _node,
    onFocusChange: (focused) {
      setState(() {});
      if (focused) {
        _focus?.record(_key, _node);
        _focus?.reveal?.call();
      }
    },
    onKeyEvent: (_, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.arrowRight ||
          AppCardKeys.validationKeys.contains(key)) {
        return KeyEventResult.handled;
      }
      final direction = switch (key) {
        LogicalKeyboardKey.arrowUp => AxisDirection.up,
        LogicalKeyboardKey.arrowDown => AxisDirection.down,
        _ => null,
      };
      final leave = _focus?.leave;
      if (direction == null || leave == null) return KeyEventResult.ignored;
      leave(direction, _node.rect.center.dx);
      return KeyEventResult.handled;
    },
    child: Semantics(
      label: AppLocalizations.of(context)!.loading,
      child: widget.builder(_node.hasFocus),
    ),
  );
}

class ContentPreviewCard extends StatefulWidget {
  const ContentPreviewCard({
    super.key,
    required this.program,
    required this.title,
    required this.style,
    required this.size,
    required this.onOpen,
    this.posterRefreshes,
    this.cachedPoster,
    this.loadPoster,
    this.loadPrioritizedPoster,
    this.onReplacementReady,
    this.invalidatePoster,
    this.observePoster,
    this.onDetails,
    this.onUp,
    this.subtitle,
    this.progress,
    this.artworkBadge,
  });

  final WatchNextProgram program;
  final String title;
  final TileAppearance style;
  final Size size;
  final Future<void> Function(BuildContext) onOpen;
  final Listenable? posterRefreshes;
  final Uint8List? Function()? cachedPoster;
  final Future<Uint8List?> Function()? loadPoster;
  final Future<Uint8List?> Function(PosterPriority priority)? loadPrioritizedPoster;
  final VoidCallback? onReplacementReady;
  final VoidCallback? invalidatePoster;
  final Future<void> Function(Uint8List?)? observePoster;
  final void Function(BuildContext)? onDetails;
  final VoidCallback? onUp;
  final String? subtitle;
  final double? progress;
  final Widget? artworkBadge;

  @override
  State<ContentPreviewCard> createState() => _ContentPreviewCardState();
}

class _ContentPreviewCardState extends State<ContentPreviewCard>
    with WidgetsBindingObserver {
  final _node = FocusNode();
  CategoryFocusController? _focus;
  Uint8List? _posterBytes;
  (String, String)? _posterSource;
  (String, String) get _source =>
      (widget.program.posterArtUri, widget.program.thumbnailUri);
  int _posterRequest = 0;
  bool _launching = false;
  bool _paintFocusTransition = false;
  Timer? _posterRetry;
  ForegroundWork? _work;
  bool _needsRetry = false, _decodeFailed = false, _enabled = true;
  int _retryAttempt = 0;
  int _posterRevision = 0;
  bool _loadingPoster = false;
  Size? _screenSize;
  bool get _foreground => WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  void _cancelRetry() {
    _posterRetry?.cancel();
    _posterRetry = null;
    _work?.cancel(this);
  }

  void _scheduleRetry() {
    _needsRetry = true;
    if (!mounted || !_foreground || !_enabled || _posterRetry != null ||
        (widget.loadPoster == null && widget.loadPrioritizedPoster == null) ||
        (_source.$1.isEmpty && _source.$2.isEmpty)) {
      return;
    }
    final delay = Duration(seconds: math.min(30, 2 << math.min(_retryAttempt, 4)));
    _posterRetry = Timer(delay, () {
      _posterRetry = null;
      if (!mounted || !_foreground || !_enabled) return;
      _retryAttempt++;
      final work = _work;
      if (work == null) {
        unawaited(_loadPoster());
      } else {
        unawaited(work.schedule(this, _loadPoster));
      }
    });
  }

  void _posterDecodeFailed() {
    if (_decodeFailed) return;
    _decodeFailed = true;
    widget.invalidatePoster?.call();
    _scheduleRetry();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _cancelRetry();
      if (_loadingPoster) {
        ++_posterRequest;
        _loadingPoster = false;
        _needsRetry = true;
      }
    } else if (_needsRetry) {
      _scheduleRetry();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.posterRefreshes?.addListener(_loadPoster);
    _posterBytes = widget.cachedPoster?.call();
    _posterSource = _posterBytes == null ? null : _source;
    _loadPoster();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.maybeSizeOf(context);
    _work = context.read<ForegroundWork?>();
    _enabled = TickerMode.valuesOf(context).enabled;
    if (!_enabled) {
      _cancelRetry();
    } else if (_needsRetry) {
      _scheduleRetry();
    }
    final focus = CategoryFocus.maybeOf(context);
    if (focus != _focus) {
      _focus?.unregister(widget.program.id.toString(), _node);
      _focus = focus;
      focus?.register(widget.program.id.toString(), _node);
    }
  }

  @override
  void didUpdateWidget(covariant ContentPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program.id != widget.program.id) {
      _focus?.unregister(oldWidget.program.id.toString(), _node);
      _focus?.register(widget.program.id.toString(), _node);
    }
    final loaderChanged = oldWidget.posterRefreshes != widget.posterRefreshes;
    if (loaderChanged) {
      oldWidget.posterRefreshes?.removeListener(_loadPoster);
      widget.posterRefreshes?.addListener(_loadPoster);
      _posterBytes = widget.cachedPoster?.call();
      _posterSource = _posterBytes == null ? null : _source;
    }
    if (loaderChanged ||
        (widget.onReplacementReady != null || oldWidget.onReplacementReady != null) &&
            oldWidget.program != widget.program ||
        (oldWidget.program.posterArtUri, oldWidget.program.thumbnailUri) !=
            _source) {
      _retryAttempt = 0;
      _decodeFailed = false;
      _loadPoster();
    }
  }

  Future<void> _loadPoster() async {
    _cancelRetry();
    if (!_foreground || !_enabled) {
      _needsRetry = true;
      return;
    }
    final request = ++_posterRequest;
    _loadingPoster = true;
    final source = _source;
    Uint8List? bytes;
    try {
      final prioritized = widget.loadPrioritizedPoster;
      bytes = prioritized == null
          ? await widget.loadPoster?.call()
          : await prioritized(() => _posterPriority(request));
    } catch (_) {
      // Service loaders report transport errors; custom loaders may throw.
    }
    if (!mounted || request != _posterRequest) return;
    _loadingPoster = false;
    if (bytes == null || bytes.isEmpty) {
      _scheduleRetry();
    } else {
      _needsRetry = false;
      if (!_decodeFailed && widget.onReplacementReady == null) _retryAttempt = 0;
    }
    // Only materialized cards contribute to automatic format detection.
    await widget.observePoster?.call(bytes);
    if (!mounted || request != _posterRequest) return;
    if (widget.onReplacementReady != null) {
      if (bytes == null || bytes.isEmpty) return;
      final settings = context.read<SettingsService>();
      final scale = LauncherStyle.of(context).tileFocusScale(settings.themes,
          widget.style, width: widget.size.width, focused: true);
      final ratio = MediaQuery.devicePixelRatioOf(context);
      final ImageProvider image = widget.style.contentAppTileStyle
          ? PosterTileImage(sizedImage(
              MemoryImage(bytes), widget.size, ratio * scale, maximumEdge: 1024,
            ))
          : CoverMemoryImage(
              bytes, logicalSize: widget.size, pixelRatio: ratio, focusScale: scale,
            );
      var failed = false;
      _loadingPoster = true;
      await precacheImage(image, context, onError: (_, _) => failed = true);
      if (!mounted || request != _posterRequest) return;
      _loadingPoster = false;
      if (!_enabled || !_foreground) {
        _needsRetry = true;
        return;
      }
      if (failed) {
        widget.invalidatePoster?.call();
        _scheduleRetry();
        return;
      }
      _retryAttempt = 0;
      widget.onReplacementReady?.call();
    }
    // A failed revalidation keeps the existing image at this URI. A genuinely
    // different, unavailable image still gets the normal placeholder.
    if (bytes == null && _posterSource == source) return;
    if (!_decodeFailed && listEquals(bytes, _posterBytes)) {
      _posterSource = source;
      return;
    }
    setState(() {
      if (_decodeFailed) _posterRevision++;
      _decodeFailed = false;
      _posterBytes = bytes;
      _posterSource = source;
    });
  }

  int _posterPriority(int request) {
    if (!mounted || request != _posterRequest || !_foreground || !_enabled) return -1;
    if (_node.hasPrimaryFocus) return 3;
    final size = _screenSize;
    final render = _node.context?.findRenderObject();
    if (size == null || render is! RenderBox || !render.attached || !render.hasSize) return 0;
    final origin = render.localToGlobal(Offset.zero);
    if (!(Offset.zero & size).overlaps(origin & render.size)) return 0;
    return _focus?.hasFocus == true ? 2 : 1;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelRetry();
    ++_posterRequest;
    widget.posterRefreshes?.removeListener(_loadPoster);
    _focus?.unregister(widget.program.id.toString(), _node);
    _node.dispose();
    super.dispose();
  }

  Future<void> _launch() async {
    if (_launching) return;
    _launching = true;
    try {
      await widget.onOpen(context);
    } finally {
      _launching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final settings = context.watch<SettingsService>();
    final launcherStyle = LauncherStyle.of(context);
    final appTiles = style.contentAppTileStyle;
    final showLabels = !appTiles || style.labels == 'all';
    final showInside =
        appTiles && showLabels && style.labelPosition == 'inside';
    final showBelow = showLabels && !showInside;
    final scrollLabel = style.scrollContentLabels && _node.hasPrimaryFocus;
    final corners = launcherStyle.tileCorners(
      settings.themes,
      radius: style.number('radius'),
    );
    final radius = corners.topLeft.x;
    final scale = launcherStyle.tileFocusScale(
      settings.themes,
      style,
      width: widget.size.width,
      focused: _node.hasFocus,
    );
    final transform = Matrix4.diagonal3Values(scale, scale, 1);
    if (_node.hasFocus && style.focusEffect == 'lift') {
      transform.setTranslationRaw(0, -style.focusLift, 0);
    }
    final animate =
        (style.values['focusTransition'] as bool? ??
            settings.appSelectorTransitionAnimationEnabled) &&
        !MediaQuery.disableAnimationsOf(context);
    if (!animate) {
      _paintFocusTransition = false;
    } else if (_node.hasFocus) {
      _paintFocusTransition =
          scale != 1 || (style.focusEffect == 'lift' && style.focusLift != 0);
    }
    const fallbackIcon = Center(child: Icon(Icons.movie_outlined, size: 40));
    Widget fallback() => appTiles
        ? fallbackIcon
        : ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: fallbackIcon,
          );
    final decodeScale = launcherStyle.tileFocusScale(
      settings.themes,
      style,
      width: widget.size.width,
      focused: true,
    );
    final bytes = _posterBytes;
    Widget image() {
      if (bytes == null || bytes.isEmpty) return fallback();
      if (appTiles) {
        return TileArtwork(
          key: ValueKey(_posterRevision),
          image: MemoryImage(bytes),
          isPoster: true,
          mode: style.bannerImageMode == TileImageMode.icon
              ? TileImageMode.edgeColor
              : style.bannerImageMode,
          borderRadius: corners,
          decodeScale: decodeScale,
          errorBuilder: (_, _, _) { _posterDecodeFailed(); return fallback(); },
        );
      }
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Image(
          key: ValueKey(_posterRevision),
          image: CoverMemoryImage(
            bytes,
            logicalSize: widget.size,
            pixelRatio: MediaQuery.devicePixelRatioOf(context),
            focusScale: decodeScale,
          ),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) { _posterDecodeFailed(); return fallback(); },
        ),
      );
    }

    final cover = image();
    final progress = widget.progress;
    final badge = widget.artworkBadge;
    final badgeInset = math.max(
      6.0,
      math.min(radius, widget.size.shortestSide / 2) * .35,
    );
    final artwork = !appTiles && progress == null && badge == null
        ? cover
        : Stack(
            fit: StackFit.expand,
            children: [
              cover,
              if (appTiles)
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _node.hasFocus ? 0 : .10,
                    duration: animate
                        ? launcherStyle.tileDuration
                        : Duration.zero,
                    curve: Curves.easeInOut,
                    child: const ColoredBox(color: Colors.black),
                  ),
                ),
              if (showInside)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: progress == null ? 0 : 4,
                  child: ColoredBox(
                    color: style.labelBackground,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ContentCardLabel(
                        widget.title,
                        style: style.labelStyle,
                        scroll: scrollLabel,
                      ),
                    ),
                  ),
                ),
              if (progress != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: LinearProgressIndicator(value: progress),
                ),
              if (badge != null)
                PositionedDirectional(
                  top: badgeInset,
                  start: badgeInset,
                  end: badgeInset,
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: badge,
                  ),
                ),
            ],
          );

    final surface = appTiles
        ? FutureBuilder<Color?>(
            future:
                _node.hasFocus &&
                    style.dynamicFocusColor &&
                    bytes != null &&
                    bytes.isNotEmpty
                ? appFocusColor(bytes)
                : null,
            builder: (_, snapshot) => AppearanceSurface(
              appearance: style,
              borderRadius: corners,
              elevation: launcherStyle.tileElevation(
                settings.themes,
                _node.hasFocus,
              ),
              focused: _node.hasFocus,
              focusColor:
                  snapshot.data ??
                  Color(int.parse('FF${settings.accentColorHex}', radix: 16)),
              child: RepaintBoundary(child: artwork),
            ),
          )
        : Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: ClipRRect(borderRadius: corners, child: artwork),
              ),
              if (_node.hasFocus)
                TileThemeOutline(
                  theme: settings.themes,
                  accent: Theme.of(context).colorScheme.primary,
                  radius: radius,
                  borderStyle: style.focusBorderStyle(
                    legacyHidden: settings.hideHighlightOutlineOnHomescreen,
                  ),
                  pulse:
                      style.values['focusPulse'] as bool? ??
                      settings.appHighlightAnimationEnabled,
                ),
            ],
          );

    return FocusKeyboardListener(
      onPressed: (key) {
        final direction = switch (key) {
          LogicalKeyboardKey.arrowUp => AxisDirection.up,
          LogicalKeyboardKey.arrowDown => AxisDirection.down,
          LogicalKeyboardKey.arrowLeft => AxisDirection.left,
          LogicalKeyboardKey.arrowRight => AxisDirection.right,
          _ => null,
        };
        if (direction != null) {
          if (direction == AxisDirection.up ||
              direction == AxisDirection.down) {
            final leave = _focus?.leave;
            if (leave != null) {
              leave(direction, _node.rect.center.dx);
              return KeyEventResult.handled;
            }
            if (direction == AxisDirection.up && widget.onUp != null) {
              widget.onUp!();
              return KeyEventResult.handled;
            }
          } else if (_focus?.navigate?.call(
                widget.program.id.toString(),
                direction,
              ) ==
              true) {
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }
        if (AppCardKeys.validationKeys.contains(key)) {
          _launch();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onLongPress: widget.onDetails == null
          ? null
          : (_) {
              widget.onDetails!(context);
              return KeyEventResult.handled;
            },
      builder: (_) => Semantics(
        label: showLabels ? null : widget.title,
        child: InkWell(
          focusNode: _node,
          onTap: _launch,
          onLongPress: widget.onDetails == null
              ? null
              : () => widget.onDetails!(context),
          onFocusChange: (focused) {
            setState(() {});
            if (focused) {
              _focus?.record(widget.program.id.toString(), _node);
              _focus?.reveal?.call();
            }
          },
          focusColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: widget.size.height,
                child: RaisedTile(
                  foreground: _node.hasFocus,
                  raised: _node.hasFocus || _paintFocusTransition,
                  // Raised artwork paints outside the row's viewport boundary.
                  // Keep its pulse/transform from repainting the shared Home layer.
                  child: RepaintBoundary(
                    child: AnimatedContainer(
                      duration: !animate
                          ? Duration.zero
                          : appTiles
                          ? launcherStyle.tileDuration
                          : const Duration(milliseconds: 150),
                      curve: appTiles ? Curves.easeOutCubic : Curves.linear,
                      // Keep the shrinking artwork outside the viewport clip until
                      // it returns to its cell, below the new focused artwork.
                      onEnd: () {
                        if (!_node.hasFocus && _paintFocusTransition) {
                          setState(() => _paintFocusTransition = false);
                        }
                      },
                      transform: transform,
                      transformAlignment: appTiles && !showBelow
                          ? Alignment.center
                          : Alignment.bottomCenter,
                      child: surface,
                    ),
                  ),
                ),
              ),
              if (showBelow) ...[
                const SizedBox(height: 8),
                ContentCardLabel(
                  widget.title,
                  style: _previewTitleStyle(context, style, focused: _node.hasFocus),
                  textAlign: appTiles ? TextAlign.center : null,
                  maxLines: !appTiles && widget.subtitle == null ? 2 : 1,
                  scroll: scrollLabel,
                  subtitle: widget.subtitle,
                  subtitleStyle: style.labelStyle.copyWith(
                    color: style.labelStyle.color?.withValues(alpha: .85),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
