import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backup_assets.dart';
import '../backup_schedule.dart';
import 'backup_service.dart';
import 'settings_service.dart';
import 'service_lifecycle.dart';

const automaticBackupEnabledKey = 'automatic_backup_enabled';
const automaticBackupCountKey = 'automatic_backup_keep_count';
const automaticBackupTimeKey = 'automatic_backup_last_success';

class AutomaticBackupEntry {
  final File file;
  final DateTime createdAt;
  final int bytes;
  const AutomaticBackupEntry(this.file, this.createdAt, this.bytes);
}

/// Daily foreground snapshots in private storage, independent of public exports.
class AutomaticBackupService extends ChangeNotifier
    with ServiceLifecycle, WidgetsBindingObserver {
  static const interval = Duration(days: 1);
  static const maximumTotalBytes = 256 * 1024 * 1024;
  static final _name = RegExp(r'^auto-(\d+)-(\d+)\.json$');
  final BackupService backup;
  final SettingsService settings;
  final SharedPreferences preferences;
  final Future<Directory> Function() directory;
  final DateTime Function() now;
  late final Future<void> _ready;
  Timer? _timer;
  bool _foreground = true;
  bool _busy = false;
  bool _failed = false;
  int _sequence = 0;
  List<AutomaticBackupEntry> _entries = [];
  int _refresh = 0;
  bool get busy => _busy;
  Future<void> get initialized => _ready;
  bool get failed => _failed;
  bool get enabled => preferences.getBool(automaticBackupEnabledKey) ?? false;
  BackupSchedule get schedule => BackupSchedule(
    frequency: BackupFrequency.values[(preferences.getInt('automatic_backup_frequency') ?? 1).clamp(0, 2)],
    hour: (preferences.getInt('automatic_backup_hour') ?? 3).clamp(0, 23),
    minute: (preferences.getInt('automatic_backup_minute') ?? 0).clamp(0, 59),
    weekday: (preferences.getInt('automatic_backup_weekday') ?? 1).clamp(1, 7),
  );
  Future<void> setSchedule(BackupSchedule value) async {
    for (final entry in {'automatic_backup_frequency': value.frequency.index,
      'automatic_backup_hour': value.hour, 'automatic_backup_minute': value.minute,
      'automatic_backup_weekday': value.weekday}.entries) {
      if (!await preferences.setInt(entry.key, entry.value)) throw StateError('Preference write failed');
    }
    notifyListeners();
    _schedule();
  }
  DateTime? get lastSuccess => _lastSuccess;
  int get keepCount {
    final count = preferences.getInt(automaticBackupCountKey) ?? 5;
    return [1, 3, 5, 10].contains(count) ? count : 5;
  }

  List<AutomaticBackupEntry> get entries => List.unmodifiable(_entries);

  AutomaticBackupService(
    this.backup,
    this.settings,
    this.preferences, {
    Future<Directory> Function()? directory,
    DateTime Function()? now,
  }) : directory = directory ?? getApplicationDocumentsDirectory,
       now = now ?? DateTime.now {
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _ready = _initialize();
  }

  Future<Directory> _root() async {
    final root = Directory(
      path.join((await directory()).path, 'automatic_backups'),
    );
    await root.create(recursive: true);
    return root;
  }

  Future<void> _initialize() async {
    try {
      await _cleanupPending(await _root());
      await _prune();
      await refresh();
    } catch (_) {
      _failed = true;
    }
    notifyListeners();
    _schedule();
  }

  Future<List<AutomaticBackupEntry>> _list() async {
    final result = <AutomaticBackupEntry>[];
    await for (final entity in (await _root()).list(followLinks: false)) {
      if (entity is! File) continue;
      final match = _name.firstMatch(path.basename(entity.path));
      if (match == null) continue;
      final micros = int.tryParse(match[1]!);
      if (micros == null || micros < 0 || micros > 8640000000000000000) {
        continue;
      }
      result.add(
        AutomaticBackupEntry(
          entity,
          DateTime.fromMicrosecondsSinceEpoch(micros),
          await entity.length(),
        ),
      );
    }
    result.sort((a, b) {
      final date = b.createdAt.compareTo(a.createdAt);
      return date != 0 ? date : b.file.path.compareTo(a.file.path);
    });
    return result;
  }

  Future<void> refresh() async {
    if (isDisposed) return;
    final request = ++_refresh;
    try {
      final result = await _list();
      if (isDisposed || request != _refresh) return;
      _entries = result;
    } catch (_) {
      _failed = true;
    }
    notifyListeners();
  }

  Future<void> _cleanupPending(Directory root) async {
    final pending = RegExp(r'^auto-\d+-\d+\.json\.partial$');
    await for (final entity in root.list(followLinks: false)) {
      if (entity is File && pending.hasMatch(path.basename(entity.path))) {
        await entity.delete();
      }
    }
  }

  Future<void> _prune() async {
    if (isDisposed) return;
    var count = 0, bytes = 0;
    for (final entry in await _list()) {
      if (count < keepCount && bytes + entry.bytes <= maximumTotalBytes) {
        ++count;
        bytes += entry.bytes;
      } else {
        if (isDisposed) return;
        await entry.file.delete();
      }
    }
  }

  Future<void> setEnabled(bool value) async {
    await _ready;
    if (isDisposed) return;
    try {
      if (!await preferences.setBool(automaticBackupEnabledKey, value)) {
        throw StateError('Preference write failed');
      }
    } catch (_) {
      _failed = true;
      notifyListeners();
      _schedule();
      return;
    }
    if (!value) _timer?.cancel();
    notifyListeners();
    if (value) await checkDue();
  }

  Future<void> setKeepCount(int value) async {
    if (![1, 3, 5, 10].contains(value)) throw ArgumentError.value(value);
    await _ready;
    if (isDisposed) return;
    try {
      if (!await preferences.setInt(automaticBackupCountKey, value)) {
        throw StateError('Preference write failed');
      }
    } catch (_) {
      _failed = true;
      notifyListeners();
      return;
    }
    if (!_busy) {
      _busy = true;
      notifyListeners();
      try {
        await _prune();
      } catch (_) {
        _failed = true;
      } finally {
        _busy = false;
        _schedule();
      }
    }
    await refresh();
  }

  DateTime? get _lastSuccess {
    final millis = preferences.getInt(automaticBackupTimeKey);
    if (millis == null || millis < 0 || millis > 8640000000000000) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  void _schedule() {
    _timer?.cancel();
    if (isDisposed || !_foreground || !enabled || _busy) return;
    final last = _lastSuccess;
    final remaining = last == null || last.isBefore(schedule.latestSlot(now()))
        ? Duration.zero
        : schedule.nextSlot(now()).difference(now());
    final delay = _failed
        ? const Duration(minutes: 15)
        : Duration(
            milliseconds: remaining.inMilliseconds.clamp(
              10000,
              const Duration(days: 8).inMilliseconds,
            ),
          );
    _timer = Timer(delay, checkDue);
  }

  Future<void> checkDue() async {
    await _ready;
    if (isDisposed || !_foreground || !enabled || _busy) return;
    final last = _lastSuccess;
    if (last == null ||
        last.isBefore(schedule.latestSlot(now())) ||
        now().isBefore(last)) {
      await _capture();
    }
    _schedule();
  }

  /// Also allows an explicit snapshot while the daily schedule is disabled.
  Future<bool> createNow() async {
    await _ready;
    return _capture(manual: true);
  }

  Future<bool> _capture({bool manual = false}) async {
    if (isDisposed || _busy || !_foreground || (!manual && !enabled)) {
      return false;
    }
    _busy = true;
    _failed = false;
    _timer?.cancel();
    notifyListeners();
    File? pending;
    try {
      final root = await _root();
      await _cleanupPending(root);
      final timestamp = now().microsecondsSinceEpoch;
      var target = File(
        path.join(
          root.path,
          'auto-$timestamp-${(_sequence++).toString().padLeft(12, '0')}.json',
        ),
      );
      while (await target.exists()) {
        target = File(
          path.join(
            root.path,
            'auto-$timestamp-${(_sequence++).toString().padLeft(12, '0')}.json',
          ),
        );
      }
      pending = File('${target.path}.partial');
      await backup.writeBackupTo(
        pending,
        settingsService: settings,
        validateStructure: true,
      );
      if (isDisposed || !_foreground || (!manual && !enabled)) return false;
      if (await pending.length() > maximumBackupBytes) {
        throw const FormatException('Oversized backup');
      }
      await pending.rename(target.path);
      pending = null;
      final saved = await preferences.setInt(
        automaticBackupTimeKey,
        now().millisecondsSinceEpoch,
      );
      if (!saved) throw StateError('Preference write failed');
      await _prune();
      return true;
    } catch (_) {
      _failed = true;
      return false;
    } finally {
      try {
        if (pending != null && await pending.exists()) await pending.delete();
      } catch (_) {
        _failed = true;
      }
      _busy = false;
      await refresh();
      _schedule();
    }
  }

  /// Reuse validated, rollback-capable import; keep the chosen snapshot intact.
  Future<void> restore(AutomaticBackupEntry entry) async {
    await _ready;
    if (isDisposed || _busy) {
      throw StateError('Backup operation already running');
    }
    final root = await _root();
    if (!path.equals(
          path.dirname(entry.file.absolute.path),
          root.absolute.path,
        ) ||
        !_name.hasMatch(path.basename(entry.file.path)) ||
        await FileSystemEntity.type(entry.file.path, followLinks: false) !=
            FileSystemEntityType.file) {
      throw const FormatException('Invalid local restore point');
    }
    if (isDisposed || _busy) {
      throw StateError('Backup operation already running');
    }
    _busy = true;
    _failed = false;
    _timer?.cancel();
    notifyListeners();
    try {
      await backup.replaceBackup(entry.file, settings);
      await _prune();
    } catch (_) {
      _failed = true;
      rethrow;
    } finally {
      _busy = false;
      await refresh();
      _schedule();
    }
  }

  Future<void> reloadPreferences() async {
    await _ready;
    if (!_busy) {
      _busy = true;
      try {
        await _prune();
      } catch (_) {
        _failed = true;
      } finally {
        _busy = false;
      }
    }
    await refresh();
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      checkDue();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    ++_refresh;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
