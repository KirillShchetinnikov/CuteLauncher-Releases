import 'settings_information.dart';
import 'settings_read_only_value.dart';
import 'settings_section.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/vpn_service.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import '../remote_text_input.dart';
import '../rounded_switch_list_tile.dart';
import '../vpn_menu.dart';
import 'focusable_settings_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_value_stepper.dart';

Future<void> _save(BuildContext context, String key, Object value) async {
  final vpn = context.read<VpnService>();
  if (vpn.busy) return;
  final ok = await vpn.save(key, value);
  if (!ok && context.mounted) {
    showActionNotice(
      context,
      AppLocalizations.of(context)!.vpnFailed,
      error: true,
    );
  }
}

/// Saving blocks activation, not focus or remote traversal through the controls.
class _VpnSettingsInteraction extends StatelessWidget {
  final VpnService vpn;
  final Widget child;
  const _VpnSettingsInteraction({required this.vpn, required this.child});

  @override
  Widget build(BuildContext context) => AbsorbPointer(
    absorbing: vpn.busy,
    child: Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) =>
          vpn.busy &&
              const [
                LogicalKeyboardKey.enter,
                LogicalKeyboardKey.numpadEnter,
                LogicalKeyboardKey.select,
                LogicalKeyboardKey.space,
                LogicalKeyboardKey.arrowLeft,
                LogicalKeyboardKey.arrowRight,
              ].contains(event.logicalKey)
          ? KeyEventResult.handled
          : KeyEventResult.ignored,
      child: child,
    ),
  );
}

class VpnSettingsPage extends StatefulWidget {
  static const routeName = 'vpn_settings';
  const VpnSettingsPage({super.key});
  @override
  State<VpnSettingsPage> createState() => _VpnSettingsPageState();
}

class _VpnSettingsPageState extends State<VpnSettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<VpnService>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final vpn = context.watch<VpnService>();
    return SettingsPageLayout(
      title: Text(l.vpnSettings),
      header: SizedBox(
        height: 4,
        child: !vpn.initialized && !vpn.failed || vpn.busy
            ? const LinearProgressIndicator()
            : null,
      ),
      child: _VpnSettingsInteraction(
        vpn: vpn,
        child: ListView(
          children: [
            if (vpn.failed)
              SettingsMessage(
                text: l.vpnUnknown,
                kind: SettingsMessageKind.error,
              ),
            SettingsSection(
              title: l.vpnApp,
              children: [
                SettingsChoiceTile<String>(
                  key: const ValueKey('vpn_app'),
                  title: l.vpnApp,
                  value: vpn.selected,
                  options: ['', ...vpn.clients.map((client) => client.app)],
                  valueLabel: vpn.selected.isEmpty
                      ? l.vpnAutomatic
                      : vpn.name(vpn.selected),
                  enabled: vpn.initialized,
                  label: (app) => app.isEmpty ? l.vpnAutomatic : vpn.name(app),
                  onChanged: (app) => _save(context, 'selected', app),
                ),
                if (vpn.target.isNotEmpty)
                  VpnClientSettings(
                    key: const ValueKey('vpn_client'),
                    app: vpn.target,
                  ),
              ],
            ),
            SettingsSection(
              title: l.settingsGroupIndicators,
              children: [
                for (final setting in [
                  ('onlyActive', l.vpnOnlyActive, vpn.onlyActive),
                  ('showName', l.vpnShowName, vpn.showName),
                  ('color', l.vpnColor, vpn.color),
                  ('notify', l.vpnNotify, vpn.notify),
                ])
                  RoundedSwitchListTile(
                    key: ValueKey('vpn_${setting.$1}'),
                    title: Text(setting.$2),
                    value: setting.$3,
                    enabled: vpn.initialized,
                    onChanged: (value) => _save(context, setting.$1, value),
                  ),
              ],
            ),
            SettingsHelp(
              key: const ValueKey('vpn_help'),
              title: l.vpnTitle,
              text: l.vpnHelp,
            ),
          ],
        ),
      ),
    );
  }
}

/// Configuration of one client's profile/permission, shared with startup settings.
class VpnClientSettings extends StatelessWidget {
  final String app;
  const VpnClientSettings({super.key, required this.app});
  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnService>();
    final l = AppLocalizations.of(context)!;
    final client = vpn.clients.where((client) => client.app == app).firstOrNull;
    if (client == null || !client.supported) {
      return SettingsMessage(
        text: l.vpnUnsupported,
        kind: SettingsMessageKind.warning,
      );
    }
    final profile = vpn.profileFor(app);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (app == 'com.mantaray.vpn')
          SettingsHelp(title: l.vpnApp, text: l.vpnClientConfirmation),
        if (client.requiresProfile)
          FocusableSettingsTile(
            title: Text(l.vpnProfile),
            trailing: Text(profile.isEmpty ? l.vpnNone : profile),
            enabled: vpn.initialized,
            onPressed: () async {
              final value = await showLauncherDialog<String>(
                context: context,
                builder: (_) => _ProfileDialog(initial: profile),
              );
              if (value != null && context.mounted) {
                await _save(context, 'profile_$app', value);
              }
            },
          ),
        if (client.requiresProfile &&
            !client.permission &&
            vpn.canRequestPermission)
          FocusableSettingsTile(
            title: Text(l.vpnAllowControl),
            enabled: vpn.initialized,
            onPressed: () => vpn.requestPermission(app),
          ),
      ],
    );
  }
}

class VpnStartupSection extends StatefulWidget {
  const VpnStartupSection({super.key});
  @override
  State<VpnStartupSection> createState() => _VpnStartupSectionState();
}

class _VpnStartupSectionState extends State<VpnStartupSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<VpnService?>()?.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnService?>();
    if (vpn == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    return _VpnSettingsInteraction(
      vpn: vpn,
      child: SettingsSection(
        title: l.vpnStartup,
        children: [
          RoundedSwitchListTile(
            key: const ValueKey('vpn_boot_enabled'),
            title: Text(l.vpnStartup),
            value: vpn.bootEnabled,
            enabled: vpn.initialized,
            onChanged: (value) => _save(context, 'bootEnabled', value),
          ),
          if (vpn.bootEnabled) ...[
            SettingsChoiceTile<String>(
              key: const ValueKey('vpn_boot_mode'),
              title: l.vpnStartupMethod,
              value: vpn.bootMode,
              options: const ['client', 'alwaysOn'],
              enabled: vpn.initialized,
              label: (mode) => mode == 'alwaysOn'
                  ? l.vpnStartupAlwaysOn
                  : l.vpnStartupClient,
              onChanged: (mode) => _save(context, 'bootMode', mode),
            ),
            SettingsChoiceTile<String>(
              key: const ValueKey('vpn_boot_app'),
              title: l.vpnStartup,
              value: vpn.bootApp,
              options: [
                '',
                ...vpn.clients
                    .where(
                      (client) =>
                          vpn.bootMode != 'alwaysOn' ||
                          client.alwaysOnSupported,
                    )
                    .map((client) => client.app),
              ],
              valueLabel: vpn.bootApp.isEmpty
                  ? l.vpnNone
                  : vpn.name(vpn.bootApp),
              enabled: vpn.initialized,
              label: (app) => app.isEmpty ? l.vpnNone : vpn.name(app),
              onChanged: (app) => _save(context, 'bootApp', app),
            ),
            if (vpn.bootMode == 'client' && vpn.bootApp.isNotEmpty) ...[
              VpnClientSettings(app: vpn.bootApp),
              RoundedSwitchListTile(
                title: Text(l.autoLaunchWake),
                value: vpn.wake,
                enabled: vpn.initialized,
                onChanged: (value) => _save(context, 'wake', value),
              ),
              SettingsValueStepper(
                title: l.autoLaunchDelay,
                value: vpn.delay,
                enabled: vpn.initialized,
                options: const [0, 3, 5, 10, 20, 30, 60],
                label: (value) => l.autoLaunchSeconds(value as int),
                onChanged: (value) => _save(context, 'delay', value as int),
              ),
              if (vpn.startupStatus != 'idle')
                SettingsMessage(
                  text: vpnResultLabel(l, vpn.startupStatus),
                  kind: switch (vpn.startupStatus) {
                    'permission' ||
                    'profile' ||
                    'unsupported' ||
                    'other' ||
                    'alwaysOn' => SettingsMessageKind.warning,
                    'connected' ||
                    'disconnected' ||
                    'pending' ||
                    'sent' => SettingsMessageKind.info,
                    _ => SettingsMessageKind.error,
                  },
                ),
            ],
            if (vpn.systemApp.isNotEmpty)
              SettingsReadOnlyValue(
                label: l.vpnStartupAlwaysOn,
                value: vpn.name(vpn.systemApp),
                wrapLines: true,
              ),
            if (vpn.bootMode == 'alwaysOn')
              SettingsHelp(title: l.vpnStartup, text: l.vpnAlwaysOnHelp),
            if (vpn.bootMode == 'client')
              SettingsHelp(title: l.vpnStartup, text: l.vpnStartupHelp),
          ],
          if (vpn.restartRequired)
            SettingsMessage(
              text: l.vpnRestartRequired,
              kind: SettingsMessageKind.warning,
            ),
        ],
      ),
    );
  }
}

class _ProfileDialog extends StatefulWidget {
  final String initial;
  const _ProfileDialog({required this.initial});
  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final _editor = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final valid =
        _editor.text.isEmpty ||
        RegExp(r'^[A-Za-z0-9_=+.-]{1,15}$').hasMatch(_editor.text);
    return LauncherAlertDialog(
      title: Text(l.vpnProfile),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RemoteTextInput(
            child: TextField(
              controller: _editor,
              autofocus: true,
              maxLength: 15,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
            ),
          ),
          SettingsHelp(title: l.vpnProfile, text: l.vpnProfileHelp),
        ],
      ),
      actions: [
        LauncherDialogButton(
          isCancel: true,
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        LauncherDialogButton(
          primary: true,
          onPressed: valid ? () => Navigator.pop(context, _editor.text) : null,
          child: Text(l.ok),
        ),
      ],
    );
  }
}
