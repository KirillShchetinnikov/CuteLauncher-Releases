import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/feed_format.dart';
import 'package:flauncher/models/app_content_channel.dart';
import 'package:flauncher/providers/app_channels_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/settings_import.dart';

import 'support/app_channels.dart';

Future<Uint8List> poster(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const ui.Color(0xff334455), ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late SettingsService settings;
  late FeedChannel channel;
  late AppChannelsService service;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    settings = SettingsService(prefs);
    channel = FeedChannel();
    service = AppChannelsService(channel, settings);
  });
  tearDown(() async {
    service.dispose();
    settings.dispose();
    await channel.events.close();
  });

  test('metadata votes ignore invalid values and ties use landscape', () {
    expect(FeedFormat.majority([2/3, 2/3, 16/9]), FeedFormat.portrait);
    expect(FeedFormat.majority([2/3, 16/9]), FeedFormat.landscape);
    expect(FeedFormat.majority([double.nan, double.infinity, -1, 0]), FeedFormat.landscape);
    final data = feed(1);
    for (final p in data['programs'] as List) { p['posterAspectRatio'] = 2/3; }
    final model = AppContentChannel.fromMap(data);
    expect(service.formatFor(model), FeedFormat.portrait);
    expect(channel.posters, isEmpty);
    final changed = feed(1);
    expect(AppContentChannel.fromMap(changed, previous: model), isNot(same(model)));
  });

  test('three loaded headers choose and persist format without fetching artwork', () async {
    final feedModel = AppContentChannel.fromMap(feed(1));
    final portrait = await poster(40, 60);
    final wide = await poster(80, 45);
    await service.observePoster(feedModel, 100, portrait);
    await service.observePoster(feedModel, 101, wide);
    expect(settings.appChannelFormat(feedModel.key, detected: true), FeedFormat.auto);
    await service.observePoster(feedModel, 102, portrait);
    expect(service.formatFor(feedModel), FeedFormat.portrait);
    expect(SettingsService(prefs).appChannelFormat(feedModel.key, detected: true), FeedFormat.portrait);
    await service.observePoster(feedModel, 100, wide);
    expect(service.formatFor(feedModel), FeedFormat.portrait);
    expect(channel.posters, isEmpty);
    await settings.setAppChannelFormat(feedModel.key, FeedFormat.landscape);
    expect(service.formatFor(feedModel), FeedFormat.landscape);
    await settings.setAppChannelFormat(feedModel.key, FeedFormat.auto);
    expect(service.formatFor(feedModel), FeedFormat.portrait);
    expect(isDeviceLocalBackupKey('app_channel_formats'), isTrue);
    expect(isDeviceLocalBackupKey('app_channel_detected_formats'), isTrue);
  });

  test('missing images do not invent a format and a failed cover has no vote', () async {
    final model = AppContentChannel.fromMap(feed(1));
    await service.observePoster(model, 100, null);
    await service.observePoster(model, 101, await poster(40, 60));
    await service.observePoster(model, 102, Uint8List.fromList([1, 2]));
    expect(service.formatFor(model), FeedFormat.portrait);
    final empty = AppContentChannel.fromMap(feed(2, count: 1));
    await service.observePoster(empty, 200, null);
    expect(settings.appChannelFormat(empty.key, detected: true), FeedFormat.auto);
  });
}
