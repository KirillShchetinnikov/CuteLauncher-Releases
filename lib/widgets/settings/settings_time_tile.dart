import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'focusable_settings_tile.dart';
import 'settings_slider_tile.dart';

class SettingsTimeTile extends StatelessWidget {
  final String title;
  final int value;
  final ValueChanged<int> onChanged;
  const SettingsTimeTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    title: Text(title),
    valueIcon: Icons.edit_outlined,
    trailing: Text(
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}',
    ),
    onPressed: () async {
      var hour = value ~/ 60;
      var minute = value % 60;
      final l = AppLocalizations.of(context)!;
      final result = await showLauncherDialog<int>(
        context: context,
        builder: (dialog) => StatefulBuilder(
          builder: (dialog, setState) => LauncherAlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SettingsSliderTile(
                    title: MaterialLocalizations.of(context)
                        .timePickerHourLabel,
                    autofocus: true,
                    value: hour,
                    options: [for (var i = 0; i < 24; i++) i],
                    label: (v) => v.toInt().toString().padLeft(2, '0'),
                    onChanged: (v) => setState(() => hour = v.toInt()),
                  ),
                  SettingsSliderTile(
                    title: MaterialLocalizations.of(context)
                        .timePickerMinuteLabel,
                    value: minute,
                    options: [for (var i = 0; i < 60; i++) i],
                    label: (v) => v.toInt().toString().padLeft(2, '0'),
                    onChanged: (v) => setState(() => minute = v.toInt()),
                  ),
                ],
              ),
            ),
            actions: [
              LauncherDialogButton(
                onPressed: () => Navigator.pop(dialog),
                isCancel: true,
                child: Text(l.cancel),
              ),
              LauncherDialogButton(
                onPressed: () => Navigator.pop(dialog, hour * 60 + minute),
                primary: true,
                child: Text(l.ok),
              ),
            ],
          ),
        ),
      );
      if (result != null && context.mounted) onChanged(result);
    },
  );
}
