import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/launcher_style.dart';
import '../theme/interface_style.dart';
import 'action_notice.dart';
import 'settings/settings_menu_layout.dart';
import 'app_card_keys.dart';
import 'notice_placement.dart';

/// Keeps modal content clear of the settings panel, including nested dialogs.
Future<T?> showLauncherDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
  bool useSafeArea = true,
  bool styleDialog = true,
  double? parentPanelWidth,
  bool parentPanelHidden = false,
  bool? onRight,
  Rect? highlightRect,
  Rect? Function()? highlightRectResolver,
}) {
  final occupied = parentPanelHidden
      ? null
      : NoticePanels.instance.boundsForRoute(context);
  final menu = SettingsMenuLayout.maybeOf(context);
  final parent = context
      .dependOnInheritedWidgetOfExactType<LauncherDialogArea>();
  final settingsOpen =
      parentPanelWidth != null ||
      menu != null ||
      (parent?.settingsOpen ?? false);
  final parentPanelOpen =
      parent != null && (ModalRoute.of(context)?.isActive ?? false);
  final panelOnRight = onRight ?? menu?.onRight ?? parent?.onRight ?? false;
  final highlight =
      highlightRect ??
      context
          .dependOnInheritedWidgetOfExactType<LauncherWidgetHighlight>()
          ?.rect;
  final resolver =
      highlightRectResolver ??
      context
          .dependOnInheritedWidgetOfExactType<LauncherWidgetHighlight>()
          ?.resolver;
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    // A parent panel already owns the dimming, even without a settings menu.
    barrierColor:
        barrierColor ??
        (settingsOpen || parentPanelOpen
            ? Colors.transparent
            : Colors.black.withValues(
                alpha: LauncherStyle.of(context).settingsBarrierOpacity,
              )),
    useRootNavigator: useRootNavigator,
    useSafeArea: useSafeArea,
    animationStyle: AnimationStyle.noAnimation,
    builder: (dialogContext) => _OpeningKeyReleaseGuard(
      child: LauncherWidgetHighlight(
        rect: highlight,
        resolver: resolver,
        child: LauncherDialogArea(
          occupied: occupied,
          settingsOpen: settingsOpen,
          onRight: panelOnRight,
          panelWidth: parentPanelWidth ?? parent?.panelWidth,
          child: Builder(
            builder: (context) => styleDialog
                ? Theme(
                    data: launcherDialogTheme(context),
                    child: Builder(builder: builder),
                  )
                : Builder(builder: builder),
          ),
        ),
      ),
    ),
  );
}

/// The press which opened a route must not activate its newly focused action.
class _OpeningKeyReleaseGuard extends StatefulWidget {
  final Widget child;
  const _OpeningKeyReleaseGuard({required this.child});

  @override
  State<_OpeningKeyReleaseGuard> createState() =>
      _OpeningKeyReleaseGuardState();
}

class _OpeningKeyReleaseGuardState extends State<_OpeningKeyReleaseGuard> {
  late final Set<LogicalKeyboardKey> _openingKeys;

  @override
  void initState() {
    super.initState();
    _openingKeys = HardwareKeyboard.instance.logicalKeysPressed
        .where(
          (key) =>
              AppCardKeys.validationKeys.contains(key) ||
              AppCardKeys.menuKeys.contains(key),
        )
        .toSet();
    if (_openingKeys.isNotEmpty) {
      FocusManager.instance.addEarlyKeyEventHandler(_handleKey);
    }
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (!_openingKeys.contains(event.logicalKey)) return KeyEventResult.ignored;
    if (event is KeyUpEvent) {
      _openingKeys.remove(event.logicalKey);
      if (_openingKeys.isEmpty) {
        FocusManager.instance.removeEarlyKeyEventHandler(_handleKey);
      }
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_handleKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Panels which hide themselves for another route keep dimming in their body.
/// Their outer dialog barrier must be transparent.
class LauncherPanelBackdrop extends StatefulWidget {
  const LauncherPanelBackdrop({super.key});

  @override
  State<LauncherPanelBackdrop> createState() => _LauncherPanelBackdropState();
}

class _LauncherPanelBackdropState extends State<LauncherPanelBackdrop> {
  Rect? _rect;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_track);
  }

  Rect? _resolveRect() {
    final highlight = context
        .getInheritedWidgetOfExactType<LauncherWidgetHighlight>();
    final global = highlight?.resolver?.call() ?? highlight?.rect;
    final box = context.findRenderObject();
    return global == null || box is! RenderBox || !box.hasSize
        ? null
        : box.globalToLocal(global.topLeft) & global.size;
  }

  void _track(Duration _) {
    if (!mounted) return;
    final rect = _resolveRect();
    if (_rect != rect) setState(() => _rect = rect);
    // Observe existing frames without scheduling continuous idle rendering.
    WidgetsBinding.instance.addPostFrameCallback(_track);
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ClipPath(
      clipper: _WidgetBackdropClipper(
        _rect,
        LauncherStyle.of(context).topButtonRadius,
        _resolveRect,
      ),
      child: ColoredBox(
        color: Colors.black.withValues(
          alpha: LauncherStyle.of(context).settingsBarrierOpacity,
        ),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class LauncherWidgetHighlight extends InheritedWidget {
  final Rect? rect;
  final Rect? Function()? resolver;
  const LauncherWidgetHighlight({
    super.key,
    required this.rect,
    this.resolver,
    required super.child,
  });
  @override
  bool updateShouldNotify(LauncherWidgetHighlight oldWidget) =>
      rect != oldWidget.rect || resolver != oldWidget.resolver;
}

class _WidgetBackdropClipper extends CustomClipper<Path> {
  final Rect? rect;
  final double radius;
  final Rect? Function() resolveRect;
  const _WidgetBackdropClipper(this.rect, this.radius, this.resolveRect);
  @override
  Path getClip(Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    // Clipping runs after layout, including the very first paint. Waiting for
    // the post-frame tracker would briefly dim the opening control as well.
    final current = resolveRect();
    if (current != null) {
      path.addRRect(RRect.fromRectAndRadius(current, Radius.circular(radius)));
    }
    return path;
  }

  @override
  bool shouldReclip(_WidgetBackdropClipper oldClipper) =>
      rect != oldClipper.rect || radius != oldClipper.radius;
}

/// Captured by new modal routes because inherited widgets below the root
/// Navigator are not automatically carried into its overlay.
class LauncherDialogArea extends InheritedWidget {
  final Rect? occupied;
  final bool settingsOpen, onRight;
  final double? panelWidth;
  LauncherDialogArea({
    super.key,
    this.occupied,
    required this.settingsOpen,
    required this.onRight,
    this.panelWidth,
    required Widget child,
  }) : super(
         child: _FreeScreenArea(
           occupied: occupied,
           settingsOpen: settingsOpen,
           onRight: onRight,
           panelWidth: panelWidth,
           child: child,
         ),
       );

  @override
  bool updateShouldNotify(LauncherDialogArea oldWidget) =>
      occupied != oldWidget.occupied ||
      settingsOpen != oldWidget.settingsOpen ||
      onRight != oldWidget.onRight ||
      panelWidth != oldWidget.panelWidth;
}

class _FreeScreenArea extends StatelessWidget {
  final Rect? occupied;
  final bool settingsOpen, onRight;
  final double? panelWidth;
  final Widget child;
  const _FreeScreenArea({
    this.occupied,
    required this.settingsOpen,
    required this.onRight,
    this.panelWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final style = LauncherStyle.of(context);
      if (occupied != null) {
        final box = context.findRenderObject() as RenderBox;
        final left = box.globalToLocal(occupied!.topLeft).dx;
        final right = box.globalToLocal(occupied!.topRight).dx;
        final useLeft = left > constraints.maxWidth - right;
        return Padding(
          padding: EdgeInsets.only(
            left: useLeft ? 0 : right.clamp(0, constraints.maxWidth),
            right: useLeft
                ? (constraints.maxWidth - left).clamp(0, constraints.maxWidth)
                : 0,
          ),
          child: child,
        );
      }
      final reserved = settingsOpen
          ? ((panelWidth ?? style.settingsWidth) + style.panelMargin * 2).clamp(
              0.0,
              constraints.maxWidth,
            )
          : 0.0;
      return Padding(
        padding: EdgeInsets.only(
          left: onRight ? 0 : reserved,
          right: onRight ? reserved : 0,
        ),
        child: child,
      );
    },
  );
}

ThemeData launcherDialogTheme(BuildContext context) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  final style = LauncherStyle.of(context);
  return InterfaceSkin.of(context).apply(theme.copyWith(
    dialogTheme: theme.dialogTheme.copyWith(
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minWidth: 0),
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(style.dialogRadius),
        side: BorderSide(color: colors.onSurface.withValues(alpha: .12)),
      ),
      titleTextStyle: theme.textTheme.titleLarge,
      contentTextStyle: theme.textTheme.bodyLarge,
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
    ),
    iconTheme: theme.iconTheme.copyWith(color: colors.primary),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: colors.onSurface.withValues(alpha: .04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(style.rowRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(style.rowRadius),
        borderSide: BorderSide(color: colors.onSurface.withValues(alpha: .18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(style.rowRadius),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.onSurface.withValues(alpha: .38)
              : colors.onSurface,
        ),
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color:
                states.contains(WidgetState.focused) &&
                    !states.contains(WidgetState.disabled)
                ? colors.onSurface
                : Colors.transparent,
            width: style.rowFocusWidth,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(style.rowRadius),
          ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ),
  ));
}

/// A bounded, scrollable body with a footer that stays visible. The explicit
/// body width also supports controls which cannot report intrinsic dimensions.
class LauncherAlertDialog extends StatelessWidget {
  final Widget? title, content;
  final List<Widget>? actions;
  final double contentWidth;
  const LauncherAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.contentWidth = 400,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: title,
    content: content == null
        ? null
        : SingleChildScrollView(
            child: content is Text || content is SizedBox
                ? content
                : SizedBox(width: contentWidth, child: content),
          ),
    actions: actions,
  );
}

/// Dialog actions use a neutral appearance with a border only while focused.
class LauncherDialogButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool autofocus, primary, danger, isCancel;
  final FocusNode? focusNode;
  final ButtonStyle? style;
  const LauncherDialogButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.autofocus = false,
    this.primary = false,
    this.danger = false,
    this.isCancel = false,
    this.focusNode,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      autofocus: autofocus,
      focusNode: focusNode,
      onPressed: onPressed == null
          ? null
          : () {
              if (isCancel) {
                showActionNotice(
                  context,
                  AppLocalizations.of(context)!.actionCancelled,
                );
              }
              onPressed!();
            },
      style:
          style?.merge(launcherDialogTheme(context).textButtonTheme.style) ??
          launcherDialogTheme(context).textButtonTheme.style,
      child: child,
    );
  }
}

Rect? launcherControlBounds(FocusNode node) {
  final box = node.context?.findRenderObject();
  return box is RenderBox && box.attached && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
}
