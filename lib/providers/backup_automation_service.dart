import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backup_assets.dart';
import '../backup_sync.dart';
import '../backup_worker.dart';
import '../backup_sync_groups.dart';
import '../image_limits.dart';
import '../settings_import.dart';
import 'automatic_backup_service.dart';
import 'backup_service.dart';
import 'backup_storage.dart';
import 'local_backup_storage.dart';
import 'cloud_backup_service.dart';
import 'drive_backup_service.dart';
import 'settings_service.dart';
import 'foreground_work.dart';
import 'apps_service.dart';
import 'package:collection/collection.dart';

enum BackupDestination { webdav, googleDrive, local }

enum BackupMode { backup, synchronization }

class BackupAutomationService extends ChangeNotifier
    with WidgetsBindingObserver {
  final SharedPreferences preferences;
  final BackupService backup;
  final SettingsService settings;
  final AutomaticBackupService local;
  final CloudBackupService webdav;
  final DriveBackupService drive;
  final List<ChangeNotifier> sources;
  final List<ChangeNotifier> databaseSources, resourceSources;
  final Map<ChangeNotifier, VoidCallback> _callbacks = {};
  final Future<void> Function(File) apply;
  final Future<Directory> Function() directory;
  final DateTime Function() now;
  final BackupStorage Function(bool) storageFactory;
  final ForegroundWork? work;
  Timer? _timer;
  Timer? _changeTimer;
  final _changedSources = <ChangeNotifier?>{};
  final _hashValues = <String, Object?>{};
  final _hashes = <String, String>{};
  final _appRevisions = <AppsService, int>{};
  final _resumeWork = Object();
  BackupStorage? _storage;
  bool busy = true,
      failed = false,
      _disposed = false,
      _foreground = true,
      _applying = false;
  int _revision = 0;
  late final Future<void> initialized;
  BackupSyncDocument? _baseline;
  String? _baselineFingerprint;
  bool _syncStateBroken = false;
  final Map<String, String> _observedSettings = {};
  final Map<String, int> _changeTimes = {};
  Future<void> _pendingTimes = Future.value();
  String get device => preferences.getString('backup_transport_device')!;
  BackupDestination get destination =>
      BackupDestination.values[(preferences.getInt(
                'backup_transport_destination',
              ) ??
              2)
          .clamp(0, 2)];
  BackupMode get mode =>
      BackupMode.values[(preferences.getInt('backup_transport_mode') ?? 0)
          .clamp(0, 1)];
  bool get shared => preferences.getBool('backup_transport_shared') ?? false;
  bool get enabled =>
      preferences.getBool('backup_transport_enabled') ?? local.enabled;
  int get syncMinutes =>
      (preferences.getInt('backup_transport_sync_minutes') ?? 15).clamp(
        1,
        1440,
      );
  String get scope => shared ? 'shared' : device;
  bool get configured => switch (destination) {
    BackupDestination.webdav => webdav.account.configured,
    BackupDestination.googleDrive => drive.configured,
    BackupDestination.local => true,
  };
  String? get localFolder =>
      preferences.getString('backup_transport_local_folder');
  bool syncGroupEnabled(BackupSyncGroup group) =>
      !disabledBackupSyncGroups(preferences.get(backupSyncGroupsKey))
          .contains(group);

  Future<void> setSyncGroupEnabled(BackupSyncGroup group, bool enabled) async {
    await initialized;
    if (busy) throw StateError('Operation busy');
    final disabled = disabledBackupSyncGroups(
      preferences.get(backupSyncGroupsKey),
    );
    if (enabled) {
      disabled.remove(group);
    } else {
      disabled.add(group);
    }
    final names = [
      for (final value in BackupSyncGroup.values)
        if (disabled.contains(value)) value.name,
    ];
    if (!await preferences.setStringList(backupSyncGroupsKey, names)) {
      throw StateError('Preference write failed');
    }
    _changed();
  }

  BackupStorage _makeStorage() => destination == BackupDestination.local
      ? LocalBackupStorage(
          webdav.accounts,
          drive,
          directory: directory,
          tree: localFolder,
        )
      : storageFactory(destination == BackupDestination.googleDrive);
  Future<void> setLocalFolder(String? value) async {
    await initialized;
    if (busy) throw StateError('Operation busy');
    if (value == null) {
      if (!await preferences.remove('backup_transport_local_folder')) {
        throw StateError('Preference write failed');
      }
    } else {
      await _set('backup_transport_local_folder', value);
    }
    await preferences.remove('backup_transport_success_local');
    for (final mode in BackupMode.values) {
      await preferences.remove('backup_transport_checked_local_${mode.name}');
    }
    _notify();
    _schedule();
  }

  Future<void> deleteCopy(RemoteBackupFile selected) async {
    await initialized;
    if (busy || !configured || !_foreground || _disposed) {
      throw StateError('Storage unavailable');
    }
    busy = true;
    _timer?.cancel();
    _notify();
    final storage = _makeStorage();
    _storage = storage;
    try {
      final files = await storage.list();
      if (!files.any((f) => f.name == selected.name && f.id == selected.id)) {
        throw StateError('Copy missing');
      }
      await storage.delete(selected);
    } finally {
      _storage = null;
      busy = false;
      _notify();
      _schedule();
    }
  }

  DateTime? get lastSuccess {
    final stamp = preferences.getInt(
      'backup_transport_success_${destination.name}',
    );
    return stamp == null ? null : DateTime.fromMillisecondsSinceEpoch(stamp);
  }

  DateTime? get _lastCheck {
    final stamp = preferences.getInt(
      'backup_transport_checked_${destination.name}_${mode.name}',
    );
    return stamp == null ? null : DateTime.fromMillisecondsSinceEpoch(stamp);
  }

  BackupAutomationService(
    this.preferences,
    this.backup,
    this.settings,
    this.local,
    this.webdav,
    this.drive, {
    required this.sources,
    this.databaseSources = const [],
    this.resourceSources = const [],
    required this.apply,
    Future<Directory> Function()? directory,
    DateTime Function()? now,
    BackupStorage Function(bool)? storageFactory,
    this.work,
  }) : directory = directory ?? getApplicationDocumentsDirectory,
       now = now ?? DateTime.now,
       storageFactory =
           storageFactory ??
           ((google) => BackupStorage(webdav.accounts, drive, google: google)) {
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    final savedTimes = preferences.getString('backup_transport_change_times');
    if (savedTimes != null) {
      try {
        _changeTimes.addAll(
          (jsonDecode(savedTimes) as Map).cast<String, int>(),
        );
      } catch (_) {
        failed = true;
      }
    }
    _observedSettings.addAll(_settingsHashes());
    for (final source in sources) {
      if (source is AppsService) _appRevisions[source] = source.contentRevision;
      void callback() => _changed(source);
      _callbacks[source] = callback;
      source.addListener(callback);
    }
    local.addListener(_localChanged);
    webdav.addListener(_notify);
    drive.addListener(_notify);
    initialized = _initialize();
  }
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _localChanged() {
    _notify();
    _schedule();
  }

  Map<String, Object?> _settingsValues() => <String, Object?>{
      ...settings.exportSettingsMap(),
      for (final key in preferences.getKeys())
        if (!isDeviceLocalBackupKey(key)) key: preferences.get(key),
    }..removeWhere((key, _) => isDeviceLocalBackupKey(key));

  Map<String, String> _settingsHashes() {
    final values = _settingsValues();
    final keys = values.keys.where((key) => !isDeviceLocalBackupKey(key)).toSet();
    _hashes.removeWhere((key, _) => !keys.contains(key));
    _hashValues.removeWhere((key, _) => !keys.contains(key));
    for (final key in keys) {
      final value = values[key];
      if (!_hashes.containsKey(key) || !const DeepCollectionEquality().equals(value, _hashValues[key])) {
        _hashes[key] = backupFingerprint(value);
        // SharedPreferences string lists must not mutate the comparison baseline.
        _hashValues[key] = value is List ? List.of(value) : value;
      }
    }
    return {for (final key in keys) 'setting:$key': _hashes[key]!};
  }

  Future<File> _stateFile() async =>
      File('${(await directory()).path}/backup_sync_state.json');
  Future<void> _initialize() async {
    try {
      if (preferences.getString('backup_transport_device') == null) {
        await _set('backup_transport_device', _random(16));
      }
      final file = await _stateFile();
      if (await file.exists()) {
        final state = jsonDecode(
          utf8.decode(
            await readBoundedImage(file.openRead(), limit: 1024 * 1024),
          ),
        ) as Map;
        if (state['stateVersion'] != 1 ||
            state['fingerprint'] is! String ||
            !RegExp(r'^[a-f0-9]{64}$')
                .hasMatch(state['fingerprint'] as String)) {
          throw const FormatException('Invalid sync history');
        }
        _baseline = BackupSyncDocument(
          {},
          BackupSyncDocument.readRevisions(state['revisions']),
        );
        _baselineFingerprint = state['fingerprint'] as String;
      }
      await local.initialized;
      if (!preferences.containsKey('backup_transport_enabled')) {
        await _set('backup_transport_enabled', local.enabled);
      }
      await local.setEnabled(false);
      if (preferences.getBool('backup_transport_local_migrated') != true) {
        final localStorage = LocalBackupStorage(
          webdav.accounts,
          drive,
          directory: directory,
        );
        final existing = await localStorage.list();
        for (final entry in local.entries) {
          final stamp = entry.createdAt.millisecondsSinceEpoch;
          if (!existing.any(
            (f) => f.name.startsWith('cute-backup-$device-$device-$stamp-'),
          )) {
            await localStorage.upload(
              entry.file,
              'cute-backup-$device-$device-$stamp-${_random(8)}.json',
            );
          }
        }
        if (local.lastSuccess != null &&
            preferences.getInt('backup_transport_success_local') == null) {
          await _set(
            'backup_transport_success_local',
            local.lastSuccess!.millisecondsSinceEpoch,
          );
        }
        await _set('backup_transport_local_migrated', true);
      }
      await Future.wait([
        webdav.refreshAccount().catchError((_) {}),
        drive.refreshAccount().catchError((_) {}),
      ]);
    } catch (_) {
      failed = true;
      _syncStateBroken = true;
    }
    busy = false;
    _notify();
    _schedule();
  }

  static String _random(int count) => List.generate(
    count,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  Future<void> _set(String key, Object value) async {
    final saved = switch (value) {
      bool v => await preferences.setBool(key, v),
      int v => await preferences.setInt(key, v),
      String v => await preferences.setString(key, v),
      _ => false,
    };
    if (!saved) throw StateError('Preference write failed');
  }

  Future<void> configure({
    BackupDestination? destination,
    BackupMode? mode,
    bool? shared,
    bool? enabled,
    int? syncMinutes,
  }) async {
    await initialized;
    if (busy) return;
    if (destination != null) {
      await _set('backup_transport_destination', destination.index);
    }
    if (mode != null) await _set('backup_transport_mode', mode.index);
    if (shared != null) await _set('backup_transport_shared', shared);
    if (enabled != null) await _set('backup_transport_enabled', enabled);
    if (syncMinutes != null) {
      await _set('backup_transport_sync_minutes', syncMinutes.clamp(1, 1440));
    }

    // Private local snapshots are restore points, independent of selected storage.
    await local.setEnabled(false);
    _notify();
    _schedule();
  }

  void _changed([ChangeNotifier? source]) {
    if (_disposed || _applying) return;
    if (source is AppsService) {
      if (_appRevisions[source] == source.contentRevision) return;
      _appRevisions[source] = source.contentRevision;
    }
    if (!databaseSources.contains(source) && !resourceSources.contains(source) &&
        const DeepCollectionEquality().equals(_settingsValues(), _hashValues)) { return; }
    // Reserve a revision immediately: a fast remote reply must not overwrite
    // a local edit while its batched fingerprint is still waiting for the timer.
    if (_changedSources.isEmpty) _revision++;
    _changedSources.add(source);
    _changeTimer ??= Timer(const Duration(milliseconds: 150), _flushChanges);
  }

  void _flushChanges() {
    _changeTimer?.cancel();
    _changeTimer = null;
    if (_disposed || _applying || _changedSources.isEmpty) return;
    final sources = Set.of(_changedSources);
    _changedSources.clear();
    final hashes = _settingsHashes();
    final stamp = now().millisecondsSinceEpoch;
    var changed =
        databaseSources.any(sources.contains) || resourceSources.any(sources.contains);
    for (final key in {...hashes.keys, ..._observedSettings.keys}) {
      if (hashes[key] != _observedSettings[key]) {
        _changeTimes[key] = stamp;
        changed = true;
      }
    }
    _observedSettings
      ..clear()
      ..addAll(hashes);
    if (!changed) return;
    if (databaseSources.any(sources.contains)) _changeTimes['database'] = stamp;
    if (resourceSources.any(sources.contains)) _changeTimes['resources'] = stamp;
    final encoded = jsonEncode(_changeTimes);
    _pendingTimes = _pendingTimes
        .then((_) => _set('backup_transport_change_times', encoded))
        .catchError((_) {
          failed = true;
        });
    _notify();
  }

  Future<BackupSyncDocument> _capture(Directory root) async {
    final file = File('${root.path}/capture.json');
    await backup.writeBackupTo(
      file,
      settingsService: settings,
      validateStructure: true,
    );
    final data = await readBackupJson(file.path);
    return captureBackup(
      data,
      _baseline,
      device,
      _baseline == null ? DateTime.fromMillisecondsSinceEpoch(0) : now(),
      Map.of(_changeTimes),
    );
  }

  Future<void> _saveBaseline(BackupSyncDocument document) async {
    final file = await _stateFile();
    final pending = File('${file.path}.partial');
    final fingerprint = await fingerprintBackup(document.backup);
    await pending.writeAsString(
      jsonEncode({
        'stateVersion': 1,
        'fingerprint': fingerprint,
        'revisions': document.revisions,
      }),
      flush: true,
    );
    if (await pending.length() > 1024 * 1024) {
      await pending.delete();
      throw const FormatException('Oversized sync state');
    }
    await pending.rename(file.path);
    _baseline = BackupSyncDocument({}, document.revisions);
    _baselineFingerprint = fingerprint;
  }

  Future<void> _checkpoint() async {
    if (_disposed || !_foreground) return;
    final root = await (await getTemporaryDirectory()).createTemp(
      'backup-checkpoint-',
    );
    try {
      await _saveBaseline(await _capture(root));
    } finally {
      await root.delete(recursive: true);
    }
  }

  /// Resume catches up one overdue operation, including a failed prior attempt.
  Future<bool> checkDue() async {
    await initialized;
    if (_disposed || !_foreground || !enabled || busy) {
      return false;
    }
    final last = _lastCheck ?? lastSuccess;
    final current = now();
    final due =
        last == null ||
        current.isBefore(last) ||
        (mode == BackupMode.synchronization
            ? !current.isBefore(last.add(Duration(minutes: syncMinutes)))
            : last.isBefore(local.schedule.latestSlot(current)));
    if (due) return run();
    _schedule();
    return false;
  }

  void _schedule() {
    _timer?.cancel();
    if (_disposed || !_foreground || busy || !enabled) {
      return;
    }
    final last = _lastCheck ?? lastSuccess;
    final delay = failed
        ? Duration(
            minutes: mode == BackupMode.synchronization
                ? max(15, syncMinutes)
                : 15,
          )
        : last == null
        ? const Duration(seconds: 10)
        : mode == BackupMode.synchronization
        ? last.add(Duration(minutes: syncMinutes)).difference(now())
        : last.isBefore(local.schedule.latestSlot(now()))
        ? Duration.zero
        : local.schedule.nextSlot(now()).difference(now());
    _timer = Timer(
      Duration(
        milliseconds: delay.inMilliseconds.clamp(
          10000,
          const Duration(days: 8).inMilliseconds,
        ),
      ),
      () => run(),
    );
  }

  Future<bool> run({bool manual = false, bool exportOnly = false}) async {
    await initialized;
    if (_disposed || !_foreground || busy || !manual && !enabled) return false;
    _flushChanges();
    busy = true;
    failed = false;
    _timer?.cancel();

    _notify();
    final operationMode = exportOnly ? BackupMode.backup : mode;
    Directory? stage;
    final storage = _makeStorage();
    _storage = storage;
    try {
      final root = await (await getTemporaryDirectory()).createTemp(
        'backup-cloud-',
      );
      stage = root;
      if (!configured) throw StateError('Connection is not configured');
      if (operationMode == BackupMode.synchronization && _syncStateBroken) {
        throw StateError(
          'Damaged local sync history; import a server copy first',
        );
      }
      final captureRevision = _revision;
      var localDocument = await _capture(root);
      if (_disposed || !_foreground || captureRevision != _revision) throw StateError('Local settings changed during capture');
      final originalDocument = localDocument;
      final unchanged =
          _baseline != null &&
          await fingerprintBackup(localDocument.backup) == _baselineFingerprint;
      if (!manual &&
          operationMode == BackupMode.backup &&
          unchanged &&
          lastSuccess != null) {
        await _set(
          'backup_transport_checked_${destination.name}_${mode.name}',
          now().millisecondsSinceEpoch,
        );
        return true;
      }
      if (operationMode == BackupMode.synchronization) {
        await _saveBaseline(localDocument);
      }
      final files = await storage.list();
      final prefix =
          'cute-${operationMode == BackupMode.backup ? 'backup' : 'sync'}-$scope-';
      if (operationMode == BackupMode.synchronization) {
        final heads = <String, RemoteBackupFile>{};
        for (final file in files.where((f) => f.name.startsWith(prefix))) {
          final id = file.name.substring(prefix.length, prefix.length + 32);
          if (heads[id] == null || _stamp(file) > _stamp(heads[id]!)) {
            heads[id] = file;
          }
        }
        final revision = _revision;
        for (final file in heads.values) {
          final downloaded = await storage.download(file, root);
          localDocument = await mergeBackup(localDocument, await readBackupJson(downloaded.path));
          await downloaded.delete();
        }
        localDocument = await preserveBackupGroups(localDocument, originalDocument);
        if (_disposed || !_foreground || revision != _revision) {
          throw StateError('Local settings changed during synchronization');
        }
        if (await fingerprintBackup(localDocument.backup) != _baselineFingerprint) {
          if (!await local.createNow()) {
            throw StateError('Restore point failed');
          }
          if (_disposed || !_foreground || revision != _revision) {
            throw StateError('Local settings changed during synchronization');
          }
          final file = File('${root.path}/merged.json');
          await writeBackupJson(file.path, localDocument.backup);
          if (_disposed || !_foreground || revision != _revision) throw StateError('Local settings changed during synchronization');
          _applying = true;
          try {
            await apply(file);
            _observedSettings
              ..clear()
              ..addAll(_settingsHashes());
          } finally {
            _applying = false;
          }
          await _saveBaseline(localDocument);
        }
      }
      if (_disposed || !_foreground) throw StateError('Cancelled');
      final stamp = max(
        now().millisecondsSinceEpoch,
        (preferences.getInt('backup_transport_sequence') ?? 0) + 1,
      );
      await _set('backup_transport_sequence', stamp);
      final name = '$prefix$device-$stamp-${_random(8)}.json';
      final upload = File('${root.path}/upload.json');
      await writeBackupJson(upload.path, operationMode == BackupMode.backup ? localDocument.backup : localDocument.toJson());
      await storage.upload(upload, name);
      if (operationMode == BackupMode.backup) {
        await _saveBaseline(localDocument);
      }
      await _set(
        'backup_transport_success_${destination.name}',
        now().millisecondsSinceEpoch,
      );
      await _set(
        'backup_transport_checked_${destination.name}_${mode.name}',
        now().millisecondsSinceEpoch,
      );
      final owned =
          files.where((f) => f.name.startsWith('$prefix$device-')).toList()
            ..sort((a, b) => _stamp(b).compareTo(_stamp(a)));
      final retain = operationMode == BackupMode.synchronization
          ? 1
          : local.keepCount;
      for (final old in owned.skip(retain - 1)) {
        if (_disposed || !_foreground) break;
        await storage.delete(old);
      }
      return true;
    } catch (_) {
      failed = true;
      return false;
    } finally {
      _storage = null;
      busy = false;
      try {
        await stage?.delete(recursive: true);
      } catch (_) {
        failed = true;
      }
      _notify();
      _schedule();
    }
  }

  static int _stamp(RemoteBackupFile file) =>
      int.parse(file.name.split('-')[4]);
  static DateTime createdAt(RemoteBackupFile file) =>
      DateTime.fromMillisecondsSinceEpoch(
        _stamp(file).clamp(0, 8640000000000000),
      );
  Future<List<RemoteBackupFile>> availableCopies() async {
    await initialized;
    if (_disposed || !_foreground || busy || !configured) {
      throw StateError('Connection is unavailable');
    }
    busy = true;
    _timer?.cancel();
    _notify();
    final storage = _makeStorage();
    _storage = storage;
    try {
      final files =
          (await storage.list())
              .where(
                (f) => f.name.startsWith(
                  'cute-${mode == BackupMode.backup ? 'backup' : 'sync'}-',
                ),
              )
              .toList()
            ..sort((a, b) => _stamp(b).compareTo(_stamp(a)));
      return mode == BackupMode.synchronization
          ? files.take(1).toList()
          : files;
    } finally {
      _storage = null;
      busy = false;
      _notify();
      _schedule();
    }
  }

  Future<void> importLatest({RemoteBackupFile? selected}) async {
    await initialized;
    if (_disposed || !_foreground || busy || !configured) {
      throw StateError('Connection is unavailable');
    }
    busy = true;
    _timer?.cancel();
    _notify();
    final storage = _makeStorage();
    _storage = storage;
    Directory? stage;
    try {
      final root = await (await getTemporaryDirectory()).createTemp(
        'backup-import-',
      );
      stage = root;
      final files =
          (await storage.list())
              .where(
                (f) =>
                    f.name.startsWith('cute-backup-$scope-') ||
                    f.name.startsWith('cute-sync-$scope-'),
              )
              .toList()
            ..sort((a, b) => _stamp(b).compareTo(_stamp(a)));
      if (selected == null && files.isEmpty) {
        throw StateError('No server backup');
      }
      final file = await storage.download(selected ?? files.first, root);
      final data = jsonDecode(
        utf8.decode(
          await readBoundedImage(file.openRead(), limit: maximumBackupBytes),
        ),
      );
      if (data is Map && data.containsKey('syncVersion')) {
        await file.writeAsString(
          jsonEncode(
            BackupSyncDocument.parse(data).restoreOver(await _capture(root)),
          ),
        );
      }
      if (!await local.createNow()) throw StateError('Restore point failed');
      if (_disposed || !_foreground) throw StateError('Cancelled');
      _applying = true;
      try {
        await apply(file);
        _observedSettings
          ..clear()
          ..addAll(_settingsHashes());
      } finally {
        _applying = false;
      }
      for (final key in {
        ...?_baseline?.revisions.keys,
        ..._settingsHashes().keys,
        'database',
        'resources',
      }) {
        _changeTimes[key] = now().millisecondsSinceEpoch;
      }
      await _set('backup_transport_change_times', jsonEncode(_changeTimes));
      await _checkpoint();
      _syncStateBroken = false;
    } finally {
      _storage = null;
      busy = false;
      try {
        await stage?.delete(recursive: true);
      } catch (_) {
        failed = true;
      }
      _notify();
      _schedule();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _changed();
      if (work == null) { checkDue(); }
      else { work!.schedule(_resumeWork, () async { await checkDue(); }, delay: const Duration(seconds: 2)); }
    } else {
      _timer?.cancel();

      _storage?.cancel();
    }
  }

  @override
  void dispose() {
    _flushChanges();
    _changeTimer?.cancel();
    work?.cancel(_resumeWork);
    _disposed = true;
    _timer?.cancel();

    _storage?.cancel();
    for (final source in sources) {
      source.removeListener(_callbacks[source]!);
    }
    local.removeListener(_localChanged);
    webdav.removeListener(_notify);
    drive.removeListener(_notify);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
