import 'package:flauncher/weather_sources.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flauncher/models/watch_next_program.dart';
import 'package:flauncher/providers/app_channels_service.dart';
import 'package:flauncher/widgets/app_content_row.dart';
import 'package:flauncher/widgets/reordering_tile_viewport.dart';
import 'package:flauncher/widgets/tile_paint_layer.dart';
import 'package:flauncher/widgets/tile_theme_outline.dart';
import 'support/app_channels.dart';
import 'package:flauncher/widgets/continue_watching_row.dart';
import 'package:flauncher/sleep_timer_configuration.dart';
import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/widgets/wallpaper_background.dart';
import 'package:flauncher/widgets/app_artwork_background.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/widgets/settings/remote_panel_page.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/panel_order_page.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/flauncher.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/providers/update_service.dart';
import 'package:flauncher/gradients.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/home_section.dart';
import 'package:flauncher/widgets/category_focus.dart';

import 'package:flauncher/widgets/app_card.dart';
import 'package:flauncher/widgets/appearance_surface.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flauncher/widgets/background_information.dart';
import 'package:flauncher/widgets/settings/settings_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import 'helpers.dart';
import 'mocks.dart';
import 'mocks.mocks.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  testWidgets('wide feed artwork fills the card when source has letterbox bars', (tester) async {
    final bytes = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const Color(0xff000000), ui.BlendMode.src);
      // A 16:9 thumbnail inside a 4:3 bitmap, as shown on the user's TV.
      canvas.drawRect(const Rect.fromLTWH(0, 45, 480, 270),
          Paint()..color = const Color(0xff20a0e0));
      final picture = recorder.endRecording();
      final image = await picture.toImage(480, 360);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      return data!.buffer.asUint8List();
    });
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    await appearance.set('focusPulse', false);
    final feedSettings = SettingsService(prefs);
    final channel = FeedChannel()
      ..data = [feed(1, count: 1, poster: 'content://poster/letterbox')]
      ..posterResponse = () async => bytes;
    final feeds = AppChannelsService(channel, feedSettings);
    await feedSettings.setSelectedAppChannels(['video.app:1']);
    await tester.runAsync(feeds.refresh);
    final apps = mkAppService();
    when(apps.applications).thenReturn([]);
    when(apps.launcherSections).thenReturn([appChannelsGroup()]);
    final settings = mkSettingsService();
    when(settings.selectedAppChannels).thenReturn(feedSettings.selectedAppChannels);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
        feeds: feeds, appearance: appearance);
    final artwork = find.descendant(of: find.byType(AppContentRow), matching: find.byType(Image)).first;
    await tester.runAsync(() => precacheImage(tester.widget<Image>(artwork).image, tester.element(artwork)));
    await tester.pump();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.ancestor(of: artwork, matching: find.byType(RepaintBoundary)).first);
    final capture = (await tester.runAsync(() => boundary.toImage()))!;
    final pixels = await tester.runAsync(() => capture.toByteData(format: ui.ImageByteFormat.rawRgba));
    for (final point in [const Offset(.1, .5), const Offset(.9, .5),
        const Offset(.5, .1), const Offset(.5, .9), const Offset(.5, .5)]) {
      final index = ((capture.height * point.dy).floor() * capture.width +
          (capture.width * point.dx).floor()) * 4;
      expect(pixels!.buffer.asUint8List().sublist(index, index + 4), [32, 160, 224, 255],
          reason: 'Artwork must reach each edge without black bars or theme margins');
    }
    capture.dispose();
    expect(channel.posters, ['content://poster/letterbox']);
    await tester.pumpWidget(const SizedBox());
    feeds.dispose(); feedSettings.dispose(); appearance.dispose(); await channel.events.close();
  });
  testWidgets('portrait feeds use one stable geometry and remote navigates between formats', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    await appearance.set('focusPulse', false);
    final feedSettings = SettingsService(prefs);
    final data = feed(1, count: 8);
    for (final item in data['programs'] as List) { item['posterAspectRatio'] = 2/3; }
    final channel = FeedChannel()..data = [data, feed(2)];
    final feeds = AppChannelsService(channel, feedSettings);
    await feedSettings.setSelectedAppChannels(['video.app:1', 'video.app:2']);
    await tester.runAsync(feeds.refresh);
    final apps = mkAppService();
    when(apps.applications).thenReturn([]);
    when(apps.launcherSections).thenReturn([appChannelsGroup()]);
    final settings = mkSettingsService();
    when(settings.selectedAppChannels).thenReturn(feedSettings.selectedAppChannels);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
        feeds: feeds, appearance: appearance);
    final row = find.byType(AppContentRow).first;
    final cards = find.descendant(of: row, matching: find.byType(InkWell));
    final art = find.descendant(of: cards.first, matching: find.byType(RaisedTile));
    final size = tester.getSize(art);
    expect(size.aspectRatio, closeTo(2/3, .001));
    tester.widget<InkWell>(cards.first).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(tester.widget<InkWell>(cards.at(1)).focusNode!.hasFocus, isTrue);
    expect(tester.getSize(art), size);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final second = find.descendant(of: find.byType(AppContentRow).at(1), matching: find.byType(InkWell));
    expect(second.evaluate().any((e) => (e.widget as InkWell).focusNode!.hasFocus), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(cards.evaluate().any((e) => (e.widget as InkWell).focusNode!.hasFocus), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    feeds.dispose(); feedSettings.dispose(); appearance.dispose(); await channel.events.close();
  });
  testWidgets('wallpaper information never changes tile viewport or remote navigation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    final remote = RemotePanelService(prefs);
    final apps = mkAppService();
    final category = fakeCategory(name: 'Apps');
    category.applications.add(fakeApp(packageName: 'background.app'));
    when(apps.applications).thenReturn(category.applications);
    when(apps.launcherSections).thenReturn([category]);
    final settings = mkSettingsService();
    when(settings.showTimeInStatusBar).thenReturn(true);
    when(settings.showDateInStatusBar).thenReturn(true);
    when(settings.showWeatherInStatusBar).thenReturn(false);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings, appearance: appearance, remotePanel: remote);
    getFocusNodeForApp(tester, 'background.app')!.requestFocus();
    await tester.pumpAndSettle();
    final card = find.byWidgetPredicate((w) => w is AppCard && w.application.packageName == 'background.app');
    final before = tester.getRect(card);
    for (final size in [96, 144, 48]) {
      await appearance.set('panelInformationPlacements', {'time': 'background', 'date': 'panel', 'weather': 'hidden'});
      await appearance.set('panelBackgroundInformationSize', size);
      await tester.pumpAndSettle();
      expect(tester.getRect(card), before);
      expect(find.byKey(const Key('background_clock')), findsOneWidget);
      expect(find.byKey(const Key('statusbar_clock')), findsNothing);
      expect(find.byKey(const Key('statusbar_date')), findsOneWidget);
      expect(find.descendant(of: find.byType(BackgroundInformation), matching: find.byType(TextButton)), findsNothing);
    }
    // Switching wallpaper sources relocates the one decorative instance,
    // without inserting a header or changing the tile viewport.
    for (final source in ['landscape', 'picture', 'landscape']) {
      when(settings.backgroundSource).thenReturn(source);
      when(settings.landscape).thenReturn(const LandscapeConfiguration(timeOfDay: false, motion: false));
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings, appearance: appearance, remotePanel: remote);
      await tester.pumpAndSettle();
      expect(find.byType(BackgroundInformation), findsOneWidget);
      expect(tester.getRect(card), before);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(isSettingsIconFocused(tester), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'background.app'), isTrue);
    final previewOwner = Object();
    remote.setSettingsPreview(previewOwner, true);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('background_clock')), findsOneWidget);
    expect(find.byKey(const Key('statusbar_clock')), findsOneWidget);
    expect(tester.getRect(card), before);
    remote.setSettingsPreview(previewOwner, false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('statusbar_clock')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    remote.dispose(); appearance.dispose();
  });
  for (final border in ['outline', 'glow']) {
  testWidgets('feed focus pulse does not repaint the shared tile layer or labels: $border', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    await appearance.set('focusPulse', false);
    await appearance.set('focusBorderStyle', border);
    final feedSettings = SettingsService(prefs);
    final channel = FeedChannel()..data = [feed(1, count: 5)];
    final feeds = AppChannelsService(channel, feedSettings);
    await feedSettings.setSelectedAppChannels(['video.app:1']);
    await tester.runAsync(feeds.refresh);
    final apps = mkAppService();
    when(apps.applications).thenReturn([]);
    when(apps.launcherSections).thenReturn([appChannelsGroup()]);
    final settings = mkSettingsService();
    when(settings.appHighlightAnimationEnabled).thenReturn(true);
    when(settings.themes).thenReturn('modern');
    when(settings.selectedAppChannels).thenReturn(feedSettings.selectedAppChannels);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
        feeds: feeds, appearance: appearance);
    await appearance.set('focusPulse', true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final layer = tester.renderObject(find.byType(TilePaintLayer));
    final labels = find.descendant(of: find.byType(AppContentRow), matching: find.byType(RichText))
        .evaluate().map((element) => element.findRenderObject()).toSet();
    var layerPaints = 0, labelPaints = 0, outlinePaints = 0;
    final previous = debugOnProfilePaint;
    debugOnProfilePaint = (object) {
      previous?.call(object);
      if (identical(object, layer)) layerPaints++;
      if (labels.contains(object)) labelPaints++;
      if (object is RenderCustomPaint &&
          (object.painter is TileOutlinePainter || object.painter is TileGlowPainter)) {
        outlinePaints++;
      }
    };
    addTearDown(() => debugOnProfilePaint = previous);
    double opacity() {
      final painter = tester.widget<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint &&
          (w.painter is TileOutlinePainter || w.painter is TileGlowPainter))).painter;
      return painter is TileGlowPainter ? painter.color.a : (painter as TileOutlinePainter).color.a;
    }
    final before = opacity();
    for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 16)); }
    expect(opacity(), isNot(before), reason: 'The selected outline must still animate');
    expect(outlinePaints, greaterThan(10), reason: 'The outline repaints without rebuilding');
    expect(layerPaints, 0, reason: 'A pulse must repaint only the selected artwork');
    expect(labelPaints, 0);
    debugOnProfilePaint = previous;
    await tester.pumpWidget(const SizedBox());
    feeds.dispose(); feedSettings.dispose(); appearance.dispose(); await channel.events.close();
  });
  }
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('feed refresh keeps decoded artwork, cards and focus ${locale.languageCode}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appearance = AppearanceService(prefs);
      await appearance.set('focusPulse', false);
      final feedSettings = SettingsService(prefs);
      final channel = FeedChannel()
        ..data = [feed(1, poster: 'content://poster/shared')]
        ..posterResponse = () async => kTransparentImage;
      final feeds = AppChannelsService(channel, feedSettings);
      await feedSettings.setSelectedAppChannels(['video.app:1']);
      await tester.runAsync(feeds.refresh);
      final apps = mkAppService();
      when(apps.applications).thenReturn([]);
      when(apps.launcherSections).thenReturn([appChannelsGroup()]);
      final settings = mkSettingsService();
      when(settings.selectedAppChannels).thenReturn(feedSettings.selectedAppChannels);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
          feeds: feeds, appearance: appearance, locale: locale);
      final images = find.descendant(of: find.byType(AppContentRow), matching: find.byType(Image));
      Future<void> decoded() async {
        await tester.runAsync(() => precacheImage(tester.widget<Image>(images.first).image, tester.element(images.first)));
        await tester.pump();
      }
      await decoded();
      final image = tester.renderObject<RenderImage>(find.descendant(of: images.first, matching: find.byType(RawImage)));
      final originalImage = image.image;
      expect(originalImage, isNotNull);
      final focus = FocusManager.instance.primaryFocus;
      final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first).controller!;
      final offset = scroll.offset;
      final original = feeds.channels.first;
      var notifications = 0;
      feeds.addListener(() => notifications++);
      void stable() {
        expect(find.byType(AppContentRow), findsOneWidget);
        expect(find.byIcon(Icons.movie_outlined), findsNothing);
        expect(FocusManager.instance.primaryFocus, same(focus));
        expect(scroll.offset, closeTo(offset, .01));
      }
      final catalogue = Completer<List<Map<dynamic, dynamic>>>();
      final poster = Completer<Uint8List?>();
      channel.response = () => catalogue.future;
      channel.posterResponse = () => poster.future;
      channel.events.add(true);
      await tester.pump(const Duration(milliseconds: 16));
      stable();
      expect(image.image, same(originalImage));
      catalogue.complete([feed(1, poster: 'content://poster/shared')]);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        stable();
        expect(image.image, same(originalImage));
      }
      expect(feeds.channels.first, same(original));
      expect(notifications, 0);
      poster.complete(Uint8List.fromList(kTransparentImage));
      await tester.pumpAndSettle();
      stable();
      expect(image.image, same(originalImage));
      // The provider can replace bytes at the same URI without changing metadata.
      final replacement = await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawColor(Colors.red, BlendMode.src);
        final picture = recorder.endRecording();
        final bitmap = await picture.toImage(2, 2);
        final data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        bitmap.dispose(); picture.dispose();
        return data!.buffer.asUint8List();
      });
      channel.response = null;
      final nextPoster = Completer<Uint8List?>();
      channel.posterResponse = () => nextPoster.future;
      channel.events.add(true);
      await tester.pump(const Duration(milliseconds: 16));
      stable();
      expect(image.image, same(originalImage));
      nextPoster.complete(replacement);
      await tester.pump();
      await tester.pump();
      await decoded();
      await tester.pumpAndSettle();
      stable();
      expect(image.image, isNot(same(originalImage)));
      expect(notifications, 0);
      final updatedImage = image.image;
      channel.fail = true;
      channel.events.add(true);
      await tester.pumpAndSettle();
      stable();
      expect(feeds.unavailable, isTrue);
      expect(image.image, same(updatedImage));
      channel.fail = false;
      channel.posterResponse = () async => null;
      channel.events.add(true);
      await tester.pumpAndSettle();
      stable();
      expect(feeds.unavailable, isFalse);
      expect(image.image, same(updatedImage));
      final differentUri = Completer<Uint8List?>();
      channel.posterResponse = () => differentUri.future;
      channel.data = [feed(1, poster: 'content://poster/shared')];
      final programs = channel.data.first['programs'] as List;
      (programs.first as Map)['title'] = 'Updated title';
      (programs.first as Map)['posterArtUri'] = 'content://poster/replacement';
      await tester.runAsync(feeds.refresh);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        stable();
        expect(image.image, same(updatedImage));
      }
      expect(find.text('Updated title'), findsOneWidget);
      expect(feeds.channels.first.programs.last, same(original.programs.last));
      differentUri.complete(kTransparentImage);
      await tester.pump(); await tester.pump(); await decoded();
      stable();
      expect(image.image, isNot(same(updatedImage)));
      channel.data = [feed(1, count: 0)];
      await tester.runAsync(feeds.refresh);
      await tester.pumpAndSettle();
      expect(find.byType(AppContentRow), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      feeds.dispose(); feedSettings.dispose(); appearance.dispose(); await channel.events.close();
    });
  }
  testWidgets('feeds use their section title and supported local appearance', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    await appearance.set('focusPulse', false);
    await appearance.set('sectionTitles', false);
    await appearance.set('aspectRatio', 1);
    final group = appChannelsGroup()..name = 'My recommendations';
    await appearance.setCategory(group.id, 'layout', 'grid');
    await appearance.setCategory(group.id, 'columns', 6);
    for (final entry in <String, dynamic>{'sectionTitles': true, 'sectionIcons': true,
      'size': 96, 'horizontalGap': 34, 'labelSize': 16, 'labelColor': 0xffffd54f,
      'radius': 20, 'sectionPadding': 24, 'sectionBackground': 0xff123456,
      'sectionOpacity': .35, 'sectionRadius': 32}.entries) {
      await appearance.setCategoryTile(group.id, entry.key, entry.value);
    }
    final feedSettings = SettingsService(prefs);
    final channel = FeedChannel()..data = [feed(1, count: 20)];
    final feeds = AppChannelsService(channel, feedSettings);
    await feedSettings.setSelectedAppChannels(['video.app:1']);
    await tester.runAsync(feeds.refresh);
    final apps = mkAppService();
    when(apps.applications).thenReturn([]);
    when(apps.launcherSections).thenReturn([group]);
    final settings = mkSettingsService();
    when(settings.selectedAppChannels).thenReturn(feedSettings.selectedAppChannels);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
        feeds: feeds, appearance: appearance);
    expect(find.text('My recommendations'), findsOneWidget);
    expect(find.text('Feed 1 · video.app'), findsOneWidget);
    expect(find.byIcon(Icons.video_library_outlined), findsOneWidget);
    final container = tester.widget<Container>(find.byKey(const ValueKey('app-channels-group')));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xff123456).withValues(alpha: .35));
    expect(decoration.borderRadius, BorderRadius.circular(32));
    expect(container.clipBehavior, Clip.none);
    expect(container.padding, const EdgeInsets.all(24));
    final viewport = tester.widget<ReorderingTileViewport>(find.descendant(
        of: find.byType(AppContentRow), matching: find.byType(ReorderingTileViewport)));
    expect(viewport.layout.mode, 'row');
    expect(viewport.layout.rows, 1);
    expect(viewport.layout.height, 96);
    expect(viewport.layout.width / viewport.layout.height, closeTo(16 / 9, .001));
    expect(viewport.layout.gapX, 34);
    final caption = tester.widget<Text>(find.text('Content 1/0'));
    expect(caption.style!.fontSize, 16);
    expect(caption.style!.color, const Color(0xffffd54f));
    final restored = AppearanceService(prefs);
    expect(restored.tilesFor(group.id).values, appearance.tilesFor(group.id).values);
    restored.dispose();
    await appearance.setCategoryTile(group.id, 'sectionTitles', false);
    await tester.pumpAndSettle();
    expect(find.text('My recommendations'), findsNothing);
    expect(find.text('Feed 1 · video.app'), findsNothing);
    expect(find.text('Content 1/0'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    feeds.dispose(); feedSettings.dispose(); appearance.dispose(); await channel.events.close();
  });
  testWidgets('feed artwork stays above the viewport while focus scale shrinks', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    await appearance.set('focusPulse', false);
    await appearance.set('focusScale', .5);
    final feedSettings = SettingsService(prefs);
    final channel = FeedChannel()..data = [feed(1, count: 5)];
    final feeds = AppChannelsService(channel, feedSettings);
    await feedSettings.setSelectedAppChannels(['video.app:1']);
    await tester.runAsync(feeds.refresh);
    final apps = mkAppService();
    when(apps.applications).thenReturn([]);
    when(apps.launcherSections).thenReturn([appChannelsGroup()]);
    final settings = mkSettingsService();
    when(settings.appSelectorTransitionAnimationEnabled).thenReturn(true);
    when(settings.appHighlightAnimationEnabled).thenReturn(true);
    when(settings.selectedAppChannels).thenReturn(feedSettings.selectedAppChannels);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
        feeds: feeds, appearance: appearance);
    final cards = find.descendant(of: find.byType(AppContentRow), matching: find.byType(InkWell));
    expect(tester.widget<TileThemeOutline>(find.descendant(
        of: cards.first, matching: find.byType(TileThemeOutline))).pulse, isFalse);
    final oldLayer = find.descendant(of: cards.first, matching: find.byType(RaisedTile));
    tester.widget<InkWell>(cards.at(1)).focusNode!.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.widget<RaisedTile>(oldLayer).raised, isTrue,
        reason: 'The shrinking image must not jump under the viewport clip');
    expect(tester.widget<RaisedTile>(oldLayer).foreground, isFalse);
    await tester.pumpAndSettle();
    expect(tester.widget<RaisedTile>(oldLayer).raised, isFalse);
    await appearance.set('focusTransition', false);
    await tester.pumpAndSettle();
    final animation = find.descendant(of: cards.at(1), matching: find.byType(AnimatedContainer));
    expect(tester.widget<AnimatedContainer>(animation).duration, Duration.zero);
    await tester.pumpWidget(const SizedBox());
    feeds.dispose(); feedSettings.dispose(); appearance.dispose(); await channel.events.close();
  });
  testWidgets('three visited feeds retain nearby cards when reversing from bottom', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    await appearance.set('focusPulse', false);
    await appearance.set('size', 180);
    final feedSettings = SettingsService(prefs);
    final channel = FeedChannel()
      ..data = List.generate(3, (i) => feed(i + 1, count: 20))
      ..posterResponse = () async => kTransparentImage;
    final feeds = AppChannelsService(channel, feedSettings);
    await feedSettings.setSelectedAppChannels(List.generate(3, (i) => 'video.app:${i + 1}'));
    await tester.runAsync(feeds.refresh);
    final apps = mkAppService();
    when(apps.applications).thenReturn([]);
    when(apps.launcherSections).thenReturn([appChannelsGroup()]);
    final settings = mkSettingsService();
    when(settings.selectedAppChannels).thenReturn(feedSettings.selectedAppChannels);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
        feeds: feeds, appearance: appearance, pixelRatio: 2);
    for (var i = 0; i < 2; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    final lastRow = find.byWidgetPredicate((w) => w is AppContentRow && w.channel.id == 3);
    Set<Element> lastCards() => find.descendant(of: lastRow, matching: find.byType(InkWell)).evaluate().toSet();
    final initial = lastCards();
    expect(initial.length, greaterThan(1));
    for (final key in [LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowDown]) {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(lastCards(), containsAll(initial),
          reason: 'Returning through three nearby feeds must not remount the warmed row');
    }
    await tester.pumpWidget(const SizedBox());
    feeds.dispose(); feedSettings.dispose(); appearance.dispose(); await channel.events.close();
  });
  for (final anchored in [true, false]) {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets('feed navigation has one vertical scroll owner: $anchored ${locale.languageCode}', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final appearance = AppearanceService(prefs);
        await appearance.set('focusPulse', false);
        await appearance.set('sectionScroll', anchored ? 'anchored' : 'free');
        final feedSettings = SettingsService(prefs);
        final channel = FeedChannel()
          ..data = List.generate(6, (i) => feed(i + 1, count: 20, poster: 'content://poster/${i + 1}'))
          ..posterResponse = () async => kTransparentImage;
        final feeds = AppChannelsService(channel, feedSettings);
        await feedSettings.setSelectedAppChannels(List.generate(6, (i) => 'video.app:${i + 1}'));
        await tester.runAsync(feeds.refresh);
        final apps = mkAppService();
        when(apps.applications).thenReturn([]);
        when(apps.launcherSections).thenReturn([appChannelsGroup()]);
        final settings = mkSettingsService();
        when(settings.selectedAppChannels).thenReturn(feedSettings.selectedAppChannels);
        await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
            feeds: feeds, appearance: appearance, locale: locale, pixelRatio: 2);
        final outer = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first).controller!;
        var starts = 0;
        void onActivity() { if (outer.position.isScrollingNotifier.value) starts++; }
        outer.position.isScrollingNotifier.addListener(onActivity);
        final requests = channel.requests.length;
        final staticArtwork = find.descendant(of: find.byType(AppContentRow), matching: find.byType(ClipRRect))
            .evaluate().map((element) => element.renderObject).toSet();
        var artworkPaints = 0;
        final previousPaintCallback = debugOnProfilePaint;
        debugOnProfilePaint = (renderObject) {
          previousPaintCallback?.call(renderObject);
          if (staticArtwork.contains(renderObject)) artworkPaints++;
        };
        addTearDown(() => debugOnProfilePaint = previousPaintCallback);
        for (final (key, id) in [
          (LogicalKeyboardKey.arrowDown, 2),
          (LogicalKeyboardKey.arrowDown, 3),
          (LogicalKeyboardKey.arrowUp, 2),
          (LogicalKeyboardKey.arrowUp, 1),
        ]) {
          starts = 0;
          final before = outer.offset;
          await tester.sendKeyEvent(key);
          final samples = [before];
          for (var frame = 0; frame < 16; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
            samples.add(outer.offset);
          }
          expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<AppContentRow>()?.channel.id, id);
          expect(starts, lessThanOrEqualTo(1), reason: 'A single focus change must not restart vertical scrolling');
          final direction = (samples.last - before).sign;
          final distance = (samples.last - before).abs();
          if (distance > 1) {
            final firstMovement = samples.firstWhere((p) => (p - before).abs() > .01);
            expect((firstMovement - before).abs(), lessThan(distance * .1),
                reason: 'Vertical reveal must accelerate gently, without a first-frame lurch');
          }
          for (var i = 1; i < samples.length; i++) {
            expect((samples[i] - samples[i - 1]) * direction, greaterThanOrEqualTo(-0.01),
                reason: 'The row must move monotonically toward the new focus');
          }
          expect(outer.position.isScrollingNotifier.value, isFalse);
          final viewport = tester.getRect(find.byType(SingleChildScrollView).first);
          final row = tester.getRect(find.byWidgetPredicate((widget) =>
              widget is AppContentRow && widget.channel.id == id));
          expect(row.top, greaterThanOrEqualTo(viewport.top - .01));
          expect(row.bottom, lessThanOrEqualTo(viewport.bottom + .01));
        }
        debugOnProfilePaint = previousPaintCallback;
        expect(artworkPaints, 0, reason: 'Scrolling and focus effects must reuse unchanged poster layers');
        // Moving across content must not move the anchored row up/down.
        final before = outer.offset;
        starts = 0;
        final forward = locale.languageCode == 'ar' ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
        for (var i = 0; i < 12; i++) {
          await tester.sendKeyEvent(forward);
          await tester.pumpAndSettle();
          expect(outer.offset, closeTo(before, 0.01));
        }
        expect(starts, 0);
        // A new direction may arrive before the preceding scroll has finished.
        for (final key in [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowUp]) {
          await tester.sendKeyEvent(key);
          for (var frame = 0; frame < 3; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
        }
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<AppContentRow>()?.channel.id, 2);
        expect(channel.requests.length, requests);
        expect(tester.takeException(), isNull);
        outer.position.isScrollingNotifier.removeListener(onActivity);
        await tester.pumpWidget(const SizedBox());
        feeds.dispose(); feedSettings.dispose(); appearance.dispose(); await channel.events.close();
      });
    }
  }
  testWidgets('feed rows keep compact spacing without moving on focus', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    await appearance.set('focusPulse', false);
    await appearance.set('sectionTitles', false);
    await appearance.set('sectionScroll', 'free');
    final feedSettings = SettingsService(prefs);
    final channel = FeedChannel()..data = [feed(1), feed(2)];
    final feeds = AppChannelsService(channel, feedSettings);
    await feedSettings.setSelectedAppChannels(['video.app:1', 'video.app:2']);
    await tester.runAsync(feeds.refresh);
    final apps = mkAppService();
    when(apps.applications).thenReturn([]);
    when(apps.launcherSections).thenReturn([appChannelsGroup()]);
    final settings = mkSettingsService();
    when(settings.selectedAppChannels).thenReturn(feedSettings.selectedAppChannels);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
        feeds: feeds, appearance: appearance);
    final rows = find.byType(AppContentRow);
    final first = tester.getRect(rows.first);
    final second = tester.getRect(rows.last);
    // Includes two caption lines, section spacing and focus reserve.
    expect(second.top - first.top - 128, lessThanOrEqualTo(100));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(tester.getRect(rows.first), first);
    expect(tester.getRect(rows.last), second);
    // The largest preview and scale must still fit a narrow TV window.
    await appearance.set('size', 256);
    await appearance.set('focusScale', .5);
    await appearance.set('focusBorderStyle', 'glow');
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
        feeds: feeds, appearance: appearance, pixelRatio: 4);
    final firstCard = find.descendant(of: rows.first,
        matching: find.byType(InkWell)).first;
    tester.widget<InkWell>(firstCard).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    final image = tester.renderObject<RenderBox>(find.descendant(of: firstCard,
        matching: find.byType(ClipRRect)).first);
    final painted = Rect.fromPoints(image.localToGlobal(Offset.zero),
        image.localToGlobal(image.size.bottomRight(Offset.zero)));
    final viewport = tester.getRect(find.ancestor(of: firstCard,
        matching: find.byType(SingleChildScrollView)).last);
    expect(painted.left, greaterThanOrEqualTo(viewport.left));
    expect(painted.right, lessThanOrEqualTo(viewport.right));
    expect(painted.left - 24, greaterThanOrEqualTo(viewport.left));
    expect(painted.right + 24, lessThanOrEqualTo(viewport.right));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    feeds.dispose(); feedSettings.dispose(); appearance.dispose();
    await channel.events.close();
  });

  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('feed glow fits after horizontal scrolling ${locale.languageCode}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appearance = AppearanceService(prefs);
      for (final entry in <String, dynamic>{
        'size': 160, 'focusScale': .5, 'focusBorderStyle': 'glow',
        'focusPulse': false, 'sectionScroll': 'free',
      }.entries) { await appearance.set(entry.key, entry.value); }
      final settings = SettingsService(prefs);
      final channel = FeedChannel()..data = [feed(1, count: 6)];
      final feeds = AppChannelsService(channel, settings);
      await settings.setSelectedAppChannels(['video.app:1']);
      await tester.runAsync(feeds.refresh);
      final apps = mkAppService();
      when(apps.applications).thenReturn([]);
      when(apps.launcherSections).thenReturn([appChannelsGroup()]);
      final homeSettings = mkSettingsService();
      when(homeSettings.selectedAppChannels).thenReturn(settings.selectedAppChannels);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps,
          homeSettings, feeds: feeds, appearance: appearance, locale: locale,
          pixelRatio: 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        final card = find.descendant(of: find.byType(AppContentRow),
            matching: find.byWidgetPredicate((w) =>
                w is InkWell && w.focusNode?.hasFocus == true));
        final box = tester.renderObject<RenderBox>(find.descendant(
            of: card, matching: find.byType(ClipRRect)).first);
        final painted = Rect.fromPoints(box.localToGlobal(Offset.zero),
            box.localToGlobal(box.size.bottomRight(Offset.zero))).inflate(24);
        final viewport = tester.getRect(find.ancestor(of: card,
            matching: find.byType(SingleChildScrollView)).last);
        expect(painted.left, greaterThanOrEqualTo(viewport.left - .01));
        expect(painted.right, lessThanOrEqualTo(viewport.right + .01));
        if (i < 5) {
          await tester.sendKeyEvent(locale.languageCode == 'ar'
              ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      feeds.dispose(); settings.dispose(); appearance.dispose();
      await channel.events.close();
    });
  }

  testWidgets('feed group moves as one block and Home enters its first feed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    await appearance.set('focusPulse', false);
    final feedSettings = SettingsService(prefs);
    final channel = FeedChannel()..data = [feed(1), feed(2)];
    final feeds = AppChannelsService(channel, feedSettings);
    await feedSettings.setSelectedAppChannels(['video.app:1', 'video.app:2']);
    await tester.runAsync(feeds.refresh);
    final apps = mkAppService();
    final top = fakeCategory(name: 'Top')..applications.add(fakeApp(packageName: 'top.app'));
    final bottom = fakeCategory(name: 'Bottom')..applications.add(fakeApp(packageName: 'bottom.app'));
    final group = appChannelsGroup();
    when(apps.applications).thenReturn([...top.applications, ...bottom.applications]);
    when(apps.launcherSections).thenReturn([top, group, bottom]);
    final settings = mkSettingsService();
    when(settings.selectedAppChannels).thenReturn(feedSettings.selectedAppChannels);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings, feeds: feeds, appearance: appearance);
    final block = find.byKey(const ValueKey('app-channels-group'));
    expect(find.descendant(of: block, matching: find.byType(AppContentRow)), findsNWidgets(2));
    for (final id in [1, 2]) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<AppContentRow>()?.channel.id, id);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'bottom.app'), isTrue);
    when(apps.launcherSections).thenReturn([group, top, bottom]);
    await appearance.set('sectionGap', 26);
    await tester.pumpAndSettle();
    tester.state<FLauncherState>(find.byType(FLauncher)).returnHome();
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<AppContentRow>()?.channel.id, 1);
    group.visible = false;
    await appearance.set('sectionGap', 28);
    await tester.pumpAndSettle();
    expect(find.byType(AppContentRow), findsNothing);
    expect(settings.selectedAppChannels, ['video.app:1', 'video.app:2']);
    group.visible = true;
    await appearance.set('sectionGap', 30);
    await tester.pumpAndSettle();
    expect(find.byType(AppContentRow), findsNWidgets(2));
    channel.data = [];
    await tester.runAsync(feeds.refresh);
    await tester.pumpAndSettle();
    expect(block, findsNothing);
    expect(settings.selectedAppChannels, ['video.app:1', 'video.app:2']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    feeds.dispose(); feedSettings.dispose(); appearance.dispose(); await channel.events.close();
  });
  for (final mode in ['row', 'rows', 'grid']) {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets('scaled app edges and glow fit $mode ${locale.languageCode}', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final appearance = AppearanceService(prefs);
        for (final entry in <String, dynamic>{
          'focusEffect': 'scale', 'focusScale': .5, 'focusPulse': false,
          'sectionScroll': 'free', 'labels': 'all', 'labelPosition': 'below',
          'backgroundColor': 0xffff0000, 'opacity': 1.0, 'radius': 0,
          'inactiveOpacity': 1.0,
          'focusBorderStyle': 'glow',
        }.entries) { await appearance.set(entry.key, entry.value); }
        final category = fakeCategory(name: 'Apps', type: CategoryType.row)
          ..applications.addAll(List.generate(10, (i) =>
              fakeApp(packageName: 'edge.$i', name: 'App $i')));
        await appearance.setCategory(category.id, 'layout', mode);
        await appearance.setCategory(category.id, 'columns', 3);
        await appearance.setCategory(category.id, 'rows', 2);
        final apps = mkAppService();
        when(apps.applications).thenReturn(category.applications);
        when(apps.launcherSections).thenReturn([category]);
        await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps,
            mkSettingsService(), appearance: appearance, locale: locale);
        final viewport = tester.getRect(find.descendant(
            of: find.byType(HomeSection), matching: find.byType(ClipRect)).first);
        final controller = CategoryFocus.maybeOf(
            tester.element(find.byType(HomeSection)))!;
        for (var index = 0; index < 10; index++) {
          final selection = controller.focusPackage('edge.$index');
          await tester.pumpAndSettle();
          expect(await selection, isTrue);
          await tester.pumpAndSettle();
          final card = find.byWidgetPredicate((w) =>
              w is AppCard && w.application.packageName == 'edge.$index');
          final box = tester.renderObject<RenderBox>(find.descendant(of: card,
              matching: find.byType(AppearanceSurface)).first);
          final painted = Rect.fromPoints(box.localToGlobal(Offset.zero),
              box.localToGlobal(box.size.bottomRight(Offset.zero)));
          expect(painted.left, greaterThanOrEqualTo(viewport.left - .01));
          expect(painted.right, lessThanOrEqualTo(viewport.right + .01));
          // The glow scales together with the artwork, beyond its rectangle.
          const glowExtent = 16 * 1.5;
          expect(painted.left - glowExtent, greaterThanOrEqualTo(viewport.left - .01));
          expect(painted.right + glowExtent, lessThanOrEqualTo(viewport.right + .01));
          expect(find.descendant(of: card, matching: find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is TileGlowPainter)), findsOneWidget);
          await expectGlowEdges(tester, box);
          Future<void> checkPaintedEdges() async {
            final current = Rect.fromPoints(box.localToGlobal(Offset.zero),
                box.localToGlobal(box.size.bottomRight(Offset.zero)));
            await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.ancestor(of: find.byType(FLauncher),
                  matching: find.byType(RepaintBoundary)).first);
              final image = await boundary.toImage();
              final pixels = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
              for (final x in [current.left + 4, current.right - 4]) {
                final point = boundary.globalToLocal(Offset(x, current.center.dy));
                final offset = (point.dy.floor() * image.width + point.dx.floor()) * 4;
                // Neighbour shadows may darken the shrinking card slightly.
                expect(pixels.getUint8(offset), greaterThan(200), reason: 'red edge $index at $point');
                expect(pixels.getUint8(offset + 1), lessThan(30), reason: 'green edge $index at $point');
              }
              image.dispose();
            });
          }
          await checkPaintedEdges();
          getSettingsFocusNode(tester)!.requestFocus();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 75));
          await checkPaintedEdges();
          await tester.pumpAndSettle();
          expect(tester.widget<RaisedTile>(find.descendant(
              of: card, matching: find.byType(RaisedTile))).raised, isFalse);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        appearance.dispose();
      });
    }
  }
  for (final target in ['app', 'feed']) {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets('scaled $target artwork stays above its caption ${locale.languageCode}', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final previousTextScale = tester.platformDispatcher.textScaleFactor;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(() => tester.platformDispatcher.textScaleFactorTestValue = previousTextScale);
        final prefs = await SharedPreferences.getInstance();
        final appearance = AppearanceService(prefs);
        for (final entry in <String, dynamic>{
          'labels': 'all', 'labelPosition': 'below', 'focusEffect': 'scale',
          'focusScale': .5, 'focusPulse': false, 'focusTransition': true,
          'sectionScroll': 'free',
        }.entries) { await appearance.set(entry.key, entry.value); }
        final feedSettings = SettingsService(prefs);
        final channel = FeedChannel()..data = [feed(1)];
        final feeds = AppChannelsService(channel, feedSettings);
        await feedSettings.setSelectedAppChannels(['video.app:1']);
        await tester.runAsync(feeds.refresh);
        final apps = mkAppService();
        final category = fakeCategory(name: 'Apps', type: CategoryType.row)
          ..applications.addAll([
            fakeApp(packageName: 'caption.first', name: 'First application'),
            fakeApp(packageName: 'caption.second', name: 'Second application'),
          ]);
        when(apps.applications).thenReturn(category.applications);
        when(apps.launcherSections).thenReturn([category, appChannelsGroup()]);
        final settings = mkSettingsService();
        when(settings.selectedAppChannels).thenReturn(feedSettings.selectedAppChannels);
        await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
          appearance: appearance, feeds: feeds, locale: locale);
        final app = find.byWidgetPredicate((w) => w is AppCard && w.application.packageName == 'caption.second');
        final card = target == 'app' ? app : find.descendant(of: find.byType(AppContentRow), matching: find.byType(InkWell)).first;
        final artwork = target == 'app'
            ? find.descendant(of: card, matching: find.byType(AppearanceSurface)).first
            : find.descendant(of: card, matching: find.byType(ClipRRect)).first;
        final caption = find.descendant(of: card,
          matching: find.text(target == 'app' ? 'Second application' : 'Content 1/0')).last;
        final cellSize = tester.getSize(card);
        Rect paintedRect(Finder finder) {
          final box = tester.renderObject<RenderBox>(finder);
          return Rect.fromPoints(box.localToGlobal(Offset.zero),
            box.localToGlobal(box.size.bottomRight(Offset.zero)));
        }
        void checkCaption() {
          expect(paintedRect(artwork).bottom, lessThanOrEqualTo(paintedRect(caption).top - 6));
          expect(tester.getSize(card), cellSize);
          if (target == 'feed') {
            final viewport = tester.getRect(find.ancestor(of: card,
                matching: find.byType(SingleChildScrollView)).last);
            expect(paintedRect(artwork).left, greaterThanOrEqualTo(viewport.left));
            expect(paintedRect(artwork).right, lessThanOrEqualTo(viewport.right));
          }
        }
        await tester.sendKeyEvent(target == 'feed' ? LogicalKeyboardKey.arrowDown
            : locale.languageCode == 'ar' ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        checkCaption();
        await tester.pumpAndSettle();
        checkCaption();
        expect(paintedRect(artwork).height, greaterThan(128));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        feeds.dispose(); feedSettings.dispose(); appearance.dispose(); await channel.events.close();
      });
    }
  }
  testWidgets('offscreen app feeds defer artwork until remote navigation reaches them', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final feedSettings = SettingsService(prefs);
    final channel = FeedChannel()..data = List.generate(16,
      (i) => feed(i + 1, count: 20, poster: 'content://poster/${i + 1}'));
    final feeds = AppChannelsService(channel, feedSettings);
    await feedSettings.setSelectedAppChannels(List.generate(16, (i) => 'video.app:${i + 1}'));
    await tester.runAsync(feeds.refresh);
    final apps = mkAppService();
    final category = fakeCategory(name: 'Top')..applications.add(fakeApp(packageName: 'top.app'));
    when(apps.applications).thenReturn(category.applications);
    when(apps.launcherSections).thenReturn([category, appChannelsGroup()]);
    final settings = mkSettingsService();
    when(settings.selectedAppChannels).thenReturn(feedSettings.selectedAppChannels);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings, feeds: feeds);
    expect(channel.posters, isNot(contains('content://poster/16')));
    for (var i = 0; i < 16; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<AppContentRow>()?.channel.id, 16);
    expect(channel.posters, contains('content://poster/16'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    feeds.dispose(); feedSettings.dispose(); await channel.events.close();
  });
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('app feeds integrate remote focus, launch, Home and empty updates ${locale.languageCode}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final feedSettings = SettingsService(prefs);
      final channel = FeedChannel()..data = [feed(1, count: 20, poster: 'content://missing/poster'), feed(2), feed(3, count: 0)];
      final feeds = AppChannelsService(channel, feedSettings);
      await feedSettings.setSelectedAppChannels(['video.app:1', 'video.app:2', 'video.app:3']);
      await tester.runAsync(() => feeds.refresh());
      final apps = mkAppService();
      final category = fakeCategory(name: 'Top')..applications.add(fakeApp(packageName: 'top.app'));
      when(apps.applications).thenReturn(category.applications);
      when(apps.launcherSections).thenReturn([category, appChannelsGroup()]);
      final settings = mkSettingsService();
      when(settings.selectedAppChannels).thenReturn(feedSettings.selectedAppChannels);
      when(settings.cardFocusMode).thenReturn(CardFocusMode.remember);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
        feeds: feeds, locale: locale);
      expect(find.byType(AppContentRow), findsNWidgets(2));
      expect(find.byIcon(Icons.movie_outlined), findsWidgets);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<AppContentRow>()?.channel.id, 1);
      final forward = locale.languageCode == 'ar' ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(forward);
        await tester.pumpAndSettle();
      }
      expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<AppContentRow>()?.channel.id, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(channel.launches.single, ('video://watch/1/12', 'video.app'));
      tester.state<FLauncherState>(find.byType(FLauncher)).returnHome();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(channel.launches.last, ('video://watch/1/12', 'video.app'));
      channel.data = [feed(1, count: 0), feed(2), feed(3, count: 0)];
      await tester.runAsync(feeds.refresh);
      await tester.pumpAndSettle();
      expect(find.byType(AppContentRow), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<AppContentRow>()?.channel.id, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'top.app'), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      feeds.dispose(); feedSettings.dispose(); await channel.events.close();
    });
  }
  for (final layout in ['row', 'rows-one', 'row-override', 'rows', 'grid', 'multiple', 'watch']) {
    testWidgets('wheel preserves single tape height only: $layout', (tester) async {
      SharedPreferences.setMockInitialValues({'card_focus_mode': 'first'});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      await appearance.set('focusPulse', false);
      final apps = mkAppService();
      final category = fakeCategory(name: 'Apps', type: layout == 'row-override' ? CategoryType.grid : CategoryType.row)
        ..applications.addAll(List.generate(30, (i) => fakeApp(packageName: 'tape.$i')));
      final hidden = fakeCategory(name: 'Hidden')..visible = false;
      final feeds = fakeCategory(name: 'App Feeds')..systemKey = 'app_channels';
      final second = fakeCategory(name: 'Second', order: 2)
        ..applications.add(fakeApp(packageName: 'second.app'));
      await appearance.setCategory(category.id, 'layout', switch (layout) {
        'multiple' || 'row-override' || 'watch' => 'row',
        'rows-one' => 'rows',
        _ => layout,
      });
      await appearance.setCategory(category.id, 'rows', layout == 'rows-one' ? 1 : 2);
      final categories = [hidden, category, feeds, if (layout == 'multiple') second];
      when(apps.launcherSections).thenReturn(categories);
      when(apps.categories).thenReturn(categories);
      when(apps.applications).thenReturn(category.applications);
      final settings = mkSettingsService();
      final watch = mkWatchNextService();
      if (layout == 'watch') {
        when(settings.showContinueWatching).thenReturn(true);
        when(settings.hiddenWatchNextProgramIds).thenReturn([]);
        when(settings.hiddenWatchNextPackages).thenReturn([]);
        when(settings.continueWatchingShowProgress).thenReturn(false);
        when(settings.continueWatchingShowPercentage).thenReturn(false);
        when(settings.continueWatchingShowDescription).thenReturn(false);
        when(settings.continueWatchingMaxItems).thenReturn(15);
        when(settings.continueWatchingCardSize).thenReturn('normal');
        when(watch.hasPermission).thenReturn(true);
        when(watch.programs).thenReturn([WatchNextProgram.fromMap({'id': 1, 'packageName': 'video.app', 'title': 'Video'})]);
      }
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings, appearance: appearance, watchNext: watch);
      final outer = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first).controller!;
      expect(outer.position.maxScrollExtent, greaterThan(0));
      final section = find.byType(HomeSection).first;
      final before = tester.getTopLeft(section).dy;
      final offset = outer.offset;
      // A wheel over empty space must not shift a lone tape vertically.
      await tester.sendEventToBinding(PointerScrollEvent(
        position: tester.getRect(find.byType(SingleChildScrollView).first).bottomRight - const Offset(10, 10),
        scrollDelta: const Offset(0, 100),
      ));
      await tester.pumpAndSettle();
      if (['row', 'rows-one', 'row-override'].contains(layout)) {
        expect(outer.offset, offset);
        expect(tester.getTopLeft(section).dy, before);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(isSettingsIconFocused(tester), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(isAppCardFocused(tester, 'tape.0'), isTrue);
        final inner = tester.state<ScrollableState>(find.descendant(of: section, matching: find.byType(Scrollable)).first).position;
        final tile = find.byWidgetPredicate((w) => w is AppCard && w.application.packageName == 'tape.0');
        await tester.sendEventToBinding(PointerScrollEvent(position: tester.getCenter(tile), scrollDelta: const Offset(0, 100)));
        await tester.pumpAndSettle();
        expect(inner.pixels, greaterThan(0));
        inner.jumpTo(inner.maxScrollExtent);
        await tester.pumpAndSettle();
        await tester.sendEventToBinding(PointerScrollEvent(position: tester.getCenter(section), scrollDelta: const Offset(0, 100)));
        await tester.pumpAndSettle();
        expect(outer.offset, offset, reason: 'The tape edge must not hand the wheel to the vertical viewport');
        await tester.sendEventToBinding(PointerScrollEvent(position: tester.getCenter(section), scrollDelta: const Offset(0, -10000)));
        await tester.pumpAndSettle();
        expect(outer.offset, offset);
        expect(tester.getTopLeft(section).dy, before);
        // Changing the effective layout must immediately restore vertical input.
        await appearance.setCategory(category.id, 'layout', 'grid');
        await tester.pumpAndSettle();
        final gridOffset = outer.offset;
        await tester.sendEventToBinding(PointerScrollEvent(
          position: tester.getRect(find.byType(SingleChildScrollView).first).bottomRight - const Offset(10, 10),
          scrollDelta: const Offset(0, 100),
        ));
        await tester.pumpAndSettle();
        expect(outer.offset, greaterThan(gridOffset));
      } else {
        expect(outer.offset, greaterThan(offset));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    });
  }
  for (final layout in ['row', 'rows', 'grid']) {
    testWidgets('mouse wheel scrolls non-TV $layout over its selected icon', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'card_focus_mode': 'first'});
      final prefs = await SharedPreferences.getInstance();
      final appearance = AppearanceService(prefs);
      await appearance.set('focusPulse', false);
      final apps = mkAppService();
      final category = fakeCategory(name: 'other_apps')
        ..applications.addAll(
          List.generate(
            30,
            (i) => fakeApp(packageName: 'other.$i', sideloaded: true),
          ),
        );
      for (final app in category.applications) {
        when(apps.getAppBanner(app.packageName))
            .thenAnswer((_) async => Uint8List(0));
      }
      await appearance.setCategory(category.id, 'layout', layout);
      await appearance.setCategory(category.id, 'maxRows', 2);
      when(apps.launcherSections).thenReturn([category]);
      when(apps.categories).thenReturn([category]);
      await _pumpWidgetWithProviders(
        tester,
        mkWallpaperService(),
        apps,
        mkSettingsService(),
        appearance: appearance,
      );
      final tile = find.byWidgetPredicate(
        (w) => w is AppCard && w.application.packageName == 'other.0',
      );
      final scrollable = find
          .descendant(
            of: find.byType(HomeSection),
            matching: find.byType(Scrollable),
          )
          .first;
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));
      await tester.tap(tile, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      verify(apps.launchApp(category.applications.first)).called(1);
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(tile),
          scrollDelta: const Offset(0, 100),
        ),
      );
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      final nextIndex = layout == 'grid' ? 8 : 2;
      final next = find.byWidgetPredicate(
        (w) => w is AppCard && w.application.packageName == 'other.$nextIndex',
      );
      await tester.tap(next, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      verify(apps.launchApp(category.applications[nextIndex])).called(1);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    });
  }
  testWidgets('mouse scrolls to non-TV apps and launches their icons', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'card_focus_mode': 'first'});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    await appearance.set('focusPulse', false);
    final apps = mkAppService();
    final tv = fakeCategory(name: 'tv_apps')
      ..applications.addAll(
        List.generate(36, (i) => fakeApp(packageName: 'tv.$i')),
      );
    final other = fakeCategory(name: 'other_apps', order: 1)
      ..applications.addAll(
        List.generate(
          30,
          (i) => fakeApp(packageName: 'other.$i', sideloaded: true),
        ),
      );
    when(apps.launcherSections).thenReturn([tv, other]);
    when(apps.categories).thenReturn([tv, other]);
    await _pumpWidgetWithProviders(
      tester,
      mkWallpaperService(),
      apps,
      mkSettingsService(),
      appearance: appearance,
    );
    final pointer = Offset(600, 400);
    for (var i = 0; i < 15; i++) {
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: pointer,
          scrollDelta: const Offset(0, 160),
        ),
      );
      await tester.pumpAndSettle();
    }
    final tile = find.byWidgetPredicate(
      (w) => w is AppCard && w.application.packageName == 'other.29',
    );
    expect(tile.hitTestable(), findsOneWidget);
    await tester.tap(tile, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    verify(apps.launchApp(other.applications.last)).called(1);
    await tester.pumpWidget(const SizedBox());
    appearance.dispose();
  });
  testWidgets('app artwork follows focused cards in the real launcher and preserves wallpaper', (tester) async {
    SharedPreferences.setMockInitialValues({'background_source': 'app', 'card_focus_mode': 'first'});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    await appearance.set('focusPulse', false);
    final settings = SettingsService(prefs);
    final apps = mkAppService();
    final category = fakeCategory(type: CategoryType.row)
      ..applications.addAll([fakeApp(packageName: 'art.first'), fakeApp(packageName: 'art.second')]);
    when(apps.launcherSections).thenReturn([category]);
    when(apps.categories).thenReturn([category]);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings, appearance: appearance);
    expect(find.byType(AppArtworkBackground), findsOneWidget);
    getFocusNodeForApp(tester, 'art.first')!.requestFocus();
    await tester.pumpAndSettle();
    expect(appearance.focusedAppImage.value, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'art.second'), isTrue);
    final state = tester.state<FLauncherState>(find.byType(FLauncher));
    state.returnHome();
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'art.first'), isTrue);
    await settings.setBackgroundSource('picture');
    await tester.pumpAndSettle();
    expect(find.byType(AppArtworkBackground), findsNothing);
    expect(find.byType(WallpaperBackground), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    settings.dispose(); appearance.dispose();
  });
  for (final onRight in [false, true]) {
    testWidgets('remote settings preview survives nested pages and closes: right=$onRight', (tester) async {
      SharedPreferences.setMockInitialValues({
        'auto_hide_app_bar': true,
        'settings_menu_on_right': onRight,
        'show_time_in_status_bar': false,
        'show_date_in_status_bar': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final panel = RemotePanelService(prefs);
      final appearance = AppearanceService(prefs);
      final settings = SettingsService(prefs);
      for (final id in RemotePanelService.ids) {
        if (!['settings', 'time'].contains(id)) await panel.show(id, false);
      }
      await panel.set('inheritAppearance', false);
      await panel.setAppearance('panelColor', 0xff123456);
      await panel.setAppearance('panelOpacity', .4);
      final apps = mkAppService();
      when(apps.launcherSections).thenReturn([]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
        appearance: appearance, remotePanel: panel, pixelRatio: 2,
        locale: Locale(onRight ? 'en' : 'ru'));
      final bar = find.byType(FocusAwareAppBar);
      final state = tester.state<FocusAwareAppBarState>(bar);
      state.focusSettings();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined).first);
      await tester.pumpAndSettle();
      final root = tester.element(find.byType(SettingsPanelPage));
      Navigator.of(root).pushNamed(StatusBarPanelPage.routeName);
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(StatusBarPanelPage)))!;
      await tester.tap(find.text(l.remotePanel));
      await tester.pumpAndSettle();
      expect(panel.previewActive, isTrue);
      expect(tester.widget<FocusAwareAppBar>(bar).remotePanel, same(panel));
      expect(tester.getSize(find.byKey(const Key('top_panel_visibility'))).height, kToolbarHeight);
      void expectClearToolbar() {
        final side = find.byType(SidePanelDialog);
        expect(tester.widget<SidePanelDialog>(side).topInset, kToolbarHeight);
        final navigator = find.descendant(of: side, matching: find.byType(Navigator));
        final rect = tester.getRect(navigator);
        expect(rect.top, greaterThanOrEqualTo(kToolbarHeight));
        expect(rect.bottom, lessThanOrEqualTo(540));
      }
      expectClearToolbar();
      var appBar = tester.widget<AppBar>(find.descendant(of: bar, matching: find.byType(AppBar)));
      expect((appBar.flexibleSpace! as ColoredBox).color,
          const Color(0xff123456).withValues(alpha: .4));
      await panel.setAppearance('panelOpacity', .7);
      await tester.pumpAndSettle();
      appBar = tester.widget<AppBar>(find.descendant(of: bar, matching: find.byType(AppBar)));
      expect((appBar.flexibleSpace! as ColoredBox).color,
          const Color(0xff123456).withValues(alpha: .7));
      await tester.tap(find.text(l.appearanceSettings));
      await tester.pumpAndSettle();
      expect(find.byType(AppearancePage), findsOneWidget);
      expect(panel.previewActive, isTrue);
      expectClearToolbar();
      await tester.tap(find.text(l.remotePanelInheritAppearance));
      await tester.pumpAndSettle();
      expect(panel.inheritAppearance, isTrue);
      appBar = tester.widget<AppBar>(find.descendant(of: bar, matching: find.byType(AppBar)));
      expect((appBar.flexibleSpace! as ColoredBox).color.a, 0);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(RemotePanelPage), findsOneWidget);
      expect(panel.previewActive, isTrue);
      await tester.tap(find.text(l.topPanelObjects));
      await tester.pumpAndSettle();
      expect(find.byType(RemotePanelObjectsPage), findsOneWidget);
      expect(panel.previewActive, isTrue);
      expectClearToolbar();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('time')),
        150,
        scrollable: find.descendant(
          of: find.byType(RemotePanelObjectsPage),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.descendant(of: find.byKey(const ValueKey('time')), matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('statusbar_clock')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(RemotePanelPage), findsOneWidget);
      expect(panel.previewActive, isTrue);
      final order = find.text(l.panelObjectOrder);
      await tester.ensureVisible(order);
      await tester.tap(order);
      await tester.pumpAndSettle();
      expect(find.byType(PanelOrderPage), findsOneWidget);
      expect(panel.previewActive, isTrue);
      expectClearToolbar();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(RemotePanelPage), findsOneWidget);
      expect(panel.previewActive, isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(panel.previewActive, isFalse);
      expect(tester.widget<FocusAwareAppBar>(bar).remotePanel, isNull);
      await tester.tap(find.text(l.remotePanel));
      await tester.pumpAndSettle();
      expect(panel.previewActive, isTrue);
      Navigator.of(tester.element(find.byType(RemotePanelPage)), rootNavigator: true).pop();
      await tester.pumpAndSettle();
      expect(panel.previewActive, isFalse);
      expect(tester.widget<FocusAwareAppBar>(bar).remotePanel, isNull);
      expect(prefs.getString(RemotePanelService.preferenceKey), isNot(contains('preview')));
      await tester.pumpWidget(const SizedBox());
      settings.dispose(); appearance.dispose(); panel.dispose();
    });
  }
  for (final mode in ['row', 'rows', 'grid']) {
    testWidgets('RTL $mode mirrors tiles, navigation and movement', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      final apps = mkAppService();
      final top = fakeCategory(type: mode == 'grid' ? CategoryType.grid : CategoryType.row, columnsCount: 4)
        ..applications.addAll(List.generate(16, (i) => fakeApp(packageName: 'rtl.top.$i')));
      final bottom = fakeCategory(order: 1, type: mode == 'grid' ? CategoryType.grid : CategoryType.row, columnsCount: 4)
        ..applications.addAll(List.generate(16, (i) => fakeApp(packageName: 'rtl.bottom.$i')));
      if (mode != 'grid') {
        await appearance.setTapeRows(top.id, mode == 'rows' ? 2 : 1);
        await appearance.setTapeRows(bottom.id, mode == 'rows' ? 2 : 1);
      }
      when(apps.launcherSections).thenReturn([top, bottom]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(),
          appearance: appearance, locale: const Locale('ar'));
      Finder card(String id) => find.byWidgetPredicate((w) => w is AppCard && w.application.packageName == id);
      expect(tester.getCenter(card('rtl.top.0')).dx,
          greaterThan(tester.getCenter(card('rtl.top.1')).dx));
      expect(tester.getRect(card('rtl.top.0')).right, lessThanOrEqualTo(1920));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'rtl.top.1'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, mode == 'row' ? 'rtl.bottom.1' : mode == 'rows' ? 'rtl.top.9' : 'rtl.top.5'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'rtl.top.1'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'rtl.top.0'), isTrue);
      tester.widget<AppCard>(card('rtl.top.0')).onMove(AxisDirection.left);
      verify(apps.reorderApplication(top, 0, 1)).called(1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    });
  }
  for (final rows in [1, 2]) {
    testWidgets('down from settings restores the scrolled tape app: $rows rows', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      final apps = mkAppService();
      final tape = fakeCategory(type: CategoryType.row)
        ..applications.addAll(List.generate(rows * 14, (i) => fakeApp(packageName: 'top.return.$i')));
      await appearance.setTapeRows(tape.id, rows);
      when(apps.launcherSections).thenReturn([tape]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance);
      for (var i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
      expect(isAppCardFocused(tester, 'top.return.10'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(getSettingsFocusNode(tester)!.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'top.return.10'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'top.return.11'), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    });
  }
  testWidgets('Home resets the tape navigation column to its current first card', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    final settings = SettingsService(prefs);
    await settings.setCardFocusMode(CardFocusMode.first);
    await settings.setAppHighlightAnimationEnabled(false);
    await settings.setAppKeyClickEnabled(false);
    final apps = mkAppService();
    final tape = fakeCategory(type: CategoryType.row)
      ..applications.addAll(List.generate(20, (i) => fakeApp(packageName: 'home.column.$i')));
    await appearance.setTapeRows(tape.id, 2);
    when(apps.launcherSections).thenReturn([tape]);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings, appearance: appearance);
    for (var i = 0; i < 9; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'home.column.19'), isTrue);
    tester.state<FLauncherState>(find.byType(FLauncher)).returnHome();
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'home.column.0'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'home.column.10'), isTrue);
    await tester.pumpWidget(const SizedBox());
    appearance.dispose(); settings.dispose();
  });
  for (final type in [CategoryType.row, CategoryType.grid]) {
    testWidgets('sort mode changes reorder focused tiles immediately: $type', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      final apps = mkAppService();
      final a = fakeApp(packageName: 'sort.a', name: 'A');
      final b = fakeApp(packageName: 'sort.b', name: 'B');
      final c = fakeApp(packageName: 'sort.c', name: 'C');
      final category = fakeCategory(sort: CategorySort.manual, type: type)
        ..applications.addAll([c, b, a]);
      when(apps.launcherSections).thenReturn([category]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance);
      getFocusNodeForApp(tester, 'sort.b')!.requestFocus();
      await tester.pumpAndSettle();
      List<String> order() => tester.widgetList<AppCard>(find.byType(AppCard))
          .map((card) => card.application.packageName).toList();
      for (final sort in [CategorySort.alphabetical, CategorySort.manual, CategorySort.mostUsed, CategorySort.alphabetical]) {
        category.sort = sort;
        final expected = sort == CategorySort.alphabetical ? [a, b, c] : [c, b, a];
        category.applications..clear()..addAll(expected);
        await appearance.set('animateReordering', true);
        await tester.pumpAndSettle();
        expect(order(), expected.map((app) => app.packageName).toList());
        expect(isAppCardFocused(tester, 'sort.b'), isTrue);
      }
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    });
  }
  testWidgets('active section stays opaque in top bar and settings; other sections stay dim', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    await appearance.set('inactiveOpacity', .2);
    await appearance.set('sectionBackground', 0xff123456);
    await appearance.set('sectionOpacity', .35);
    await appearance.set('sectionRadius', 32);
    final apps = mkAppService();
    final top = fakeCategory(name: 'Top')..applications.add(fakeApp(packageName: 'opacity.top'));
    final bottom = fakeCategory(name: 'Bottom')..applications.add(fakeApp(packageName: 'opacity.bottom'));
    when(apps.launcherSections).thenReturn([top, bottom]);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance);
    double opacity(String name) => tester.widget<AnimatedOpacity>(find.descendant(
      of: find.byWidgetPredicate((w) => w is HomeSection && w.category.name == name),
      matching: find.byType(AnimatedOpacity)).first).opacity;
    final background = tester.widget<Container>(find.descendant(
      of: find.byType(HomeSection).first,
      matching: find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration),
    ).first);
    expect((background.decoration! as BoxDecoration).color,
        const Color(0xff123456).withValues(alpha: .35));
    expect((background.decoration! as BoxDecoration).borderRadius, BorderRadius.circular(32));
    expect(background.clipBehavior, Clip.none);
    for (final entry in [('Top', 'opacity.top', 'Bottom'), ('Bottom', 'opacity.bottom', 'Top')]) {
      getFocusNodeForApp(tester, entry.$2)!.requestFocus();
      await tester.pumpAndSettle();
      expect(opacity(entry.$1), 1);
      expect(opacity(entry.$3), .2);
      final settingsNode = getSettingsFocusNode(tester)!;
      settingsNode.requestFocus();
      await tester.pumpAndSettle();
      expect(opacity(entry.$1), 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPanelPage), findsOneWidget);
      expect(opacity(entry.$1), 1);
      expect(opacity(entry.$3), .2);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(opacity(entry.$1), 1);
    }
    await tester.pumpWidget(const SizedBox());
    appearance.dispose();
  });
  for (final titles in [true, false]) {
    testWidgets('selected name stays in header without moving bottom grid, titles=$titles', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      await appearance.set('sectionTitles', titles);
      await appearance.set('sectionPosition', 1);
      await appearance.set('focusEffect', 'border');
      final apps = mkAppService();
      final category = fakeCategory(name: 'Мои приложения', type: CategoryType.grid, columnsCount: 4);
      category.applications.addAll(List.generate(8, (i) => fakeApp(
        packageName: 'header.$i', name: i == 0 ? 'Первое' : 'Очень длинное название выбранного приложения $i',
      )));
      when(apps.launcherSections).thenReturn([category]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps,
        mkSettingsService(), appearance: appearance);
      getFocusNodeForApp(tester, 'header.0')!.requestFocus();
      await tester.pumpAndSettle();
      final before = getFocusNodeForApp(tester, 'header.0')!.rect;
      await appearance.set('labels', 'selected');
      await tester.pumpAndSettle();
      final label = find.byKey(ValueKey(('selected-app-label', category.id)));
      expect(tester.widget<Text>(label).data, 'Первое');
      expect(tester.getRect(label).bottom, lessThan(getFocusNodeForApp(tester, 'header.0')!.rect.top));
      if (titles) {
        expect(getFocusNodeForApp(tester, 'header.0')!.rect, before);
        expect((tester.getCenter(label).dy - tester.getCenter(find.text('Мои приложения')).dy).abs(), lessThan(1));
      } else {
        expect(find.text('Мои приложения'), findsNothing);
      }
      final cell = getFocusNodeForApp(tester, 'header.1')!.rect;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(label).data, 'Очень длинное название выбранного приложения 1');
      expect(getFocusNodeForApp(tester, 'header.1')!.rect, cell);
      expect(isAppCardFocused(tester, 'header.1'), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    });
  }
  for (final type in [CategoryType.row, CategoryType.grid]) {
    testWidgets('Up reaches settings even when an update is available: $type', (tester) async {
      SharedPreferences.setMockInitialValues({automaticUpdatesKey: true,
        updateCheckTimeKey: DateTime.now().millisecondsSinceEpoch});
      final updates = UpdateService(await SharedPreferences.getInstance(),
        environment: () async => {'play': false, 'version': '1.0.0',
          'versionCode': 1, 'abis': ['armeabi-v7a']});
      updates.release = AppRelease('v1.0.0+2', Uri.parse('https://github.com/update.apk'), 3, null);
      final apps = mkAppService();
      final category = fakeCategory(type: type)..applications.add(fakeApp(packageName: 'notice.app'));
      when(apps.launcherSections).thenReturn([category]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), updates: updates);
      getFocusNodeForApp(tester, 'notice.app')!.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(isSettingsIconFocused(tester), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'notice.app'), isTrue);
      await updates.setNotificationsEnabled(false);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(isSettingsIconFocused(tester), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      updates.dispose();
    });
  }
  for (final labels in ['none', 'selected', 'all']) {
    testWidgets('outline shadow toggle preserves grid cell bounds with labels=$labels', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      await appearance.set('labels', labels);
      await appearance.set('focusEffect', 'border');
      final service = mkAppService();
      final category = fakeCategory(type: CategoryType.grid, columnsCount: 4);
      category.applications.addAll(List.generate(8, (i) => fakeApp(packageName: 'shadow.$i')));
      when(service.launcherSections).thenReturn([category]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), service,
        mkSettingsService(), appearance: appearance);
      await tester.pumpAndSettle();
      final before = [for (var i = 0; i < 8; i++) getFocusNodeForApp(tester, 'shadow.$i')!.rect];
      await appearance.set('focusShadow', true);
      await tester.pumpAndSettle();
      expect([for (var i = 0; i < 8; i++) getFocusNodeForApp(tester, 'shadow.$i')!.rect], before);
      await appearance.set('focusShadow', false);
      await tester.pumpAndSettle();
      expect([for (var i = 0; i < 8; i++) getFocusNodeForApp(tester, 'shadow.$i')!.rect], before);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    });
  }
  for (final scrollMode in ['anchored', 'free']) {
    for (final shape in [
      {'aspectRatio': 1.0, 'radius': 100, 'size': 128, 'labels': 'none'},
      {'aspectRatio': 1.0, 'radius': 0, 'size': 64, 'labels': 'all'},
      {'aspectRatio': .5, 'radius': 50, 'size': 256, 'labels': 'all'},
      {'aspectRatio': 16 / 9, 'radius': 16, 'size': 256, 'labels': 'selected'},
      {'aspectRatio': 21 / 9, 'radius': 100, 'size': 64, 'labels': 'all'},
    ]) {
      testWidgets('three complete grid rows move together: $scrollMode $shape', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final appearance = AppearanceService(await SharedPreferences.getInstance());
        addTearDown(appearance.dispose);
        await appearance.set('sectionScroll', scrollMode);
        for (final entry in shape.entries) { await appearance.set(entry.key, entry.value); }
        await appearance.set('horizontalGap', 8);
        await appearance.set('verticalGap', 8);
        await appearance.set('focusPulse', false);
        final apps = mkAppService();
        final grid = Category(id: 77, name: 'Three-row grid', type: CategoryType.grid, columnsCount: 6)
          ..applications.addAll(List.generate(14, (i) => fakeApp(packageName: 'whole.$i')));
        when(apps.launcherSections).thenReturn([grid]);
        when(apps.categories).thenReturn([grid]);
        await appearance.setCategory(77, 'maxRows', 3);
        await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance, pixelRatio: 2);
        getFocusNodeForApp(tester, 'whole.0')!.requestFocus();
        await tester.pumpAndSettle();
        final viewport = find.byType(ReorderingTileViewport);
        final layout = tester.widget<ReorderingTileViewport>(viewport).layout;
        expect(tester.getSize(viewport).height, closeTo(3 * layout.stepY - layout.gapY, .01));
        final inner = tester.state<ScrollableState>(find.descendant(of: viewport, matching: find.byType(Scrollable)).first).position;
        expect(inner.maxScrollExtent, closeTo(0, .01));
        final title = find.text('Three-row grid');
        final first = getFocusNodeForApp(tester, 'whole.0')!.rect;
        final heading = tester.getRect(title);
        for (final index in [6, 12]) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          expect(isAppCardFocused(tester, 'whole.$index'), isTrue);
          final tile = getFocusNodeForApp(tester, 'whole.$index')!.rect;
          final outer = tester.getRect(find.byType(SingleChildScrollView).first);
          // A single tile taller than the screen cannot fit, but its bottom is revealed.
          expect(tile.bottom, lessThanOrEqualTo(outer.bottom + .1));
        }
        expect(heading.top - tester.getRect(title).top,
          closeTo(first.top - getFocusNodeForApp(tester, 'whole.0')!.rect.top, .1));
        expect(inner.pixels, 0);
        for (final index in [6, 0]) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          expect(isAppCardFocused(tester, 'whole.$index'), isTrue);
        }
        if (scrollMode == 'anchored') expect(tester.getRect(title).top, closeTo(heading.top, .1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('changing grid geometry reveals the selected row inside its new window', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    addTearDown(appearance.dispose);
    final apps = mkAppService();
    final grid = Category(id: 77, name: 'Changing grid', type: CategoryType.grid, columnsCount: 6)
      ..applications.addAll(List.generate(30, (i) => fakeApp(packageName: 'resize.$i')));
    when(apps.launcherSections).thenReturn([grid]);
    await appearance.set('focusPulse', false);
    await appearance.setCategory(77, 'maxRows', 3);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance, pixelRatio: 2);
    getFocusNodeForApp(tester, 'resize.0')!.requestFocus();
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    for (final limit in [1, 2, 3, 0]) {
      await appearance.setCategory(77, 'maxRows', limit);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'resize.12'), isTrue);
      final viewport = tester.getRect(find.byType(ReorderingTileViewport));
      final tile = getFocusNodeForApp(tester, 'resize.12')!.rect;
      expect(tile.top, greaterThanOrEqualTo(viewport.top - .1));
      expect(tile.bottom, lessThanOrEqualTo(viewport.bottom + .1));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('limited category grid keeps every row reachable by remote', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    final service = mkAppService();
    final category = Category(id: 77, name: 'Applications', type: CategoryType.grid, columnsCount: 6);
    category.applications.addAll(List.generate(30, (i) => fakeApp(packageName: 'limited.$i')));
    when(service.launcherSections).thenReturn([category]);
    await appearance.setCategory(77, 'maxRows', 2);
    await appearance.setCategory(77, 'padding', 16);
    await appearance.setCategory(77, 'background', 0x8011141B);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), service, mkSettingsService(), appearance: appearance);
    final viewport = find.byType(ReorderingTileViewport);
    final layout = tester.widget<ReorderingTileViewport>(viewport).layout;
    expect(tester.getSize(viewport).height, closeTo(2 * layout.stepY - layout.gapY, .01));
    final inner = tester.state<ScrollableState>(find.descendant(of: viewport, matching: find.byType(Scrollable)).first).position;
    expect(inner.maxScrollExtent, greaterThan(0));
    getFocusNodeForApp(tester, 'limited.0')!.requestFocus();
    await tester.pumpAndSettle();
    for (var row = 1; row < 5; row++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(getFocusNodeForApp(tester, 'limited.${row * 6}')!.hasFocus, isTrue);
    }
    expect(inner.pixels, greaterThan(0));
    for (var row = 3; row >= 0; row--) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(getFocusNodeForApp(tester, 'limited.${row * 6}')!.hasFocus, isTrue);
    }
    expect(inner.pixels, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    appearance.dispose();
  });

  testWidgets('each size step changes grid tiles; fixed columns win over global size', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    final apps = mkAppService();
    final category = fakeCategory(columnsCount: 6)
      ..applications.addAll(List.generate(30, (i) => fakeApp(packageName: 'size.$i')));
    when(apps.launcherSections).thenReturn([category]);
    await appearance.setCategory(category.id, 'layout', 'auto');
    await appearance.set('size', 128);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance, pixelRatio: 2);
    final tile = find.byKey(const Key('size.0'));
    final before = tester.getSize(tile);
    await appearance.set('size', 136);
    await tester.pumpAndSettle();
    expect(tester.getSize(tile).width - before.width, closeTo(8 * 16 / 9, 0.01));
    await appearance.setCategory(category.id, 'layout', 'columns');
    await tester.pumpAndSettle();
    final fixed = tester.getSize(tile);
    await appearance.set('size', 160);
    await tester.pumpAndSettle();
    expect(tester.getSize(tile), fixed);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'size.6'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); appearance.dispose();
  });

  testWidgets('multiple rows scroll together, preserve order and never wrap', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    final apps = mkAppService();
    final category = fakeCategory()..applications.addAll(List.generate(23, (i) => fakeApp(packageName: 'rows.$i')));
    when(apps.launcherSections).thenReturn([category]);
    await appearance.setCategory(category.id, 'layout', 'rows');
    await appearance.setCategory(category.id, 'rows', 2);
    await appearance.setCategory(category.id, 'columns', 4);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance, pixelRatio: 2);
    final start = tester.getTopLeft(find.byKey(const Key('rows.12'))).dx;
    for(var i=1;i<=6;i++) { await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); await tester.pumpAndSettle(); }
    expect(isAppCardFocused(tester, 'rows.6'), isTrue);
    expect(tester.getTopLeft(find.byKey(const Key('rows.16'))).dx,
        closeTo(tester.getTopLeft(find.byKey(const Key('rows.4'))).dx, .1));
    expect(tester.getTopLeft(find.byKey(const Key('rows.16'))).dx, lessThan(start + 4 * 250));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'rows.18'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp); await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'rows.6'), isTrue);
    for(var i=0;i<20;i++) { await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); await tester.pumpAndSettle(); }
    expect(isAppCardFocused(tester, 'rows.11'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); appearance.dispose();
  });

  for (final spacerHeight in [10, 250]) {
    testWidgets('first tile preserves full top spacer and category title: $spacerHeight', (tester) async {
      final apps = mkAppService();
      final category = fakeCategory(name: 'All apps')
        ..applications.addAll(List.generate(60, (i) => fakeApp(packageName: 'spacer.$i')));
      when(apps.launcherSections).thenReturn([
        LauncherSpacer(id: 9999, height: spacerHeight), category,
      ]);
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      await appearance.set('sectionScroll', 'free');
      addTearDown(appearance.dispose);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance, pixelRatio: 2);
      getFocusNodeForApp(tester, 'spacer.0')!.requestFocus(); await tester.pumpAndSettle();
      final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first).controller!;
      expect(scroll.offset, 0);
      final title = tester.getRect(find.text('All apps'));
      final spacer = tester.getRect(find.byKey(const Key('9999')));
      expect(spacer.height, spacerHeight);
      expect(title.top, greaterThanOrEqualTo(spacer.bottom));
      expect(title.top, greaterThan(0));
      final panelBottom = tester.getBottomLeft(find.byType(FocusAwareAppBar)).dy;
      final viewport = find.byType(SingleChildScrollView).first;
      expect(spacer.top - panelBottom, 24,
          reason: 'The initial gap below the panel must be preserved');
      expect(tester.getTopLeft(viewport).dy, panelBottom,
          reason: 'Content must clip at the panel edge, without a fixed gap');
      scroll.jumpTo(24);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('All apps')).top, closeTo(title.top - 24, .01));
      expect(tester.getRect(find.byKey(const Key('9999'))).top, panelBottom);
      expect(tester.getTopLeft(viewport).dy, panelBottom);
      expect(isAppCardFocused(tester, 'spacer.0'), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('anchored sections keep position at both ends; free mode preserves selection', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    final apps = mkAppService();
    final first = fakeCategory(type: CategoryType.row)..applications.add(fakeApp(packageName: 'anchor.first'));
    final last = fakeCategory(type: CategoryType.row)..applications.add(fakeApp(packageName: 'anchor.last'));
    when(apps.launcherSections).thenReturn([first,last]);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance);
    final y = tester.getTopLeft(find.byKey(const Key('anchor.first'))).dy;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'anchor.last'), isTrue);
    expect(tester.getTopLeft(find.byKey(const Key('anchor.last'))).dy, closeTo(y, 1));
    await appearance.set('sectionScroll', 'free'); await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'anchor.last'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); appearance.dispose();
  });

  testWidgets('grid remembers desired column and leaves only at the data edge', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    addTearDown(appearance.dispose);
    final apps = mkAppService();
    final grid = fakeCategory()..applications.addAll(List.generate(10, (i) => fakeApp(packageName: 'edge.$i')));
    final row = fakeCategory(type: CategoryType.row)..applications.addAll(List.generate(10, (i) => fakeApp(packageName: 'next.$i')));
    when(apps.launcherSections).thenReturn([grid, row]);
    await appearance.setCategory(grid.id, 'layout', 'grid');
    await appearance.setCategory(grid.id, 'columns', 4);
    await appearance.setCategory(grid.id, 'maxRows', 2);
    await appearance.setCategory(row.id, 'columns', 4);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance, pixelRatio: 2);
    Future<void> key(LogicalKeyboardKey key) async { await tester.sendKeyEvent(key); await tester.pumpAndSettle(); }
    for (var i = 0; i < 3; i++) { await key(LogicalKeyboardKey.arrowRight); }
    await key(LogicalKeyboardKey.arrowDown); expect(isAppCardFocused(tester, 'edge.7'), isTrue);
    await key(LogicalKeyboardKey.arrowDown); expect(isAppCardFocused(tester, 'edge.9'), isTrue);
    await key(LogicalKeyboardKey.arrowUp); expect(isAppCardFocused(tester, 'edge.7'), isTrue);
    await key(LogicalKeyboardKey.arrowDown);
    await key(LogicalKeyboardKey.arrowDown); expect(isAppCardFocused(tester, 'next.1'), isTrue);
    await key(LogicalKeyboardKey.arrowUp); expect(isAppCardFocused(tester, 'edge.9'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rapid arrows, relayout and removal preserve a single meaningful selection', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    addTearDown(appearance.dispose);
    final apps = mkAppService();
    final category = fakeCategory(type: CategoryType.row)
      ..applications.addAll(List.generate(24, (i) => fakeApp(packageName: 'rapid.$i')));
    when(apps.launcherSections).thenReturn([category]);
    await appearance.setCategory(category.id, 'columns', 4);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance, pixelRatio: 2);
    for (var i = 0; i < 6; i++) { await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); }
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'rapid.6'), isTrue);
    for (final mode in ['rows', 'grid', 'row']) {
      await appearance.setCategory(category.id, 'layout', mode);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'rapid.6'), isTrue);
      final packages = tester.widgetList<AppCard>(find.byType(AppCard)).map((c) => c.application.packageName).toList();
      expect(packages.toSet().length, packages.length);
    }
    category.applications.removeWhere((a) => a.packageName == 'rapid.6');
    await appearance.set('horizontalGap', 18);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'rapid.7'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    getSettingsFocusNode(tester)!.requestFocus();
    await tester.pumpAndSettle();
    expect(isSettingsIconFocused(tester), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final sort in [CategorySort.mostUsed, CategorySort.lastUsed]) {
    for (final type in [CategoryType.row, CategoryType.grid]) {
      testWidgets('usage order refreshes immediately with section focused: $sort $type', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        final apps = mkAppService();
        final appearance = AppearanceService(await SharedPreferences.getInstance());
        final category = fakeCategory(sort: sort, type: type)
          ..applications.addAll([
            fakeApp(packageName: 'usage.a'),
            fakeApp(packageName: 'usage.b'),
            ...List.generate(38, (i) => fakeApp(packageName: 'usage.extra.$i')),
          ]);
        when(apps.launcherSections).thenReturn([category]);
        await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance);
        getFocusNodeForApp(tester, 'usage.b')!.requestFocus();
        await tester.pumpAndSettle();
        List<String> order() => tester.widgetList<AppCard>(find.byType(AppCard))
            .map((card) => card.application.packageName).toList();
        final launched = category.applications[1];
        when(apps.launchApp(launched)).thenAnswer((_) async {
          launched.launchCount++;
          category.applications.remove(launched);
          category.applications.add(launched);
          // A provider notification rebuilds the section after recording usage.
          await appearance.set('animateReordering', true);
          return true;
        });
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        verify(apps.launchApp(launched)).called(1);
        expect(launched.launchCount, 1);
        expect(order().last, 'usage.b');
        expect(isAppCardFocused(tester, 'usage.b'), isTrue);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();
        expect(order().last, 'usage.b');
        expect(isAppCardFocused(tester, 'usage.b'), isTrue);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpWidget(const SizedBox());
        appearance.dispose();
      });
    }
  }

  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.single.physicalSize = Size(1280, 720);
    binding.platformDispatcher.views.single.devicePixelRatio = 1.0;
    // Scale-down the font size because the font 'Ahem' used when running tests is much wider than Roboto
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  testWidgets("Home page shows categories with apps", (tester) async {
    final appsService = mkAppService();
    final favoritesCategory = fakeCategory(name: "Favorites", order: 0, type: CategoryType.row);
    final applicationsCategory = fakeCategory(name: "Applications", order: 1);
    favoritesCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher.1",
      name: "FLauncher 1",
      version: "1.0.0",
    ));
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher.2",
      name: "FLauncher 2",
      version: "2.0.0",
    ));
    when(appsService.launcherSections).thenReturn([
      favoritesCategory,
      applicationsCategory,
    ]);

    await _pumpWidgetWith(tester, appsService);

    expect(find.text("Applications"), findsOneWidget);
    expect(find.text("Favorites"), findsOneWidget);
    expect(find.byType(HomeSection), findsNWidgets(2));
    expect(find.byKey(Key("me.efesser.flauncher.2")), findsOneWidget);

    expect(find.byKey(Key("me.efesser.flauncher.1")), findsOneWidget);

    // This was changed by how the the image is made, I don't know what it now should be
    //expect(tester.widget(find.byKey(Key("background"))), isA<Container>());

  });

  for (final type in CategoryType.values) {
    testWidgets('startup focuses first usable category: $type', (tester) async {
      final strategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      addTearDown(() => FocusManager.instance.highlightStrategy = strategy);
      final apps = mkAppService();
      final hidden = fakeCategory(type: type)..visible = false;
      final first = fakeCategory(type: type)..applications.add(fakeApp(packageName: 'startup.first'));
      when(apps.launcherSections).thenReturn([hidden, first]);
      final settings = mkSettingsService();
      when(settings.cardFocusMode).thenReturn(CardFocusMode.first);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings);
      expect(isAppCardFocused(tester, 'startup.first'), isTrue);
      final surface = find.descendant(
        of: find.byWidgetPredicate((widget) => widget is AppCard &&
            widget.application.packageName == 'startup.first'),
        matching: find.byType(AppearanceSurface),
      );
      expect(tester.widget<AppearanceSurface>(surface).focused, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  for (final type in CategoryType.values) {
    for (final custom in [false, true]) {
      testWidgets('hidden app remains visible and focusable in manual section: $type, custom=$custom', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final db = FLauncherDatabase.inMemory();
        final channel = MockFLauncherChannel();
        when(channel.getApplications()).thenAnswer((_) async => [
          {'packageName': 'manual.hidden', 'name': 'Hidden candidate', 'version': '1', 'sideloaded': false},
          {'packageName': 'manual.other', 'name': 'Other', 'version': '1', 'sideloaded': false},
        ]);
        when(channel.addAppsChangedListener(any)).thenReturn(null);
        when(channel.getApplicationIcon(any)).thenAnswer((_) async => kTransparentImage);
        when(channel.getApplicationBanner(any)).thenAnswer((_) async => kTransparentImage);
        late AppsService apps;
        late Category manual;
        try {
          await tester.runAsync(() async {
            apps = AppsService(channel, db);
            for (var i = 0; i < 200 && !apps.initialized; i++) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
            expect(apps.initialized, isTrue);
            final id = custom ? await apps.addCategory('Custom')
                : apps.categories.firstWhere((category) => category.systemKey == 'favorites').id;
            manual = apps.categories.firstWhere((category) => category.id == id);
            await apps.setCategoryType(manual, type);
            manual = apps.categories.firstWhere((category) => category.id == id);
            await apps.addToCategory(apps.getApp('manual.hidden')!, manual);
            await apps.addToCategory(apps.getApp('manual.other')!, manual);
            for (final category in apps.categories.where((category) => category.id != manual.id)) {
              await apps.setCategoryVisible(category.id, false);
            }
          });
          final settings = mkSettingsService();
          when(settings.cardFocusMode).thenReturn(CardFocusMode.first);
          await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings);
          expect(isAppCardFocused(tester, 'manual.hidden'), isTrue);
          await tester.runAsync(() => apps.hideApplication(apps.getApp('manual.hidden')!));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('manual.hidden')), findsOneWidget);
          expect(isAppCardFocused(tester, 'manual.hidden'), isTrue);
          expect(apps.categories.where((category) => category.isAutomatic).every((category) =>
              category.applications.every((app) => app.packageName != 'manual.hidden')), isTrue);
          await tester.runAsync(() => apps.removeFromCategory(apps.getApp('manual.other')!, manual));
          await tester.pumpAndSettle();
          await tester.runAsync(apps.refreshState);
          await tester.pumpAndSettle();
          tester.state<FLauncherState>(find.byType(FLauncher)).returnHome();
          await tester.pumpAndSettle();
          expect(isAppCardFocused(tester, 'manual.hidden'), isTrue);
          await tester.runAsync(() => apps.addToCategory(apps.getApp('manual.other')!, manual));
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
          expect(isAppCardFocused(tester, 'manual.other'), isTrue);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          await tester.pumpAndSettle();
          expect(isAppCardFocused(tester, 'manual.hidden'), isTrue);
          await tester.runAsync(() => apps.removeFromCategory(apps.getApp('manual.hidden')!, manual));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('manual.hidden')), findsNothing);
          expect(isAppCardFocused(tester, 'manual.other'), isTrue);
          await tester.runAsync(() => apps.showApplication(apps.getApp('manual.hidden')!));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('manual.hidden')), findsNothing);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() async { apps.dispose(); await db.close(); });
        }
      });
    }
  }

  for (final remember in [false,true]) {
    for (final type in CategoryType.values) {
    testWidgets('section entry uses nearest edge card despite legacy memory: $remember, $type', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      await appearance.preferences.setString('tile_appearance', '{"rememberSection":$remember}');
      final apps=mkAppService();
      final top=fakeCategory(type: CategoryType.row)..applications.add(fakeApp(packageName:'memory.top'));
      final bottom=fakeCategory(type: type)..applications.addAll(List.generate(10,(i)=>fakeApp(packageName:'memory.$i')));
      when(apps.launcherSections).thenReturn([top,bottom]);
      await _pumpWidgetWithProviders(tester,mkWallpaperService(),apps,mkSettingsService(),appearance:appearance);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); await tester.pumpAndSettle();
      for(var i=0;i<3;i++) { await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); await tester.pumpAndSettle(); }
      expect(isAppCardFocused(tester,'memory.3'),isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp); await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); await tester.pumpAndSettle();
      expect(isAppCardFocused(tester,'memory.0'),isTrue);
      await tester.pumpWidget(const SizedBox());appearance.dispose();
    });
    }
  }

  for (final type in CategoryType.values) {
    for (final mode in CardFocusMode.values) {
      testWidgets('Home restores selected section in $type, mode=$mode', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final settings = SettingsService(await SharedPreferences.getInstance());
        await settings.setCardFocusMode(mode);
        await settings.setAppKeyClickEnabled(false);
        await settings.setAppHighlightAnimationEnabled(false);
        final apps = mkAppService();
        final top = fakeCategory(type: type)..applications.add(fakeApp(packageName: 'return.top'));
        final bottom = fakeCategory(type: type)..applications.addAll(List.generate(24, (i) => fakeApp(packageName: 'return.$i')));
        when(apps.launcherSections).thenReturn([top, bottom]);
        await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings);
        getFocusNodeForApp(tester, 'return.1')!.requestFocus();
        await tester.pumpAndSettle();
        if (type == CategoryType.row) {
          for (var i = 0; i < 9; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
            await tester.pumpAndSettle();
          }
        } else {
          getFocusNodeForApp(tester, 'return.10')!.requestFocus();
          await tester.pumpAndSettle();
        }
        expect(isAppCardFocused(tester, 'return.10'), isTrue);
        tester.state<FocusAwareAppBarState>(find.byType(FocusAwareAppBar)).focusSettings();
        await tester.pumpAndSettle();
        tester.state<FLauncherState>(find.byType(FLauncher)).returnHome();
        await tester.pumpAndSettle();
        if (mode == CardFocusMode.settings) {
          expect(isSettingsIconFocused(tester), isTrue);
        } else {
          expect(isAppCardFocused(tester, mode == CardFocusMode.remember ? 'return.10' : 'return.top'), isTrue);
          bottom.visible = false;
          settings.reload();
          await tester.pumpAndSettle();
          tester.state<FLauncherState>(find.byType(FLauncher)).returnHome();
          await tester.pumpAndSettle();
          expect(isAppCardFocused(tester, 'return.top'), isTrue);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        settings.dispose();
      });
    }
  }

  testWidgets('returnHome restores launcher and focuses settings', (tester) async {
    final appsService = mkAppService();
    when(appsService.launcherSections).thenReturn([fakeCategory(name: 'Applications')]);
    await _pumpWidgetWith(tester, appsService);
    final state = tester.state<FLauncherState>(find.byType(FLauncher));
    final launcher = Provider.of<LauncherState>(tester.element(find.byType(FLauncher)), listen: false);
    launcher.toggleLauncherVisibility();
    await tester.pumpAndSettle();
    expect(launcher.launcherVisible, isFalse);
    state.returnHome();
    await tester.pumpAndSettle();
    expect(launcher.launcherVisible, isTrue);
    expect(isSettingsIconFocused(tester), isTrue);
  });

  testWidgets('returnHome keeps the list at the top when a large tile loses focus', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    await appearance.set('size', 256);
    await appearance.set('aspectRatio', 1);
    final service = mkAppService();
    final category = fakeCategory(name: 'Applications', type: CategoryType.grid, columnsCount: 6);
    category.applications.addAll(List.generate(60, (i) => fakeApp(packageName: 'home.$i')));
    when(service.launcherSections).thenReturn([category]);
    final settings = mkSettingsService();
    when(settings.cardFocusMode).thenReturn(CardFocusMode.settings);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), service, settings, appearance: appearance, pixelRatio: 2);
    getFocusNodeForApp(tester, 'home.8')!.requestFocus();
    await tester.pumpAndSettle();
    final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first).controller!;
    scroll.jumpTo(300);
    await tester.pump();
    tester.state<FLauncherState>(find.byType(FLauncher)).returnHome();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(isSettingsIconFocused(tester), isTrue);
    expect(scroll.offset, 0);
    await tester.pumpWidget(const SizedBox());
    appearance.dispose();
  });

  testWidgets('compact square tiles with large labels fit TV grid and remote follows effective columns', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    await appearance.set('labels', 'all');
    await appearance.set('size', 64);
    await appearance.set('aspectRatio', 1);
    await appearance.set('labelSize', 20);
    await appearance.set('horizontalGap', 48);
    await appearance.set('focusEffect', 'border');
    final service = mkAppService();
    final category = fakeCategory(name: 'Приложения с длинными названиями', type: CategoryType.grid, columnsCount: 6);
    await appearance.setCategory(category.id, 'layout', 'auto');
    category.applications.addAll(List.generate(24, (i) => fakeApp(packageName: 'geometry.$i', name: 'Очень длинное русское название приложения $i')));
    when(service.launcherSections).thenReturn([category]);
    final settings = mkSettingsService();
    when(settings.appHighlightAnimationEnabled).thenReturn(false);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), service, settings, appearance: appearance, pixelRatio: 2);
    getFocusNodeForApp(tester, 'geometry.0')!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'geometry.8'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    appearance.dispose();
  });

  for (final gap in ['empty', 'spacer', 'only empty above']) {
    testWidgets('Watch Next vertical navigation skips $gap', (tester) async {
      final apps = mkAppService();
      final top = fakeCategory(name: 'All Apps', order: 0);
      top.applications.add(fakeApp(packageName: 'top.app'));
      final bottom = fakeCategory(name: 'Bottom', order: 2);
      bottom.applications.add(fakeApp(packageName: 'bottom.app'));
      when(apps.applications).thenReturn([...top.applications, ...bottom.applications]);
      when(apps.launcherSections).thenReturn([
        if (gap != 'only empty above') top,
        if (gap == 'spacer') LauncherSpacer(id: 777, height: 120)
        else fakeCategory(name: 'Empty', order: 1),
        bottom,
      ]);
      final settings = mkSettingsService();
      when(settings.showContinueWatching).thenReturn(true);
      when(settings.continueWatchingOrder).thenReturn(gap == 'only empty above' ? 1 : 2);
      when(settings.continueWatchingMaxItems).thenReturn(15);
      when(settings.continueWatchingCardSize).thenReturn('normal');
      when(settings.hiddenWatchNextProgramIds).thenReturn([]);
      when(settings.hiddenWatchNextPackages).thenReturn([]);
      when(settings.continueWatchingShowProgress).thenReturn(false);
      when(settings.continueWatchingShowPercentage).thenReturn(false);
      when(settings.continueWatchingShowDescription).thenReturn(false);
      final watch = MockWatchNextService();
      when(watch.hasPermission).thenReturn(true);
      when(watch.programs).thenReturn([
        WatchNextProgram.fromMap({'id': 1, 'packageName': 'video.app', 'title': 'Video 1'}),
        WatchNextProgram.fromMap({'id': 2, 'packageName': 'video.app', 'title': 'Video 2'}),
      ]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings, watchNext: watch);
      FocusNode cardNode(int index) => tester.widget<InkWell>(find.descendant(
        of: find.byType(WatchNextCard).at(index), matching: find.byType(InkWell)).first).focusNode!;
      cardNode(0).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(cardNode(1).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      if (gap == 'only empty above') {
        expect(isSettingsIconFocused(tester), isTrue);
      } else {
        expect(isAppCardFocused(tester, 'top.app'), isTrue);
      }
      cardNode(0).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'bottom.app'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(cardNode(0).hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("Home page shows category empty-state", (tester) async {
    final appsService = mkAppService();
    final applicationsCategory = fakeCategory(name: "Applications", order: 0, type: CategoryType.grid);
    final favoritesCategory = fakeCategory(name: "Favorites", order: 1, type: CategoryType.row);
    when(appsService.launcherSections).thenReturn([
      applicationsCategory,
      favoritesCategory,
    ]);

    await _pumpWidgetWith(tester, appsService);

    expect(find.text("Applications"), findsOneWidget);
    expect(find.text("Favorites"), findsOneWidget);

    expect(find.byType(HomeSection), findsNWidgets(2));
    expect(find.text("This category is empty."), findsNWidgets(2));
  });

  testWidgets("Home page displays background image", (tester) async {
    final appsService = mkAppService();
    when(appsService.launcherSections).thenReturn([]);

    await _pumpWidgetWith(tester, appsService);

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets("Home page displays background gradient", (tester) async {
    final appsService = mkAppService();
    when(appsService.launcherSections).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mkWallpaperService(false), appsService, mkSettingsService());

    expect(tester.widget<WallpaperBackground>(find.byType(WallpaperBackground)).image, isNull);
  });

  testWidgets("Pressing select on settings icon opens SettingsPanel", (tester) async {
    final appsService = mkAppService();
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites", order: 0),
      fakeCategory(name: "Applications", order: 1),
    ]);
    await _pumpWidgetWith(tester, appsService);

    final settingsNode = getSettingsFocusNode(tester);
    settingsNode!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPanelPage), findsOneWidget);
  });

  testWidgets("Pressing select on app opens ApplicationInfoPanel", (tester) async {
    final appsService = mkAppService();
    final app = fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    );
    final fav = fakeCategory(name: "Favorites", order: 0);
    final apps = fakeCategory(name: "Applications", order: 1);
    apps.applications.add(app);
    when(appsService.launcherSections).thenReturn([
      fav,
      apps,
    ]);
    await _pumpWidgetWith(tester, appsService);

    final inkWellFinder = find.descendant(
      of: find.byKey(Key("me.efesser.flauncher")),
      matching: find.byType(InkWell),
    );
    final FocusNode focusNode = tester.widget<InkWell>(inkWellFinder).focusNode!;
    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 500));

    verify(appsService.launchApp(app));
  });

  testWidgets("Long pressing on app opens ApplicationInfoPanel", (tester) async {
    const startupChannel = MethodChannel('cutelauncher/auto_launch');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(startupChannel,
      (_) async => {'apps': [], 'outcomes': {}});
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(startupChannel, null));
    final appsService = mkAppService();
    final applicationsCategory = fakeCategory(name: "Applications", order: 1);
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    ));
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites", order: 0),
      applicationsCategory,
    ]);
    await _pumpWidgetWith(tester, appsService);

    await tester.longPress(find.byKey(Key("me.efesser.flauncher")));
    await tester.pump();

    expect(find.byType(ApplicationInfoPanel), findsOneWidget);
  });

  testWidgets("AppCard moves in grid", (tester) async {
    final appsService = mkAppService();
    final applicationsCategory = fakeCategory(name: "Applications", order: 1, type: CategoryType.grid);
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    ));
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher.2",
      name: "FLauncher 2",
      version: "1.0.0",
    ));
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites", order: 0),
      applicationsCategory,
    ]);
    await _pumpWidgetWith(tester, appsService);

    await tester.longPress(find.byKey(Key("me.efesser.flauncher")));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Reorder"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    verify(appsService.reorderApplication(applicationsCategory, 0, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    verify(appsService.saveApplicationOrderInCategory(applicationsCategory));
  });

  testWidgets("AppCard reorder cancels on Back button", (tester) async {
    final appsService = mkAppService();
    final applicationsCategory = fakeCategory(name: "Applications", order: 1, type: CategoryType.grid);
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    ));
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher.2",
      name: "FLauncher 2",
      version: "1.0.0",
    ));
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites", order: 0),
      applicationsCategory,
    ]);
    await _pumpWidgetWith(tester, appsService);

    await tester.longPress(find.byKey(Key("me.efesser.flauncher")));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Reorder"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    verify(appsService.reorderApplication(applicationsCategory, 0, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
    await tester.pump();
    verify(appsService.cancelReorderApplication(applicationsCategory));
  });

  testWidgets("AppCard moves in row", (tester) async {
    final appsService = mkAppService();
    final applicationsCategory = fakeCategory(name: "Applications", order: 1, type: CategoryType.row);
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    ));
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher.2",
      name: "FLauncher 2",
      version: "1.0.0",
    ));
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites", order: 0),
      applicationsCategory,
    ]);
    await _pumpWidgetWith(tester, appsService);

    await tester.longPress(find.byKey(Key("me.efesser.flauncher")));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Reorder"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    verify(appsService.reorderApplication(applicationsCategory, 0, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    verify(appsService.saveApplicationOrderInCategory(applicationsCategory));
  });

  testWidgets("Moving down does not skip row", (tester) async {
    // given
    final appsService = mkAppService();

    /*
     * we are creating 3 rows like the following:
     * ▭ ▭ ▭
     * ▭ ▭
     * ▭ ▭ ▭
     */
    final tvCat = fakeCategory(name: "tv", order: 0);
    tvCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.tv1",
        name: "tv 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.tv2",
        name: "tv 2",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.tv3",
        name: "tv 3",
        version: "1.0.0",
      ),
    ]);
    final musicCat = fakeCategory(name: "music", order: 1);
    musicCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.music1",
        name: "music 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music2",
        name: "music 2",
        version: "1.0.0",
      ),
    ]);
    final gamesCat = fakeCategory(name: "games", order: 2);
    gamesCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.game1",
        name: "game 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.game2",
        name: "game 2",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.game3",
        name: "game 3",
        version: "1.0.0",
      ),
    ]);
    when(appsService.launcherSections).thenReturn([
      tvCat,
      musicCat,
      gamesCat,
    ]);

    await _pumpWidgetWith(tester, appsService);
    // when
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    // then
    Element? tv1 = findAppCardByPackageName(tester, "me.efesser.tv1");
    expect(tv1, isNotNull);
    Element? music2 = findAppCardByPackageName(tester, "me.efesser.music2");
    expect(music2, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.music2"), isTrue); // first-card mode still visits each row

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    Element? game2 = findAppCardByPackageName(tester, "me.efesser.game2");
    expect(game2, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.music2"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.game2"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.music2"), isTrue);
    expect(isAppCardFocused(tester, "me.efesser.game2"), isFalse);
  });

  testWidgets("Moving left or right stays on the same row", (tester) async {
    // given
    final appsService = mkAppService();

    /*
     * we are creating 2 rows like the following:
     * ▭ ▭
     * ▭ ▭ ▭ ▭ ▭
     */
    final tvCat = fakeCategory(name: "tv", order: 0);
    tvCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.tv1",
        name: "tv 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.tv2",
        name: "tv 2",
        version: "1.0.0",
      ),
    ]);
    final musicCat = fakeCategory(name: "music", order: 1, columnsCount: 5);
    musicCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.music1",
        name: "music 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music2",
        name: "music 2",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music3",
        name: "music 3",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music4",
        name: "music 4",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music5",
        name: "music 5",
        version: "1.0.0",
      ),
    ]);
    when(appsService.launcherSections).thenReturn([
      tvCat,
      musicCat,
    ]);

    await _pumpWidgetWith(tester, appsService);

    // then
    Element? tv1 = findAppCardByPackageName(tester, "me.efesser.tv1");
    expect(tv1, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    Element? music1 = findAppCardByPackageName(tester, "me.efesser.music1");
    expect(music1, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.music1"), isTrue);

    // check right direction
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    Element? music2 = findAppCardByPackageName(tester, "me.efesser.music2");
    expect(music2, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.music1"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.music2"), isTrue);

    // check if right on the last app stays on the same app
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    Element? music5 = findAppCardByPackageName(tester, "me.efesser.music5");
    expect(music5, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.music5"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    Element? tv2 = findAppCardByPackageName(tester, "me.efesser.tv2");
    expect(tv2, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv2"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(isAppCardFocused(tester, "me.efesser.music2"), isTrue);

    // check left direction
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(isAppCardFocused(tester, "me.efesser.music1"), isTrue);

    // check if going left on the first app stays on the same app
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(isAppCardFocused(tester, "me.efesser.music1"), isTrue);
  });

  testWidgets("Moving right or up can go the settings icon", (tester) async {
    // given
    final appsService = mkAppService();

    /*
     * we are creating 2 rows like the following:
     * ▭ ▭
     * ▭ ▭ ▭
     */
    final tvCat = fakeCategory(name: "tv", order: 0);
    tvCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.tv1",
        name: "tv 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.tv2",
        name: "tv 2",
        version: "1.0.0",
      ),
    ]);
    final musicCat = fakeCategory(name: "music", order: 1);
    musicCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.music1",
        name: "music 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music2",
        name: "music 2",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music3",
        name: "music 3",
        version: "1.0.0",
      ),
    ]);
    when(appsService.launcherSections).thenReturn([
      tvCat,
      musicCat,
    ]);

    await _pumpWidgetWith(tester, appsService);

    // then
    Element? tv1 = findAppCardByPackageName(tester, "me.efesser.tv1");
    expect(tv1, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();


    Element? settingsIcon = findSettingsIcon(tester);
    expect(settingsIcon, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isFalse);
    expect(isSettingsIconFocused(tester), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(isSettingsIconFocused(tester), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(isSettingsIconFocused(tester), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(isAppCardFocused(tester, "me.efesser.tv2"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(isSettingsIconFocused(tester), isTrue);
  });
}

SettingsService mkSettingsService() {
  final settingsService = MockSettingsService();
  when(settingsService.screenshotScene).thenReturn(null);
  when(settingsService.sleepTimerConfiguration).thenReturn(SleepTimerConfiguration());
  final demo = ValueNotifier<LandscapeDemoFrame?>(null);
  addTearDown(demo.dispose);
  when(settingsService.landscapeDemo).thenReturn(demo);
  when(settingsService.appKeyClickEnabled).thenReturn(false);
  when(settingsService.homeKeyClickEnabled).thenReturn(false);
  when(settingsService.showSleepTimerInStatusBar).thenReturn(false);
  when(settingsService.showNightModeInStatusBar).thenReturn(false);
  when(settingsService.settingsMenuOnRight).thenReturn(false);
  when(settingsService.backgroundSource).thenReturn('picture');
  when(settingsService.wallpaperFit).thenReturn('cover');
  when(settingsService.wallpaperBrightness).thenReturn(1);
  when(settingsService.wallpaperSaturation).thenReturn(1);
  when(settingsService.wallpaperDimming).thenReturn(1);
  when(settingsService.memorySaverEnabled).thenReturn(false);
  when(settingsService.watchNextAppLimits).thenReturn({});
  when(settingsService.rememberCategoryFocus).thenReturn(false);
  when(settingsService.cardFocusMode).thenReturn(CardFocusMode.first);
  when(settingsService.dateFormat).thenReturn(SettingsService.defaultDateFormat);
  when(settingsService.timeFormat).thenReturn(SettingsService.defaultTimeFormat);
  when(settingsService.appHighlightAnimationEnabled).thenReturn(false);
  when(settingsService.showCategoryTitles).thenReturn(true);
  when(settingsService.autoHideAppBarEnabled).thenReturn(false);
  when(settingsService.showInputsWidgetInStatusBar).thenReturn(true);
  when(settingsService.showSystemSettingsInStatusBar).thenReturn(true);
  when(settingsService.showNetworkIndicatorInStatusBar).thenReturn(true);
  when(settingsService.showVolumeInStatusBar).thenReturn(false);
  when(settingsService.showSystemInStatusBar).thenReturn(false);
  when(settingsService.showNetworkSpeedInStatusBar).thenReturn(false);
  when(settingsService.networkSpeedInterval).thenReturn(3);
  when(settingsService.showDataWidgetInStatusBar).thenReturn(true);
  when(settingsService.showDateInStatusBar).thenReturn(true);
  when(settingsService.showTimeInStatusBar).thenReturn(true);
  when(settingsService.accentColorHex).thenReturn('00ff00');
  when(settingsService.showAppNamesBelowIcons).thenReturn(true);
  when(settingsService.themes).thenReturn('classic');
  when(settingsService.screensaverClockStyle).thenReturn('classic');
  when(settingsService.hideHighlightOutlineOnHomescreen).thenReturn(false);
  when(settingsService.appSelectorTransitionAnimationEnabled).thenReturn(true);
  when(settingsService.showContinueWatching).thenReturn(false);
  when(settingsService.continueWatchingOrder).thenReturn(0);
  when(settingsService.showNotificationsWidgetInStatusBar).thenReturn(true);
  when(settingsService.autoHideNotificationsWidget).thenReturn(false);
  when(settingsService.showWeatherInStatusBar).thenReturn(false);
  when(settingsService.showWeatherWarnings).thenReturn(false);
  when(settingsService.useFahrenheit).thenReturn(false);
  return settingsService;
}

WallpaperService mkWallpaperService([bool wallpaper = true]) {
  final wallpaperService = MockWallpaperService();
  when(wallpaperService.video).thenReturn(null);
  when(wallpaperService.gradient).thenReturn(FLauncherGradients.greatWhale);
  when(wallpaperService.wallpaper).thenReturn(wallpaper ? Image.asset('assets/icon.png').image : null);
  when(wallpaperService.version).thenReturn(0);
  return wallpaperService;
}

TvInputsService mkTvInputsService() {
  final tvInputsService = MockTvInputsService();
  when(tvInputsService.hasInputs).thenReturn(false);
  when(tvInputsService.initialized).thenReturn(false);
  return tvInputsService;
}

NotificationsService mkNotificationsService() {
  final notificationsService = MockNotificationsService();
  when(notificationsService.getNotificationCount(any)).thenReturn(0);
  when(notificationsService.hasPermission).thenReturn(false);
  when(notificationsService.notifications).thenReturn([]);
  return notificationsService;
}

WatchNextService mkWatchNextService() {
  final watchNextService = MockWatchNextService();
  when(watchNextService.programs).thenReturn([]);
  return watchNextService;
}

WeatherService mkWeatherService() {
  final weatherService = MockWeatherService();
  when(weatherService.stale).thenReturn(false);
  when(weatherService.configuration).thenReturn(const WeatherConfiguration());
  when(weatherService.hasWeather).thenReturn(false);
  when(weatherService.weatherData).thenReturn(null);
  when(weatherService.isBreezyInstalled).thenReturn(false);
  return weatherService;
}

AppsService mkAppService() {
  final appsService = MockAppsService();
  when(appsService.imageRevisionFor(any)).thenReturn((0, 0));
  when(appsService.isTileHidden(any)).thenReturn(false);
    when(appsService.launchApp(any)).thenAnswer((_) async => true);
  when(appsService.initialized).thenReturn(true);
  when(appsService.getAppBanner(any)).thenAnswer((_) async => kTransparentImage);
  when(appsService.getAppIcon(any)).thenAnswer((_) async => kTransparentImage);
  when(appsService.pendingReorderFocusPackage).thenReturn(null);
  when(appsService.hasCustomBanner(any)).thenAnswer((_) async => false);
  when(appsService.isAppInFavorites(any)).thenReturn(false);
  return appsService;
}


Future<void> _pumpWidgetWith(
  WidgetTester tester,
  AppsService appsService,
  ) async {
  return _pumpWidgetWithProviders(tester, mkWallpaperService(), appsService, mkSettingsService());
}

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  WallpaperService wallpaperService,
  AppsService appsService,
  SettingsService settingsService,
  {AppearanceService? appearance, UpdateService? updates, RemotePanelService? remotePanel, WatchNextService? watchNext, AppChannelsService? feeds, double pixelRatio = 1, Locale? locale}) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = pixelRatio;
  final network = MockNetworkService();
  when(network.networkType).thenReturn(NetworkType.Unknown);
  when(network.cellularNetworkType).thenReturn(CellularNetworkType.Unknown);
  when(network.wirelessNetworkSignalLevel).thenReturn(0);
  when(network.hasInternetAccess).thenReturn(false);
  when(network.vpnActive).thenReturn(false);
  when(network.dailyDataUsage).thenReturn(0);
  when(network.hasUsageStatsPermission).thenReturn(false);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        if (feeds != null) ChangeNotifierProvider<AppChannelsService>.value(value: feeds),
        if (remotePanel != null) ChangeNotifierProvider.value(value: remotePanel),
        if (updates != null) ChangeNotifierProvider<UpdateService>.value(value: updates),
        if (appearance != null) ChangeNotifierProvider<AppearanceService>.value(value: appearance),
        ChangeNotifierProvider<WallpaperService>.value(value: wallpaperService),
        ChangeNotifierProvider<AppsService>.value(value: appsService),
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider<TvInputsService>.value(value: mkTvInputsService()),
        ChangeNotifierProvider<NotificationsService>.value(value: mkNotificationsService()),
        ChangeNotifierProvider<WatchNextService>.value(value: watchNext ?? mkWatchNextService()),
        ChangeNotifierProvider<WeatherService>.value(value: mkWeatherService()),
        ChangeNotifierProvider(create: (_) => LauncherState()),
        ChangeNotifierProvider<NetworkService>(create: (_) => network),
      ],
      builder: (_, _) => MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: FLauncher(),
      ),
    ),
  );
  await tester.pump(Duration(seconds: 30), EnginePhase.sendSemanticsUpdate);
  // Image decoding runs outside the fake test clock. Wait before interacting
  // with the home screen, which is now revealed only after decoding completes.
  await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
}

FocusNode? getFocusNodeForApp(WidgetTester tester, String packageName) {
  final appCardFinder = find.byWidgetPredicate((widget) =>
    widget is AppCard && widget.application.packageName == packageName
  );
  if (appCardFinder.evaluate().isEmpty) return null;
  final inkWellFinder = find.descendant(
    of: appCardFinder,
    matching: find.byType(InkWell),
  );
  if (inkWellFinder.evaluate().isEmpty) return null;
  final inkWell = tester.widget<InkWell>(inkWellFinder);
  return inkWell.focusNode;
}

FocusNode? getSettingsFocusNode(WidgetTester tester) {
  try {
    final appBarState = tester.state<FocusAwareAppBarState>(find.byType(FocusAwareAppBar));
    return appBarState.settingsFocusNode;
  } catch (e) {
    return null;
  }
}

bool isAppCardFocused(WidgetTester tester, String packageName) {
  final focusNode = getFocusNodeForApp(tester, packageName);
  return focusNode?.hasFocus ?? false;
}

bool isSettingsIconFocused(WidgetTester tester) {
  final focusNode = getSettingsFocusNode(tester);
  return focusNode?.hasFocus ?? false;
}

Future<void> expectGlowEdges(WidgetTester tester, RenderBox artwork) async {
  final rect = Rect.fromPoints(artwork.localToGlobal(Offset.zero),
      artwork.localToGlobal(artwork.size.bottomRight(Offset.zero)));
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.ancestor(
        of: find.byType(FLauncher), matching: find.byType(RepaintBoundary)).first);
    final image = await boundary.toImage();
    final pixels = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    int brightness(double x) {
      final point = boundary.globalToLocal(Offset(x, rect.center.dy));
      final at = (point.dy.floor() * image.width + point.dx.floor()) * 4;
      return pixels.getUint8(at + 1) + pixels.getUint8(at + 2);
    }
    // At 50% enlargement the 16 dp glow extends 24 dp outside the artwork.
    // Halfway through it must still be brighter than the background outside.
    for (final (edge, direction) in [(rect.left, -1), (rect.right, 1)]) {
      expect(brightness(edge + direction * 12),
          greaterThan(brightness(edge + direction * 26) + 20));
    }
    image.dispose();
  });
}
