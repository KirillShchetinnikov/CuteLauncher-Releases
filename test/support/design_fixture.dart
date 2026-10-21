// Reproducible captures of production widgets; platform data is a fixed fixture.
// flutter test test/design_capture_test.dart --dart-define=CAPTURE_STAGE=after
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flauncher/flauncher_app.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/gradients.dart';
import 'package:flauncher/models/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../flauncher_test.dart' as fixtures;
import '../mocks.dart';
import '../mocks.mocks.dart';

import 'dart:convert';

import 'package:flauncher/providers/memory_resources.dart';
import 'package:flauncher/tile_appearance.dart';

class DesignFixture {
  final GlobalKey boundary;
  final AppearanceService appearance;
  final SettingsService settings;
  DesignFixture(this.boundary, this.appearance, this.settings);
}

Future<void> loadDesignFonts(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final entry in {
      'PanelSans': 'sans',
      'PanelSerif': 'serif',
      'PanelMono': 'mono',
      'PanelCondensed': 'condensed',
    }.entries) {
      await (FontLoader(entry.key)..addFont(
            File('assets/fonts/${entry.value}.ttf')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
    }
    final font = FontLoader('Roboto')
      ..addFont(
        File('test/design/fonts/DejaVuSans.ttf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    await font.load();
    final config = File('.dart_tool/package_config.json');
    final packages =
        (jsonDecode(await config.readAsString())
                as Map<String, dynamic>)['packages']
            as List;
    final flutter = packages.cast<Map<String, dynamic>>().singleWhere(
      (p) => p['name'] == 'flutter',
    );
    final root = config.absolute.uri.resolve('${flutter['rootUri']}/');
    final version = jsonDecode(
      await File.fromUri(root.resolve('../../bin/cache/flutter.version.json'))
          .readAsString(),
    ) as Map<String, dynamic>;
    if (version['frameworkRevision'] !=
        '5fc346839b5d0eef006ed8404392afb4dfae428d') {
      throw StateError('Design renderer must use pinned Flutter 3.47.6.');
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File.fromUri(
          root.resolve(
            '../../bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ),
        ).readAsBytes().then(ByteData.sublistView),
      );
    await icons.load();
  });
}

Future<DesignFixture> pumpDesignFixture(
  WidgetTester tester, {
  Size size = const Size(1920, 1080),
  double dpr = 2,
  double scale = 1,
  String language = 'ru',
  String theme = 'modern',
  Color accent = const Color(0xFF9674FF),
  FLauncherGradient? gradient,
  Map<String, dynamic> appearanceValues = const {},
  bool economy = false,
  bool longLabels = false,
  bool settingsMenuOnRight = false,
  Map<String, dynamic> categoryValues = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // The test default paints elevation as solid black; enable real shadows.
  debugDisableShadows = false;
  addTearDown(() => debugDisableShadows = true);
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('me.efesser.flauncher/event_home'),
    (_) async => null,
  );
  await loadDesignFonts(tester);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({
    tileAppearanceKey: jsonEncode(appearanceValues),
  });
  final appearance = AppearanceService(await SharedPreferences.getInstance());
  final apps = fixtures.mkAppService() as MockAppsService;
  when(apps.isDefaultLauncher()).thenAnswer((_) async => true);
  final settings = fixtures.mkSettingsService();
  when(settings.accentColor).thenReturn(accent);
  when(settings.accentColorHex)
      .thenReturn(accent.toARGB32().toRadixString(16).substring(2));
  when(settings.appLocale).thenReturn(Locale(language));
  when(settings.appLanguage).thenReturn(language);
  when(settings.backButtonAction).thenReturn('nothing');
  when(settings.cardFocusMode).thenReturn(CardFocusMode.settings);
  when(settings.appKeyClickEnabled).thenReturn(false);
  when(settings.settingsMenuOnRight).thenReturn(settingsMenuOnRight);
  when(settings.showCategoryTitles).thenReturn(true);
  when(settings.hideLauncherTile).thenReturn(false);
  when(settings.hideAndroidSettingsTile).thenReturn(true);
  when(settings.dataUsagePeriod).thenReturn('daily');
  when(settings.themes).thenReturn(theme);
  when(settings.memorySaverEnabled).thenReturn(economy);
  final memory = MemoryResources(settings: settings);
  when(settings.appHighlightAnimationEnabled).thenReturn(false);
  when(settings.showNetworkIndicatorInStatusBar).thenReturn(false);
  when(settings.showDataWidgetInStatusBar).thenReturn(false);
  when(settings.timeFormat).thenReturn("'20:30'");
  when(settings.dateFormat).thenReturn("'4 октября'");
  final wallpaper = fixtures.mkWallpaperService(false);
  when(wallpaper.gradient)
      .thenReturn(gradient ?? FLauncherGradients.viciousStance);
  final names = [
    longLabels ? 'Очень длинное название приложения для телевизора' : 'Кино',
    'Музыка',
    'Видео',
    'Галерея',
    'ТВ',
    'Файлы',
    'Радио',
    'Медиатека',
    'Браузер',
    'Подкасты',
  ];
  final colors = [0xFF4E456D, 0xFF854B5E, 0xFF306D78, 0xFF556F90, 0xFF477469];
  final banners = <String, Uint8List>{};
  await tester.runAsync(() async {
    for (var i = 0; i < names.length; i++) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 480, 270),
        Paint()..color = Color(colors[i % colors.length]),
      );
      canvas.drawCircle(
        const Offset(410, 35),
        170,
        Paint()..color = Colors.white.withValues(alpha: .06),
      );
      final text = TextPainter(
        text: TextSpan(
          text: names[i],
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 42,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset((480 - text.width) / 2, (270 - text.height) / 2),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(480, 270);
      banners['demo.$i'] = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      image.dispose();
      picture.dispose();
    }
  });
  when(apps.getAppBanner(any))
      .thenAnswer((call) async => banners[call.positionalArguments.first]!);
  final favorites = fakeCategory(
    name: 'Избранное',
    type: CategoryType.row,
    rowHeight: 130,
  );
  final all = fakeCategory(name: 'Все приложения', order: 1, columnsCount: 5);
  for (var i = 0; i < names.length; i++) {
    final app = fakeApp(packageName: 'demo.$i', name: names[i]);
    all.applications.add(app);
    if (i < 4 || categoryValues.isNotEmpty) favorites.applications.add(app);
  }
  for (final entry in categoryValues.entries) {
    await appearance.setCategory(favorites.id, entry.key, entry.value);
  }
  when(apps.categories).thenReturn([favorites, all]);
  when(apps.launcherSections).thenReturn([favorites, all]);
  final boundary = GlobalKey();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MemoryResources>.value(value: memory),
        ChangeNotifierProvider<AppearanceService>.value(value: appearance),
        ChangeNotifierProvider<AppsService>.value(value: apps),
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider<WallpaperService>.value(value: wallpaper),
        ChangeNotifierProvider<TvInputsService>.value(
          value: fixtures.mkTvInputsService(),
        ),
        ChangeNotifierProvider<NotificationsService>.value(
          value: fixtures.mkNotificationsService(),
        ),
        ChangeNotifierProvider<WatchNextService>.value(
          value: fixtures.mkWatchNextService(),
        ),
        ChangeNotifierProvider<WeatherService>.value(
          value: fixtures.mkWeatherService(),
        ),
        ChangeNotifierProvider(create: (_) => LauncherState()),
      ],
      child: RepaintBoundary(key: boundary, child: const FLauncherApp()),
    ),
  );
  await tester.pump();
  final imageContext = tester.element(find.byType(FLauncherApp));
  await tester.runAsync(() async {
    for (final bytes in banners.values) {
      await precacheImage(MemoryImage(bytes), imageContext);
    }
  });
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    appearance.dispose();
    memory.dispose();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
  return DesignFixture(boundary, appearance, settings);
}
