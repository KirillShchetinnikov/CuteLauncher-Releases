import 'package:flauncher/bridge_result.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../image_limits.dart';
import 'service_lifecycle.dart';

const automaticUpdatesKey = 'automatic_update_checks';
const updateNotificationsKey = 'show_update_notifications';
const prereleaseUpdatesKey = 'update_prereleases';
const updateCheckTimeKey = 'update_last_check';
const _pendingNotificationKey = 'update_pending_notification';
const _shownNotificationKey = 'update_shown_notification';
const updateRepository = 'KirillShchetinnikov/CuteLauncher-Releases';
const maximumUpdateBytes = 128 * 1024 * 1024;

class AppRelease {
  final String version;
  final Uri uri;
  final int size;
  final String? digest;
  const AppRelease(this.version, this.uri, this.size, this.digest);
  static List<int>? _version(String value) {
    final match = RegExp(
      r'^v?(\d+)\.(\d+)\.(\d+)(?:-[0-9A-Za-z.-]+)?(?:\+(\d+))?$',
    ).firstMatch(value);
    if (match == null) return null;
    return [
      for (var index = 1; index <= 4; index++)
        int.tryParse(match.group(index) ?? '0') ?? 0,
    ];
  }

  static AppRelease? parse(
    Map<String, dynamic> data,
    String installed,
    int build,
    List<String> abis, {
    bool includePrereleases = false,
  }) {
    if (data['releases'] is List) {
      final releases =
          (data['releases'] as List).whereType<Map<String, dynamic>>().toList()
            ..sort((a, b) {
              final av =
                  _version(a['tag_name'] as String? ?? '') ?? [0, 0, 0, 0];
              final bv =
                  _version(b['tag_name'] as String? ?? '') ?? [0, 0, 0, 0];
              // Android accepts updates only with a larger global versionCode.
              for (final index in [3, 0, 1, 2]) {
                final order = bv[index].compareTo(av[index]);
                if (order != 0) return order;
              }
              return 0;
            });
      for (final release in releases) {
        final candidate = parse(
          release,
          installed,
          build,
          abis,
          includePrereleases: includePrereleases,
        );
        if (candidate != null) return candidate;
      }
      return null;
    }
    if (data['draft'] == true) return null;
    final tag = data['tag_name'] as String? ?? '';
    if (!includePrereleases &&
        (data['prerelease'] == true || tag.split('+').first.contains('-'))) {
      return null;
    }
    final next = _version(tag), current = _version(installed);
    if (next == null || current == null) return null;
    if (tag.contains('+') && next[3] <= build) return null;
    current[3] = build;
    var newer = false;
    for (var index = 0; index < 4; index++) {
      if (next[index] == current[index]) continue;
      newer = next[index] > current[index];
      break;
    }
    if (!newer && !tag.contains('+')) return null;
    final candidates = <Map>[];
    for (final item in (data['assets'] as List? ?? [])) {
      if (item is! Map || item['name'] is! String || item['size'] is! int) {
        continue;
      }
      final name = (item['name'] as String).toLowerCase();
      if (!name.endsWith('.apk') ||
          item['size'] <= 0 ||
          item['size'] > maximumUpdateBytes) {
        continue;
      }
      if (name.contains('universal') ||
          name == 'app-release.apk' ||
          abis.any(name.contains)) {
        candidates.add(item);
      }
    }
    int rank(Map item) {
      final name = (item['name'] as String).toLowerCase();
      if (name.contains('universal') || name == 'app-release.apk') {
        return abis.length;
      }
      return abis.indexWhere(name.contains);
    }

    candidates.sort((a, b) => rank(a).compareTo(rank(b)));
    for (final item in candidates) {
      final uri = Uri.tryParse(item['browser_download_url'] as String? ?? '');
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host != 'github.com' ||
          uri.userInfo.isNotEmpty ||
          !uri.path.startsWith('/$updateRepository/releases/download/')) {
        continue;
      }
      final digest = item['digest'] as String?;
      if (digest != null &&
          !RegExp(r'^sha256:[a-fA-F0-9]{64}$').hasMatch(digest)) {
        continue;
      }
      return AppRelease(
        tag,
        uri,
        item['size'] as int,
        digest?.substring(7).toLowerCase(),
      );
    }
    return null;
  }
}

Future<Map<String, dynamic>?> fetchAppRelease() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  try {
    return await (() async {
      final request = await client.getUrl(
        Uri.https('api.github.com', '/repos/$updateRepository/releases', {
          'per_page': '100',
        }),
      );
      request.followRedirects = false;
      request.headers.set(HttpHeaders.userAgentHeader, 'CuteLauncher');
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      final response = await request.close();
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw const FormatException('Release unavailable');
      }
      final bytes = await readBoundedImage(response, limit: 2 * 1024 * 1024);
      return {'releases': jsonDecode(utf8.decode(bytes)) as List};
    })().timeout(const Duration(seconds: 20));
  } finally {
    client.close(force: true);
  }
}

Future<File> downloadAppRelease(
  AppRelease release,
  Directory directory,
  void Function(double) progress,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  final temporary = File('${directory.path}/update.tmp');
  IOSink? sink;
  var cancelled = false;
  try {
    return await (() async {
      await directory.create(recursive: true);
      var uri = release.uri;
      for (var redirects = 0; redirects <= 5; redirects++) {
        if (uri.scheme != 'https' ||
            uri.userInfo.isNotEmpty ||
            !(uri.host == 'github.com' ||
                uri.host.endsWith('.githubusercontent.com'))) {
          throw const FormatException('Invalid download host');
        }
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        final response = await request.close();
        if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location == null) throw const FormatException('Invalid redirect');
          uri = uri.resolve(location);
          await response.drain<void>();
          continue;
        }
        if (response.statusCode != 200 ||
            response.contentLength > maximumUpdateBytes) {
          throw const FormatException('Invalid APK download');
        }
        sink = temporary.openWrite();
        var received = 0;
        await for (final chunk in response) {
          if (cancelled) throw const FormatException('Download cancelled');
          received += chunk.length;
          if (received > release.size || received > maximumUpdateBytes) {
            throw const FormatException('APK too large');
          }
          sink!.add(chunk);
          await sink!.flush();
          progress(received / release.size);
        }
        await sink!.close();
        sink = null;
        if (received != release.size) {
          throw const FormatException('Incomplete APK');
        }
        if (release.digest != null &&
            (await sha256.bind(temporary.openRead()).first).toString() !=
                release.digest) {
          throw const FormatException('APK digest mismatch');
        }
        final target = File('${directory.path}/update.apk');
        final exists = await target.exists();
        if (cancelled) throw const FormatException('Download cancelled');
        if (exists) await target.delete();
        if (cancelled) throw const FormatException('Download cancelled');
        return temporary.rename(target.path);
      }
      throw const FormatException('Too many redirects');
    })().timeout(const Duration(minutes: 5));
  } finally {
    cancelled = true;
    client.close(force: true);
    await sink?.close();
    if (await temporary.exists()) await temporary.delete();
  }
}

typedef UpdateDownload = Future<File> Function(
  AppRelease,
  Directory,
  void Function(double),
);

class UpdateService extends ChangeNotifier
    with ServiceLifecycle, WidgetsBindingObserver {
  static const channel = BridgeChannel('cutelauncher/updates');
  final SharedPreferences preferences;
  final Future<Map<String, dynamic>?> Function() lookup;
  final Future<Map<dynamic, dynamic>?> Function() environment;
  final Future<String?> Function() installer;
  final UpdateDownload download;
  Map<dynamic, dynamic>? _environment;
  bool initialized = false,
      checked = false,
      busy = false,
      failed = false,
      ready = false,
      _foreground = true;
  String? installStatus;
  double? progress;
  AppRelease? release;
  Timer? _timer;
  bool get fromPlay => _environment?['play'] == true;
  bool get automatic => preferences.getBool(automaticUpdatesKey) ?? false;
  bool get prereleases => preferences.getBool(prereleaseUpdatesKey) ?? false;
  bool get notificationsEnabled =>
      preferences.getBool(updateNotificationsKey) ?? true;
  bool get hasUpdateNotification =>
      automatic && notificationsEnabled && !fromPlay && release != null;

  /// Consumes a deferred notice only while the launcher can display it.
  String? takeUpdateNotification() {
    if (!initialized ||
        !automatic ||
        !notificationsEnabled ||
        fromPlay ||
        isDisposed) {
      return null;
    }
    final version = preferences.getString(_pendingNotificationKey);
    if (version == null) return null;
    final next = AppRelease._version(version);
    final current = AppRelease._version(installedVersion);
    final build = _environment?['versionCode'] as int?;
    if (next == null ||
        current == null ||
        build == null ||
        (!prereleases && version.split('+').first.contains('-'))) {
      return null;
    }
    current[3] = build;
    final newer = version.contains('+')
        ? next[3] > build
        : _newerVersion(next, current);
    unawaited(preferences.remove(_pendingNotificationKey));
    if (!newer || preferences.getString(_shownNotificationKey) == version) {
      return null;
    }
    unawaited(preferences.setString(_shownNotificationKey, version));
    return version;
  }

  static bool _newerVersion(List<int> next, List<int> current) {
    for (var i = 0; i < next.length; i++) {
      if (next[i] != current[i]) return next[i] > current[i];
    }
    return false;
  }

  String get installedVersion => _environment?['version'] as String? ?? '';
  List<String> get supportedAbis =>
      List<String>.from(_environment?['abis'] as List? ?? []);
  UpdateService(
    this.preferences, {
    Future<Map<String, dynamic>?> Function()? lookup,
    Future<Map<dynamic, dynamic>?> Function()? environment,
    Future<String?> Function()? installer,
    UpdateDownload? download,
  }) : lookup = lookup ?? fetchAppRelease,
       environment =
           environment ?? (() => channel.invokeMapMethod('environment')),
       installer = installer ?? (() => channel.invokeMethod<String>('install')),
       download = download ?? downloadAppRelease {
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }
  Future<void> _initialize() async {
    try {
      _environment = await environment();
    } catch (_) {
      failed = true;
    }
    if (isDisposed) return;
    initialized = true;
    notifyListeners();
    _schedule();
    if (automatic) check();
  }

  void _schedule() {
    _timer?.cancel();
    if (!isDisposed && _foreground && automatic && !fromPlay) {
      _timer = Timer.periodic(const Duration(hours: 1), (_) => check());
    }
  }

  void reloadPreferences() {
    if (isDisposed) return;
    release = null;
    ready = false;
    checked = false;
    unawaited(preferences.remove(_pendingNotificationKey));
    notifyListeners();
    _schedule();
    if (automatic) check(force: true);
  }

  Future<void> setPrereleases(bool enabled) async {
    if (busy || isDisposed) return;
    await preferences.setBool(prereleaseUpdatesKey, enabled);
    if (isDisposed) return;
    release = null;
    ready = false;
    checked = false;
    await preferences.remove(_pendingNotificationKey);
    if (isDisposed) return;
    notifyListeners();
    await check(force: true);
  }

  Future<void> setAutomatic(bool enabled) async {
    await preferences.setBool(automaticUpdatesKey, enabled);
    if (!enabled) await preferences.remove(_pendingNotificationKey);
    if (isDisposed) return;
    notifyListeners();
    _schedule();
    if (enabled) await check();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await preferences.setBool(updateNotificationsKey, enabled);
    if (!enabled) await preferences.remove(_pendingNotificationKey);
    if (!isDisposed) notifyListeners();
  }

  Future<void> check({bool force = false, bool notify = true}) async {
    if (!initialized ||
        isDisposed ||
        !_foreground ||
        fromPlay ||
        _environment == null ||
        busy) {
      return;
    }
    final last = preferences.getInt(updateCheckTimeKey);
    final elapsed = last == null
        ? null
        : DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last));
    if (!force &&
        elapsed != null &&
        !elapsed.isNegative &&
        elapsed < const Duration(hours: 24)) {
      return;
    }
    busy = true;
    failed = false;
    installStatus = null;
    notifyListeners();
    try {
      // Record attempts as well as success to avoid repeated polling during an outage.
      await preferences.setInt(
        updateCheckTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      final data = await lookup();
      if (isDisposed) return;
      checked = true;
      final next = data == null
          ? null
          : AppRelease.parse(
              data,
              installedVersion,
              _environment!['versionCode'] as int,
              List<String>.from(_environment!['abis'] as List),
              includePrereleases: prereleases,
            );
      if (next?.uri != release?.uri || next?.digest != release?.digest) {
        ready = false;
      }
      release = next;
      if (next == null) {
        await preferences.remove(_pendingNotificationKey);
      } else if (notify &&
          hasUpdateNotification &&
          preferences.getString(_shownNotificationKey) != next.version) {
        await preferences.setString(_pendingNotificationKey, next.version);
      }
    } catch (_) {
      failed = true;
    } finally {
      busy = false;
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> downloadAndInstall() async {
    if (isDisposed ||
        busy ||
        fromPlay ||
        release == null ||
        _environment == null) {
      return;
    }
    busy = true;
    failed = false;
    installStatus = null;
    notifyListeners();
    try {
      if (!ready) {
        progress = 0;
        notifyListeners();
        await download(
          release!,
          Directory(_environment!['directory'] as String),
          (value) {
            if (!isDisposed) {
              if (progress == null || value - progress! >= 0.01 || value == 1) {
                progress = value;
                notifyListeners();
              }
            }
          },
        );
        if (isDisposed) return;
        ready = true;
        progress = null;
        notifyListeners();
      }
      installStatus = await installer();
      if (installStatus == 'invalid') ready = false;
      failed =
          installStatus == null ||
          ['invalid', 'unavailable'].contains(installStatus);
    } catch (_) {
      failed = true;
    } finally {
      busy = false;
      progress = null;
      if (!isDisposed) notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isDisposed) return;
    _foreground = state == AppLifecycleState.resumed;
    _schedule();
    if (_foreground && automatic) check();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
