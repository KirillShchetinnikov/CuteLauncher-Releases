import 'dart:convert';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../tv_cleaner.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'settings_text_tile.dart';

class TvCleanerPage extends StatefulWidget {
  final TvCleanerClient? client;
  const TvCleanerPage({super.key, this.client});
  @override
  State<TvCleanerPage> createState() => _TvCleanerPageState();
}

class _TvCleanerPageState extends State<TvCleanerPage> {
  late final _client = widget.client ?? TvCleanerClient();
  final _report = ValueNotifier<Map<String, dynamic>?>(null);
  final _busy = ValueNotifier(false);
  Map<String, dynamic> _descriptions = {},
      _profiles = {},
      _bundledProfiles = {};
  bool _projectReady = false, _externalReady = false;
  List<Map> _externalFolders = [];
  VoidCallback? _dismissUpdating;
  bool _initialized = false;
  AppLocalizations get l => AppLocalizations.of(context)!;
  bool get ru => Localizations.localeOf(context).languageCode == 'ru';
  List<Map> get apps =>
      (_report.value?['packages'] as List? ?? []).whereType<Map>().toList();

  @override
  void initState() {
    super.initState();
    _busy.value = true;
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final descriptions = await _client.catalog(
        'catalog/app_descriptions.json',
      );
      final profiles = await _client.catalog('catalog/cleaner_profiles.json');
      final cached = await _client.loadInventory();
      if (!mounted) return;
      _descriptions = descriptions['packages'] as Map<String, dynamic>;
      _profiles = profiles;
      _bundledProfiles = profiles;
      _report.value = cached;
    } catch (_) {
      if (mounted) showActionNotice(context, l.cleanerFailure, error: true);
    } finally {
      _initialized = true;
      if (mounted) _busy.value = false;
    }
  }

  @override
  void dispose() {
    // Remove an overlay after this route's widget tree finishes disposing.
    final dismiss = _dismissUpdating;
    if (dismiss != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => dismiss());
    }
    _report.dispose();
    _busy.dispose();
    super.dispose();
  }

  Future<T?> _work<T>(Future<T> Function() action) async {
    if (_busy.value) return null;
    _busy.value = true;
    try {
      return await action();
    } catch (_) {
      if (mounted) showActionNotice(context, l.cleanerFailure, error: true);
      return null;
    } finally {
      if (mounted) _busy.value = false;
    }
  }

  Future<bool> _execute(
    String action, {
    List<String>? packages,
    bool? enable,
    String? stateId,
    String? stateName,
    String? listName,
    String? listScope,
  }) async {
    if (action != 'cleanerInventory') await _client.clearInventory();
    late final Map<String, dynamic> value;
    try {
      value = await _client.call(
        action,
        packages: packages,
        enable: enable,
        stateId: stateId,
        stateName: stateName,
        listName: listName,
        listScope: listScope,
      );
    } catch (_) {
      if (mounted && action != 'cleanerInventory') _report.value = null;
      rethrow;
    }
    if (!mounted) return false;
    if (value['status'] == 'success') {
      await _acceptReport(value);
      if (mounted) showActionNotice(context, l.cleanerDone);
      return true;
    } else {
      showActionNotice(
        context,
        value['status'] == 'snapshotFailed'
            ? l.cleanerSnapshotFailed
            : value['status'] == 'partial'
            ? l.cleanerPartial
            : value['status'] == 'protected'
            ? l.cleanerProtected
            : l.cleanerFailure,
        error: true,
        duration: const Duration(seconds: 10),
      );
      if (action == 'cleanerInventory') return false;
      // Never keep stale enabled/disabled values after partial mutation.
      _report.value = null;
      final fresh = await _client.call('cleanerInventory');
      if (mounted && fresh['status'] == 'success') {
        await _acceptReport(fresh);
      }
    }
    return false;
  }

  Future<void> _acceptReport(Map<String, dynamic> report) async {
    _report.value = report;
    try {
      await _client.saveInventory(report);
    } catch (_) {
      // Never restore an older persisted report after a failed replacement.
      try {
        await _client.clearInventory();
      } catch (_) {}
      if (mounted) {
        showActionNotice(context, l.cleanerCacheFailure, error: true);
      }
    }
  }

  Future<bool> _refresh() async {
    if (_busy.value) return false;
    _dismissUpdating = showActionNotice(
      context,
      l.cleanerUpdating,
      persistent: true,
    );
    try {
      return await _work(() => _execute('cleanerInventory')) ?? false;
    } finally {
      _dismissUpdating?.call();
      _dismissUpdating = null;
    }
  }

  Widget _watch(Widget Function() builder) => ListenableBuilder(
    listenable: Listenable.merge([_report, _busy]),
    builder: (_, _) => builder(),
  );

  Widget _tile(
    String title,
    VoidCallback action, {
    bool ready = true,
    bool autofocus = false,
    bool submenu = false,
    Widget? leading,
  }) => FocusableSettingsTile(
    key: ValueKey(title),
    leading: leading,
    title: Text(title),
    autofocus: autofocus,
    trailing: submenu ? const Icon(Icons.chevron_right) : null,
    // Keep the opener focusable while ADB runs so the route can restore it.
    enabled: ready,
    onPressed: _busy.value ? null : action,
  );

  Future<void> _open(String title, Widget Function() builder) =>
      Navigator.of(context).push<void>(
        SettingsRoute(
          builder: (_) => _watch(
            () => SettingsPageLayout(
              title: Text(title),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_busy.value) const LinearProgressIndicator(),
                  Expanded(key: const ValueKey('content'), child: builder()),
                ],
              ),
            ),
          ),
        ),
      );

  Future<bool> _confirm(
    List<String> packages, {
    bool restore = false,
    String? restoreName,
    bool enable = false,
    bool verified = false,
    List<String> skipped = const [],
  }) async =>
      await Navigator.of(context).push<bool>(
        SettingsRoute(
          builder: (ctx) => SettingsPageLayout(
            title: Text(
              restore
                  ? (restoreName == null
                        ? l.cleanerRestore
                        : '${l.backupRestoreCopy} · $restoreName')
                  : enable
                  ? l.cleanerEnable
                  : l.cleanerDisable,
            ),
            child: ListView(
              children: [
                FocusableSettingsTile(
                  autofocus: true,
                  title: Text(l.cancel),
                  onPressed: () => Navigator.pop(ctx, false),
                ),
                Text(
                  restore ? l.cleanerStateRestoreHelp : l.cleanerConfirmText,
                ),
                const SizedBox(height: 12),
                if (!restore && !verified) Text(l.cleanerObserved),
                for (final package in packages) Text(package),
                if (skipped.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(l.cleanerSkipped),
                  for (final package in skipped) Text(package),
                ],
                FocusableSettingsTile(
                  title: Text(l.ok),
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;

  Future<void> _preview(
    List<String> packages, {
    bool enable = false,
    bool verified = false,
    bool refresh = true,
    String? sourceName,
    String? scope,
  }) async {
    if (_busy.value || _report.value == null) return;
    if (refresh && (!await _refresh() || !mounted)) return;
    final installed = {for (final row in apps) row['package']: row};
    final matching = packages.where((name) {
      final row = installed[name];
      if (row == null) return false;
      final kind = cleanerAppKind(row, _descriptions[name] as Map?);
      return scope == null || kind.name == scope;
    }).toList();
    final selected = matching
        .where(
          (name) =>
              (enable || installed[name]!['protected'] != true) &&
              installed[name]!['enabled'] != enable,
        )
        .toList();
    if (selected.isEmpty) {
      showActionNotice(
        context,
        matching.isEmpty
            ? l.cleanerNoInstalled
            : matching.every((name) => installed[name]!['enabled'] == enable)
            ? (enable ? l.cleanerAlreadyEnabled : l.cleanerAlreadyDisabled)
            : l.cleanerListProtected,
      );
      return;
    }
    final skipped = packages.where((name) => !selected.contains(name)).toList();
    if (await _confirm(
          selected,
          enable: enable,
          skipped: skipped,
          verified: verified,
        ) &&
        mounted) {
      final label = sourceName
          ?.replaceAll(RegExp(r'[\x00-\x1f\x7f-\x9f]'), ' ')
          .trim();
      await _work(
        () => _execute(
          'cleanerApply',
          packages: selected,
          enable: enable,
          listScope: scope,
          listName: !enable && label != null
              ? l.cleanerBeforeList(String.fromCharCodes(label.runes.take(180)))
              : null,
        ),
      );
    }
  }

  Future<void> _import() async {
    final source = await _work(() => _client.importFile());
    if (source == null || !mounted) return;
    await _fromSource(
      source,
      sourceName: _client.importedFileName.isEmpty
          ? l.cleanerLocal
          : _client.importedFileName,
    );
  }

  Future<void> _fromSource(String source, {required String sourceName}) async {
    if (!await _refresh() || !mounted) return;
    try {
      if (source.trimLeft().startsWith('{')) {
        final json = jsonDecode(source) as Map;
        final identity = json['identity'];
        if (identity is Map &&
            ['manufacturer', 'model', 'device', 'fingerprint'].any(
              (key) =>
                  identity[key] != null &&
                  identity[key] != (_report.value?['identity'] as Map?)?[key],
            )) {
          showActionNotice(context, l.cleanerMismatch, error: true);
          return;
        }
      }
      await _preview(
        parseDisableList(source),
        refresh: false,
        sourceName: sourceName,
      );
    } catch (_) {
      if (mounted) showActionNotice(context, l.cleanerFailure, error: true);
    }
  }

  Future<void> _catalogPage(
    String title,
    List<Map> Function() entries,
    String Function(Map) label,
    Future<void> Function(Map) selected,
    bool Function() ready,
    Future<void> Function() update, {
    bool Function(Map)? matchesDevice,
  }) {
    var query = '';
    return _open(
      title,
      () => StatefulBuilder(
        builder: (ctx, change) {
          final rows = entries()
              .where(
                (row) =>
                    label(row)
                        .toLowerCase()
                        .contains(query.toLowerCase().trim()),
              )
              .toList();
          final header = <Widget>[
            _tile(l.cleanerRemoteProject, update),
            if (!ready()) Text(l.cleanerCatalogUpdateRequired),
            SettingsTextTile(
              title: l.cleanerSearch,
              value: query,
              maxLength: 100,
              onChanged: (value) => change(() => query = value),
            ),
          ];
          return ListView.builder(
            itemCount:
                header.length + rows.length + (ready() && rows.isEmpty ? 1 : 0),
            itemBuilder: (_, index) {
              if (index < header.length) return header[index];
              if (rows.isEmpty) return Text(l.cleanerNoSearchResults);
              final row = rows[index - header.length];
              return _tile(
                label(row),
                () => selected(row),
                ready: ready(),
                leading: matchesDevice?.call(row) == true
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  String _profileLabel(Map profile) {
    final identity = profile['identity'] as Map? ?? {};
    return '${profile['id']} · ${identity['model'] ?? ''} · ${identity['device'] ?? ''}';
  }

  Future<void> _project() => _catalogPage(
    l.cleanerProject,
    () => (_profiles['profiles'] as List? ?? []).whereType<Map>().toList(),
    _profileLabel,
    (profile) => _fromSource(
      jsonEncode({
        'schemaVersion': 1,
        'reportType': 'tvDisableList',
        'identity': profile['identity'],
        'packages': profile['packages'],
      }),
      sourceName: '${l.cleanerProject}: ${profile['id']}',
    ),
    () => _projectReady,
    _updateProject,
    matchesDevice: _profileMatchesDevice,
  );

  Future<void> _updateProject() async {
    await _work(() async {
      String source;
      try {
        source = await _client.github(
          Uri.https(
            'raw.githubusercontent.com',
            '/KirillShchetinnikov/CuteLauncher-Releases/main/catalog/cleaner_profiles.json',
          ),
        );
      } catch (_) {
        if (mounted) {
          showActionNotice(context, l.cleanerGitUnavailable, error: true);
        }
        return;
      }
      final parsed = jsonDecode(source);
      if (parsed is! Map<String, dynamic> ||
          parsed['schemaVersion'] != 1 ||
          parsed['profiles'] is! List) {
        throw const FormatException();
      }
      if (mounted) {
        _profiles = parsed;
        _projectReady = true;
      }
    });
  }

  bool _profileMatchesDevice(Map profile) {
    final identity = _report.value?['identity'] as Map?;
    final id = profile['identity'];
    return id is Map &&
        identity != null &&
        ['manufacturer', 'model', 'device', 'fingerprint'].every(
          (key) =>
              id[key] is String &&
              (id[key] as String).isNotEmpty &&
              id[key] == identity[key],
        );
  }

  List<Map> _matchingProfiles(Map<String, dynamic> catalog) =>
      (catalog['profiles'] as List? ?? [])
          .whereType<Map>()
          .where(_profileMatchesDevice)
          .toList();

  Future<void> _safe() async {
    if (!await _refresh() || !mounted) return;
    final recommended = <String>{};
    for (final profile
        in (_bundledProfiles['profiles'] as List? ?? []).whereType<Map>()) {
      if (profile['approval'] == 'userRequestedObservedSystemList') {
        recommended.addAll(
          (profile['userApprovedSystemPackages'] as List? ?? [])
              .whereType<String>()
              .where(cleanerPackageId),
        );
      }
    }
    for (final profile in _matchingProfiles(_bundledProfiles)) {
      if (profile['verification'] == 'verifiedFunctionsPreserved') {
        for (final name
            in (profile['recommended'] as List? ?? []).whereType<String>()) {
          if (cleanerPackageId(name) &&
              (_descriptions[name] as Map?)?['safeToDisable'] == true) {
            recommended.add(name);
          }
        }
      }
    }
    if (recommended.isEmpty) {
      showActionNotice(context, l.cleanerNoSafe);
      return;
    }
    await _preview(
      recommended.toList()..sort(),
      verified: true,
      refresh: false,
      sourceName: l.cleanerSafe,
      scope: 'system',
    );
  }

  Future<void> _external() => _catalogPage(
    l.cleanerExternal,
    () => _externalFolders,
    (row) => row['name'] as String,
    (row) async {
      final name = row['name'] as String;
      final source = await _work(
        () => _client.github(
          Uri.https(
            'raw.githubusercontent.com',
            '/Gathin23/cleanyourtv/main/examples/$name/debloat.txt',
          ),
        ),
      );
      if (source != null && mounted) {
        await _fromSource(source, sourceName: 'CleanYourTV: $name');
      }
    },
    () => _externalReady,
    _updateExternal,
  );

  Future<void> _updateExternal() async {
    await _work(() async {
      final source = await _client.github(
        Uri.https(
          'api.github.com',
          '/repos/Gathin23/cleanyourtv/contents/examples',
        ),
      );
      final rows = jsonDecode(source);
      if (rows is! List) throw const FormatException();
      final folders =
          rows
              .whereType<Map>()
              .where(
                (row) =>
                    row['type'] == 'dir' &&
                    row['name'] is String &&
                    RegExp(r'^[a-zA-Z0-9_-]{1,100}$')
                        .hasMatch(row['name'] as String),
              )
              .map((row) => {'name': row['name'] as String})
              .take(500)
              .toList()
            ..sort((a, b) => a['name']!.compareTo(b['name']!));
      if (mounted) {
        _externalFolders = folders;
        _externalReady = true;
      }
    });
  }

  Future<void> _details(
    String package, {
    String? listName,
    String? scope,
  }) => _open(package, () {
    final found = apps.where((row) => row['package'] == package);
    if (found.isEmpty) return Text(l.cleanerMissing);
    final app = found.first;
    final description = _descriptions[package] as Map?;
    final kind = cleanerAppKind(app, description);
    return ListView(
      children: [
        Text(
          '${app['name']}\n$package\n${app['versionName']} (${app['versionCode']})',
        ),
        Text(switch (kind) {
          CleanerAppKind.user => l.cleanerUser,
          CleanerAppKind.preinstalled => l.cleanerPreinstalled,
          CleanerAppKind.system => l.cleanerSystem,
        }),
        Text(app['enabled'] == true ? l.enabled : l.disabled),
        const SizedBox(height: 12),
        if (kind == CleanerAppKind.system) ...[
          Text(
            description?[ru ? 'ru' : 'en'] as String? ?? l.cleanerUnidentified,
          ),
          const SizedBox(height: 12),
          Text(l.cleanerRisk, style: Theme.of(context).textTheme.titleMedium),
          Text(
            description?[ru ? 'riskRu' : 'riskEn'] as String? ??
                l.cleanerUnknown,
          ),
        ] else ...[
          Text(l.cleanerNotSystem),
          const SizedBox(height: 12),
          Text(l.cleanerRisk, style: Theme.of(context).textTheme.titleMedium),
          Text(l.cleanerMinimalRisk),
        ],
        if (app['protected'] == true) Text(l.cleanerProtected),
        _tile(
          app['enabled'] == true ? l.cleanerDisable : l.cleanerEnable,
          () => _preview(
            [package],
            enable: app['enabled'] != true,
            sourceName: listName,
            scope: scope,
          ),
          ready: app['protected'] != true || app['enabled'] != true,
        ),
      ],
    );
  });

  Future<void> _allApps({CleanerAppKind? filter}) async {
    if (!await _refresh() || !mounted) return;
    var query = '';
    await _open(
      filter == null ? l.cleanerApps : l.cleanerPreinstalledApps,
      () => StatefulBuilder(
        builder: (ctx, change) {
          final rows = <Object>[];
          for (final kind in CleanerAppKind.values) {
            if (filter != null && filter != kind) continue;
            final group = apps
                .where(
                  (app) =>
                      cleanerAppKind(
                            app,
                            _descriptions[app['package']] as Map?,
                          ) ==
                          kind &&
                      '${app['name']} ${app['package']}'.toLowerCase().contains(
                        query.toLowerCase().trim(),
                      ),
                )
                .toList();
            if (group.isEmpty) continue;
            rows.add(switch (kind) {
              CleanerAppKind.user => l.cleanerUserApps,
              CleanerAppKind.preinstalled => l.cleanerPreinstalledApps,
              CleanerAppKind.system => l.cleanerSystemApps,
            });
            rows.addAll(group);
          }
          return ListView.builder(
            itemCount: rows.length + 1 + (rows.isEmpty ? 1 : 0),
            itemBuilder: (_, index) {
              if (index == 0) {
                return SettingsTextTile(
                  title: l.cleanerSearch,
                  maxLength: 100,
                  value: query,
                  onChanged: (value) => change(() => query = value),
                );
              }
              if (rows.isEmpty) return Text(l.cleanerNoSearchResults);
              final row = rows[index - 1];
              if (row is String) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    row,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }
              final app = row as Map;
              return FocusableSettingsTile(
                enabled: !_busy.value,
                leading: Icon(
                  app['enabled'] == true
                      ? Icons.check_circle_outline
                      : Icons.block,
                ),
                title: Text('${app['name']}\n${app['package']}'),
                trailing: Text(app['enabled'] == true ? l.enabled : l.disabled),
                onPressed: () => _details(
                  app['package'] as String,
                  listName: filter == CleanerAppKind.preinstalled
                      ? l.cleanerPreinstalledApps
                      : null,
                  scope: filter?.name,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _preinstalled() async {
    await _open(
      l.cleanerPreinstalledApps,
      () => ListView(
        children: [
          _tile(
            l.cleanerDisableAllPreinstalled,
            () => _preinstalledBatch(false),
          ),
          _tile(l.cleanerEnableAllPreinstalled, () => _preinstalledBatch(true)),
          _tile(
            l.cleanerPreinstalledList,
            () => _allApps(filter: CleanerAppKind.preinstalled),
            submenu: true,
          ),
        ],
      ),
    );
  }

  Future<void> _preinstalledBatch(bool enable) async {
    if (!await _refresh() || !mounted) return;
    final names = apps
        .where(
          (app) =>
              cleanerAppKind(app, _descriptions[app['package']] as Map?) ==
              CleanerAppKind.preinstalled,
        )
        .map((app) => app['package'] as String)
        .toList();
    await _preview(
      names,
      enable: enable,
      refresh: false,
      sourceName: l.cleanerPreinstalledApps,
      scope: 'preinstalled',
    );
  }

  Future<void> _lists() => _open(
    l.cleanerLists,
    () => ListView(
      children: [
        _tile(l.cleanerSafe, _safe, ready: _report.value != null),
        _tile(
          l.cleanerPreinstalledApps,
          _preinstalled,
          ready: _report.value != null,
          submenu: true,
        ),
        _tile(l.cleanerLocal, _import, ready: _report.value != null),
        _tile(
          l.cleanerProject,
          _project,
          ready: _report.value != null,
          submenu: true,
        ),
        _tile(
          l.cleanerExternal,
          _external,
          ready: _report.value != null,
          submenu: true,
        ),
      ],
    ),
  );

  String _created(dynamic value) {
    if (value is! num || value <= 0) return l.cleanerNoSnapshot;
    return DateTime.fromMillisecondsSinceEpoch(value.toInt())
        .toLocal()
        .toString()
        .split('.')
        .first;
  }

  Future<void> _restore({String? id, String? name}) async {
    if (!await _refresh() || !mounted) return;
    if (await _confirm(const [], restore: true, restoreName: name) && mounted) {
      await _work(
        () => _execute(
          id == null ? 'cleanerRestore' : 'cleanerManualRestore',
          stateId: id,
        ),
      );
    }
  }

  Future<void> _recovery() async {
    await _open(l.cleanerRecovery, () {
      final report = _report.value;
      final created = report?['baselineCreatedAt'] as num? ?? 0;
      return ListView(
        children: [
          Text(
            l.cleanerBaseline,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(created > 0 ? _created(created) : l.cleanerNoSnapshot),
          _tile(l.cleanerRestore, () => _restore(), ready: created > 0),
          _tile(
            l.cleanerManualStates,
            _manualStates,
            ready: report != null,
            submenu: true,
          ),
          SettingsHelp(
            text: '${l.cleanerCopiesHelp}\n\n${l.cleanerListSnapshotHelp}',
          ),
        ],
      );
    });
  }

  Future<void> _manualStates() async {
    await _open(l.cleanerManualStates, () {
      final copies = (_report.value?['manualStates'] as List? ?? [])
          .whereType<Map>()
          .toList();
      return ListView.builder(
        itemCount: copies.length + 1,
        itemBuilder: (_, index) {
          if (index == 0) {
            return _tile(
              l.cleanerManualSave,
              _saveManual,
              ready: _report.value != null,
            );
          }
          final copy = copies[index - 1];
          final date = _created(copy['capturedAt']);
          final label = copy['name'] == date ? date : '${copy['name']}\n$date';
          return _tile(label, () => _manualActions(copy));
        },
      );
    });
  }

  Future<String?> _customStateName() async {
    var name = '';
    return Navigator.of(context).push<String>(
      SettingsRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, update) => SettingsPageLayout(
            title: Text(l.cleanerManualSave),
            child: ListView(
              children: [
                SettingsTextTile(
                  title: l.name,
                  value: name,
                  maxLength: 120,
                  onChanged: (value) => update(() => name = value.trim()),
                ),
                FocusableSettingsTile(
                  title: Text(l.save),
                  enabled: name.isNotEmpty,
                  onPressed: () => Navigator.pop(ctx, name),
                ),
                FocusableSettingsTile(
                  title: Text(l.cancel),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveManual() async {
    final choice = await showLauncherDialog<int>(
      context: context,
      builder: (ctx) => LauncherAlertDialog(
        title: Text(l.cleanerManualSave),
        actions: [
          LauncherDialogButton(
            autofocus: true,
            onPressed: () => Navigator.pop(ctx, 0),
            child: Text(l.cleanerDateName),
          ),
          LauncherDialogButton(
            onPressed: () => Navigator.pop(ctx, 1),
            child: Text(l.cleanerCustomName),
          ),
          LauncherDialogButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    final name = choice == 0
        ? _created(DateTime.now().millisecondsSinceEpoch)
        : await _customStateName();
    if (name == null || !mounted) return;
    // The native capture reads current package states and does not replace the baseline.
    await _work(() => _execute('cleanerManualSave', stateName: name));
  }

  Future<void> _manualActions(Map copy) async {
    final id = copy['id'] as String;
    final action = await showLauncherDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(copy['name'] as String),
        children: [
          SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FocusableSettingsTile(
                  autofocus: true,
                  title: Text(l.backupRestoreCopy),
                  onPressed: () => Navigator.pop(ctx, 0),
                ),
                FocusableSettingsTile(
                  title: Text(l.delete),
                  onPressed: () => Navigator.pop(ctx, 1),
                ),
                FocusableSettingsTile(
                  title: Text(l.cleanerStateExport),
                  onPressed: () => Navigator.pop(ctx, 2),
                ),
                FocusableSettingsTile(
                  title: Text(l.cancel),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 0) {
      await _restore(id: id, name: copy['name'] as String);
    } else if (action == 1) {
      final confirmed = await showLauncherDialog<bool>(
        context: context,
        builder: (ctx) => LauncherAlertDialog(
          title: Text(l.delete),
          content: Text(l.backupDeleteConfirm),
          actions: [
            LauncherDialogButton(
              autofocus: true,
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            LauncherDialogButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.delete),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await _work(() => _execute('cleanerManualDelete', stateId: id));
      }
    } else {
      await _work(() async {
        final response = await _client.call('cleanerManualExport', stateId: id);
        if (response['status'] != 'success') throw const FormatException();
        final value = Map<String, dynamic>.from(
          jsonDecode(response['manualSnapshot'] as String) as Map,
        );
        final result = await _client.export(value, 'state');
        if (mounted && result != null) {
          showActionNotice(context, l.cleanerSaved);
        }
      });
    }
  }

  Future<void> _exportDisabledReport() async {
    if (!await _refresh() || !mounted) return;
    await _work(() async {
      final result = await _client.export(
        Map<String, dynamic>.from(disabledList(_report.value!)),
        'disabled',
      );
      if (mounted && result != null) showActionNotice(context, l.cleanerSaved);
    });
  }

  Future<void> _exports() => _open(
    l.cleanerExports,
    () => ListView(
      children: [
        _tile(
          l.cleanerDisabledExport,
          _exportDisabledReport,
          ready: _report.value != null,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => _watch(() {
    if (!_initialized) return const Center(child: CircularProgressIndicator());
    final report = _report.value;
    return SettingsPageLayout(
      title: Text(l.cleanerTitle),
      child: ListView(
        children: [
          if (_busy.value) const LinearProgressIndicator(),
          if (report != null)
            Text(
              '${(report['identity'] as Map)['model']} · ${(report['identity'] as Map)['device']}\n'
              '${l.cleanerApps}: ${apps.length}\n${l.cleanerPending}: ${report['pendingRestore']}',
            ),
          if (report == null && !_busy.value) Text(l.cleanerRefreshRequired),
          _tile(l.cleanerRefresh, _refresh, autofocus: true),
          _tile(l.cleanerApps, _allApps, ready: report != null, submenu: true),
          _tile(l.cleanerLists, _lists, ready: report != null, submenu: true),
          _tile(
            l.cleanerRecovery,
            _recovery,
            ready: report != null,
            submenu: true,
          ),
          _tile(
            l.cleanerExports,
            _exports,
            ready: report != null,
            submenu: true,
          ),
          SettingsHelp(text: l.cleanerHelp),
        ],
      ),
    );
  });
}
