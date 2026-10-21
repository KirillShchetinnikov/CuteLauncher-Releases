import 'dart:math' as math;
import 'package:flutter/foundation.dart' show ValueListenable;

import 'package:flutter/material.dart';
import 'reordering_tile_viewport.dart';
import 'package:provider/provider.dart';

import '../home_layout.dart';
import '../models/app.dart';
import '../models/category.dart';
import '../providers/apps_service.dart';
import '../providers/appearance_service.dart';
import '../l10n/app_localizations.dart';
import '../section_names.dart';
import '../tile_appearance.dart';
import 'app_card.dart';
import 'category_container_common.dart';
import 'category_focus.dart';
import 'tile_paint_layer.dart';

/// A section owns one scroll axis; navigation is based on data, never paint bounds.
class HomeSection extends StatefulWidget {
  final Category category;
  final bool first;
  final ValueListenable<int?>? activeCategory;
  const HomeSection({super.key, required this.category, this.first = false, this.activeCategory});
  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  final _scroll = ScrollController();
  final _bounds = GlobalKey();
  CategoryFocusController? _focus;
  HomeLayout? _layout;
  List<App> _apps = [];
  bool _active = false;
  CategorySort? _appliedSort;
  int _request = 0;
  String? _signature;
  String? _pendingPackage;
  int? _preferredColumn;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = CategoryFocus.maybeOf(context);
    if (next != _focus) {
      _disconnect();
      _focus = next;
      next?.materialize = _select;
      next?.navigate = _navigate;
      next?.enter = _enter;
      next?.reveal = _reveal;
      next?.selected.addListener(_changed);
    }
  }

  void _disconnect() {
    _focus?.selected.removeListener(_changed);
    _focus?.materialize = null;
    _focus?.navigate = null;
    _focus?.enter = null;
    _focus?.reveal = null;
  }

  @override
  void dispose() {
    ++_request;
    _disconnect();
    _scroll.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reveal();
    });
  }

  AxisDirection _logicalDirection(AxisDirection direction) {
    if (Directionality.of(context) != TextDirection.rtl) return direction;
    return switch (direction) {
      AxisDirection.left => AxisDirection.right,
      AxisDirection.right => AxisDirection.left,
      _ => direction,
    };
  }

  bool _navigate(String package, AxisDirection direction) {
    final layout = _layout;
    final index = _apps.indexWhere(
      (a) => a.packageName == (_pendingPackage ?? package),
    );
    if (layout == null || index < 0) return true;
    final (row, column) = layout.cell(index);
    final vertical =
        direction == AxisDirection.up || direction == AxisDirection.down;
    if (!vertical) _preferredColumn = null;
    if (vertical) _preferredColumn ??= column;
    final nextRow = row + (direction == AxisDirection.up ? -1 : 1);
    final target = vertical && nextRow >= 0 && nextRow < layout.rows
        ? layout.start(nextRow) +
              math.min<int>(_preferredColumn!, layout.lengths[nextRow] - 1)
        : layout.neighbor(index, _logicalDirection(direction));
    if (target != null) {
      _select(_apps[target].packageName, preserveColumn: vertical);
    } else if (direction == AxisDirection.up ||
        direction == AxisDirection.down) {
      final box = _bounds.currentContext?.findRenderObject() as RenderBox?;
      final fromStart =
          layout.inset +
          layout.cell(index).$2 * layout.stepX +
          layout.width / 2 -
          (layout.mode != 'grid' && _scroll.hasClients ? _scroll.offset : 0);
      final x = (box?.localToGlobal(Offset.zero).dx ?? 0) +
          (Directionality.of(context) == TextDirection.rtl
              ? (box?.size.width ?? 0) - fromStart : fromStart);
      ++_request;
      _pendingPackage = null;
      _focus?.leave?.call(direction, x);
    }
    return true;
  }

  Future<bool> _enter(AxisDirection direction, double x) async {
    if (_apps.isEmpty || _layout == null) return false;
    _preferredColumn = null;
    final l = _layout!;
    final row = direction == AxisDirection.down ? 0 : l.rows - 1;
    final box = _bounds.currentContext?.findRenderObject() as RenderBox?;
    final fromLeft = x - (box?.localToGlobal(Offset.zero).dx ?? 0);
    final localX =
        (Directionality.of(context) == TextDirection.rtl
            ? (box?.size.width ?? 0) - fromLeft : fromLeft) -
        l.inset +
        (l.mode != 'grid' && _scroll.hasClients ? _scroll.offset : 0);
    final col = ((localX - l.width / 2) / l.stepX).round().clamp(
      0,
      l.lengths[row] - 1,
    );
    return _select(_apps[l.start(row) + col].packageName);
  }

  Future<bool> _select(String package, {bool preserveColumn = false}) async {
    if (!preserveColumn) _preferredColumn = null;

    final request = ++_request;
    final origin = FocusManager.instance.primaryFocus;
    final index = _apps.indexWhere((a) => a.packageName == package);
    final l = _layout;
    if (index < 0 || l == null) return false;
    _pendingPackage = package;
    final (r, c) = l.cell(index);
    if (_scroll.hasClients) {
      final start = l.mode == 'grid' ? r * l.stepY : c * l.stepX;
      final extent = l.mode == 'grid' ? l.height + l.labelHeight : l.width;
      final end = start + extent;
      var offset = _scroll.offset;
      if (start < offset) offset = start;
      if (end > offset + _scroll.position.viewportDimension) {
        offset = end - _scroll.position.viewportDimension;
      }
      _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
    }
    WidgetsBinding.instance.ensureVisualUpdate();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted ||
        ModalRoute.of(context)?.isCurrent == false ||
        request != _request ||
        (FocusManager.instance.primaryFocus != origin &&
            // A lazy reorder can dispose the old card and move focus to a
            // sibling. That is not a new navigation request by the user.
            (origin?.context != null || _focus?.hasFocus != true) &&
            FocusManager.instance.primaryFocus is! FocusScopeNode)) {
      if (request == _request) _pendingPackage = null;
      return false;
    }
    _pendingPackage = null;
    final result = _focus?.focusMounted(package) ?? false;
    if (result) _reveal();
    return result;
  }

  void _reveal() {
    if (!mounted || !_active) return;
    final outer = Scrollable.maybeOf(context);
    final box = context.findRenderObject();
    final bounds = _bounds.currentContext?.findRenderObject();
    if (outer == null || box is! RenderBox || bounds is! RenderBox) return;
    final viewport = outer.context.findRenderObject();
    if (viewport is! RenderBox) return;
    final style =
        context.read<AppearanceService?>()?.appearance ??
        const TileAppearance();
    final pos = outer.position;
    final sectionTop =
        box.localToGlobal(Offset.zero, ancestor: viewport).dy + pos.pixels;
    var offset = style.anchored
        ? sectionTop - pos.viewportDimension * style.sectionPosition
        : pos.pixels;
    final index = _apps.indexWhere((a) => a.packageName == _focus?.lastPackage);
    final l = _layout;
    if (index >= 0 && l != null) {
      final top =
          bounds.localToGlobal(Offset.zero, ancestor: viewport).dy +
          pos.pixels +
          l.cell(index).$1 * l.stepY -
          (l.mode == 'grid' && _scroll.hasClients ? _scroll.offset : 0);
      final bottom = top + l.height + l.labelHeight + 2 * l.inset;
      if (top < offset) offset = top;
      if (bottom > offset + pos.viewportDimension) {
        offset = bottom - pos.viewportDimension;
      }
    }
    offset = offset.clamp(pos.minScrollExtent, pos.maxScrollExtent);
    if ((offset - pos.pixels).abs() > .5) {
      pos.animateTo(
        offset,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  void _move(App app, AxisDirection direction) {
    final index = _apps.indexOf(app);
    final target = _layout?.neighbor(index, _logicalDirection(direction));
    if (target == null) return;
    final service = context.read<AppsService>();
    service.setPendingReorderFocus(app.packageName, widget.category.id, target);
    service.reorderApplication(
      widget.category,
      widget.category.applications.indexOf(app),
      widget.category.applications.indexOf(_apps[target]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AppearanceService?>();
    final style =
        service?.tilesFor(widget.category.id) ?? const TileAppearance();
    final categoryStyle = service?.category(widget.category.id);
    final mode =
        categoryStyle?.resolvedLayout(
          widget.category.type == CategoryType.row,
        ) ??
        (widget.category.type == CategoryType.row ? 'row' : 'grid');
    final oldSelected = _focus?.lastPackage;
    final oldIndex = _apps.indexWhere((a) => a.packageName == oldSelected);
    // An explicit sort-mode change must bypass the focused section order lock.
    final sortChanged = _appliedSort != widget.category.sort;
    _appliedSort = widget.category.sort;
    // Usage sorts update after each successful launch, retaining focus by package.
    // AppsService already applies hidden only to automatic categories.
    final incoming = widget.category.applications.toList();
    if (_active &&
        !sortChanged &&
        widget.category.sort != CategorySort.manual &&
        widget.category.sort != CategorySort.mostUsed &&
        widget.category.sort != CategorySort.lastUsed &&
        _apps.isNotEmpty) {
      final byId = {for (final a in incoming) a.packageName: a};
      _apps = [
        for (final a in _apps)
          if (byId.containsKey(a.packageName)) byId.remove(a.packageName)!,
        ...byId.values,
      ];
    } else {
      _apps = incoming;
    }
    _focus?.configure(_apps.map((a) => a.packageName));
    final columns =
        categoryStyle?.resolvedColumns(
          legacyRow: widget.category.type == CategoryType.row,
          legacyColumns: widget.category.columnsCount,
        ) ??
        (mode == 'grid' ? widget.category.columnsCount : 0);
    final padding =
        style.number('sectionPadding') ?? categoryStyle?.padding ?? 0;
    return Focus(
      onFocusChange: (active) {
        if (mounted && active != _active) setState(() => _active = active);
      },
      child: ListenableBuilder(
        listenable: widget.activeCategory ?? _scroll,
        builder: (_, child) => AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _active || (widget.activeCategory != null &&
              (widget.activeCategory!.value == widget.category.id ||
               widget.activeCategory!.value == null && widget.first))
              ? 1 : style.number('inactiveOpacity') ?? 1,
          child: child,
        ),
        child: Container(
          color: style.color('sectionBackground') ?? categoryStyle?.background,
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (style.sectionTitles || style.labels == 'selected')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      if (style.sectionTitles && style.sectionIcons) ...[
                        const Icon(Icons.apps),
                        const SizedBox(width: 8),
                      ],
                      if (style.sectionTitles) Flexible(
                        child: Text(
                          localizedSectionName(
                            widget.category.name,
                            AppLocalizations.of(context)!,
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (style.labels == 'selected') ...[
                        if (style.sectionTitles)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('·', style: style.labelStyle),
                          ),
                        Expanded(
                          child: Text(
                            _apps.where((a) => a.packageName == _focus?.lastPackage)
                                .firstOrNull?.name ?? '',
                            key: ValueKey(('selected-app-label', widget.category.id)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: style.labelStyle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (_apps.isEmpty)
                ExcludeFocus(child: categoryContainerEmptyState(context)),
              if (_apps.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final labelHeight =
                        style.labels == 'all' && style.labelPosition == 'below'
                        ? style.labelSize *
                                  MediaQuery.textScalerOf(context).scale(1) *
                                  1.4 +
                              8
                        : 0.0;
                    final l = HomeLayout(
                      mode: mode,
                      count: _apps.length,
                      availableWidth: constraints.maxWidth,
                      style: style,
                      requestedRows: categoryStyle?.rows ?? 2,
                      requestedColumns: columns,
                      labelHeight: labelHeight,
                    );
                    _layout = l;
                    final signature =
                        '$mode:$columns:${l.rows}:${l.width}:${l.height}:${l.gapX}:${l.gapY}:${style.labels}:${service?.appearance.anchored}:${service?.appearance.sectionPosition}:$padding:${style.sectionTitles}:${_apps.map((a) => a.packageName).join(',')}';
                    if (_signature != signature) {
                      _signature = signature;
                      _preferredColumn = null;
                      if (_active) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _apps.isNotEmpty) {
                            _select(
                              _apps.any((a) => a.packageName == oldSelected)
                                  ? oldSelected!
                                  : _apps[oldIndex.clamp(0, _apps.length - 1)]
                                        .packageName,
                            );
                          }
                        });
                      }
                    }
                    Widget card(int index) {
                      final a = _apps[index];
                      final (r, c) = l.cell(index);
                      return SizedBox(
                        width: l.width,
                        height: l.height + labelHeight,
                        child: AppCard(
                          key: ValueKey(a.packageName),
                          index: index,
                          category: widget.category,
                          application: a,
                          autofocus: false,
                          handleUpNavigationToSettings: widget.first && r == 0,
                          isFirstInRow: c == 0,
                          isLastInRow: c == l.lengths[r] - 1,
                          onMove: (d) => _move(a, d),
                          onMoveEnd: () => context
                              .read<AppsService>()
                              .saveApplicationOrderInCategory(widget.category),
                          onMoveCancel: () => context
                              .read<AppsService>()
                              .cancelReorderApplication(widget.category),
                        ),
                      );
                    }

                    final maxRows = categoryStyle?.maxRows ?? 0;
                    final height = l.windowHeight(
                      maxRows,
                      MediaQuery.sizeOf(context).height - 180,
                    );
                    final child = ReorderingTileViewport(
                      layout: l,
                      packages: _apps.map((app) => app.packageName).toList(),
                      controller: _scroll,
                      selected: _focus?.lastPackage,
                      animate: style.animateReordering && !MediaQuery.disableAnimationsOf(context),
                      physics: mode == 'grid' && maxRows == 0
                          ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
                      itemBuilder: (_, index) => card(index),
                    );
                    return SizedBox(
                      key: _bounds,
                      height: height,
                      child: ClipRect(
                        child: TilePaintLayer(
                          child: Padding(
                            padding: EdgeInsets.all(l.inset),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
