import 'dart:math' as math;

import 'package:flauncher/theme/launcher_style.dart';
import 'package:flauncher/actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_service.dart';
import '../theme/interface_style.dart';

class SidePanelDialog extends StatelessWidget {
  final Widget child;
  final double width;
  final bool? isRightSide;
  final double topInset;
  final Rect? anchor;

  const SidePanelDialog({
    super.key,
    required this.child,
    this.width = 250,
    this.isRightSide,
    this.topInset = 0,
    this.anchor,
  });

  @override
  Widget build(BuildContext context) {
    final style = LauncherStyle.of(context);
    final skin = InterfaceSkin.of(context);
    final borderRadius = BorderRadius.circular(style.panelRadius);
    final onRight =
        isRightSide ??
        context.watch<SettingsService?>()?.settingsMenuOnRight ??
        false;

    final panel = Align(
      heightFactor: anchor == null ? null : 1,
      alignment: onRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          anchor == null ? style.panelMargin : 0,
          anchor == null ? style.panelMargin + topInset : 0,
          anchor == null ? style.panelMargin : 0,
          anchor == null ? style.panelMargin : 0,
        ),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: skin.style == InterfaceStyle.outline ? 0 : 16,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black54,
          borderRadius: borderRadius,
          child: Container(
            width: width,
            decoration: skin.standard ? BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
            ) : skin.surface(Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.onSurface,
              cornerRadius: style.panelRadius, borderWidth: 1),
            padding: EdgeInsets.all(style.panelPadding),
            child: Actions(
              actions: {BackIntent: BackAction(context)},
              child: child,
            ),
          ),
        ),
      ),
    );
    if (anchor == null) return panel;
    return LayoutBuilder(
      builder: (context, constraints) {
        final margin = math.max(12.0, style.panelMargin);
        final panelWidth = math.min(
          width,
          math.max(0.0, constraints.maxWidth - margin * 2),
        );
        final top = math.min(
          math.max(anchor!.bottom, topInset) + 8,
          constraints.maxHeight - margin,
        );
        final left = (anchor!.center.dx - panelWidth / 2)
            .clamp(
              margin,
              math.max(margin, constraints.maxWidth - panelWidth - margin),
            )
            .toDouble();
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: panelWidth,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: math.max(0, constraints.maxHeight - top - margin),
                ),
                child: panel,
              ),
            ),
          ],
        );
      },
    );
  }
}
