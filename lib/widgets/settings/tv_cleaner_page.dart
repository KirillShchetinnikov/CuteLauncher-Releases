import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../tv_cleaner.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';

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
  Map<String, dynamic> _descriptions = {}, _profiles = {};
  AppLocalizations get l => AppLocalizations.of(context)!;
  bool get ru => Localizations.localeOf(context).languageCode == 'ru';
  List<Map> get apps =>
      (_report.value?['packages'] as List? ?? []).whereType<Map>().toList();

  @override
  void dispose() {
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

  Future<void> _execute(
    String action, {
    List<String>? packages,
    bool? enable,
  }) async {
    final value = await _client.call(
      action,
      packages: packages,
      enable: enable,
    );
    if (!mounted) return;
    if (value['status'] == 'success') {
      _report.value = value;
      showActionNotice(context, l.cleanerDone);
    } else {
      showActionNotice(
        context,
        value['status'] == 'partial'
            ? l.cleanerPartial
            : value['status'] == 'protected'
            ? l.cleanerProtected
            : l.cleanerFailure,
        error: true,
        duration: const Duration(seconds: 10),
      );
      if (action == 'cleanerInventory') return;
      // Never keep stale enabled/disabled values after partial mutation.
      _report.value = null;
      final fresh = await _client.call('cleanerInventory');
      if (mounted && fresh['status'] == 'success') _report.value = fresh;
    }
  }

  Future<void> _refresh() async {
    await _work(() async {
      final descriptions = await _client.catalog(
        'catalog/app_descriptions.json',
      );
      final profiles = await _client.catalog('catalog/cleaner_profiles.json');
      if (!mounted) return;
      _descriptions = descriptions['packages'] as Map<String, dynamic>;
      _profiles = profiles;
      await _execute('cleanerInventory');
    });
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
  }) => FocusableSettingsTile(
    title: Text(title),
    autofocus: autofocus,
    enabled: ready && !_busy.value,
    onPressed: action,
  );

  Future<void> _open(String title, Widget Function() builder) =>
      Navigator.of(context).push<void>(
        SettingsRoute(
          builder: (_) => _watch(
            () => SettingsPageLayout(title: Text(title), child: builder()),
          ),
        ),
      );

  Future<bool> _confirm(
    List<String> packages, {
    bool restore = false,
    bool enable = false,
    bool verified = false,
    List<String> skipped = const [],
  }) async =>
      await Navigator.of(context).push<bool>(
        SettingsRoute(
          builder: (ctx) => SettingsPageLayout(
            title: Text(
              restore
                  ? l.cleanerRestore
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
                Text(l.cleanerConfirmText),
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
  }) async {
    if (_busy.value || _report.value == null) return;
    final installed = {for (final row in apps) row['package']: row};
    final selected = packages
        .where(
          (name) =>
              installed.containsKey(name) &&
              (enable || installed[name]!['protected'] != true) &&
              (enable
                  ? installed[name]!['enabled'] != true
                  : installed[name]!['enabled'] == true),
        )
        .toList();
    if (selected.isEmpty) {
      showActionNotice(context, l.cleanerMissing);
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
      await _work(
        () => _execute('cleanerApply', packages: selected, enable: enable),
      );
    }
  }

  Future<void> _import() async {
    final source = await _work(() => _client.importFile());
    if (source == null || !mounted) return;
    await _fromSource(source);
  }

  Future<void> _fromSource(String source) async {
    try {
      if (source.trimLeft().startsWith('{')) {
        final json = jsonDecode(source) as Map;
        final identity = json['identity'];
        if (identity is Map &&
            identity['fingerprint'] != null &&
            identity['fingerprint'] !=
                (_report.value?['identity'] as Map?)?['fingerprint']) {
          showActionNotice(context, l.cleanerMismatch, error: true);
          return;
        }
      }
      await _preview(parseDisableList(source));
    } catch (_) {
      if (mounted) showActionNotice(context, l.cleanerFailure, error: true);
    }
  }

  Future<void> _export(Map<String, dynamic> value, String kind) async {
    final choice = await showLauncherDialog<int>(
      context: context,
      builder: (ctx) => LauncherAlertDialog(
        title: Text(l.diagnosticsExport),
        actions: [
          LauncherDialogButton(
            autofocus: true,
            onPressed: () => Navigator.pop(ctx, 0),
            child: Text(l.diagnosticsCopy),
          ),
          LauncherDialogButton(
            onPressed: () => Navigator.pop(ctx, 1),
            child: Text(l.diagnosticsSave),
          ),
          LauncherDialogButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    await _work(() async {
      if (choice == 0) {
        await Clipboard.setData(
          ClipboardData(
            text: const JsonEncoder.withIndent('  ').convert(value),
          ),
        );
        if (mounted) showActionNotice(context, l.cleanerDone);
      } else {
        final result = await _client.export(value, kind);
        if (mounted && result != null) {
          showActionNotice(context, l.cleanerSaved);
        }
      }
    });
  }

  Future<void> _project({bool remote = false}) async {
    if (remote) {
      final source = await _work(() async {
        try {
          return await _client.github(
            Uri.https(
              'raw.githubusercontent.com',
              '/KirillShchetinnikov/CuteLauncher/main/catalog/cleaner_profiles.json',
            ),
          );
        } catch (_) {
          if (mounted) {
            showActionNotice(context, l.cleanerGitUnavailable, error: true);
          }
          return null;
        }
      });
      if (source == null || !mounted) return;
      try {
        final parsed = jsonDecode(source);
        if (parsed is! Map<String, dynamic> ||
            parsed['schemaVersion'] != 1 ||
            parsed['profiles'] is! List) {
          throw const FormatException();
        }
        _profiles = parsed;
      } catch (_) {
        showActionNotice(context, l.cleanerFailure, error: true);
        return;
      }
    }
    if (!mounted) return;
    final profiles = _matchingProfiles();
    await _open(
      l.cleanerProject,
      () => ListView(
        children: [
          if (profiles.isEmpty) Text(l.cleanerMissing),
          for (final profile in profiles)
            _tile(
              '${profile['id']} — ${l.cleanerObserved}',
              () => _fromSource(
                jsonEncode({
                  'schemaVersion': 1,
                  'reportType': 'tvDisableList',
                  'identity': profile['identity'],
                  'packages': profile['packages'],
                }),
              ),
            ),
        ],
      ),
    );
  }

  List<Map> _matchingProfiles() {
    final identity = _report.value?['identity'] as Map?;
    return (_profiles['profiles'] as List? ?? []).whereType<Map>().where((
      profile,
    ) {
      final id = profile['identity'];
      return id is Map &&
          identity != null &&
          ['manufacturer', 'model', 'device', 'fingerprint'].every(
            (key) =>
                id[key] is String &&
                (id[key] as String).isNotEmpty &&
                id[key] == identity[key],
          );
    }).toList();
  }

  Future<void> _safe() async {
    final recommended = <String>{};
    for (final profile in _matchingProfiles()) {
      if (profile['verification'] != 'verifiedFunctionsPreserved') continue;
      for (final name
          in (profile['recommended'] as List? ?? []).whereType<String>()) {
        if (cleanerPackageId(name) &&
            (_descriptions[name] as Map?)?['safeToDisable'] == true) {
          recommended.add(name);
        }
      }
    }
    if (recommended.isEmpty) {
      showActionNotice(context, l.cleanerNoSafe);
      return;
    }
    await _preview(recommended.toList()..sort(), verified: true);
  }

  Future<void> _external() async {
    final folders = await _work(() async {
      final source = await _client.github(
        Uri.https(
          'api.github.com',
          '/repos/Gathin23/cleanyourtv/contents/examples',
        ),
      );
      final rows = jsonDecode(source);
      if (rows is! List) throw const FormatException();
      return rows
          .whereType<Map>()
          .where(
            (row) =>
                row['type'] == 'dir' &&
                row['name'] is String &&
                RegExp(r'^[a-zA-Z0-9_-]{1,100}$')
                    .hasMatch(row['name'] as String),
          )
          .map((row) => row['name'] as String)
          .take(500)
          .toList()
        ..sort();
    });
    if (!mounted || folders == null) return;
    await _open(
      l.cleanerExternal,
      () => ListView.builder(
        itemCount: folders.length,
        itemBuilder: (_, index) => _tile(folders[index], () async {
          final source = await _work(
            () => _client.github(
              Uri.https(
                'raw.githubusercontent.com',
                '/Gathin23/cleanyourtv/main/examples/${folders[index]}/debloat.txt',
              ),
            ),
          );
          if (source != null && mounted) await _fromSource(source);
        }),
      ),
    );
  }

  Future<void> _details(String package) => _open(package, () {
    final found = apps.where((row) => row['package'] == package);
    if (found.isEmpty) return Text(l.cleanerMissing);
    final app = found.first;
    final description = _descriptions[package] as Map?;
    return ListView(
      children: [
        Text(
          '${app['name']}\n$package\n${app['versionName']} (${app['versionCode']})',
        ),
        Text(app['system'] == true ? l.cleanerSystem : l.cleanerUser),
        Text(app['enabled'] == true ? l.enabled : l.disabled),
        const SizedBox(height: 12),
        Text(
          description?[ru ? 'ru' : 'en'] as String? ?? l.cleanerUnidentified,
        ),
        const SizedBox(height: 12),
        Text(l.cleanerRisk, style: Theme.of(context).textTheme.titleMedium),
        Text(
          description?[ru ? 'riskRu' : 'riskEn'] as String? ?? l.cleanerUnknown,
        ),
        if (app['protected'] == true) Text(l.cleanerProtected),
        _tile(
          app['enabled'] == true ? l.cleanerDisable : l.cleanerEnable,
          () => _preview([package], enable: app['enabled'] != true),
          ready: app['protected'] != true || app['enabled'] != true,
        ),
      ],
    );
  });

  Future<void> _allApps() => _open(l.cleanerApps, () {
    final rows = apps;
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (_, index) {
        final app = rows[index];
        return FocusableSettingsTile(
          enabled: !_busy.value,
          leading: Icon(
            app['enabled'] == true ? Icons.check_circle_outline : Icons.block,
          ),
          title: Text('${app['name']}\n${app['package']}'),
          trailing: Text(app['enabled'] == true ? l.enabled : l.disabled),
          onPressed: () => _details(app['package'] as String),
        );
      },
    );
  });

  @override
  Widget build(BuildContext context) => _watch(() {
    final report = _report.value;
    return SettingsPageLayout(
      title: Text(l.cleanerTitle),
      child: ListView(
        children: [
          if (_busy.value) const LinearProgressIndicator(),
          if (report != null)
            Text(
              '${(report['identity'] as Map)['model']} · ${(report['identity'] as Map)['device']}\n'
              '${l.cleanerApps}: ${apps.length}\n${report['snapshotSaved'] == true ? l.cleanerSnapshotSaved : l.cleanerNoSnapshot}\n${l.cleanerPending}: ${report['pendingRestore']}',
            ),
          _tile(l.cleanerRefresh, _refresh, autofocus: true),
          _tile(
            l.cleanerSnapshot,
            () => _work(() => _execute('cleanerSnapshot')),
            ready: report != null,
          ),
          _tile(l.cleanerRestore, () async {
            if (await _confirm(const [], restore: true) && mounted) {
              await _work(() => _execute('cleanerRestore'));
            }
          }, ready: (report?['pendingRestore'] as int? ?? 0) > 0),
          _tile(
            l.cleanerExportSnapshot,
            () => _export(
              Map<String, dynamic>.from(
                jsonDecode(report!['snapshot'] as String) as Map,
              ),
              'restore',
            ),
            ready: report?['snapshotSaved'] == true,
          ),
          _tile(l.cleanerSafe, _safe, ready: report != null),
          _tile(l.cleanerLocal, _import, ready: report != null),
          _tile(l.cleanerProject, _project, ready: report != null),
          _tile(
            l.cleanerRemoteProject,
            () => _project(remote: true),
            ready: report != null,
          ),
          _tile(l.cleanerExternal, _external, ready: report != null),
          _tile(
            l.cleanerDisabledExport,
            () => _export(
              Map<String, dynamic>.from(disabledList(report!)),
              'disabled',
            ),
            ready: report != null,
          ),
          _tile(
            l.cleanerInventoryExport,
            () => _export({...report!}..remove('snapshot'), 'apps'),
            ready: report != null,
          ),
          _tile(l.cleanerApps, _allApps, ready: report != null),
          SettingsHelp(text: l.cleanerHelp),
        ],
      ),
    );
  });
}
