import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/remote_battery_service.dart';
import 'launcher_dialog.dart';
import 'menu_header.dart';
import 'menu_header_action.dart';
import 'remote_battery_widget.dart';
import 'settings/remote_battery_settings_page.dart';
import 'settings/settings_panel.dart';
import 'settings/settings_panel_style.dart';
import 'settings/settings_read_only_value.dart';
import 'side_panel_dialog.dart';

class RemoteBatteryMenu extends StatefulWidget {
  final Rect anchor;
  const RemoteBatteryMenu({super.key, required this.anchor});

  @override
  State<RemoteBatteryMenu> createState() => _RemoteBatteryMenuState();
}

class _RemoteBatteryMenuState extends State<RemoteBatteryMenu> {
  final _settingsNode = FocusNode();
  bool _settingsOpen = false;

  @override
  void dispose() {
    _settingsNode.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    if (_settingsOpen) return;
    setState(() => _settingsOpen = true);
    try {
      await showLauncherDialog<void>(
        context: context,
        parentPanelHidden: true,
        styleDialog: false,
        barrierColor: Colors.transparent,
        builder: (_) => const SettingsPanel(
          initialRoute: RemoteBatterySettingsPage.routeName,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _settingsOpen = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _settingsNode.requestFocus();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SettingsPanelStyle(
    builder: (context) {
      final l = AppLocalizations.of(context)!;
      final (device, selectedName) = context
          .select<RemoteBatteryService?, (RemoteBatteryDevice?, String?)>(
            (battery) => (battery?.activeDevice, battery?.selectedName),
          );
      return ExcludeFocus(
        excluding: _settingsOpen,
        child: Offstage(
          offstage: _settingsOpen,
          child: Stack(
            children: [
              const Positioned.fill(child: LauncherPanelBackdrop()),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              SidePanelDialog(
                anchor: widget.anchor,
                topInset: kToolbarHeight,
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: MenuHeader(
                        title: Text(l.remoteBatteryTitle),
                        actions: [
                          MenuHeaderAction(
                            focusNode: _settingsNode,
                            tooltip: l.widgetSettings,
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: _openSettings,
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SettingsReadOnlyValue(
                              label: l.name,
                              value: device?.name ?? selectedName ?? '—',
                              wrapLines: true,
                            ),
                            SettingsReadOnlyValue(
                              label: l.remoteBatteryBluetoothAddress,
                              value: device?.address ?? '—',
                              textDirection: TextDirection.ltr,
                              wrapLines: true,
                            ),
                            const Divider(),
                            RemoteBatteryDeviceButton(
                              autofocus: true,
                              visible: !_settingsOpen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
