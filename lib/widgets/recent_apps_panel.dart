import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/night_mode_service.dart';
import '../l10n/app_localizations.dart';
import '../recent_apps_client.dart';
import '../theme/launcher_style.dart';
import 'remote_panel.dart';
import 'recent_apps_access.dart';
import 'recent_apps_memory.dart';
import 'settings/settings_panel_style.dart';
import 'settings/focusable_settings_tile.dart';
import 'panel_tooltip.dart';

/// A focusable service window: icons only, with no background polling or task snapshots on disk.
class RecentAppsPanel extends StatefulWidget {
  const RecentAppsPanel({super.key});
  @override
  State<RecentAppsPanel> createState() => _RecentAppsPanelState();
}

class _RecentAppsPanelState extends State<RecentAppsPanel>
    with WidgetsBindingObserver {
  final _client = RecentAppsClient();
  final _icons = <String, Future<Uint8List?>>{};
  List<RecentApp> _apps = [];
  bool _busy = true, _failed = false;
  bool _readySent = false;
  int _accessRevision = 0;
  int _memoryRevision = 0;
  int? _ramTotal, _ramAvailable;
  bool _ramLoading = true, _foreground = true;
  final _memory = <String, RecentAppMemory>{};
  final _memoryPending = <String>{};
  final _refresh = FocusNode();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _run('list');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _memoryRevision++;
    unawaited(_client.cancelMemory());
    _refresh.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_foreground) {
        _foreground = true;
        if (!_busy) unawaited(_run('list'));
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _memoryRevision++;
      unawaited(_client.cancelMemory());
    }
  }

  Future<void> _loadMemory() async {
    if (!_foreground) return;
    final revision = ++_memoryRevision;
    bool current() => mounted && _foreground && revision == _memoryRevision;
    final packages = _apps.map((app) => app.packageName).toList();
    setState(() {
      _ramLoading = true;
      _ramTotal = _ramAvailable = null;
      _memory.clear();
      _memoryPending
        ..clear()
        ..addAll(packages);
    });
    try {
      final ram = await _client.ram();
      if (!current()) return;
      setState(() {
        _ramTotal = ram['ramTotalBytes'] as int?;
        _ramAvailable = ram['ramAvailableBytes'] as int?;
      });
    } catch (_) {
      // RAM and task access are independent.
    } finally {
      if (current()) setState(() => _ramLoading = false);
    }
    final budget = Stopwatch()..start();
    for (final pkg in packages) {
      if (!current()) return;
      if (budget.elapsed >= const Duration(seconds: 10)) break;
      var memory = const RecentAppMemory.unavailable();
      try {
        memory = await _client.memory(pkg);
      } catch (_) {
        // Keep other measurements and every task action available.
      }
      if (!current()) return;
      setState(() {
        _memory[pkg] = memory;
        _memoryPending.remove(pkg);
      });
    }
    if (current() && _memoryPending.isNotEmpty) {
      setState(_memoryPending.clear);
    }
  }

  String _memoryLabel(BuildContext context, String pkg) {
    final l = AppLocalizations.of(context)!;
    if (_memoryPending.contains(pkg)) return l.loading;
    final memory = _memory[pkg] ?? const RecentAppMemory.unavailable();
    return switch (memory.status) {
      RecentAppMemoryStatus.running => l.recentRamApp(
        recentMemoryBytes(context, memory.bytes!),
      ),
      RecentAppMemoryStatus.unloaded => l.recentRamUnloaded,
      RecentAppMemoryStatus.unavailable => l.recentRamUnavailable,
    };
  }

  Future<void> _run(String action, [String? pkg]) async {
    if (_busy && _accessRevision > 0) return;
    _memoryRevision++;
    final previousFocus = FocusManager.instance.primaryFocus;
    setState(() {
      _busy = true;
      _accessRevision++;
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
        if (action != 'switch' || _failed) unawaited(_loadMemory());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (previousFocus?.context != null &&
              previousFocus!.canRequestFocus) {
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
    final scrollMemory =
        MediaQuery.textScalerOf(context).scale(16) > 22 ||
        MediaQuery.sizeOf(context).height < 480;
    final memoryHeader = RecentAppsMemory(
      key: const ValueKey('recent_memory_header'),
      total: _ramTotal,
      available: _ramAvailable,
      loading: _ramLoading,
    );
    final ready = context.select<NightModeService?, bool>(
      (night) => night == null || night.panelPresentationReady,
    );
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
                            RecentAppsAccess(
                              key: const ValueKey('recent_access_header'),
                              revision: _accessRevision,
                            ),
                            if (!scrollMemory) memoryHeader,
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
                                PanelTooltip(
                                  message: l.close,
                                  child: IconButton(
                                    onPressed: () => remotePanelChannel
                                        .invokeMethod<void>('close'),
                                    icon: const Icon(Icons.close),
                                  ),
                                ),
                              ],
                            ),
                            Flexible(
                              key: const ValueKey('recent_list'),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _apps.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return Column(
                                      children: [
                                        if (scrollMemory) memoryHeader,
                                        if (_failed)
                                          Text(
                                            l.recentAppsUnavailable,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                            ),
                                          ),
                                        if (!_busy && !_failed && _apps.isEmpty)
                                          Text(l.recentAppsEmpty),
                                      ],
                                    );
                                  }
                                  final app = _apps[index - 1];
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
                                          trailing: Text(
                                            _memoryLabel(
                                              context,
                                              app.packageName,
                                            ),
                                            key: ValueKey(
                                              'recent_memory_${app.packageName}',
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          onPressed: () =>
                                              _run('switch', app.packageName),
                                        ),
                                      ),
                                      PanelTooltip(
                                        message: l.close,
                                        child: IconButton(
                                          onPressed: _busy
                                              ? null
                                              : () => _run(
                                                  'close',
                                                  app.packageName,
                                                ),
                                          icon: const Icon(Icons.close),
                                        ),
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
