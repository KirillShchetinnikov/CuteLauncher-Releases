import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/network_speed_service.dart';
import 'launcher_dialog.dart';
import 'menu_header.dart';
import 'menu_header_action.dart';
import 'network_speed_widget.dart';
import 'settings/network_speed_settings_page.dart';
import 'settings/settings_panel.dart';
import 'settings/settings_panel_style.dart';
import 'side_panel_dialog.dart';

class NetworkSpeedMenu extends StatefulWidget {
  final Rect anchor;
  const NetworkSpeedMenu({super.key, required this.anchor});
  @override
  State<NetworkSpeedMenu> createState() => _NetworkSpeedMenuState();
}

class _NetworkSpeedMenuState extends State<NetworkSpeedMenu> {
  final _settingsNode = FocusNode();
  NetworkSpeedService? _service;
  bool _settingsOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<NetworkSpeedService>();
    if (_service == service) return;
    _service?.setVisible(this, false);
    _service = service;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) service.setVisible(this, true);
    });
  }

  Future<void> _openSettings() async {
    setState(() => _settingsOpen = true);
    _service?.setVisible(this, false);
    await showLauncherDialog<void>(
      context: context,
      parentPanelHidden: true,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) =>
          const SettingsPanel(initialRoute: NetworkSpeedSettingsPage.routeName),
    );
    if (!mounted) return;
    setState(() => _settingsOpen = false);
    _service?.setVisible(this, true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _service?.setVisible(this, false);
    _settingsNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SettingsPanelStyle(
    builder: (context) {
      final l = AppLocalizations.of(context)!;
      final state = context.select<NetworkSpeedService, NetworkSpeed>(
        (s) => s.state,
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
                  onTap: () => Navigator.pop(context),
                ),
              ),
              SidePanelDialog(
                anchor: widget.anchor,
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MenuHeader(
                        title: Text(l.networkSpeedTitle),
                        actions: [
                          MenuHeaderAction(
                            focusNode: _settingsNode,
                            autofocus: true,
                            tooltip: l.networkSpeedSettings,
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: _openSettings,
                          ),
                        ],
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          children: [
                            Text(
                              '${l.trafficReceived}\n↓ ${networkSpeedLabel(context, state.received)}',
                            ),
                            Text(
                              '${l.trafficSent}\n↑ ${networkSpeedLabel(context, state.sent)}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
