import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/night_mode_service.dart';
import '../l10n/app_localizations.dart';
import '../recent_apps_client.dart';
import '../theme/launcher_style.dart';
import 'remote_panel.dart';
import 'settings/settings_panel_style.dart';
import 'settings/focusable_settings_tile.dart';

/// A focusable service window: icons only, with no background polling or task snapshots on disk.
class RecentAppsPanel extends StatefulWidget {
  const RecentAppsPanel({super.key});
  @override
  State<RecentAppsPanel> createState() => _RecentAppsPanelState();
}

class _RecentAppsPanelState extends State<RecentAppsPanel> {
  final _client = RecentAppsClient();
  final _icons = <String, Future<Uint8List?>>{};
  List<RecentApp> _apps = [];
  bool _busy = true, _failed = false;
  bool _readySent = false;
  final _refresh = FocusNode();
  @override
  void initState() {
    super.initState();
    _run('list');
  }

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  Future<void> _run(String action, [String? pkg]) async {
    final previousFocus = FocusManager.instance.primaryFocus;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final result = await _client.action(action, pkg);
      if (!mounted) return;
      if (action == 'switch' && result['status'] == 'success') return;
      final apps = (result['apps'] as List)
          .map((row) => RecentApp.fromMap(row as Map))
          .toList();
      setState(() {
        _apps = apps;
        _icons.removeWhere(
          (key, _) => !apps.any((app) => app.packageName == key),
        );
        _failed = result['status'] != 'success';
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (previousFocus?.context != null && previousFocus!.canRequestFocus) {
            previousFocus.requestFocus();
          } else {
            _refresh.requestFocus();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final ready = context.select<NightModeService?, bool>((night) => night == null || night.panelPresentationReady);
    if (ready && !_readySent) {
      _readySent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) remotePanelChannel.invokeMethod<void>('ready');
      });
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) remotePanelChannel.invokeMethod<void>('close');
      },
      child: !ready
          ? const SizedBox.shrink()
          : SettingsPanelStyle(
              builder: (context) => Material(
                color: Colors.transparent,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 760,
                      maxHeight: MediaQuery.sizeOf(context).height * .85,
                    ),
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(
                        LauncherStyle.of(context).panelRadius,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l.recentAppsTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (_busy) const LinearProgressIndicator(),
                            Row(
                              key: const ValueKey('recent_actions'),
                              children: [
                                Expanded(
                                  child: FocusableSettingsTile(
                                    focusNode: _refresh,
                                    autofocus: true,
                                    title: Text(l.recentAppsRefresh),
                                    enabled: !_busy,
                                    onPressed: () => _run('list'),
                                  ),
                                ),
                                Expanded(
                                  child: FocusableSettingsTile(
                                    title: Text(l.recentAppsCloseAll),
                                    enabled:
                                        !_busy &&
                                        _apps.any((app) => app.userApp),
                                    onPressed: () => _run('closeAll'),
                                  ),
                                ),
                                IconButton(
                                  tooltip: l.close,
                                  onPressed: () => remotePanelChannel
                                      .invokeMethod<void>('close'),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                            if (_failed)
                              Text(
                                l.recentAppsUnavailable,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            if (!_busy && !_failed && _apps.isEmpty)
                              Text(l.recentAppsEmpty),
                            Flexible(
                              key: const ValueKey('recent_list'),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _apps.length,
                                itemBuilder: (context, index) {
                                  final app = _apps[index];
                                  return Row(
                                    key: ValueKey(app.packageName),
                                    children: [
                                      Expanded(
                                        child: FocusableSettingsTile(
                                          enabled: !_busy,
                                          leading: SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: FutureBuilder<Uint8List?>(
                                              future: _icons.putIfAbsent(
                                                app.packageName,
                                                () => _client.icon(
                                                  app.packageName,
                                                ),
                                              ),
                                              builder: (context, snapshot) =>
                                                  snapshot.hasData
                                                  ? Image.memory(
                                                      snapshot.data!,
                                                      width: 48,
                                                      height: 48,
                                                      cacheWidth: 96,
                                                    )
                                                  : const Icon(Icons.apps),
                                            ),
                                          ),
                                          title: Text(app.name),
                                          onPressed: () =>
                                              _run('switch', app.packageName),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: l.close,
                                        onPressed: _busy
                                            ? null
                                            : () => _run(
                                                'close',
                                                app.packageName,
                                              ),
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
