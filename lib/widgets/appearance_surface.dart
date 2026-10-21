import 'tile_theme_outline.dart';
import '../providers/settings_service.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../tile_appearance.dart';
import '../providers/memory_resources.dart';
import 'package:provider/provider.dart';

class AppearanceSurface extends StatelessWidget {
  final TileAppearance appearance;
  final BorderRadius borderRadius;
  final double elevation;
  final bool focused;
  final Color? focusColor;
  final Widget child;
  const AppearanceSurface({super.key, required this.appearance, required this.borderRadius,
    required this.elevation, required this.focused, this.focusColor, required this.child});

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<MemoryResources?>()?.economyEnabled ?? false;
    final settings = context.watch<SettingsService?>();
    final radius = appearance.number('radius');
    final corners = radius == null ? borderRadius : BorderRadius.circular(radius);
    final background = appearance.color('backgroundColor') ?? Theme.of(context).canvasColor;
    final baseShadow = appearance.number('shadow') ?? 0;
    final focusShadow = elevation > 0 ? elevation : 12.0;
    final requestedElevation = focused
        ? (appearance.showFocusShadow ? (baseShadow > focusShadow ? baseShadow : focusShadow) : 0.0)
        : baseShadow;
    return Material(
      color: Colors.transparent, borderRadius: corners,
      elevation: economy && !focused ? requestedElevation.clamp(0, 4) : requestedElevation,
      shadowColor: Colors.black,
      child: Stack(clipBehavior: Clip.none, fit: StackFit.expand, children: [
        ClipRRect(borderRadius: corners, child: Stack(fit: StackFit.expand, children: [
        if (appearance.blurTiles && !economy) BackdropFilter(filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), child: const SizedBox.expand()),
        ColoredBox(color: background.withValues(alpha: appearance.opacity)),
        child,
        ])),
        if (focused && appearance.focusBorderStyle(legacyHidden: settings?.hideHighlightOutlineOnHomescreen ?? false) != 'none')
          TileThemeOutline(theme: appearance.active ? 'modern' : settings?.themes ?? 'modern', radius: corners.topLeft.x,
            borderStyle: appearance.focusBorderStyle(legacyHidden: settings?.hideHighlightOutlineOnHomescreen ?? false),
            accent: focusColor ?? Theme.of(context).colorScheme.primary,
            pulse: appearance.values['focusPulse'] as bool? ?? settings?.appHighlightAnimationEnabled ?? false),
      ]),
    );
  }
}

class PanelAppearanceSurface extends StatelessWidget {
  final TileAppearance appearance;
  final Widget child;
  const PanelAppearanceSurface({super.key, required this.appearance, required this.child});
  @override
  Widget build(BuildContext context) {
    final economy = context.watch<MemoryResources?>()?.economyEnabled ?? false;
    final color = appearance.color('panelColor') ?? Colors.black;
    final opacity = appearance.number('panelOpacity') ?? 0;
    final content = ColoredBox(color: color.withValues(alpha: color == Colors.transparent ? 0 : opacity), child: child);
    return ClipRect(child: appearance.blurPanel && !economy
      ? BackdropFilter(filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), child: content)
      : content);
  }
}
