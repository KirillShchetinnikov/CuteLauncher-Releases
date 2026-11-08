import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appearance_service.dart';
import '../../theme/settings_section_tokens.dart';
import '../../tile_appearance.dart';

/// A heading and its related controls share geometry across both group styles.
/// The page supplies localized text and continues to own the scroll view.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = context.select<AppearanceService?, SettingsSectionStyle>(
      (service) =>
          service?.appearance.settingsSectionStyle ??
          SettingsSectionStyle.surface,
    );
    final surface = style == SettingsSectionStyle.surface;
    final heading = Semantics(
      container: true,
      header: true,
      child: Text(title, style: theme.textTheme.titleMedium),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: SettingsSectionTokens.gap),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface
              ? colors.onSurface.withValues(
                  alpha: SettingsSectionTokens.surfaceOpacity,
                )
              : null,
          borderRadius: BorderRadius.circular(SettingsSectionTokens.radius),
        ),
        child: Padding(
          padding: SettingsSectionTokens.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: SettingsSectionTokens.headerPadding,
                decoration: BoxDecoration(
                  color: surface
                      ? null
                      : colors.primary.withValues(
                          alpha: SettingsSectionTokens.accentOpacity,
                        ),
                  // Reserve both edges so a style change never moves controls.
                  border: BorderDirectional(
                    start: BorderSide(
                      color: surface ? Colors.transparent : colors.primary,
                      width: SettingsSectionTokens.accentWidth,
                    ),
                    bottom: BorderSide(
                      color: surface
                          ? colors.onSurface.withValues(
                              alpha: SettingsSectionTokens.dividerOpacity,
                            )
                          : Colors.transparent,
                      width: SettingsSectionTokens.dividerWidth,
                    ),
                  ),
                ),
                child: heading,
              ),
              const SizedBox(height: SettingsSectionTokens.headerGap),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
