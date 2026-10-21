import 'package:flauncher/widgets/launcher_dialog.dart';
import 'tile_paint_layer.dart';
import 'tile_focus_scroll.dart';
import 'package:flauncher/theme/launcher_style.dart';
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

import 'dart:async';
import '../app_focus_color.dart';
import '../image_limits.dart';
import '../content_image.dart';
import '../providers/appearance_service.dart';
import '../tile_appearance.dart';
import 'appearance_surface.dart';
import 'initial_app_images.dart';

import 'package:flauncher/actions.dart';
import 'package:flauncher/app_image_type.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/focus_keyboard_listener.dart';
import 'package:flauncher/widgets/app_card_keys.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';
import '../models/category.dart';
import 'category_focus.dart';

class AppCard extends StatefulWidget
{
  final App application;
  final Category category;
  final bool autofocus;
  final void Function(AxisDirection) onMove;
  final VoidCallback onMoveEnd;
  final VoidCallback? onMoveCancel;
  final int index;
  final bool handleUpNavigationToSettings;
  final bool isFirstInRow;
  final bool isLastInRow;

  const AppCard({
    super.key,
    required this.application,
    required this.category,
    required this.autofocus,
    required this.onMove,
    required this.onMoveEnd,
    this.onMoveCancel,
    this.index = 0,
    this.handleUpNavigationToSettings = false,
    this.isFirstInRow = false,
    this.isLastInRow = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with TickerProviderStateMixin {
  CategoryFocusController? _categoryFocus;
  bool _moving = false;
  bool _clicked = false;
  late FocusNode _focusNode;

  late Future<(AppImageType, ImageProvider)> _appImageLoadFuture;
  (AppImageType, ImageProvider)? _lastAppImage;
  VoidCallback? _imageReady;
  int _imageRequest = 0;
  double _bumpDirection = 0;
  late final AnimationController _bumpController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _bumpAnimation = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0).chain(CurveTween(curve: Curves.easeOut)), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 1),
  ]).animate(_bumpController);

  Color? _imageFocusColor;
  AppearanceService? _appearanceService;
  AppsService? _appsService;

  @override
  void initState() {
    super.initState();
    _focusNode = TileFocusNode(() => context);

    _appsService = Provider.of<AppsService>(context, listen: false);
    _appsService!.addListener(_onAppsServiceChanged);

    FocusManager.instance.addHighlightModeListener(_focusHighlightModeChanged);
    _appImageLoadFuture = _loadAppBannerOrIcon(_appsService!);

    // Check if we need to restore focus/reorder mode after a move
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (!mounted) return;
       final appsService = Provider.of<AppsService>(context, listen: false);
       if (appsService.pendingReorderFocusPackage == widget.application.packageName &&
           appsService.pendingReorderFocusCategoryId == widget.category.id) {
          appsService.clearPendingReorderFocusPackage();
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
          
          if (!_moving) {
            setState(() {
              _moving = true;
            });
          }
       }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appearanceService = context.read<AppearanceService?>();
    _appearanceService?.registerPreviewTile(this, () {
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) return null;
      return box.localToGlobal(Offset.zero) & box.size;
    }, categoryId: widget.category.id);
    final controller = CategoryFocus.maybeOf(context);
    if (controller != _categoryFocus) {
      _categoryFocus?.unregister(widget.application.packageName, _focusNode);
      _categoryFocus = controller;
      _categoryFocus?.register(widget.application.packageName, _focusNode);
    }
    _imageReady ??= context.getInheritedWidgetOfExactType<AppImagesReadiness>()?.register();
  }

  @override
  void didUpdateWidget(AppCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.application.packageName != widget.application.packageName) {
      _categoryFocus?.unregister(oldWidget.application.packageName, _focusNode);
      _categoryFocus?.register(widget.application.packageName, _focusNode);
      _lastAppImage = null;
      _imageFocusColor = null;
      _appImageLoadFuture = _loadAppBannerOrIcon(_appsService!);
    }
    
    // Check for pending focus on update as well
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (!mounted) return;
       final appsService = Provider.of<AppsService>(context, listen: false);
       if (appsService.pendingReorderFocusPackage == widget.application.packageName &&
           appsService.pendingReorderFocusCategoryId == widget.category.id) {
          appsService.clearPendingReorderFocusPackage();
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
          
          if (!_moving) {
            setState(() {
              _moving = true;
            });
          }
       }
    });
  }

  @override
  void dispose() {
    _categoryFocus?.unregister(widget.application.packageName, _focusNode);
    _appearanceService?.unregisterPreviewTile(this);
    _imageReady?.call();
    if (_appsService != null) {
      _appsService!.removeListener(_onAppsServiceChanged);
    }
    FocusManager.instance.removeHighlightModeListener(_focusHighlightModeChanged);
    _bumpController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  void _onAppsServiceChanged() {
    // Reload the app image when the AppsService notifies of changes
    // (e.g., after setting a custom banner)
    setState(() {
      _appImageLoadFuture = _loadAppBannerOrIcon(_appsService!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceService?>()?.tilesFor(widget.category.id) ?? const TileAppearance();
    final bool showAppNames = appearance.labels == 'all';
    final String themes = context.select<SettingsService, String>((s) => s.themes);
    final accentColorHex = context.select<SettingsService, String>((s) => s.accentColorHex);
    final bool appSelectorTransitionAnimationEnabled = appearance.values['focusTransition'] as bool? ?? context.select<SettingsService, bool>((s) => s.appSelectorTransitionAnimationEnabled);

    final style = LauncherStyle.of(context);
    final borderRadius = style.tileCorners(themes, radius: appearance.number('radius'));

    return FocusKeyboardListener(
      onPressed: (key) => _onPressed(context, key),
      onLongPress: (key) => _onLongPress(context, key),
      builder: (context) {
        final bool shouldHighlight = _shouldHighlight(context);

        return RaisedTile(raised: shouldHighlight, child: AnimatedBuilder(
          animation: _bumpAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_bumpAnimation.value * _bumpDirection, 0),
              child: child,
            );
          },
          child: AnimatedScale(
          scale: _clicked ? 0.9 : 1.0,
          duration: style.pressDuration,
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _clicked ? 0.5 : 1.0,
            duration: style.pressDuration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AspectRatio(
                    aspectRatio: appearance.aspectRatio,
                    child: RepaintBoundary(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return AnimatedContainer(
                            duration: appSelectorTransitionAnimationEnabled ? style.tileDuration : Duration.zero,
                            curve: Curves.easeOutCubic,
                            transformAlignment: Alignment.center,
                            transform: _scaleTransform(context, themes, constraints.maxWidth),
                            child: AppearanceSurface(
                          appearance: appearance,
                          focused: shouldHighlight,
                          focusColor: appearance.dynamicFocusColor && _imageFocusColor != null
                              ? _imageFocusColor : Color(int.parse('FF$accentColorHex', radix: 16)),
                          borderRadius: borderRadius,
                          elevation: style.tileElevation(themes, shouldHighlight),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Selector<NotificationsService, int>(
                                selector: (_, service) => service.getNotificationCount(widget.application.packageName),
                                builder: (context, count, _) {
                                  if (count <= 0) return const SizedBox.shrink();
                                  return Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IgnorePointer(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black45,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$count',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Actions(
                                actions: <Type, Action<Intent>>{
                                  ActivateIntent: CallbackAction<ActivateIntent>(
                                    onInvoke: (_) => _onPressed(context, LogicalKeyboardKey.enter),
                                  ),
                                  ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
                                    onInvoke: (_) => _onPressed(context, LogicalKeyboardKey.enter),
                                  ),
                                },
                                child: InkWell(
                                  focusNode: _focusNode,
                                  autofocus: widget.autofocus,
                                  focusColor: Colors.transparent,
                                  child: _appImage(),
                                  onTap: () => _onPressed(context, LogicalKeyboardKey.enter),
                                  onLongPress: () => _onLongPress(context, LogicalKeyboardKey.enter),
                                  onFocusChange: (focused) {
                                    // Losing focus to Home must not undo its scroll reset.
                                    if (!focused) return;
                                    _appearanceService?.focusedAppImage.value = _lastAppImage?.$2;
                                    _categoryFocus?.record(widget.application.packageName, _focusNode);
                                    if (_categoryFocus?.reveal != null) { _categoryFocus!.reveal!(); return; }
                                    revealFocusedTile(this.context,
                                      alignment: context.read<AppearanceService?>()?.appearance.focusAlignment ?? 0.5,
                                      keepTop: widget.handleUpNavigationToSettings,
                                      horizontalStart: widget.isFirstInRow,
                                    );
                                  },
                                ),
                              ),
                              if (_moving) ..._arrows(),
                              if (showAppNames && appearance.labelPosition == 'inside')
                                Positioned(left: 0, right: 0, bottom: 0,
                                  child: IgnorePointer(child: Container(color: appearance.labelBackground,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text(widget.application.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: appearance.labelStyle),
                                  ))),
                              IgnorePointer(
                                child: AnimatedOpacity(
                                  duration: appSelectorTransitionAnimationEnabled ? style.tileDuration : Duration.zero,
                                  curve: Curves.easeInOut,
                                  opacity: shouldHighlight ? 0 : 0.10,
                                  child: Container(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (showAppNames && appearance.labelPosition == 'below')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      widget.application.name,
                      style: style.tileLabelStyle(context, appearance, shouldHighlight),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          ),
        ));
      },
    );
  }

  Future<(AppImageType, ImageProvider)> _loadAppBannerOrIcon(AppsService service) async {
    final request = ++_imageRequest;
    final packageName = widget.application.packageName;
    Uint8List bytes = Uint8List(0);

    bytes = await service.getAppBanner(packageName);
    AppImageType type = AppImageType.Banner;

    if (bytes.isEmpty) {
      type = AppImageType.Icon;
      bytes = await service.getAppIcon(packageName);
    }

    if (bytes.isEmpty) throw StateError('App image is unavailable');
    final image = (type, await contentImage(bytes));
    if (mounted && request == _imageRequest) {
      _lastAppImage = image;
      if (_focusNode.hasFocus) _appearanceService?.focusedAppImage.value = image.$2;
    }
    unawaited(appFocusColor(bytes).then((color) {
      if (mounted && request == _imageRequest) {
        setState(() => _imageFocusColor = color);
      }
    }));
    return image;
  }

  Widget _imageFrame(BuildContext context, Widget child, int? frame, bool synchronous) {
    if (frame != null || synchronous) _imageReady?.call();
    return child;
  }

  Widget _imageError(BuildContext context, Object error, StackTrace? stack) {
    _imageReady?.call();
    return const SizedBox.shrink();
  }

  Widget _appImage()
  {
    final appearance = context.watch<AppearanceService?>()?.tilesFor(widget.category.id) ?? const TileAppearance();
    App app = widget.application;

    return LayoutBuilder(builder: (context, constraints) => FutureBuilder(
      key: ValueKey('image:${app.packageName}'),
      future: _appImageLoadFuture,
      builder: (context, snapshot) {
        final record = snapshot.data ?? _lastAppImage;
        if (record != null) {

          if (record.$1 == AppImageType.Banner) {
            return Image(
              image: sizedImage(record.$2, Size(constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
                  constraints.maxHeight.isFinite ? constraints.maxHeight : 180),
                  MediaQuery.devicePixelRatioOf(context), maximumEdge: 1024),
              fit: appearance.aspectRatio == 16 / 9 ? BoxFit.cover : BoxFit.contain,
              gaplessPlayback: true,
              frameBuilder: _imageFrame,
              errorBuilder: _imageError,
            );
          }
          else {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FractionallySizedBox(
                      widthFactor: appearance.iconScale, heightFactor: appearance.iconScale,
                      child: LayoutBuilder(builder: (context, iconConstraints) => Image(
                        image: sizedImage(
                          record.$2,
                          Size(
                            iconConstraints.maxWidth.isFinite ? iconConstraints.maxWidth : 128,
                            iconConstraints.maxHeight.isFinite ? iconConstraints.maxHeight : 128,
                          ),
                          MediaQuery.devicePixelRatioOf(context) * LauncherStyle.of(context).tileFocusScale(
                            context.read<SettingsService>().themes, appearance,
                            width: constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
                            focused: true,
                          ),
                          maximumEdge: 1024,
                        ),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        frameBuilder: _imageFrame,
                        errorBuilder: _imageError,
                      )),
                    ),
                  ),
                  if (!appearance.active) Flexible(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        app.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }
        else if (snapshot.hasError) {
          _imageReady?.call();
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text(
                app.name,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              )
            ),
          );
        }
        else {
          return Padding(
            padding: EdgeInsets.all(8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 0, width: 16),
                  Text(AppLocalizations.of(context)!.loading)
                ],
              ),
            ),
          );
        }
      }
    ));
  }

  void _focusHighlightModeChanged(FocusHighlightMode mode)
  {
    setState(() { });
  }

  bool _shouldHighlight(BuildContext context)
  {
    return context.read<AppearanceService?>()?.focusPreviewTile == this ||
      (FocusManager.instance.highlightMode == FocusHighlightMode.traditional && Focus.of(context).hasFocus);
  }

  Matrix4 _scaleTransform(BuildContext context, String theme, double maxWidth) {
    final appearance = context.read<AppearanceService?>()?.tilesFor(widget.category.id) ?? const TileAppearance();
    final scale = LauncherStyle.of(context).tileFocusScale(theme, appearance,
      width: maxWidth, focused: !_moving && _shouldHighlight(context));
    final transform = Matrix4.diagonal3Values(scale, scale, 1.0);
    if (!_moving && _shouldHighlight(context) && appearance.focusEffect == 'lift') {
      transform.setTranslationRaw(0, -appearance.focusLift, 0);
    }
    return transform;
  }

  List<Widget> _arrows() {
    final arrows = <Widget>[
      _arrow(Alignment.centerLeft, Icons.keyboard_arrow_left, () {
        widget.onMove(AxisDirection.left);
      }),
      _arrow(Alignment.centerRight, Icons.keyboard_arrow_right, () {
        widget.onMove(AxisDirection.right);
      }),
    ];
    
    // Only show Up/Down arrows for grid layouts
    if ((context.read<AppearanceService?>()?.category(widget.category.id).resolvedLayout(widget.category.type == CategoryType.row) ?? (widget.category.type == CategoryType.row ? 'row' : 'grid')) != 'row') {
      arrows.add(_arrow(Alignment.topCenter, Icons.keyboard_arrow_up, () {
        widget.onMove(AxisDirection.up);
      }));
      arrows.add(_arrow(Alignment.bottomCenter, Icons.keyboard_arrow_down, () {
        widget.onMove(AxisDirection.down);
      }));
    }

    return arrows;
  }

  Widget _arrow(Alignment alignment, IconData icon, VoidCallback onTap) =>
      ExcludeFocus(
        child: Align(
          alignment: alignment,
          child: Ink(
            decoration: ShapeDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
              shape: CircleBorder()
            ),
            child: SizedBox(
              height: 36,
              width: 36,
              child: IconButton(
                icon: Icon(icon, size: 24),
                onPressed: onTap,
                padding: EdgeInsets.all(0)
              )
            )
          )
        ),
      );

  DateTime? _lastMoveTime;

  KeyEventResult _onPressed(BuildContext context, LogicalKeyboardKey? key) {
    if (!_moving) {
      final direction = switch (key) {
        LogicalKeyboardKey.arrowLeft => AxisDirection.left,
        LogicalKeyboardKey.arrowRight => AxisDirection.right,
        LogicalKeyboardKey.arrowUp => AxisDirection.up,
        LogicalKeyboardKey.arrowDown => AxisDirection.down,
        _ => null,
      };
      if (direction != null && _categoryFocus?.navigate != null) {
        _categoryFocus!.navigate!(widget.application.packageName, direction);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowLeft && widget.isFirstInRow) {
        _bumpDirection = -1.0;
        if (!_bumpController.isAnimating) {
          _bumpController.forward(from: 0.0);
        }
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.arrowRight && widget.isLastInRow) {
        _bumpDirection = 1.0;
        if (!_bumpController.isAnimating) {
          _bumpController.forward(from: 0.0);
        }
        return KeyEventResult.handled;
      }
    }

    if (_moving) {
      if (AppCardKeys.isArrowKey(key)) {
        final now = DateTime.now();
        if (_lastMoveTime != null && now.difference(_lastMoveTime!) < const Duration(milliseconds: 50)) {
          return KeyEventResult.handled;
        }
        _lastMoveTime = now;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_categoryFocus?.reveal != null) { _categoryFocus!.reveal!(); return; }
        revealFocusedTile(this.context,
          alignment: context.read<AppearanceService?>()?.appearance.focusAlignment ?? 0.5,
          keepTop: widget.handleUpNavigationToSettings,
          horizontalStart: widget.isFirstInRow);
      });
      if (key == LogicalKeyboardKey.arrowLeft) {
        widget.onMove(AxisDirection.left);
      } else if (key == LogicalKeyboardKey.arrowUp) {
        widget.onMove(AxisDirection.up);
      } else if (key == LogicalKeyboardKey.arrowRight) {
        widget.onMove(AxisDirection.right);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        widget.onMove(AxisDirection.down);
      } else if (AppCardKeys.validationKeys.contains(key)) {
        setState(() => _moving = false);
        widget.onMoveEnd();
      } else if (AppCardKeys.cancelKeys.contains(key)) {
        setState(() => _moving = false);
        widget.onMoveCancel?.call();
        context.read<LauncherState>().suppressBackNavigation();
      } else {
        return KeyEventResult.ignored;
      }

      return KeyEventResult.handled;
    } else if (key == null || AppCardKeys.validationKeys.contains(key)) {
      if (!_clicked) {
        setState(() => _clicked = true);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted || !context.mounted) return;
          context.read<AppsService>().launchApp(widget.application);
          // Reset after a short delay so it looks normal when user returns
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() => _clicked = false);
            }
          });
        });
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp && widget.handleUpNavigationToSettings) {
      Actions.invoke(context, const MoveFocusToSettingsIntent());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onLongPress(BuildContext context, LogicalKeyboardKey? key) {
    if (!_moving && (key == null || AppCardKeys.longPressableKeys.contains(key))) {
      _showPanel(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _showPanel(BuildContext context) async {
    final controller = _categoryFocus;
    final package = widget.application.packageName;
    final index = widget.index;
    try {
      _focusNode.requestFocus();
      final result = await showLauncherDialog<ApplicationInfoPanelResult>(
        context: context,
        builder: (context) => ApplicationInfoPanel(
          category: widget.category,
          application: widget.application,
        ),
      );
      if (!mounted) {
        await controller?.restoreAfterEdit(package, index);
        return;
      }
      _focusNode.requestFocus();
      if (result == ApplicationInfoPanelResult.reorderApp) {
        setState(() => _moving = true);
      }
    } catch (e, stackTrace) {
      debugPrint('Error showing panel: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
