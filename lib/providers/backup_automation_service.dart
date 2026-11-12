import '../bridge_result.dart';
import '../diagnostics_store.dart';

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
import '../native_sync.dart';
import '../backup_data_protection.dart';
import 'backup_preferences.dart';
import 'backup_accounts.dart';
import 'automatic_backup_service.dart';
import 'backup_service.dart';
import 'backup_storage.dart';
import 'yandex_backup_storage.dart';
import 'smb_backup_storage.dart';
import 'smb_backup_service.dart';
import 'local_backup_storage.dart';
import 'cloud_backup_service.dart';
import 'drive_backup_service.dart';
import 'settings_service.dart';
import 'foreground_work.dart';
import 'apps_service.dart';

import 'package:collection/collection.dart';

enum BackupDestination { webdav, googleDrive, local, yandexDisk, smb }

enum BackupMode { backup, synchronization }

typedef ChooseBackupSyncResume = Future<BackupSyncResumeChoice?> Function(
  DateTime? previousSync,
  DateTime remoteCopy,
);

class BackupOperationGate extends ChangeNotifier {
  Object? owner;
  void changed() => notifyListeners();
}

class BackupAutomationService extends ChangeNotifier
    with WidgetsBindingObserver {
  final SharedPreferences preferences;
  final BackupService backup;
  final SettingsService settings;
  final AutomaticBackupService local;
  final CloudBackupService _webdav;
  final DriveBackupService _drive;
  CloudBackupService? _listenedWebdav;
  DriveBackupService? _listenedDrive;
  DriveBackupService? _listenedYandex;
  SmbBackupService? _listenedSmb, _fallbackSmb;
  SmbBackupService get smb =>
      accounts?.smb(accountId(BackupDestination.smb)) ??
      (_fallbackSmb ??= SmbBackupService());
  DriveBackupService? _fallbackYandex;
  DriveBackupService get yandex =>
      accounts?.yandex(accountId(BackupDestination.yandexDisk)) ??
      (_fallbackYandex ??= DriveBackupService(yandex: true));
  void _listenAccounts() {
    _listenedWebdav?.removeListener(_notify);
    _listenedDrive?.removeListener(_notify);
    _listenedYandex?.removeListener(_notify);
    _listenedSmb?.removeListener(_notify);
    _listenedWebdav = webdav;
    _listenedDrive = drive;
    _listenedWebdav!.addListener(_notify);
    _listenedDrive!.addListener(_notify);
    _listenedYandex = destination == BackupDestination.yandexDisk
        ? yandex
        : null;
    _listenedYandex?.addListener(_notify);
    _listenedSmb = destination == BackupDestination.smb ? smb : null;
    _listenedSmb?.addListener(_notify);
  }

  final BackupMode? fixedMode;
  final BackupOperationGate? gate;
  final BackupAccounts? accounts;
  final Future<void>? startAfter;
  BackupAutomationService? synchronization;
  final bool createSynchronization;
  CloudBackupService get webdav =>
      accounts?.webdav(accountId(BackupDestination.webdav)) ?? _webdav;
  DriveBackupService get drive =>
      accounts?.drive(accountId(BackupDestination.googleDrive)) ?? _drive;
  String accountId(BackupDestination type) =>
      preferences.getString('backup_transport_account_${type.name}') ??
      'default';
  BackupDataProtection get protection => BackupDataProtection(mode.name);
  bool get setupComplete =>
      preferences.getBool('backup_transport_setup_complete') ?? false;
  bool _setupActive = false;
  Future<Map<String, Object>> beginSetup() async {
    await initialized;
    if (busy || _setupActive) throw StateError('Operation busy');
    _setupActive = true;
    _timer?.cancel();
    return {
      for (final key in preferences.getKeys())
        if ((key.startsWith('backup_transport_') &&
                !BackupPreferences.shared.contains(key)) ||
            mode == BackupMode.backup && key.startsWith('automatic_backup_') ||
            key == backupSyncGroupsKey)
          if (preferences.get(key) case final Object value)
            key: value is List<String> ? List<String>.of(value) : value,
    };
  }

  Future<void> endSetup(
    Map<String, Object> snapshot, {
    required bool keep,
  }) async {
    if (!keep) {
      for (final key
          in preferences
              .getKeys()
              .where(
                (key) =>
                    ((key.startsWith('backup_transport_') &&
                            !BackupPreferences.shared.contains(key)) ||
                        mode == BackupMode.backup &&
                            key.startsWith('automatic_backup_') ||
                        key == backupSyncGroupsKey) &&
                    !snapshot.containsKey(key),
              )
              .toList()) {
        await preferences.remove(key);
      }
      for (final e in snapshot.entries) {
        if (e.value is List<String>) {
          await preferences.setStringList(e.key, e.value as List<String>);
        } else {
          await _set(e.key, e.value);
        }
      }
    }
    _setupActive = false;
    _listenAccounts();
    _notify();
    _schedule();
  }

  Future<DateTime?> inspectSynchronization() async {
    final files = await synchronizationFiles();
    final matching = files
        .where((f) => f.name.startsWith('cute-sync-$scope-'))
        .toList();
    if (matching.isEmpty) return null;
    matching.sort((a, b) => _stamp(b).compareTo(_stamp(a)));
    return createdAt(matching.first);
  }

  BackupAutomationService forMode(BackupMode value) =>
      value == BackupMode.synchronization ? synchronization ?? this : this;
  Future<void> completeSetup() => _set('backup_transport_setup_complete', true);
  Future<void> setPassword(String value) async {
    await initialized;
    if (busy) throw StateError('Operation busy');
    busy = true;
    _timer?.cancel();
    _notify();
    try {
      await protection.setPassword(value);
    } finally {
      busy = false;
      _notify();
      _schedule();
    }
  }

  Future<void> selectAccount(String id) async {
    await initialized;
    if (busy ||
        accounts == null ||
        !accounts!
            .ids(
              destination == BackupDestination.googleDrive,
              yandex: destination == BackupDestination.yandexDisk,
              smb: destination == BackupDestination.smb,
            )
            .contains(id)) {
      throw StateError('Account unavailable');
    }
    await _set('backup_transport_account_${destination.name}', id);
    _listenAccounts();
    if (mode == BackupMode.synchronization) {
      await _set('backup_transport_enabled', false);
    }
    if (destination == BackupDestination.webdav) await webdav.refreshAccount();
    if (destination == BackupDestination.googleDrive) {
      await drive.refreshAccount();
    }
    if (destination == BackupDestination.yandexDisk) {
      await yandex.refreshAccount();
    }
    if (destination == BackupDestination.smb) await smb.refreshAccount();
    _notify();
    _schedule();
  }

  final List<ChangeNotifier> sources;
  final Future<Map?> Function() identityLoader;
  String get deviceLabel =>
      preferences.getString('backup_transport_device_label') ?? 'TV';
  final List<ChangeNotifier> databaseSources, resourceSources;
  final Map<ChangeNotifier, VoidCallback> _callbacks = {};
  final Future<void> Function(File) apply;
  final Future<Directory> Function() directory;
  final DateTime Function() now;
  final BackupStorage Function(bool)? storageFactory;
  final ForegroundWork? work;
  final NativeSync nativeSync;
  Map<String, String> _capturedNative = {};
  Timer? _timer;
  Timer? _changeTimer;
  final _changedSources = <ChangeNotifier?>{};
  final _hashValues = <String, Object?>{};
  final _hashes = <String, String>{};
  final _appRevisions = <AppsService, int>{};
  final _resumeWork = Object();
  BackupStorage? _storage;
  bool _busy = true;
  bool get busy => _busy || gate?.owner != null && gate?.owner != this;
  set busy(bool value) {
    if (value && gate?.owner != null && gate?.owner != this) {
      throw StateError('Operation busy');
    }
    _busy = value;
    if (gate != null) {
      if (value) {
        gate!.owner = this;
      } else if (gate!.owner == this) {
        gate!.owner = null;
      }
      gate!.changed();
    }
  }

  bool failed = false, _disposed = false, _foreground = true, _applying = false;
  int _revision = 0;
  late final Future<void> initialized;
  BackupSyncDocument? _baseline;
  String? _baselineFingerprint;
  String? _stateContext;
  bool cleanupFailed = false;
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
          .clamp(0, 4)];
  BackupMode get mode =>
      fixedMode ??
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
    BackupDestination.yandexDisk => yandex.configured,
    BackupDestination.smb => smb.account.configured,
    BackupDestination.local => true,
  };
  String? get localFolder =>
      preferences.getString('backup_transport_local_folder');
  bool syncGroupEnabled(BackupSyncGroup group) =>
      !disabledBackupSyncGroups(preferences.get(backupSyncGroupsKey))
          .contains(group);

  Future<void> setSyncKey(String key) async {
    await initialized;
    if (busy) throw StateError('Operation busy');
    busy = true;
    _timer?.cancel();
    _notify();
    try {
      await nativeSync.setKey(key);
    } finally {
      busy = false;
      _notify();
      _schedule();
    }
  }

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

  BackupStorage _makeStorage() => destination == BackupDestination.smb
      ? SmbBackupStorage(
          webdav.accounts,
          drive,
          profile: accountId(BackupDestination.smb),
        )
      : destination == BackupDestination.yandexDisk
      ? YandexBackupStorage(webdav.accounts, yandex)
      : destination == BackupDestination.local
      ? LocalBackupStorage(
          webdav.accounts,
          drive,
          directory: directory,
          tree: localFolder,
        )
      : storageFactory?.call(destination == BackupDestination.googleDrive) ??
            BackupStorage(
              webdav.accounts,
              drive,
              google: destination == BackupDestination.googleDrive,
            );

  Future<void> setSyncGroups(Set<BackupSyncGroup> disabled) async {
    await initialized;
    if (busy) throw StateError('Operation busy');
    if (!await preferences.setStringList(backupSyncGroupsKey, [
      for (final g in BackupSyncGroup.values)
        if (disabled.contains(g)) g.name,
    ])) {
      throw StateError('Preference write failed');
    }
    _changed();
  }

  Future<void> setLocalFolder(String? value) async {
    await initialized;
    if (busy) throw StateError('Operation busy');
    if (destination == BackupDestination.local &&
        mode == BackupMode.synchronization &&
        enabled &&
        value != localFolder) {
      await _set('backup_transport_enabled', false);
    }
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
      if (!selected.name.startsWith('cute-backup-') ||
          !files.any((f) => f.name == selected.name && f.id == selected.id)) {
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
    SharedPreferences preferences,
    this.backup,
    this.settings,
    this.local,
    CloudBackupService webdav,
    DriveBackupService drive, {
    this.fixedMode,
    this.createSynchronization = false,
    BackupOperationGate? gate,
    BackupAccounts? accounts,
    this.startAfter,
    required this.sources,
    this.databaseSources = const [],
    this.resourceSources = const [],
    required this.apply,
    Future<Directory> Function()? directory,
    DateTime Function()? now,
    BackupStorage Function(bool)? storageFactory,
    this.work,
    this.nativeSync = const NativeSync(),
    Future<Map?> Function()? identityLoader,
  }) : preferences = fixedMode == null
           ? preferences
           : BackupPreferences(preferences, fixedMode.name),
       _webdav = webdav,
       _drive = drive,
       gate = gate ?? (createSynchronization ? BackupOperationGate() : null),
       accounts =
           accounts ??
           (createSynchronization
               ? BackupAccounts(preferences, webdav, drive)
               : null),
       identityLoader =
           identityLoader ??
           (() =>
               const BridgeChannel('me.efesser.flauncher/method')
                   .invokeMethod<Map>('getBackupDeviceIdentity')),
       directory = directory ?? getApplicationDocumentsDirectory,
       now = now ?? DateTime.now,
       storageFactory = storageFactory {
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    final savedTimes = this.preferences.getString(
      'backup_transport_change_times',
    );
    if (savedTimes != null) {
      try {
        _changeTimes.addAll(
          (jsonDecode(savedTimes) as Map).cast<String, int>(),
        );
      } catch (diagnosticError, diagnosticStack) {
        DiagnosticsStore.instance.recordException(
          'backupAutomationService',
          diagnosticError,
          diagnosticStack,
        );
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
    _listenAccounts();
    initialized = _initialize();
    this.gate?.addListener(_localChanged);
    if (createSynchronization) {
      synchronization = BackupAutomationService(
        preferences,
        backup,
        settings,
        local,
        webdav,
        drive,
        fixedMode: BackupMode.synchronization,
        gate: this.gate,
        accounts: this.accounts,
        startAfter: initialized,
        sources: sources,
        databaseSources: databaseSources,
        resourceSources: resourceSources,
        apply: apply,
        directory: this.directory,
        now: this.now,
        storageFactory: storageFactory,
        work: work,
        nativeSync: nativeSync,
        identityLoader: this.identityLoader,
      );
    }
  }
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _localChanged() {
    _notify();
    _schedule();
  }

  Map<String, Object?> _settingsValues() => BackupSyncDocument.parts({
    'settings': <String, Object?>{
      ...settings.exportSettingsMap(),
      for (final key in preferences.getKeys())
        if (!isDeviceLocalBackupKey(key)) key: preferences.get(key),
    }..removeWhere((key, _) => isDeviceLocalBackupKey(key)),
  });

  Map<String, String> _settingsHashes() {
    final values = _settingsValues();
    final keys = values.keys
        .where((key) => !isDeviceLocalBackupKey(key))
        .toSet();
    _hashes.removeWhere((key, _) => !keys.contains(key));
    _hashValues.removeWhere((key, _) => !keys.contains(key));
    for (final key in keys) {
      final value = values[key];
      if (!_hashes.containsKey(key) ||
          !const DeepCollectionEquality().equals(value, _hashValues[key])) {
        _hashes[key] = backupFingerprint(value);
        // SharedPreferences string lists must not mutate the comparison baseline.
        _hashValues[key] = value is List ? List.of(value) : value;
      }
    }
    return {for (final key in keys) key: _hashes[key]!};
  }

  Future<File> _stateFile() async => File(
    '${(await directory()).path}/backup_sync_state${fixedMode == null ? '' : '_${fixedMode!.name}'}.json',
  );
  Future<void> _initialize() async {
    try {
      await startAfter;
      busy = true;
      if (preferences case BackupPreferences scoped) await scoped.migrate();
      _listenAccounts();
      final migratedTimes = preferences.getString(
        'backup_transport_change_times',
      );
      if (migratedTimes != null) {
        _changeTimes.addAll(
          (jsonDecode(migratedTimes) as Map).cast<String, int>(),
        );
      }
      await _recoverSyncTransaction();
      // The native bridge returns a domain-separated hash, never raw Android ID.
      try {
        final identity = await identityLoader().timeout(
          const Duration(seconds: 5),
        );
        final id = identity?['id'];
        final label = identity?['label'];
        if (id is String && RegExp(r'^[a-f0-9]{32}$').hasMatch(id)) {
          await _set('backup_transport_device', id);
        }
        if (label is String &&
            RegExp(r'^[A-Za-z0-9_]{1,64}$').hasMatch(label)) {
          await _set('backup_transport_device_label', label);
        }
      } catch (diagnosticError, diagnosticStack) {
        DiagnosticsStore.instance.recordException(
          'backupAutomationService',
          diagnosticError,
          diagnosticStack,
        );
        // Keep the installation ID when the firmware cannot supply an identity.
      }
      if (preferences.getString('backup_transport_device') == null) {
        await _set('backup_transport_device', _random(16));
      }
      final file = await _stateFile();
      if (fixedMode != null && setupComplete && !await file.exists()) {
        final legacy = File(
          '${(await directory()).path}/backup_sync_state.json',
        );
        if (await legacy.exists()) await legacy.copy(file.path);
      }
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
        _stateContext = state['context'] as String?;
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
        if (destination == BackupDestination.smb)
          smb.refreshAccount().catchError((_) {}),
        if (destination == BackupDestination.yandexDisk)
          yandex.refreshAccount().catchError((_) {}),
      ]);
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'backupAutomationService',
        diagnosticError,
        diagnosticStack,
      );
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
    if (fixedMode != null && mode != null && mode != fixedMode) {
      throw ArgumentError('Independent mode');
    }
    final needsSyncSetup =
        (mode ?? this.mode) == BackupMode.synchronization &&
        ((mode != null && mode != this.mode) ||
            (destination != null && destination != this.destination) ||
            (shared != null && shared != this.shared));
    if (needsSyncSetup && this.enabled) {
      await _set('backup_transport_enabled', false);
    }
    if (destination != null) {
      await _set('backup_transport_destination', destination.index);
    }
    _listenAccounts();
    if (this.destination == BackupDestination.smb) await smb.refreshAccount();
    if (this.destination == BackupDestination.yandexDisk) {
      await yandex.refreshAccount();
    }
    if (mode != null) await _set('backup_transport_mode', mode.index);
    if (shared != null) await _set('backup_transport_shared', shared);
    if (enabled != null && !needsSyncSetup) {
      await _set('backup_transport_enabled', enabled);
    }
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
    if (!databaseSources.contains(source) &&
        !resourceSources.contains(source) &&
        const DeepCollectionEquality().equals(_settingsValues(), _hashValues)) {
      return;
    }
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
        databaseSources.any(sources.contains) ||
        resourceSources.any(sources.contains);
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
    if (resourceSources.any(sources.contains)) {
      _changeTimes['resources'] = stamp;
    }
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
    _capturedNative = await nativeSync.capture();
    (data['settings'] as Map).addAll(_capturedNative);
    return captureBackup(
      data,
      _baseline,
      device,
      _baseline == null ? DateTime.fromMillisecondsSinceEpoch(0) : now(),
      {
        ..._changeTimes,
        for (final e in (await nativeSync.changeTimes()).entries)
          if (_capturedNative.containsKey(e.key)) 'setting:${e.key}': e.value,
      },
    );
  }

  Future<Map<String, dynamic>> _readTransfer(File file) async {
    await protection.transform(file, encrypt: false);
    return readBackupJson(file.path);
  }

  Future<void> _saveBaseline(BackupSyncDocument document) async {
    final file = await _stateFile();
    final pending = File('${file.path}.partial');
    final fingerprint = await fingerprintBackup(document.backup);
    await pending.writeAsString(
      jsonEncode({
        'stateVersion': 1,
        'context': _stateContext,
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
    if (_disposed || !_foreground || busy || _setupActive) return;
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
    if (_disposed || !_foreground || !enabled || busy || _setupActive) {
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
    if (_disposed || !_foreground || busy || !enabled || _setupActive) {
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

  Future<bool> resumeSynchronization(
    ChooseBackupSyncResume choose, {
    bool enable = true,
  }) => _run(manual: true, choose: choose, enableAfterSync: enable);

  Future<bool> run({bool manual = false, bool exportOnly = false}) =>
      _run(manual: manual, exportOnly: exportOnly);

  Future<bool> _run({
    required bool manual,
    bool exportOnly = false,
    ChooseBackupSyncResume? choose,
    bool enableAfterSync = false,
  }) async {
    await initialized;
    if (_disposed ||
        !_foreground ||
        busy ||
        !manual && (!enabled || _setupActive)) {
      return false;
    }
    if (choose != null && (enabled || mode != BackupMode.synchronization)) {
      return false;
    }
    _flushChanges();
    busy = true;
    failed = false;
    cleanupFailed = false;
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
      await _recoverSyncTransaction();
      await _pendingTimes;
      final context = backupFingerprint([
        destination.name,
        scope,
        localFolder,
        accountId(destination),
        if (destination != BackupDestination.local)
          await nativeSync.identity(
                destination == BackupDestination.smb
                    ? 'smb'
                    : destination == BackupDestination.yandexDisk
                    ? 'yandex'
                    : destination == BackupDestination.webdav
                    ? 'webdav'
                    : 'drive',
                profile: accountId(destination),
              ) ??
              '${webdav.account.url}/${webdav.account.user}/${drive.clientId}',
      ]);
      final updateHistory = !exportOnly || mode == BackupMode.backup;
      if (updateHistory && _stateContext != null && context != _stateContext) {
        _baseline = null;
        _baselineFingerprint = null;
        _changeTimes.clear();
        await _set('backup_transport_change_times', '{}');
        for (final key in preferences.getKeys().where(
          (key) => key.startsWith('sync_member_'),
        )) {
          await preferences.remove(key);
        }
      }
      if (updateHistory) _stateContext = context;
      if (operationMode == BackupMode.synchronization && _syncStateBroken) {
        throw StateError(
          'Damaged local sync history; import a server copy first',
        );
      }
      final captureRevision = _revision;
      var localDocument = await _capture(root);
      if (_disposed || !_foreground || captureRevision != _revision) {
        throw StateError('Local settings changed during capture');
      }
      final originalDocument = localDocument;
      final originalFingerprint =
          operationMode == BackupMode.synchronization || _baseline != null
          ? await fingerprintBackup(localDocument.backup)
          : null;
      final unchanged =
          _baseline != null && originalFingerprint == _baselineFingerprint;
      if (!manual &&
          operationMode == BackupMode.backup &&
          unchanged &&
          lastSuccess != null) {
        await _set(
          'backup_transport_checked_${destination.name}_${operationMode.name}',
          now().millisecondsSinceEpoch,
        );
        return true;
      }
      if (operationMode == BackupMode.synchronization && choose == null) {
        await _saveBaseline(localDocument);
      }
      final files = await storage.list();
      final prefix =
          'cute-${operationMode == BackupMode.backup ? 'backup' : 'sync'}-$scope-';
      var applyChanges = false;
      if (operationMode == BackupMode.synchronization) {
        final rawHeads = _syncHeads(files, prefix);
        final heads = await _activeSyncHeads(
          rawHeads,
          originalDocument,
          storage,
          root,
        );
        if (choose == null) {
          for (final file in heads.values) {
            final downloaded = await storage.download(file, root);
            localDocument = await mergeBackup(
              localDocument,
              await _readTransfer(downloaded),
            );
            await downloaded.delete();
          }
          localDocument = await preserveBackupGroups(
            localDocument,
            originalDocument,
          );
        }
        var confirmed = false;
        if (choose != null && heads.isNotEmpty) {
          final prepared = await _prepareResume(
            originalDocument,
            originalFingerprint!,
            heads,
            storage,
            root,
            prefix,
            captureRevision,
            choose,
            _headsSignature(rawHeads),
          );
          if (prepared == null) return false;
          (localDocument, confirmed) = prepared;
        }
        _requireSyncRevision(captureRevision);
        applyChanges =
            await fingerprintBackup(localDocument.backup) !=
            originalFingerprint;
        if (confirmed || applyChanges) {
          if (!await local.createNow()) {
            throw StateError('Restore point failed');
          }
        }
      }
      if (_disposed ||
          !_foreground ||
          choose != null && captureRevision != _revision) {
        throw StateError('Cancelled');
      }
      final stamp = max(
        now().millisecondsSinceEpoch,
        (preferences.getInt('backup_transport_sequence') ?? 0) + 1,
      );
      await _set('backup_transport_sequence', stamp);
      final name = '$prefix$device-$stamp-${_random(8)}-$deviceLabel.json';
      final upload = File('${root.path}/upload.json');
      await writeBackupJson(
        upload.path,
        operationMode == BackupMode.backup
            ? localDocument.backup
            : localDocument.toJson(),
      );
      if (operationMode == BackupMode.synchronization) {
        _requireSyncRevision(captureRevision);
      }
      if (operationMode == BackupMode.synchronization) {
        await nativeSync.validate(_nativeValues(localDocument));
        await _requireNativeUnchanged();
      }
      await protection.transform(upload, encrypt: true);
      await storage.upload(upload, name);
      if (operationMode == BackupMode.synchronization) {
        _requireSyncRevision(captureRevision);
        if (applyChanges) {
          await _applySyncDocument(localDocument, root, captureRevision);
        }
        await _saveBaseline(localDocument);
      }
      if (operationMode == BackupMode.backup && mode == BackupMode.backup) {
        await _saveBaseline(localDocument);
      }
      if (operationMode == mode) {
        await _set(
          'backup_transport_success_${destination.name}',
          now().millisecondsSinceEpoch,
        );
      }
      await _set(
        'backup_transport_checked_${destination.name}_${operationMode.name}',
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
        try {
          await storage.delete(old);
        } catch (_) {
          cleanupFailed = true;
        }
      }
      if (enableAfterSync) await _set('backup_transport_enabled', true);
      return true;
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'backupAutomationService',
        diagnosticError,
        diagnosticStack,
      );
      failed = true;
      return false;
    } finally {
      _storage = null;
      busy = false;
      try {
        await stage?.delete(recursive: true);
      } catch (diagnosticError, diagnosticStack) {
        DiagnosticsStore.instance.recordException(
          'backupAutomationService',
          diagnosticError,
          diagnosticStack,
        );
        failed = true;
      }
      _notify();
      _schedule();
    }
  }

  Future<void> _applySyncDocument(
    BackupSyncDocument document,
    Directory root,
    int revision,
  ) async {
    _requireSyncRevision(revision);
    final file = File('${root.path}/merged.json');
    final undo = File('${(await directory()).path}/sync-rollback.json');
    final committed = File('${undo.path}.committed');
    final pending = File('${undo.path}.partial');
    await backup.writeBackupTo(
      pending,
      settingsService: settings,
      validateStructure: true,
    );
    await pending.rename(undo.path);
    await writeBackupJson(file.path, document.backup);
    _requireSyncRevision(revision);
    _applying = true;
    try {
      await _requireNativeUnchanged();
      await nativeSync.begin(_nativeValues(document));
      await apply(file);
      await undo.rename(committed.path);
      await nativeSync.commit();
      await committed.delete();
      await webdav.refreshAccount();
      await drive.refreshAccount();
      _observedSettings
        ..clear()
        ..addAll(_settingsHashes());
    } catch (_) {
      if (await undo.exists()) {
        await nativeSync.rollback();
        await apply(undo);
        await undo.delete();
      }
      rethrow;
    } finally {
      _applying = false;
    }
  }

  Future<void> _requireNativeUnchanged() async {
    if (!const DeepCollectionEquality().equals(
      await nativeSync.capture(),
      _capturedNative,
    )) {
      throw StateError('Native settings changed during synchronization');
    }
  }

  Future<void> _recoverSyncTransaction() async {
    final undo = File('${(await directory()).path}/sync-rollback.json');
    final committed = File('${undo.path}.committed');
    _applying = true;
    try {
      if (await committed.exists()) {
        await nativeSync.commit();
        await committed.delete();
        await webdav.refreshAccount();
        await drive.refreshAccount();
      } else if (await undo.exists()) {
        await nativeSync.rollback();
        await apply(undo);
        await undo.delete();
      } else {
        await nativeSync.rollback();
      }
    } finally {
      _applying = false;
    }
  }

  static Map<String, String> _nativeValues(BackupSyncDocument document) => {
    for (final e in (document.backup['settings'] as Map).entries)
      if (isNativeSyncKey(e.key as String)) e.key as String: e.value as String,
  };

  Future<(BackupSyncDocument, bool)?> _prepareResume(
    BackupSyncDocument original,
    String originalFingerprint,
    Map<String, RemoteBackupFile> heads,
    BackupStorage storage,
    Directory root,
    String prefix,
    int revision,
    ChooseBackupSyncResume choose,
    String headsSignature,
  ) async {
    var remote = BackupSyncDocument({'version': 3, 'settings': {}}, {});
    var common = <String, dynamic>{};
    for (final entry in heads.entries) {
      final downloaded = await storage.download(entry.value, root);
      final (merged, own) = await mergeRemoteBackup(
        remote,
        await _readTransfer(downloaded),
        entry.key == device,
      );
      remote = merged;
      if (own != null) common = own;
      await downloaded.delete();
    }
    final candidate = await resumeBackup(
      original,
      remote,
      common,
      BackupSyncResumeChoice.remote,
      device,
    );
    if (await fingerprintBackup(candidate.backup) == originalFingerprint) {
      return (candidate, false);
    }
    _requireSyncRevision(revision);
    final latest = heads.values.reduce((a, b) => _stamp(a) > _stamp(b) ? a : b);
    final previous = heads[device];
    final choice = await choose(
      previous == null ? null : createdAt(previous),
      createdAt(latest),
    );
    if (choice == null) return null;
    _requireSyncRevision(revision);
    final current = _syncHeads(await storage.list(), prefix);
    if (_headsSignature(current) != headsSignature) {
      throw StateError('Remote settings changed during synchronization');
    }
    if (choice == BackupSyncResumeChoice.remote) return (candidate, true);
    return (await resumeBackup(original, remote, common, choice, device), true);
  }

  void _requireSyncRevision(int revision) {
    if (_disposed || !_foreground || revision != _revision) {
      throw StateError('Local settings changed during synchronization');
    }
  }

  static Map<String, RemoteBackupFile> _syncHeads(
    List<RemoteBackupFile> files,
    String prefix,
  ) {
    final heads = <String, RemoteBackupFile>{};
    for (final file in files.where((file) => file.name.startsWith(prefix))) {
      final id = file.name.substring(prefix.length, prefix.length + 32);
      final previous = heads[id];
      if (previous == null || _compareFiles(file, previous) > 0) {
        heads[id] = file;
      }
    }
    return heads;
  }

  static int _compareFiles(RemoteBackupFile a, RemoteBackupFile b) {
    final stamp = _stamp(a).compareTo(_stamp(b));
    if (stamp != 0) return stamp;
    final name = a.name.compareTo(b.name);
    return name == 0 ? a.id.compareTo(b.id) : name;
  }

  static String _headsSignature(Map<String, RemoteBackupFile> heads) =>
      backupFingerprint({
        for (final entry in heads.entries)
          entry.key: [entry.value.name, entry.value.id],
      });

  Future<Map<String, RemoteBackupFile>> _activeSyncHeads(
    Map<String, RemoteBackupFile> heads,
    BackupSyncDocument localDocument,
    BackupStorage storage,
    Directory root,
  ) async {
    if (heads.length > 64) {
      throw StateError('Too many synchronization participants');
    }
    final membership = <String, (Map, bool)>{};
    void collect(BackupSyncDocument doc) {
      final values = doc.backup['settings'] as Map;
      for (final e in doc.revisions.entries) {
        if (!e.key.startsWith('setting:sync_member_')) continue;
        final id = e.key.substring('setting:sync_member_'.length);
        if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(id)) {
          throw const FormatException('Invalid participant');
        }
        final value = values['sync_member_$id'];
        if (value != null && value is! bool) {
          throw const FormatException('Invalid participant state');
        }
        final revision = e.value as Map, old = membership[id]?.$1;
        if (old == null ||
            revision['time'] > old['time'] ||
            revision['time'] == old['time'] &&
                (revision['device'] as String).compareTo(
                      old['device'] as String,
                    ) >
                    0) {
          membership[id] = (revision, value == true);
        }
      }
    }

    collect(localDocument);
    final unreadable = <String>{};
    for (final entry in heads.entries) {
      if (membership[entry.key]?.$2 == true) continue;
      try {
        final downloaded = await storage.download(entry.value, root);
        collect(BackupSyncDocument.parse(await _readTransfer(downloaded)));
        await downloaded.delete();
      } catch (_) {
        unreadable.add(entry.key);
      }
    }
    if (unreadable.any((id) => membership[id]?.$2 != true)) {
      throw StateError('An active synchronization state is unreadable');
    }
    if (membership[device]?.$2 == true) {
      await _set('backup_transport_enabled', false);
      throw StateError('Device excluded from synchronization group');
    }
    return {
      for (final e in heads.entries)
        if (membership[e.key]?.$2 != true) e.key: e.value,
    };
  }

  Future<List<RemoteBackupFile>> synchronizationFiles() async {
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
      return (await storage.list())
          .where((f) => f.name.startsWith('cute-sync-$scope-'))
          .toList()
        ..sort((a, b) => _compareFiles(b, a));
    } finally {
      _storage = null;
      busy = false;
      _notify();
      _schedule();
    }
  }

  Future<void> cleanSynchronizationFiles() async {
    await initialized;
    if (busy || !configured || !_foreground || _disposed) {
      throw StateError('Storage unavailable');
    }
    busy = true;
    cleanupFailed = false;
    _timer?.cancel();
    _notify();
    final storage = _makeStorage();
    _storage = storage;
    Directory? stage;
    try {
      final prefix = 'cute-sync-$scope-$device-';
      final files =
          (await storage.list())
              .where((f) => f.name.startsWith(prefix))
              .toList()
            ..sort((a, b) => _compareFiles(b, a));
      if (files.length > 1) {
        stage = await (await getTemporaryDirectory()).createTemp(
          'sync-cleanup-',
        );
        final current = await storage.download(files.first, stage);
        BackupSyncDocument.parse(await _readTransfer(current));
        for (final old in files.skip(1)) {
          if (_disposed || !_foreground) throw StateError('Cancelled');
          try {
            await storage.delete(old);
          } catch (_) {
            cleanupFailed = true;
          }
        }
      }
      for (final partial in await storage.temporaryFiles()) {
        final name = partial.name.substring(0, partial.name.length - 8);
        if (!name.startsWith(prefix)) continue;
        final stamp = _stamp(RemoteBackupFile(name, partial.id));
        if (stamp >=
                now()
                    .subtract(const Duration(days: 1))
                    .millisecondsSinceEpoch ||
            stamp >= (preferences.getInt('backup_transport_sequence') ?? 0)) {
          continue;
        }
        if (_disposed || !_foreground) throw StateError('Cancelled');
        try {
          await storage.deleteTemporary(partial);
        } catch (_) {
          cleanupFailed = true;
        }
      }
    } finally {
      try {
        await stage?.delete(recursive: true);
      } finally {
        _storage = null;
        busy = false;
        _notify();
        _schedule();
      }
    }
  }

  Future<bool> excludeSyncDevice(RemoteBackupFile selected) async {
    final files = await synchronizationFiles();
    if (!files.any((f) => f.id == selected.id && f.name == selected.name)) {
      throw StateError('Device missing');
    }
    final id = selected.name.split('-')[3];
    if (id == device) throw StateError('Cannot exclude this TV');
    await preferences.setBool('sync_member_$id', true);
    _changed();
    return run(manual: true);
  }

  Future<void> deleteSynchronizationFile(RemoteBackupFile selected) async {
    await initialized;
    if (busy || !configured || !_foreground || _disposed) {
      throw StateError('Storage unavailable');
    }
    if (!selected.name.startsWith('cute-sync-$scope-$device-')) {
      throw StateError('Not owned');
    }
    busy = true;
    _timer?.cancel();
    _notify();
    final storage = _makeStorage();
    _storage = storage;
    try {
      if (!(await storage.list()).any(
        (f) => f.id == selected.id && f.name == selected.name,
      )) {
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

  static String copyDeviceLabel(RemoteBackupFile file) {
    final parts = file.name.replaceFirst(RegExp(r'\.json$'), '').split('-');
    return parts.length == 7
        ? "${parts[6].replaceAll('_', ' ')} · ${parts[3].substring(0, 6)}"
        : 'TV ${parts[3].substring(0, 6)}';
  }

  /// Old mismatching installation IDs cannot identify a different physical TV.
  static bool? copyBelongsToDevice(RemoteBackupFile file, String device) {
    if (!BackupStorage.validName.hasMatch(file.name)) return null;
    final parts = file.name.split('-');
    if (parts[3] == device) return true;
    return parts.length == 7 ? false : null;
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
              .where((f) => f.name.startsWith('cute-backup-'))
              .toList()
            ..sort((a, b) => _stamp(b).compareTo(_stamp(a)));
      return files;
    } finally {
      _storage = null;
      busy = false;
      _notify();
      _schedule();
    }
  }

  Future<void> importLatest({
    RemoteBackupFile? selected,
    bool backupOnly = false,
  }) async {
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
      await _recoverSyncTransaction();
      final files =
          (await storage.list())
              .where(
                (f) => backupOnly
                    ? f.name.startsWith('cute-backup-')
                    : f.name.startsWith('cute-backup-$scope-') ||
                          f.name.startsWith('cute-sync-$scope-'),
              )
              .toList()
            ..sort((a, b) => _stamp(b).compareTo(_stamp(a)));
      if (selected == null && files.isEmpty) {
        throw StateError('No server backup');
      }
      if (selected != null &&
          !files.any((f) => f.name == selected.name && f.id == selected.id)) {
        throw StateError('Copy unavailable');
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
      _capturedNative = await nativeSync.capture();
      await _applySyncDocument(
        BackupSyncDocument(await _readTransfer(file), {}),
        root,
        _revision,
      );
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
      } catch (diagnosticError, diagnosticStack) {
        DiagnosticsStore.instance.recordException(
          'backupAutomationService',
          diagnosticError,
          diagnosticStack,
        );
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
      if (work == null) {
        checkDue();
      } else {
        work!.schedule(_resumeWork, () async {
          await checkDue();
        }, delay: const Duration(seconds: 2));
      }
    } else {
      _timer?.cancel();

      _storage?.cancel();
    }
  }

  @override
  void dispose() {
    synchronization?.dispose();
    gate?.removeListener(_localChanged);
    if (createSynchronization) accounts?.dispose();
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
    _listenedWebdav?.removeListener(_notify);
    _listenedDrive?.removeListener(_notify);
    _listenedYandex?.removeListener(_notify);
    _listenedSmb?.removeListener(_notify);
    _fallbackYandex?.dispose();
    _fallbackSmb?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
