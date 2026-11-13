import 'dart:async';

import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/video_folder_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const channel = MethodChannel('me.efesser.flauncher/method');
  const folder = 'content://test/tree/videos';
  final rows = [
    for (final (name, modified) in [('03', 0), ('02', 9), ('01', 9)])
      {
        'uri': 'file:///storage/videos/$name.mp4',
        'name': '$name.mp4',
        'modified': modified,
        'size': 512,
      },
  ];
  late VideoFolderService service;
  late SettingsService settings;
  late LauncherState launcher;
  late SharedPreferences preferences;
  late int scans;
  late List<String> released;

  Future<void> start(
    WidgetTester tester, {
    String source = videoFolderSource,
    Future<Object?> Function()? list,
  }) async {
    SharedPreferences.setMockInitialValues({
      'background_source': source,
      videoFolderKey: folder,
    });
    preferences = await SharedPreferences.getInstance();
    settings = SettingsService(preferences);
    launcher = LauncherState();
    scans = 0;
    released = [];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'listWallpaperVideos') {
        scans++;
        return list == null ? rows : await list();
      }
      if (call.method == 'releaseWallpaperFolder') {
        released.add(call.arguments['uri'] as String);
      }
      return null;
    });
    service = VideoFolderService(preferences, settings, launcher);
    addTearDown(() {
      service.dispose();
      launcher.dispose();
      settings.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });
    await tester.pump();
  }

  testWidgets('name order, manual skip, completion and a fresh circular scan', (
    tester,
  ) async {
    await start(tester);
    expect(service.clip?.name, '01.mp4');
    await service.next();
    expect(service.clip?.name, '02.mp4');
    service.completed(service.clip!);
    expect(service.clip?.name, '03.mp4');
    service.completed(service.clip!);
    await tester.pump();
    expect(service.clip?.name, '01.mp4');
    expect(scans, 2);
  });

  testWidgets('date order is newest first, tied by name, missing dates last', (
    tester,
  ) async {
    await start(
      tester,
      list: () async => [
        ...rows,
        {
          'uri': 'file:///storage/videos/04.mp4',
          'name': '04.mp4',
          'modified': 10,
          'size': 512,
        },
      ],
    );
    await service.setOrder(VideoFolderOrder.date);
    await tester.pump();
    expect(service.clip?.name, '04.mp4');
    await service.next();
    expect(service.clip?.name, '01.mp4');
    await service.next();
    expect(service.clip?.name, '02.mp4');
    await service.next();
    expect(service.clip?.name, '03.mp4');
  });

  testWidgets(
    'shuffle visits every file and avoids immediate repeats between cycles',
    (tester) async {
      await start(tester);
      await service.setOrder(VideoFolderOrder.random);
      await tester.pump();
      final names = <String>{};
      for (var i = 0; i < 2; i++) {
        names.add(service.clip!.name);
        await service.next();
      }
      final last = service.clip!.name;
      expect({...names, last}, hasLength(3));
      await service.next();
      expect(service.clip!.name, isNot(last));
    },
  );

  testWidgets('all failed files stop the queue until a user retries', (
    tester,
  ) async {
    await start(tester);
    final failed = <String>{};
    for (var i = 0; i < rows.length; i++) {
      final clip = service.clip!;
      failed.add(clip.name);
      service.playbackFailed(clip, true);
      await tester.pump();
    }
    expect(failed, hasLength(rows.length));
    expect(service.failed, isTrue);
    expect(service.clip, isNull);
    await service.next();
    expect(service.clip?.name, '01.mp4');
  });

  testWidgets('inactive sources and hidden Home do not read the directory', (
    tester,
  ) async {
    await start(tester, source: 'gradient');
    expect(scans, 0);
    launcher.toggleLauncherVisibility();
    await settings.setBackgroundSource(videoFolderSource);
    expect(scans, 0);
    launcher.showLauncher();
    await tester.pump();
    final clip = service.clip;
    launcher.toggleLauncherVisibility();
    await service.next();
    expect(service.clip, same(clip));
    expect(scans, 1);
  });

  testWidgets('a late list response cannot apply after changing sources', (
    tester,
  ) async {
    final pending = Completer<Object?>();
    await start(tester, list: () => pending.future);
    expect(service.loading, isTrue);
    await settings.setBackgroundSource('gradient');
    pending.complete(rows);
    await tester.pump();
    expect(service.clip, isNull);
    expect(service.loading, isFalse);
  });

  testWidgets('reset keeps access shared with the image slideshow', (
    tester,
  ) async {
    await start(tester);
    await preferences.setString('slideshow_folder', folder);
    await service.setOrder(VideoFolderOrder.random);
    await service.reset();
    expect(service.folder, isEmpty);
    expect(service.order, VideoFolderOrder.name);
    expect(released, isEmpty);
    expect(isDeviceLocalBackupKey(videoFolderKey), isTrue);
    expect(isDeviceLocalBackupKey(videoFolderOrderKey), isFalse);
  });
}
