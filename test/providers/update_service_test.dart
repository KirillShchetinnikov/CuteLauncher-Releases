import 'dart:async';
import 'dart:io';

import 'package:flauncher/providers/update_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> release({
  String tag = 'v1.1.0',
  String name = 'CuteLauncher-universal-release.apk',
  String url = 'https://github.com/KirillShchetinnikov/CuteLauncher-Releases/releases/download/v1.1.0/app.apk',
}) => {
  'tag_name': tag,
  'assets': [
    {'name': name, 'size': 3, 'browser_download_url': url},
  ],
};
Future<void> initialized(UpdateService service) async {
  while (!service.initialized) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Versioned APK names select device ABI with universal fallback', () {
    final data = release(tag: 'v1.1.1');
    final asset = (data['assets'] as List).first as Map;
    data['assets'] = [
      for (final abi in ['universal', 'arm64-v8a', 'armeabi-v7a'])
        {
          ...asset,
          'name': 'CuteLauncher-1.1.1-$abi-release.apk',
          'browser_download_url': '${asset['browser_download_url']}?$abi',
        },
    ];
    for (final abi in ['arm64-v8a', 'armeabi-v7a']) {
      expect(AppRelease.parse(data, '1.1.0', 75, [abi])!.uri.query, abi);
    }
    expect(AppRelease.parse(data, '1.1.0', 75, ['x86_64'])!.uri.query, 'universal');
  });
  test('New version tags win over older tags with a build suffix', () {
    final data = {
      'releases': [release(tag: 'v1.1.0+75'), release(tag: 'v1.1.1')],
    };
    expect(
      AppRelease.parse(data, '1.0.0', 70, ['armeabi-v7a'])!.version,
      'v1.1.1',
    );
  });
  test('Pending notice survives restart, is consumed once and ignores repeated checks', () async {
    SharedPreferences.setMockInitialValues({
      automaticUpdatesKey: true,
      updateCheckTimeKey: DateTime.now().millisecondsSinceEpoch,
    });
    final prefs = await SharedPreferences.getInstance();
    var tag = 'v1.0.0+3';
    var requests = 0;
    UpdateService create({int build = 2}) => UpdateService(
      prefs,
      environment: () async => {
        'play': false,
        'version': '1.0.0',
        'versionCode': build,
        'abis': ['armeabi-v7a'],
      },
      lookup: () async {
        requests++;
        return release(tag: tag);
      },
    );
    final first = create();
    await initialized(first);
    await first.check(force: true);
    first.dispose();
    final restarted = create();
    await initialized(restarted);
    expect(requests, 1);
    expect(restarted.takeUpdateNotification(), 'v1.0.0+3');
    expect(restarted.takeUpdateNotification(), isNull);
    await restarted.check(force: true);
    expect(restarted.takeUpdateNotification(), isNull);
    tag = 'v1.0.0+4';
    await restarted.check(force: true);
    expect(restarted.takeUpdateNotification(), 'v1.0.0+4');
    tag = 'v1.0.0+5';
    await restarted.check(force: true);
    restarted.dispose();
    final upgraded = create(build: 5);
    await initialized(upgraded);
    expect(upgraded.takeUpdateNotification(), isNull);
    upgraded.dispose();
  });

  test(
    'Disabled notices and explicit checks do not queue automatic notices',
    () async {
      SharedPreferences.setMockInitialValues({
        automaticUpdatesKey: true,
        updateCheckTimeKey: DateTime.now().millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = UpdateService(
        prefs,
        environment: () async => {
          'play': false,
          'version': '1.0.0',
          'versionCode': 2,
          'abis': ['armeabi-v7a'],
        },
        lookup: () async => release(tag: 'v1.0.0+3'),
      );
      addTearDown(service.dispose);
      await initialized(service);
      await service.check(force: true, notify: false);
      expect(service.takeUpdateNotification(), isNull);
      await service.check(force: true);
      await service.setNotificationsEnabled(false);
      expect(service.takeUpdateNotification(), isNull);
      await service.setNotificationsEnabled(true);
      expect(service.takeUpdateNotification(), isNull);
      await service.check(force: true);
      await service.setAutomatic(false);
      expect(service.takeUpdateNotification(), isNull);
      await service.setAutomatic(true);
      expect(service.takeUpdateNotification(), isNull);
    },
  );
  test(
    'Channel persists, bypasses daily delay and clears cached prerelease',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var requests = 0;
      final service = UpdateService(
        prefs,
        environment: () async => {
          'play': false,
          'version': '1.0.0',
          'versionCode': 2,
          'abis': ['armeabi-v7a'],
        },
        lookup: () async {
          requests++;
          return {
            'releases': [
              release(tag: 'v1.0.0+3'),
              {...release(tag: 'v1.0.0-test.1+4'), 'prerelease': true},
            ],
          };
        },
      );
      addTearDown(service.dispose);
      await initialized(service);
      expect(service.prereleases, isFalse);
      await service.check(force: true);
      expect(service.release!.version, 'v1.0.0+3');
      expect(service.hasUpdateNotification, isFalse);
      await service.setAutomatic(true);
      expect(service.hasUpdateNotification, isTrue);
      await service.setNotificationsEnabled(false);
      expect(service.hasUpdateNotification, isFalse);
      expect(service.automatic, isTrue);
      expect(service.release, isNotNull);
      expect(prefs.getBool(updateNotificationsKey), isFalse);
      await service.setNotificationsEnabled(true);
      expect(service.hasUpdateNotification, isTrue);
      expect(requests, 1);
      await service.setPrereleases(true);
      expect(service.release!.version, 'v1.0.0-test.1+4');
      expect(prefs.getBool(prereleaseUpdatesKey), isTrue);
      service.ready = true;
      await service.setPrereleases(false);
      expect(service.release!.version, 'v1.0.0+3');
      expect(service.ready, isFalse);
      expect(requests, 3);
      await service.check();
      expect(requests, 3);
      await service.setAutomatic(false);
      expect(service.hasUpdateNotification, isFalse);
    },
  );
  test(
    'Due automatic check shows notice only for a compatible newer release',
    () async {
      SharedPreferences.setMockInitialValues({
        automaticUpdatesKey: true,
        updateCheckTimeKey: DateTime.now().millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic>? result = release();
      final service = UpdateService(
        prefs,
        environment: () async => {
          'play': false,
          'version': '1.0.0',
          'versionCode': 2,
          'abis': ['armeabi-v7a'],
        },
        lookup: () async => result,
      );
      addTearDown(service.dispose);
      await initialized(service);
      expect(service.hasUpdateNotification, isFalse);
      await prefs.setInt(
        updateCheckTimeKey,
        DateTime.now()
            .subtract(const Duration(hours: 25))
            .millisecondsSinceEpoch,
      );
      await service.check();
      expect(service.hasUpdateNotification, isTrue);
      result = null;
      await service.check(force: true);
      expect(service.hasUpdateNotification, isFalse);
    },
  );
  test('Release selection compares versions and accepts only compatible APKs from our repository', () {
    expect(
      AppRelease.parse(release(), '1.0.0', 2, ['armeabi-v7a'])?.version,
      'v1.1.0',
    );
    expect(
      AppRelease.parse(release(tag: 'v1.0.0'), '1.0.0', 2, ['armeabi-v7a']),
      isNull,
    );
    expect(
      AppRelease.parse(release(tag: 'v1.0.0+3'), '1.0.0', 2, ['armeabi-v7a']),
      isNotNull,
    );
    expect(
      AppRelease.parse(release(tag: 'v1.1.0-beta'), '1.0.0', 2, [
        'armeabi-v7a',
      ]),
      isNull,
    );
    expect(
      AppRelease.parse(
        release(name: 'CuteLauncher-arm64-v8a-release.apk'),
        '1.0.0',
        2,
        ['armeabi-v7a'],
      ),
      isNull,
    );
    expect(
      AppRelease.parse(
        release(
          url: 'https://github.com/other/project/releases/download/v1.1.0/app.apk',
        ),
        '1.0.0',
        2,
        ['armeabi-v7a'],
      ),
      isNull,
    );
    final huge = release();
    expect(
      AppRelease.parse(
        release(
          url: 'https://github.com/KirillShchetinnikov/CuteLauncher/releases/download/v1.1.0/app.apk',
        ),
        '1.0.0',
        2,
        ['armeabi-v7a'],
      ),
      isNull,
    );
    (huge['assets'] as List).first['size'] = maximumUpdateBytes + 1;
    expect(AppRelease.parse(huge, '1.0.0', 2, ['armeabi-v7a']), isNull);
  });
  test('ABI APK is preferred in device order, with universal fallback', () {
    final data = release(tag: 'v1.0.0-test.1+15');
    final universal = (data['assets'] as List).first as Map;
    data['prerelease'] = true;
    data['assets'] = [
      universal,
      {
        ...universal,
        'name': 'CuteLauncher-armeabi-v7a-release.apk',
        'browser_download_url': '${universal['browser_download_url']}?arm',
      },
      {
        ...universal,
        'name': 'CuteLauncher-arm64-v8a-release.apk',
        'browser_download_url': '${universal['browser_download_url']}?arm64',
      },
    ];
    expect(
      AppRelease.parse(data, '1.0.0', 14, [
        'arm64-v8a',
        'armeabi-v7a',
      ], includePrereleases: true)!.uri.query,
      'arm64',
    );
    expect(
      AppRelease.parse(data, '1.0.0', 14, [
        'armeabi-v7a',
      ], includePrereleases: true)!.uri.query,
      'arm',
    );
    expect(
      AppRelease.parse(data, '1.0.0', 14, [
        'x86_64',
      ], includePrereleases: true)!.uri.query,
      isEmpty,
    );
    expect(AppRelease.parse(data, '1.0.0', 15, ['arm64-v8a']), isNull);
    expect(
      AppRelease.parse(release(tag: 'v2.0.0+13'), '1.0.0', 14, ['arm64-v8a']),
      isNull,
    );
  });
  test(
    'Newest build includes prereleases, skips drafts and incompatible releases',
    () {
      final data = {
        'releases': [
          release(tag: 'v1.0.0+15'),
          {...release(tag: 'v1.0.0-test.1+16'), 'prerelease': true},
          {...release(tag: 'v1.0.0+17'), 'draft': true},
          release(tag: 'v1.0.0+18', name: 'CuteLauncher-x86_64-release.apk'),
        ],
      };
      expect(
        AppRelease.parse(data, '1.0.0', 14, ['armeabi-v7a'])!.version,
        'v1.0.0+15',
      );
      expect(
        AppRelease.parse(data, '1.0.0', 14, [
          'armeabi-v7a',
        ], includePrereleases: true)!.version,
        'v1.0.0-test.1+16',
      );
    },
  );
  test('Play install never checks or downloads even when automatic checking is enabled', () async {
    SharedPreferences.setMockInitialValues({automaticUpdatesKey: true});
    final prefs = await SharedPreferences.getInstance();
    var requests = 0;
    final service = UpdateService(
      prefs,
      environment: () async => {'play': true, 'version': '1.0.0'},
      lookup: () async {
        requests++;
        return release();
      },
    );
    addTearDown(service.dispose);
    await initialized(service);
    await service.check(force: true);
    await service.downloadAndInstall();
    expect(service.fromPlay, isTrue);
    expect(requests, 0);
  });
  test('Checks coalesce, stop in background and respect daily interval; permission retry reuses download', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var requests = 0, downloads = 0, installations = 0;
    final pending = Completer<Map<String, dynamic>?>();
    final service = UpdateService(
      prefs,
      environment: () async => {
        'play': false,
        'version': '1.0.0',
        'versionCode': 2,
        'abis': ['armeabi-v7a'],
        'directory': 'unused',
      },
      lookup: () {
        requests++;
        return pending.future;
      },
      download: (release, root, progress) async {
        downloads++;
        progress(1);
        return File('unused');
      },
      installer: () async => ++installations == 1 ? 'permission' : 'launched',
    );
    addTearDown(service.dispose);
    await initialized(service);
    final check = service.check(force: true);
    await Future<void>.delayed(Duration.zero);
    await service.check(force: true);
    expect(requests, 1);
    pending.complete(release());
    await check;
    await service.check();
    expect(requests, 1);
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    await service.check(force: true);
    expect(requests, 1);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await service.downloadAndInstall();
    expect(service.installStatus, 'permission');
    await service.downloadAndInstall();
    expect(service.installStatus, 'launched');
    expect(downloads, 1);
    expect(installations, 2);
  });
  test(
    'Disposed service does not launch installer after a late download',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final pending = Completer<File>();
      var installations = 0;
      final service = UpdateService(
        prefs,
        environment: () async => {
          'play': false,
          'version': '1.0.0',
          'versionCode': 2,
          'abis': ['armeabi-v7a'],
          'directory': 'unused',
        },
        lookup: () async => release(),
        download: (_, _, _) => pending.future,
        installer: () async {
          installations++;
          return 'launched';
        },
      );
      await initialized(service);
      await service.check(force: true);
      final task = service.downloadAndInstall();
      service.dispose();
      pending.complete(File('unused'));
      await task;
      expect(installations, 0);
    },
  );
}
