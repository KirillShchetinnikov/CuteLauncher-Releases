import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_content_channel.dart';
import '../models/watch_next_program.dart';
import '../providers/app_channels_service.dart';
import '../providers/appearance_service.dart';
import '../providers/settings_service.dart';
import '../tile_appearance.dart';
import '../home_layout.dart';
import '../cover_memory_image.dart';
import '../theme/launcher_style.dart';
import 'action_notice.dart';
import 'app_card_keys.dart';
import 'category_focus.dart';
import 'focus_keyboard_listener.dart';
import 'tile_paint_layer.dart';
import 'tile_theme_outline.dart';
import 'reordering_tile_viewport.dart';

class AppContentRow extends StatefulWidget {
  final AppContentChannel channel;
  final TileAppearance? appearance;
  const AppContentRow({super.key, required this.channel, this.appearance});
  @override
  State<AppContentRow> createState() => _AppContentRowState();
}

class _AppContentRowState extends State<AppContentRow> {
  CategoryFocusController? _focus;
  double _extent = 240;
  double _horizontalInset = 32;
  final _bounds = GlobalKey();
  String? _pending;
  int _request = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final focus = CategoryFocus.maybeOf(context);
    if (focus == _focus) return;
    _disconnect();
    _focus = focus;
    focus?.materialize = _select;
    focus?.navigate = _navigate;
    focus?.enter = _enter;
  }

  void _disconnect() {
    _focus?.materialize = null;
    _focus?.navigate = null;
    _focus?.enter = null;
  }

  Future<bool> _enter(AxisDirection direction, double x) {
    final box = _bounds.currentContext?.findRenderObject();
    final scroll = _focus?.scrollController;
    if (box is! RenderBox || widget.channel.programs.isEmpty) {
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
            .clamp(0, widget.channel.programs.length - 1);
    return _select(widget.channel.programs[index].id.toString());
  }

  Future<bool> _select(String id) async {
    final request = ++_request;
    final origin = FocusManager.instance.primaryFocus;
    final index = widget.channel.programs.indexWhere(
      (p) => p.id.toString() == id,
    );
    final focus = _focus;
    if (index < 0 || focus == null) return false;
    final materializing = !focus.hasMountedPackage(id);
    if (materializing) setState(() => _pending = id);
    final scroll = focus.scrollController;
    if (scroll.hasClients) {
      final start = index * _extent;
      var offset = scroll.offset;
      if (start < offset) offset = start;
      if (start + _extent > offset + scroll.position.viewportDimension) {
        offset = start + _extent - scroll.position.viewportDimension;
      }
      offset = offset.clamp(0, scroll.position.maxScrollExtent);
      if ((offset - scroll.offset).abs() > .5) scroll.jumpTo(offset);
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
    final index = widget.channel.programs.indexWhere(
      (p) => p.id.toString() == (_pending ?? id),
    );
    final forward =
        (direction == AxisDirection.right) !=
        (Directionality.of(context) == TextDirection.rtl);
    final target = index + (forward ? 1 : -1);
    if (target >= 0 && target < widget.channel.programs.length) {
      _select(widget.channel.programs[target].id.toString());
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant AppContentRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focus = _focus;
    final last = focus?.lastPackage;
    if (focus?.hasFocus == true &&
        last != null &&
        !widget.channel.programs.any((p) => p.id.toString() == last) &&
        widget.channel.programs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent != false) {
          _select(widget.channel.programs.first.id.toString());
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
    context.watch<SettingsService>();
    final ratio = context
        .read<AppChannelsService>()
        .formatFor(widget.channel)
        .aspectRatio;
    final style =
        widget.appearance ??
        context.watch<AppearanceService?>()?.appearance ??
        const TileAppearance();
    final textHeight =
        style.labelSize * MediaQuery.textScalerOf(context).scale(1) * 2.8 + 12;
    final height = style.tileSize * (ratio < 1 ? 1.5 : 1);
    final width = height * ratio;
    _extent = width + style.horizontalGap;
    _focus?.gap = style.horizontalGap;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: style.sectionGap / 2),
      child: LayoutBuilder(
        builder: (_, constraints) {
          HomeLayout makeLayout(double availableWidth) => HomeLayout(
            mode: 'row',
            count: widget.channel.programs.length,
            availableWidth: availableWidth,
            labelHeight: textHeight,
            style: TileAppearance({
              ...style.values,
              'aspectRatio': ratio,
              'size': height,
            }),
          );
          var layout = makeLayout(constraints.maxWidth);
          final scale = LauncherStyle.of(context).tileFocusScale(
            context.watch<SettingsService>().themes,
            style,
            width: layout.width,
            focused: true,
          );
          // Reserve focus growth at both ends even before a card is focused.
          // On narrow windows, shrink the base card to keep that reserve.
          _horizontalInset = math.max(
            layout.inset,
            layout.width * (scale - 1) / 2 +
                (style.focusBorderStyle() == 'glow'
                    ? TileGlowPainter.extent * scale
                    : 2),
          );
          if (_horizontalInset > layout.inset) {
            layout = makeLayout(
              constraints.maxWidth - 2 * (_horizontalInset - layout.inset),
            );
          }
          final topInset = math.max(
            8.0,
            layout.height * (scale - 1) +
                (style.focusEffect == 'lift' ? style.focusLift : 0) +
                2,
          );
          _extent = layout.stepX;
          final tiles = SizedBox(
            key: _bounds,
            height: layout.height + textHeight + topInset + 8,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _horizontalInset,
                topInset,
                _horizontalInset,
                8,
              ),
              child: ReorderingTileViewport(
                layout: layout,
                packages: widget.channel.programs
                    .map((p) => p.id.toString())
                    .toList(),
                controller: _focus!.scrollController,
                selected: _focus?.lastPackage,
                selection: _focus?.selected,
                requested: _pending,
                animate: false,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (_, i) => _ContentCard(
                  feed: widget.channel,
                  aspectRatio: ratio,
                  program: widget.channel.programs[i],
                  style: style,
                  height: layout.height,
                ),
              ),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (style.sectionTitles)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: style.sectionTitleAligned ? _horizontalInset : 16,
                    end: style.sectionTitleAligned ? _horizontalInset : 0,
                    bottom: 8,
                  ),
                  child: Text(
                    '${widget.channel.name} · ${widget.channel.appName}',
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              tiles,
            ],
          );
        },
      ),
    );
  }
}

class _ContentCard extends StatefulWidget {
  final AppContentChannel feed;
  final double aspectRatio;
  final WatchNextProgram program;
  final TileAppearance style;
  final double height;
  const _ContentCard({
    required this.feed,
    required this.aspectRatio,
    required this.program,
    required this.style,
    required this.height,
  });
  @override
  State<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<_ContentCard> {
  final _node = FocusNode();
  CategoryFocusController? _focus;
  AppChannelsService? _service;
  Uint8List? _posterBytes;
  String? _posterUri;
  int _posterRequest = 0;
  bool _launching = false;
  bool _paintFocusTransition = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final focus = CategoryFocus.maybeOf(context);
    if (focus != _focus) {
      _focus?.unregister(widget.program.id.toString(), _node);
      _focus = focus;
      focus?.register(widget.program.id.toString(), _node);
    }
    final service = context.read<AppChannelsService>();
    if (service != _service) {
      _service?.posterRefreshes.removeListener(_loadPoster);
      _service = service;
      service.posterRefreshes.addListener(_loadPoster);
      _posterBytes = service.cachedPoster(widget.program.posterArtUri);
      _posterUri = _posterBytes == null ? null : widget.program.posterArtUri;
      _loadPoster();
    }
  }

  @override
  void didUpdateWidget(covariant _ContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program.posterArtUri != widget.program.posterArtUri) {
      _loadPoster();
    }
  }

  Future<void> _loadPoster() async {
    final request = ++_posterRequest;
    final uri = widget.program.posterArtUri;
    final bytes = await _service!.poster(uri);
    if (!mounted || request != _posterRequest) return;
    // Observe only materialized cards; format stays fixed once learned.
    await _service!.observePoster(widget.feed, widget.program.id, bytes);
    if (!mounted || request != _posterRequest) return;
    // A failed revalidation keeps the existing image at this URI. A genuinely
    // different, unavailable image still gets the normal placeholder.
    if (bytes == null && _posterUri == uri) return;
    if (listEquals(bytes, _posterBytes)) {
      _posterUri = uri;
      return;
    }
    setState(() {
      _posterBytes = bytes;
      _posterUri = uri;
    });
  }

  @override
  void dispose() {
    ++_posterRequest;
    _service?.posterRefreshes.removeListener(_loadPoster);
    _focus?.unregister(widget.program.id.toString(), _node);
    _node.dispose();
    super.dispose();
  }

  Future<void> _launch() async {
    if (_launching) return;
    _launching = true;
    final ok = await context.read<AppChannelsService>().launch(widget.program);
    if (!mounted) return;
    _launching = false;
    if (!ok) {
      showActionNotice(
        context,
        AppLocalizations.of(context)!.appChannelsLaunchFailed,
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final settings = context.watch<SettingsService>();
    final launcherStyle = LauncherStyle.of(context);
    final corners = launcherStyle.tileCorners(
      settings.themes,
      radius: style.number('radius'),
    );
    final radius = corners.topLeft.x;
    final scale = launcherStyle.tileFocusScale(
      settings.themes,
      style,
      width: widget.height * widget.aspectRatio,
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
    Widget fallback() => ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.movie_outlined, size: 40)),
    );
    Widget image() {
      final bytes = _posterBytes;
      if (bytes == null || bytes.isEmpty) return fallback();
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Image(
          image: CoverMemoryImage(
            bytes,
            logicalSize: Size(
              widget.height * widget.aspectRatio,
              widget.height,
            ),
            pixelRatio: MediaQuery.devicePixelRatioOf(context),
            focusScale: launcherStyle.tileFocusScale(
              settings.themes,
              style,
              width: widget.height * widget.aspectRatio,
              focused: true,
            ),
          ),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => fallback(),
        ),
      );
    }

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
            _focus?.leave?.call(direction, _node.rect.center.dx);
          } else {
            _focus?.navigate?.call(widget.program.id.toString(), direction);
          }
          return KeyEventResult.handled;
        }
        if (AppCardKeys.validationKeys.contains(key)) {
          _launch();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      builder: (_) => InkWell(
        focusNode: _node,
        onTap: _launch,
        onFocusChange: (focused) {
          setState(() {});
          if (focused) {
            _focus?.record(widget.program.id.toString(), _node);
            // Only adjust this row horizontally. Walking all Scrollables also
            // starts an outer animation which competes with the section anchor.
            final inner = Scrollable.maybeOf(context);
            final box = context.findRenderObject();
            if (inner != null && box != null) {
              inner.position.ensureVisible(
                box,
                alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
              );
            }
            _focus?.reveal?.call();
          }
        },
        focusColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: widget.height,
              child: RaisedTile(
                foreground: _node.hasFocus,
                raised: _node.hasFocus || _paintFocusTransition,
                // Raised artwork paints outside the row's viewport boundary.
                // Keep its pulse/transform from repainting the shared Home layer.
                child: RepaintBoundary(
                  child: AnimatedContainer(
                    duration: animate
                        ? const Duration(milliseconds: 150)
                        : Duration.zero,
                    // Keep the shrinking artwork outside the viewport clip until
                    // it returns to its cell, below the new focused artwork.
                    onEnd: () {
                      if (!_node.hasFocus && _paintFocusTransition) {
                        setState(() => _paintFocusTransition = false);
                      }
                    },
                    transform: transform,
                    transformAlignment: Alignment.bottomCenter,
                    child: Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.expand,
                      children: [
                        RepaintBoundary(
                          child: ClipRRect(
                            borderRadius: corners,
                            child: image(),
                          ),
                        ),
                        if (_node.hasFocus)
                          TileThemeOutline(
                            theme: settings.themes,
                            accent: Theme.of(context).colorScheme.primary,
                            radius: radius,
                            borderStyle: style.focusBorderStyle(
                              legacyHidden:
                                  settings.hideHighlightOutlineOnHomescreen,
                            ),
                            pulse:
                                style.values['focusPulse'] as bool? ??
                                settings.appHighlightAnimationEnabled,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.program.title,
              style: style.labelStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
