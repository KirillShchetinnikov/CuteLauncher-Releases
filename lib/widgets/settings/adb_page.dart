import 'tv_power_page.dart';
import '../remote_text_input.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';

import 'dart:convert';

import 'auto_launch_page.dart';
import 'remote_buttons_page.dart';
import 'recent_apps_page.dart';
import 'tv_cleaner_page.dart';
import 'adb_notice.dart';

import 'package:flauncher/bridge_result.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../rounded_switch_list_tile.dart';
import 'adb_action_confirmation.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_help.dart';
import 'settings_route.dart';

/// Both former entry routes display the same launcher and TV settings.
class AdbPage extends StatefulWidget {
  static const routeName = 'adb_panel';
  final String? section;
  const AdbPage({super.key, this.section});
  @override
  State<AdbPage> createState() => _AdbPageState();
}

class _AdbPageState extends State<AdbPage> with WidgetsBindingObserver {
  static const _channel = BridgeChannel('cutelauncher/adb');
  int _port = 5555;
  bool _busy = false, _verified = false;
  bool? _overrideHome;
  bool? _isHome, _accessibility;
  Map<String, dynamic> _snapshot = {};
  Map _compatibility = {};
  String? _status, _currentHomeName;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<void> _load() async {
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>('info');
      if (!mounted) return;
      if (info != null) {
        setState(() {
          _port = info['port'] as int? ?? 5555;
          _overrideHome = info['homeOverride'] as bool?;
          _compatibility = info['compatibility'] as Map? ?? {};
          final saved = info['connectionSnapshot'];
          _snapshot = saved is String && saved.isNotEmpty
              ? Map<String, dynamic>.from(jsonDecode(saved) as Map)
              : {};
          _status = _snapshot['status'] as String?;
          _verified = _status == 'ready' && _snapshot['launchers'] is List;
          _isHome = _snapshot['isHome'] as bool?;
          final launcher = info['launcherStatus'] as Map?;
          _currentHomeName = launcher?['name'] as String?;
          _isHome = launcher?['isHome'] as bool? ?? _isHome;
        });
      }
    } catch (_) {}
    if (!mounted) return;
    bool? home, accessibility;
    try {
      final apps = context.read<AppsService?>();
      final launcher = context.read<LauncherState?>();
      if (apps != null && launcher != null) {
        await launcher.refresh(apps);
        home = launcher.isDefaultLauncher;
      } else {
        home = await apps?.isDefaultLauncher();
      }
    } catch (_) {}
    try {
      accessibility = await FLauncherChannel().checkAccessibilityPermission();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isHome = home ?? _isHome;
        _accessibility = accessibility ?? _snapshot['accessibility'] as bool?;
      });
    }
  }

  Future<void> _refreshLauncherState() async {
    if (!mounted) return;
    final apps = context.read<AppsService?>();
    final launcher = context.read<LauncherState?>();
    if (apps != null && launcher != null) {
      try {
        await launcher.refresh(apps);
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> _call(
    String action, [
    Map<String, dynamic> extra = const {},
  ]) async =>
      await _channel.invokeMapMethod<String, dynamic>('action', {
        'action': action,
        'port': _port,
        'tls': false,
        ...extra,
      }) ??
      {};
  Future<void> _check() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _verified = false;
      _status = null;
      _snapshot = {};
    });
    try {
      final value = await _call('check');
      if (!mounted) return;
      final valid =
          value['status'] == 'ready' &&
          value['isHome'] is bool &&
          value['accessibility'] is bool &&
          value['launchers'] is List;
      setState(() {
        _verified = valid;
        _status = valid
            ? 'ready'
            : value['status'] == 'ready'
            ? 'unavailable'
            : value['status'] as String?;
        if (valid) {
          _snapshot = value;
          _compatibility = value['compatibility'] as Map? ?? _compatibility;
          _isHome = value['isHome'];
          _accessibility = value['accessibility'];
        }
      });
    } catch (_) {
      if (mounted) setState(() => _status = 'unavailable');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        showAdbNotice(
          context,
          _status,
          title: AppLocalizations.of(context)!.adbCheck,
        );
      }
    }
  }

  Future<void> _editPort() async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: '$_port');
    final okFocus = FocusNode();
    String? error;
    final value = await showLauncherDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => LauncherAlertDialog(
          title: Text(l.adbPort),
          content: RemoteTextInput(
            child: TextField(
              autofocus: true,
              controller: controller,
              textInputAction: TextInputAction.done,
              onEditingComplete: () => okFocus.requestFocus(),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(errorText: error),
            ),
          ),
          actions: [
            LauncherDialogButton(
              onPressed: () => Navigator.pop(ctx),
              isCancel: true,
              child: Text(l.cancel),
            ),
            LauncherDialogButton(
              primary: true,
              focusNode: okFocus,
              onPressed: () {
                final port = int.tryParse(controller.text);
                if (port == null || port < 1024 || port > 65535) {
                  update(() => error = l.adbInvalid);
                  return;
                }
                Navigator.pop(ctx, port);
              },
              child: Text(l.ok),
            ),
          ],
        ),
      ),
    );
    // Dispose after the closing dialog finishes its transition.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    okFocus.dispose();
    if (mounted && value != null && value != _port) {
      try {
        if (await _channel.invokeMethod<bool>('port', {'port': value}) !=
            true) {
          return;
        }
      } catch (_) {
        if (mounted) setState(() => _status = 'unavailable');
        return;
      }
      if (!mounted) return;
      setState(() {
        _port = value;
        _verified = false;
        _status = null;
        _snapshot = {};
      });
    }
  }

  Future<void> _run(String action, String title, {String? target}) async {
    if (_busy || !_verified) return;
    var report = false;
    setState(() => _busy = true);
    try {
      var plan = await _call('preview', {
        'operation': action,
        'target': ?target,
      });
      if (!mounted) return;
      var allowOwnedWifi = false;
      if (action == 'disableSystem' && plan['status'] == 'wifiOwned') {
        if (!await confirmAdbWifiRisk(context) || !mounted) return;
        allowOwnedWifi = true;
        plan = await _call('preview', {
          'operation': action,
          'target': ?target,
          'allowOwnedWifi': true,
        });
        if (!mounted) return;
      }
      if (plan['status'] != 'ready' || plan['commands'] is! List) {
        report = true;
        setState(() {
          _status = plan['status'] as String? ?? 'unavailable';
          _verified = false;
          _snapshot = {};
        });
        return;
      }
      final commands = (plan['commands'] as List).cast<String>();
      if (!allowOwnedWifi && (!await confirmAdbAction(
            context,
            plan['targetName'] is String &&
                    (plan['targetName'] as String).isNotEmpty
                ? '$title: ${plan['targetName']}'
                : title,
            action,
            commands,
          ) ||
          !mounted)) {
        return;
      }
      if (!mounted) return;
      report = true;
      final result = await _call(action, {
        if (allowOwnedWifi) 'allowOwnedWifi': true,
        'commands': commands,
        'target': ?target,
      });
      if (!mounted) return;
      final value = result['status'] == 'success'
          ? await _call('check')
          : result;
      await _refreshLauncherState();
      if (!mounted) return;
      setState(() {
        _status =
            (value['status'] == 'ready' ? result['status'] : value['status'])
                as String? ??
            'unavailable';
        _verified =
            result['status'] == 'success' &&
            value['status'] == 'ready' &&
            value['isHome'] is bool &&
            value['accessibility'] is bool &&
            value['launchers'] is List;
        if (_verified) {
          _snapshot = value;
          _compatibility = value['compatibility'] as Map? ?? _compatibility;
          _isHome = value['isHome'];
          _accessibility = value['accessibility'];
        } else {
          _snapshot = {};
        }
      });
    } catch (_) {
      report = true;
      if (mounted) {
        setState(() {
          _verified = false;
          _snapshot = {};
          _status = 'unavailable';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (report) showAdbNotice(context, _status, title: title);
      }
    }
  }

  String _stateText(AppLocalizations l) => _busy
      ? l.adbPermissionChecking
      : switch (_status) {
          'ready' => l.adbReady,
          'success' => l.adbReady,
          'authorization' => l.adbAuthorization,
          'denied' => l.adbDenied,
          'invalid' => l.adbInvalid,
          'noRecovery' => l.adbNoRecovery,
          'changed' => l.adbChanged,
          'unavailable' => l.adbUnavailable,
          'unsupported' => l.adbUnsupported,
          'wifiOwned' => l.adbWifiOwned,
          'wifiUnknown' => l.adbWifiUnknown,
          _ => l.adbNotChecked,
        };
  bool _supported(String action, [String? target]) =>
      (_compatibility['actions'] as Map?)?[action] == true &&
      (action != 'restore' || _snapshot['restoreSupported'] != false) &&
      (action != 'disableSystem' ||
          (_compatibility['disableTargets'] as Map?)?[target] == true);
  Future<void> _openSection(String section) async {
    await Navigator.of(context).push(
      SettingsRoute<void>(
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: AdbPage(section: section),
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openPage(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) await _load();
  }

  Widget _menuTile(
    String title,
    IconData icon,
    bool? value,
    VoidCallback onPressed, {
    bool autofocus = false,
    bool showStatus = true,
    String? statusLabel,
  }) {
    final l = AppLocalizations.of(context)!;
    final state = value == null
        ? l.nightPermissionUnknown
        : value
        ? l.enabled
        : l.disabled;
    return FocusableSettingsTile(
      autofocus: autofocus,
      title: Text(title),
      leading: Icon(icon),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStatus) ...[
            Tooltip(
              message: '${statusLabel ?? title}: $state',
              child: Icon(
                value == null
                    ? Icons.help_outline
                    : value
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                semanticLabel: '${statusLabel ?? title}: $state',
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right_rounded, size: 20),
        ],
      ),
      onPressed: onPressed,
    );
  }

  Widget _block(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
  Widget _statusBox(String text, bool? value) => _block(text, [
    Row(
      children: [
        Icon(
          value == null
              ? Icons.help_outline
              : value
              ? Icons.check_circle_outline
              : Icons.cancel_outlined,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value == null
                ? AppLocalizations.of(context)!.nightPermissionUnknown
                : value
                ? AppLocalizations.of(context)!.enabled
                : AppLocalizations.of(context)!.disabled,
          ),
        ),
      ],
    ),
  ]);
  Widget _launcherStatus(AppLocalizations l) {
    final current = (_snapshot['launchers'] as List? ?? [])
        .whereType<Map>()
        .where((item) => item['component'] == _snapshot['currentHome']);
    final name = _isHome == true
        ? 'CuteLauncher'
        : current.isNotEmpty
        ? current.first['name']
        : _currentHomeName ?? _snapshot['currentHome'];
    return _statusBox(
      '${_isHome == null
          ? l.nightPermissionUnknown
          : _isHome!
          ? l.defaultLauncherIsDefault
          : l.defaultLauncherNotDefault}${name == null ? '' : '\n$name'}',
      _isHome,
    );
  }

  Widget _accessibilityStatus(AppLocalizations l) =>
      _statusBox(l.accessibilityPermission, _accessibility);

  Widget _action(
    String title,
    String action,
    bool applied, {
    String? target,
    bool available = true,
    bool showAppliedState = false,
  }) {
    final l = AppLocalizations.of(context)!;
    final supported = _supported(action, target);
    final homeBlocked =
        action == 'disableSystem' &&
        (_compatibility['actions'] as Map?)?['disableSystem'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Opacity(
      opacity: _verified && available && supported ? 1 : 0.45,
      child: FocusableSettingsTile(
        leading: const Icon(Icons.terminal),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (!supported || !_verified || showAppliedState)
              Text(
                !supported
                    ? l.memoryUnavailable
                    : !_verified
                    ? l.adbNotChecked
                    : applied
                    ? l.adbApplied
                    : l.adbNotApplied,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        onPressed: _verified && !_busy && available && supported
            ? () => _run(action, title, target: target)
            : null,
      ),
    ),
    if (!supported)
      SettingsHelp(text: action == 'home'
          ? l.adbHomeUnavailable
          : homeBlocked ? l.adbDisableHomeUnavailable : l.adbUnsupported),
    ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService?>();
    final builtins = <String, Map>{
      for (final item
          in (_snapshot['launchers'] as List? ?? []).whereType<Map>())
        if (item['builtin'] == true && item['package'] is String)
          item['package'] as String: item,
    }.values.toList();
    return SettingsPageLayout(
      title: Text(
        widget.section == 'launcher'
            ? l.adbDefaultBlock
            : widget.section == 'home'
            ? l.adbHomeBlock
            : widget.section == 'connection'
            ? l.adbConnectionBlock
            : l.controlAndStartup,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.section == 'launcher'
              ? [
                  _launcherStatus(l),
                  if (!_verified && _status != null) Text(_stateText(l)),
                  FocusableSettingsTile(
                    autofocus: true,
                    title: Text(l.adbSystemDefault),
                    leading: const Icon(Icons.home),
                    onPressed: () =>
                        FLauncherChannel().openDefaultLauncherSettings(),
                  ),
                  if (_isHome == true || _snapshot['homeRecoverySaved'] == true)
                    _action(
                      l.adbRestoreDefault,
                      'restore',
                      false,
                      available: (_snapshot['restoreTarget'] as String? ?? '')
                          .isNotEmpty,
                    )
                  else
                    _action(l.adbAssignDefault, 'home', _isHome == true),
                  if (_verified &&
                      (_isHome == true ||
                          _snapshot['homeRecoverySaved'] == true) &&
                      (_snapshot['restoreTarget'] as String? ?? '').isEmpty)
                    Text(l.adbNoAvailableLauncher),

                  for (final item in builtins)
                    _action(
                      '${item['enabled'] == true ? l.adbDisableBuiltin : l.adbEnableBuiltin}: ${item['name']}',
                      item['enabled'] == true
                          ? 'disableSystem'
                          : 'enableSystem',
                      false,
                      target: item['package'] as String,
                      available: true,
                    ),
                  if (_verified && builtins.isEmpty) Text(l.adbNoBuiltin),
                ]
              : widget.section == 'home'
              ? [
                  _accessibilityStatus(l),
                  if (!_verified && _status != null) Text(_stateText(l)),
                  FocusableSettingsTile(
                    autofocus: true,
                    title: Text(l.adbAccessibilitySettings),
                    leading: const Icon(Icons.accessibility),
                    onPressed: () async {
                      await showLauncherDialog<void>(
                        context: context,
                        builder: (ctx) => LauncherAlertDialog(
                          title: Text(l.adbAccessibilitySettings),
                          content: Text(l.adbAccessibilityGuide),
                          actions: [
                            LauncherDialogButton(
                              autofocus: true,
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(l.ok),
                            ),
                          ],
                        ),
                      );
                      if (mounted) {
                        await FLauncherChannel()
                            .requestAccessibilityPermission();
                      }
                    },
                  ),
                  _action(
                    _accessibility == true
                        ? l.adbDisableService
                        : l.adbEnableService,
                    _accessibility == true
                        ? 'disableAccessibility'
                        : 'accessibility',
                    false,
                  ),
                  if (_overrideHome == null)
                    FocusableSettingsTile(
                      enabled: false,
                      title: Text(l.adbHomeOverride),
                      leading: const Icon(Icons.home),
                      trailing: const Text('—'),
                    )
                  else
                    RoundedSwitchListTile(
                      value: _overrideHome!,
                      enabled: !_busy && _accessibility == true,
                      title: Text(l.adbHomeOverride),
                      onChanged: (value) async {
                        try {
                          final saved = await _channel.invokeMethod<bool>(
                            'homeOverride',
                            {'enabled': value},
                          );
                          if (!mounted) return;
                          setState(() {
                            if (saved == true) {
                              _overrideHome = value;
                            } else {
                              _status = 'unavailable';
                              _verified = false;
                              _snapshot = {};
                            }
                          });
                        } catch (_) {
                          if (mounted) {
                            setState(() {
                              _status = 'unavailable';
                              _verified = false;
                              _snapshot = {};
                            });
                          }
                        }
                      },
                    ),
                  if (settings != null)
                    RoundedSwitchListTile(
                      value: settings.startOnBoot,
                      enabled: !_busy && _accessibility == true,
                      onChanged: settings.setStartOnBoot,
                      title: Text(l.startOnBoot),
                    ),
                  SettingsHelp(text: l.adbHomeOptional),
                ]
              : widget.section == 'connection'
              ? [
                  SettingsHelp(text: l.adbSetupIntro),
                  if (_compatibility['system'] is String)
                    Text(_compatibility['system'] as String),
                  Text('${l.adbTransport}: ${l.adbTcp}'),
                  FocusableSettingsTile(
                    autofocus: true,
                    title: Text(l.adbPort),
                    trailing: Text('$_port'),
                    valueIcon: Icons.edit_outlined,
                    onPressed: _busy ? null : _editPort,
                  ),
                  FocusableSettingsTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.adbCheck),
                        Text(
                          _stateText(l),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    leading: const Icon(Icons.link),
                    onPressed: _busy ? null : _check,
                  ),
                ]
              : [
                  _menuTile(
                    l.autoLaunchTitle,
                    Icons.power_settings_new,
                    null,
                    () => _openPage(AutoLaunchPage.routeName),
                    autofocus: true,
                    showStatus: false,
                  ),
                  _menuTile(
                    l.tvPowerTitle,
                    Icons.power_settings_new,
                    null,
                    () => _openPage(TvPowerPage.routeName),
                    showStatus: false,
                  ),
                  _menuTile(
                    l.adbConnectionBlock,
                    Icons.link,
                    _status == null ? null : _verified,
                    () => _openSection('connection'),
                  ),
                  _menuTile(
                    l.adbDefaultBlock,
                    Icons.home,
                    _isHome,
                    () => _openSection('launcher'),
                  ),
                  _menuTile(
                    l.adbHomeBlock,
                    Icons.settings_remote,
                    _accessibility == false || _overrideHome == false
                        ? false
                        : _accessibility == true && _overrideHome == true
                        ? true
                        : null,
                    () => _openSection('home'),
                    statusLabel: l.adbHomeOverride,
                  ),
                  _menuTile(
                    l.remoteButtonsTitle,
                    Icons.settings_remote,
                    _accessibility,
                    () => _openPage(RemoteButtonsPage.routeName),
                    statusLabel: l.accessibilityPermission,
                  ),
                  _menuTile(l.recentAppsTitle, Icons.recent_actors_outlined, null,
                    () => _openPage(RecentAppsPage.routeName), showStatus: false),
                  _menuTile(
                    l.cleanerTitle,
                    Icons.cleaning_services_outlined,
                    null,
                    () => Navigator.of(context).push(
                      SettingsRoute(builder: (_) => const TvCleanerPage()),
                    ),
                    showStatus: false,
                  ),
                ],
        ),
      ),
    );
  }
}
