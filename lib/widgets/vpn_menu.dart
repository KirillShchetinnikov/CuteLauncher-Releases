import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/network_service.dart';
import '../providers/vpn_service.dart';
import 'action_notice.dart';
import 'launcher_dialog.dart';
import 'menu_header.dart';
import 'menu_header_action.dart';
import 'settings/focusable_settings_tile.dart';
import 'settings/settings_help.dart';
import 'settings/settings_panel.dart';
import 'settings/settings_panel_style.dart';
import 'settings/vpn_settings_page.dart';
import 'side_panel_dialog.dart';

String vpnResultLabel(AppLocalizations l, String result) => switch (result) {
  'connected' => l.vpnConnected,
  'disconnected' => l.vpnDisconnected,
  'permission' => l.vpnAllowControl,
  'profile' => l.vpnProfileHelp,
  'unsupported' => l.vpnUnsupported,
  'other' => l.vpnOther,
  'alwaysOn' => l.vpnAlwaysOnManaged,
  'pending' || 'sent' => l.vpnPending,
  'idle' || '' => '',
  _ => l.vpnFailed,
};

class VpnMenu extends StatefulWidget {
  final Rect anchor;
  const VpnMenu({super.key, required this.anchor});
  @override
  State<VpnMenu> createState() => _VpnMenuState();
}

class _VpnMenuState extends State<VpnMenu> with WidgetsBindingObserver {
  final _settingsNode = FocusNode();
  final _scroll = ScrollController();
  Timer? _poll;
  bool _settingsOpen = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  void _start() {
    _poll?.cancel();
    context.read<VpnService>().refresh();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_settingsOpen) context.read<VpnService>().refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _poll?.cancel();
    if (state == AppLifecycleState.resumed) _start();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _settingsNode.dispose();
    _scroll.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _settings() async {
    setState(() => _settingsOpen = true);
    await showLauncherDialog<void>(
      context: context,
      parentPanelHidden: true,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) =>
          const SettingsPanel(initialRoute: VpnSettingsPage.routeName),
    );
    if (!mounted) return;
    setState(() => _settingsOpen = false);
    await context.read<VpnService>().refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) => SettingsPanelStyle(
    builder: (context) {
      final vpn = context.watch<VpnService>();
      final l = AppLocalizations.of(context)!;
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
                  controller: _scroll,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MenuHeader(
                        title: Text(l.vpnTitle),
                        actions: [
                          MenuHeaderAction(
                            focusNode: _settingsNode,
                            autofocus: true,
                            tooltip: l.vpnSettings,
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: _settings,
                          ),
                        ],
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vpn.statusUnknown
                                  ? l.vpnUnknown
                                  : vpn.active
                                  ? l.vpnConnected
                                  : l.vpnDisconnected,
                            ),
                            if (vpn.target.isNotEmpty)
                              Text(vpn.name(vpn.target)),
                            if (vpn.active &&
                                (vpn.owner.isEmpty || vpn.owner != vpn.target))
                              Text(l.vpnOther),
                            if (vpn.profile.isNotEmpty && vpn.requiresProfile)
                              Text(vpn.profile),
                            if (vpn.managed) Text(l.vpnAlwaysOnManaged),
                            if (vpn.target == 'com.mantaray.vpn')
                              Text(l.vpnClientConfirmation),
                            if (vpn.restartRequired &&
                                vpn.bootEnabled &&
                                vpn.bootMode == 'alwaysOn')
                              Text(l.vpnRestartRequired),
                            if (vpn.result.isNotEmpty)
                              Text(vpnResultLabel(l, vpn.result)),
                          ],
                        ),
                      ),
                      if (vpn.busy) const LinearProgressIndicator(),
                      if (vpn.canControl)
                        FocusableSettingsTile(
                          title: Text(
                            vpn.active ? l.vpnDisconnect : l.vpnConnect,
                          ),
                          enabled: !vpn.busy,
                          leading: Icon(
                            vpn.active ? Icons.link_off : Icons.link,
                          ),
                          onPressed: () async {
                            final result = await vpn.toggle();
                            if (context.mounted && vpn.notify) {
                              showActionNotice(
                                context,
                                vpnResultLabel(l, result),
                                error:
                                    result != 'connected' &&
                                    result != 'disconnected',
                              );
                            }
                          },
                        ),
                      if (vpn.supported &&
                          !vpn.permission &&
                          vpn.canRequestPermission)
                        FocusableSettingsTile(
                          title: Text(l.vpnAllowControl),
                          onPressed: () => vpn.requestPermission(vpn.target),
                        ),
                      if (!vpn.canControl) SettingsHelp(text: l.vpnHelp),
                      if (vpn.target.isNotEmpty)
                        FocusableSettingsTile(
                          title: Text(l.vpnOpenApp),
                          leading: const Icon(Icons.open_in_new),
                          onPressed: () async {
                            if (!await vpn.open() && context.mounted) {
                              showActionNotice(
                                context,
                                l.vpnFailed,
                                error: true,
                              );
                            }
                          },
                        ),
                      FocusableSettingsTile(
                        title: Text(l.vpnAndroidSettings),
                        leading: const Icon(Icons.settings_ethernet),
                        onPressed: () =>
                            context.read<NetworkService>().openVpnSettings(),
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
