import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/appearance_service.dart';
import '../../providers/settings_service.dart';
import '../launcher_dialog.dart';
import '../action_notice.dart';
import 'settings_page_layout.dart';
import 'settings_choice_tile.dart';
import 'settings_percentage_slider.dart';
import 'settings_value_stepper.dart';
import 'focusable_settings_tile.dart';
import 'color_palette_dialog.dart';
import 'reset_style_tile.dart';

class SettingsStylePage extends StatefulWidget {
  static const routeName = 'settings_style';
  static const notificationsRouteName = 'notification_style';
  final bool notifications;
  const SettingsStylePage({super.key, this.notifications = false});
  @override
  State<SettingsStylePage> createState() => _SettingsStylePageState();
}

class _SettingsStylePageState extends State<SettingsStylePage> {
  VoidCallback? _closePreview;
  bool _previewScheduled = false;
  bool get notifications => widget.notifications;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!notifications || _previewScheduled) return;
    _previewScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _closePreview = showActionNotice(
        context,
        AppLocalizations.of(context)!.noticeStylePreview,
        persistent: true,
      );
    });
  }

  @override
  void dispose() {
    final close = _closePreview;
    if (close != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final service = context.watch<AppearanceService>();
    final appearance = service.appearance;
    final prefix = notifications ? 'notice' : 'settings';
    Widget color(String title, String key, Color fallback) =>
        FocusableSettingsTile(
          title: Text(title),
          trailing: Container(
            width: 36,
            height: 24,
            color: appearance.color(key) ?? fallback,
          ),
          onPressed: () async {
            final selected = await showLauncherDialog<(int?,)>(
              context: context,
              builder: (_) => ColorPaletteDialog(
                title: title,
                current: appearance.values[key] as int?,
                allowDefault: true,
              ),
            );
            if (selected != null) {
              if (selected.$1 == null) {
                await service.resetFields([key]);
              } else {
                await service.set(key, selected.$1);
              }
            }
          },
        );
    return SettingsPageLayout(
      title: Text(notifications ? l.notificationStyle : l.settingsStyle),
      child: ListView(
        children: [
          if (!notifications)
            SettingsChoiceTile<bool>(
              autofocus: true,
              valueBelow: true,
              title: l.settingsMenuPosition,
              value: settings.settingsMenuOnRight,
              options: const [false, true],
              label: (right) =>
                  right ? l.settingsMenuRight : l.settingsMenuLeft,
              onChanged: settings.setSettingsMenuOnRight,
            ),
          color(
            l.styleBackgroundColor,
            '${prefix}Color',
            Theme.of(context).colorScheme.surface.withAlpha(255),
          ),
          SettingsPercentageSlider(
            title: l.styleTransparency,
            value: 1 - (appearance.number('${prefix}Opacity') ?? 1),
            onChanged: (v) => service.set('${prefix}Opacity', 1 - v),
          ),
          if (notifications)
            SettingsValueStepper(
              title: l.noticeSize,
              options: [for (var n = 240; n <= 600; n += 20) n],
              value: appearance.number('noticeWidth') ?? 360,
              label: (v) => '${(v as num).round()}',
              onChanged: (v) => service.set('noticeWidth', v),
            ),
          SettingsValueStepper(
            title: l.styleTextSize,
            options: [for (var n = 12; n <= 24; n++) n],
            value: appearance.number('${prefix}TextSize') ?? 16,
            label: (v) => '${(v as num).round()}',
            onChanged: (v) => service.set('${prefix}TextSize', v),
          ),
          color(
            l.styleTextColor,
            '${prefix}TextColor',
            Theme.of(context).colorScheme.onSurface,
          ),
          ResetStyleTile(
            onReset: () async {
              await service.resetFields(
                appearance.values.keys
                    .where((key) => key.startsWith(prefix))
                    .toList(),
              );
              if (!notifications) await settings.setSettingsMenuOnRight(false);
            },
          ),
        ],
      ),
    );
  }
}
