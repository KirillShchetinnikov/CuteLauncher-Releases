import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../feed_format.dart';
import '../../providers/app_channels_service.dart';
import '../../providers/settings_service.dart';
import '../action_notice.dart';
import '../rounded_switch_list_tile.dart';
import 'adb_permission_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_value_stepper.dart';
import 'app_channels_order_page.dart';

class AppChannelsSettingsPage extends StatefulWidget {
  static const routeName = 'app_channels_settings';
  const AppChannelsSettingsPage({super.key});
  @override
  State<AppChannelsSettingsPage> createState() =>
      _AppChannelsSettingsPageState();
}

class _AppChannelsSettingsPageState extends State<AppChannelsSettingsPage>
    with WidgetsBindingObserver {
  bool _busy = false;
  AppChannelsService? _service;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _service = context.read<AppChannelsService>()..openCatalog();
        _refresh();
      }
    });
  }

  @override
  void dispose() {
    _service?.closeCatalog();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) _refresh();
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() => _busy = true);
    await context.read<AppChannelsService>().refresh(reloadPosters: true);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _select(String key, bool enabled) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final settings = context.read<SettingsService>();
      final selected = settings.selectedAppChannels.toList()..remove(key);
      if (enabled) selected.add(key);
      await settings.setSelectedAppChannels(selected);
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.appChannelsSaveFailed,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestAccess() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context
          .read<AppChannelsService>()
          .channel
          .requestAppChannelsPermission();
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.appChannelsUnavailable,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) await _refresh();
  }

  Future<void> _format(String key, FeedFormat format) async {
    try {
      await context.read<SettingsService>().setAppChannelFormat(key, format);
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.appChannelsSaveFailed,
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AppChannelsService>();
    final settings = context.watch<SettingsService>();
    final selected = settings.selectedAppChannels;
    final channels = [
      for (final key in selected)
        ...service.channels.where((c) => c.key == key),
      ...service.channels.where((c) => !selected.contains(c.key)),
    ];
    return SettingsPageLayout(
      title: Text(l.appChannelsTitle),
      child: ListView(
        children: [
          FocusableSettingsTile(
            autofocus: true,
            leading: const Icon(Icons.refresh),
            title: Text(l.appChannelsRefresh),
            enabled: !_busy,
            onPressed: _refresh,
            trailing: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  )
                : null,
          ),
          SettingsHelp(
            title: l.appChannelsTitle,
            text: '${l.appChannelsHelp}\n\n${l.feedFormatHelp}',
          ),
          if (selected.length > 1)
            FocusableSettingsTile(
              leading: const Icon(Icons.swap_vert),
              title: Text(l.reorder),
              onPressed: () =>
                  Navigator.pushNamed(context, AppChannelsOrderPage.routeName),
            ),
          if (service.unavailable) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.appChannelsUnavailable),
            ),
            FocusableSettingsTile(
              leading: const Icon(Icons.security),
              title: Text(l.appChannelsAccess),
              enabled: !_busy,
              onPressed: _requestAccess,
            ),
            AdbPermissionTile(
              title: '${l.appChannelsAccess} · ADB',
              action: 'watchNext',
              permissionMethod: 'checkAppChannelsPermission',
              onRefresh: service.refresh,
            ),
          ] else if (service.initialized && service.channels.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.appChannelsEmpty),
            ),
          for (final channel in channels) ...[
            RoundedSwitchListTile(
              key: ValueKey(channel.key),
              title: Text('${channel.name} · ${channel.appName}'),
              value: selected.contains(channel.key),
              onChanged: (value) => _select(channel.key, value),
            ),
            if (selected.contains(channel.key))
              SettingsValueStepper(
                key: ValueKey('format:${channel.key}'),
                title: '${l.feedFormat} · ${channel.name}',
                value: settings.appChannelFormat(channel.key),
                options: FeedFormat.values,
                label: (value) => switch (value as FeedFormat) {
                  FeedFormat.auto => l.feedFormatAuto,
                  FeedFormat.landscape => l.feedFormatLandscape,
                  FeedFormat.portrait => l.feedFormatPortrait,
                },
                onChanged: (value) => _format(channel.key, value as FeedFormat),
              ),
          ],
          for (final key in selected.where(
            (key) => !service.channels.any((c) => c.key == key),
          ))
            RoundedSwitchListTile(
              key: ValueKey(key),
              title: Text('${l.appChannelsMissing}\n$key'),
              value: true,
              onChanged: (_) => _select(key, false),
            ),
        ],
      ),
    );
  }
}
