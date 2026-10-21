import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appearance_service.dart';
import '../tile_appearance.dart';
import '../theme/launcher_style.dart';

/// One presentation contract for Flutter notices and the Android popup bridge.
class NoticeStyle {
  final Color background, foreground, border;
  final double width, textSize, radius;
  const NoticeStyle({
    required this.background,
    required this.foreground,
    required this.border,
    required this.width,
    required this.textSize,
    required this.radius,
  });
  static NoticeStyle of(BuildContext context) {
    final appearance =
        context.watch<AppearanceService?>()?.appearance ??
        const TileAppearance();
    final theme = Theme.of(
      Navigator.maybeOf(context, rootNavigator: true)?.context ?? context,
    );
    final foreground =
        appearance.color('noticeTextColor') ?? theme.colorScheme.onSurface;
    return NoticeStyle(
      background:
          (appearance.color('noticeColor') ??
                  theme.colorScheme.surface.withAlpha(255))
              .withValues(alpha: appearance.number('noticeOpacity') ?? 1),
      foreground: foreground,
      border: foreground.withValues(alpha: .12),
      width: appearance.number('noticeWidth') ?? 360,
      textSize:
          appearance.number('noticeTextSize') ??
          theme.textTheme.bodyLarge?.fontSize ??
          16,
      radius: LauncherStyle.of(context).dialogRadius,
    );
  }

  TextStyle get textStyle => TextStyle(color: foreground, fontSize: textSize);
}

class NoticeSurface extends StatelessWidget {
  final Widget child;
  const NoticeSurface({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final style = NoticeStyle.of(context);
    return Material(
      elevation: 8,
      color: style.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(style.radius),
        side: BorderSide(color: style.border),
      ),
      child: DefaultTextStyle.merge(
        style: style.textStyle,
        child: IconTheme.merge(
          data: IconThemeData(color: style.foreground),
          child: child,
        ),
      ),
    );
  }
}
