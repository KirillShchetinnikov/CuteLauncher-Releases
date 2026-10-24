import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/landscape_page.dart';
import 'package:flauncher/widgets/settings/settings_route.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/information_settings_page.dart';
import 'package:flauncher/widgets/adaptive_landscape_background.dart';
import 'package:flauncher/widgets/landscape_demo_presentation.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flauncher/actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Back stops preview before the settings route is disposed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    addTearDown(settings.dispose);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: LandscapeDemoPresentation(
              child: Navigator(
                key: navigator,
                onGenerateRoute: (_) => SettingsRoute(
                  builder: (_) =>
                      const Scaffold(body: Text('previous settings')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    navigator.currentState!.push(
      SettingsRoute(builder: (_) => const LandscapePage()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Демонстрация изменений'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(settings.landscapeDemo.value, isNotNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(settings.landscapeDemo.value, isNull);
    expect(find.byType(LandscapePage), findsOneWidget);
    await tester.tap(find.text('Демонстрация изменений'));
    await tester.pump();
    await navigator.currentState!.maybePop();
    // Cancellation must happen before disposal finalizes under the widget-tree lock.
    final cancelledBeforeDispose = settings.landscapeDemo.value == null;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(cancelledBeforeDispose, true);
    expect(find.text('previous settings'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(settings.landscapeDemo.value, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'system Back stops preview without popping the nested settings page',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final appearance = AppearanceService(prefs);
      addTearDown(settings.dispose);
      addTearDown(appearance.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: appearance),
          ],
          child: MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showLauncherDialog<void>(
                    context: context,
                    styleDialog: false,
                    barrierColor: Colors.transparent,
                    builder: (_) => const SettingsPanel(
                      initialRoute: InformationSettingsPage.routeName,
                    ),
                  ),
                  child: const Text('open settings'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open settings'));
      await tester.pumpAndSettle();
      final navigator = tester.state<NavigatorState>(
        find.descendant(
          of: find.byType(SettingsPanel),
          matching: find.byType(Navigator),
        ),
      );
      navigator.push(SettingsRoute(builder: (_) => const LandscapePage()));
      await tester.pumpAndSettle();
      final pageState = tester.state(find.byType(LandscapePage));
      await tester.tap(find.text('Демонстрация изменений'));
      await tester.pumpAndSettle();
      expect(find.byType(LandscapePage), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(settings.landscapeDemo.value, isNull);
      expect(tester.state(find.byType(LandscapePage)), same(pageState));
      await tester.pump(const Duration(milliseconds: 300));
      expect(settings.landscapeDemo.value, isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LandscapePage), findsNothing);
      expect(find.byType(InformationSettingsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final onRight in [false, true]) {
    testWidgets(
      'demo hides settings and focuses the status stop button, side $onRight',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final settings = SettingsService(await SharedPreferences.getInstance());
        addTearDown(settings.dispose);
        final originalFocus = FocusNode();
        addTearDown(originalFocus.dispose);
        var builds = 0;
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: settings,
            child: MaterialApp(
              theme: ThemeData(
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff102030),
                    foregroundColor: const Color(0xff102030),
                  ),
                ),
                textTheme: ThemeData.dark().textTheme,
              ),
              locale: const Locale('ru'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.escape): BackIntent(),
              },
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(onRight ? 2 : 1)),
                child: child!,
              ),
              home: Scaffold(
                body: LandscapeDemoPresentation(
                  child: Builder(
                    builder: (_) {
                      builds++;
                      return Stack(
                        children: [
                          const LauncherPanelBackdrop(),
                          SidePanelDialog(
                            isRightSide: onRight,
                            width: 320,
                            child: TextButton(
                              focusNode: originalFocus,
                              autofocus: true,
                              onPressed: () {},
                              child: const Text('settings control'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(originalFocus.hasFocus, true);
        final originalBuilds = builds;
        settings.landscapeDemo.value = LandscapeDemoFrame(
          const Duration(milliseconds: 13334),
          DateTime(2026, 10, 24),
        );
        await tester.pumpAndSettle();
        expect(find.text('settings control'), findsNothing);
        expect(
          find.text('settings control', skipOffstage: false),
          findsOneWidget,
        );
        final stop = find.byKey(const ValueKey('landscape-demo-stop'));
        final progress = find.byKey(const ValueKey('landscape-demo-progress'));
        expect(stop, findsOneWidget);
        expect(tester.getCenter(progress).dx, closeTo(640, .1));
        expect(
          tester.getCenter(stop).dy,
          closeTo(
            tester
                .getCenter(find.byKey(const ValueKey('landscape-demo-time')))
                .dy,
            .1,
          ),
        );
        expect(tester.getSize(progress).width, lessThanOrEqualTo(332));
        expect(find.text('Стоп'), findsOneWidget);
        final button = tester.widget<FilledButton>(stop);
        final label = tester.widget<Text>(find.text('Стоп'));
        final foreground = label.style!.color!;
        for (final states in [
          <WidgetState>{},
          {WidgetState.focused},
          {WidgetState.pressed},
          {WidgetState.hovered},
        ]) {
          final background = button.style!.backgroundColor!.resolve(states)!;
          final contrast =
              (background.computeLuminance() + .05) /
              (foreground.computeLuminance() + .05);
          expect(contrast, greaterThanOrEqualTo(4.5));
          expect(button.style!.foregroundColor!.resolve(states), foreground);
        }
        final buttonFocus = FocusManager.instance.primaryFocus;
        expect(buttonFocus, isNot(same(originalFocus)));
        expect(
          buttonFocus!.context!.findAncestorWidgetOfExactType<FilledButton>(),
          isNotNull,
        );
        settings.landscapeDemo.value = LandscapeDemoFrame(
          LandscapeDemoFrame.dayDuration + const Duration(seconds: 5),
          DateTime(2026, 10, 24),
        );
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(buttonFocus));
        expect(find.text('Времена года · Осень · 12:00'), findsOneWidget);
        expect(builds, originalBuilds);
        if (onRight) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        } else {
          await tester.tap(stop);
        }
        await tester.pumpAndSettle();
        expect(settings.landscapeDemo.value, isNull);
        expect(find.text('settings control'), findsOneWidget);
        expect(originalFocus.hasFocus, true);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('realistic landscape uses the same warm sky overlay', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    addTearDown(settings.dispose);
    await settings.setLandscape(
      const LandscapeConfiguration(variant: 'realistic'),
    );
    settings.landscapeDemo.value = LandscapeDemoFrame(
      const Duration(milliseconds: 2611),
      DateTime(2026, 10, 24),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          home: const Scaffold(body: AdaptiveLandscapeBackground()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is LandscapeSkyGlowPainter,
      ),
      findsOneWidget,
    );
    final glow = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<LandscapeSkyGlowPainter>()
        .single;
    expect(glow.glow.strength, greaterThan(.99));
    expect(tester.takeException(), isNull);
    final seasonsCapture =
        Platform.environment['LANDSCAPE_SEASONS_CAPTURE'] == '1';
    final glowCapture = Platform.environment['LANDSCAPE_GLOW_CAPTURE'] == '1';
    final contactCapture =
        Platform.environment['LANDSCAPE_CONTACT_CAPTURE'] == '1';
    if (Platform.environment['LANDSCAPE_BODIES_CAPTURE'] == '1' ||
        seasonsCapture ||
        glowCapture ||
        contactCapture) {
      await tester.binding.setSurfaceSize(const Size(640, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = GlobalKey();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: MaterialApp(
            home: RepaintBoundary(
              key: key,
              child: const AdaptiveLandscapeBackground(),
            ),
          ),
        ),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      var index = 0;
      for (final variant in ['illustrated', 'realistic']) {
        await settings.setLandscape(
          LandscapeConfiguration(
            variant: variant,
            starRotation: seasonsCapture,
          ),
        );
        await tester.pump();
        final times = contactCapture
            ? [
                for (final minute in [359, 365, 1075, 1081])
                  DateTime(2026, 6, 21).add(Duration(minutes: minute)),
              ]
            : glowCapture
            ? [
                for (final minute in [350, 360, 380, 1080])
                  DateTime(2026, 6, 21).add(Duration(minutes: minute)),
              ]
            : seasonsCapture
            ? [
                DateTime(2026, 4, 24, 12),
                DateTime(2026, 7, 24, 12),
                DateTime(2026, 7, 24),
                DateTime(2026, 7, 24, 4),
              ]
            : [
                for (final minute in [720, 990, 0, 420])
                  DateTime(2026, 10, 24).add(Duration(minutes: minute)),
              ];
        for (final time in times) {
          settings.landscapeDemo.value = LandscapeDemoFrame(
            Duration.zero,
            time,
          );
          await tester.pump();
          if (variant == 'realistic') {
            final context = tester.element(
              find.byType(AdaptiveLandscapeBackground),
            );
            for (final widget in tester.widgetList<Image>(find.byType(Image))) {
              await tester.runAsync(() => precacheImage(widget.image, context));
            }
          }
          await tester.pumpAndSettle();
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = (await tester.runAsync(() => boundary.toImage()))!;
          canvas.drawImage(
            image,
            Offset((index % 4) * 640.0, (index ~/ 4) * 360.0),
            Paint(),
          );
          image.dispose();
          index++;
        }
      }
      final picture = recorder.endRecording();
      final image = (await tester.runAsync(() => picture.toImage(2560, 720)))!;
      final bytes = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      );
      await tester.runAsync(
        () => File(
          contactCapture
              ? '.local/landscape-contact-review.png'
              : glowCapture
              ? '.local/landscape-glow-review.png'
              : seasonsCapture
              ? '.local/landscape-seasons-stars-review.png'
              : '.local/landscape-bodies-review.png',
        ).writeAsBytes(bytes!.buffer.asUint8List()),
      );
      image.dispose();
      picture.dispose();
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'sun and moon switch persists and disables both variants including preview',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final appearance = AppearanceService(prefs);
      addTearDown(settings.dispose);
      addTearDown(appearance.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: appearance),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: LandscapePage()),
          ),
        ),
      );
      final rotation = find.text('Star rotation');
      await tester.ensureVisible(rotation);
      await tester.tap(rotation);
      await tester.pumpAndSettle();
      expect(settings.landscape.starRotation, true);
      final toggle = find.text('Sun and moon');
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(settings.landscape.celestialBodies, false);
      settings.reload();
      expect(settings.landscape.starRotation, true);
      expect(settings.landscape.celestialBodies, false);
      for (final variant in ['illustrated', 'realistic']) {
        await settings.setLandscape(
          settings.landscape.withValue('variant', variant),
        );
        settings.landscapeDemo.value = LandscapeDemoFrame(
          Duration.zero,
          DateTime(2026, 10, 24, 12),
        );
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: settings,
            child: const MaterialApp(
              home: Scaffold(body: AdaptiveLandscapeBackground()),
            ),
          ),
        );
        await tester.pump();
        settings.landscapeDemo.value = LandscapeDemoFrame(
          Duration.zero,
          DateTime(2026, 10, 24, 12),
        );
        await tester.pumpAndSettle();
        final painters = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter);
        expect(painters.whereType<LandscapeCelestialPainter>(), isEmpty);
        for (final sky in painters.whereType<LandscapeStarsPainter>()) {
          expect(sky.angle, closeTo(3.14159265, .00001));
        }
        for (final painter in painters.whereType<LandscapePainter>()) {
          expect(painter.bodies, isNull);
          expect(painter.starAngle, closeTo(3.14159265, .00001));
        }
        await settings.setLandscape(
          settings.landscape.withValue('celestialBodies', true),
        );
        await tester.pumpAndSettle();
        final enabled = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter);
        expect(
          variant == 'realistic'
              ? enabled.whereType<LandscapeCelestialPainter>().isNotEmpty
              : enabled.whereType<LandscapePainter>().any(
                  (p) => p.bodies != null,
                ),
          true,
        );
        await settings.setLandscape(
          settings.landscape.withValue('celestialBodies', false),
        );
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final variant in ['illustrated', 'realistic']) {
    testWidgets(
      'demo season transition discards old three-second controllers in $variant',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final settings = SettingsService(await SharedPreferences.getInstance());
        addTearDown(settings.dispose);
        await settings.setLandscape(
          LandscapeConfiguration(variant: variant, seasons: false),
        );
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: settings,
            child: const MaterialApp(
              home: Scaffold(body: AdaptiveLandscapeBackground()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final start = DateTime(2026, 1, 1, 12);
        settings.landscapeDemo.value = LandscapeDemoFrame(Duration.zero, start);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 550));
        final day = LandscapeDemoTimeline(start).dayDuration;
        for (var i = 0; i < 4; i++) {
          settings.landscapeDemo.value = LandscapeDemoFrame(
            day + Duration(seconds: i * 5),
            start,
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 550));
          final switcher = tester.widget<AnimatedSwitcher>(
            find.byType(AnimatedSwitcher),
          );
          expect(switcher.duration, const Duration(milliseconds: 500));
          if (variant == 'illustrated') {
            final scenes = tester
                .widgetList<CustomPaint>(find.byType(CustomPaint))
                .map((w) => w.painter)
                .whereType<LandscapePainter>()
                .toList();
            expect(
              scenes,
              hasLength(1),
              reason: 'no old season may linger through the two-second clear period',
            );
            expect(scenes.single.season, LandscapeDemoFrame.seasons[i]);
          } else {
            expect(
              find.byType(Image),
              findsOneWidget,
              reason: 'no old photograph may keep a three-second fade',
            );
          }
        }
        settings.landscapeDemo.value = null;
        await tester.pump();
        expect(
          tester
              .widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher))
              .duration,
          const Duration(seconds: 3),
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'preview Stop has a compact visible surface and a 48dp remote/touch target',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      addTearDown(settings.dispose);
      settings.landscapeDemo.value = LandscapeDemoFrame(
        Duration.zero,
        DateTime(2026, 10, 24, 12),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: LandscapeDemoPresentation(child: SizedBox()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final stop = find.byKey(const ValueKey('landscape-demo-stop'));
      final surface = find.descendant(
        of: stop,
        matching: find.byType(Material),
      );
      expect(tester.getSize(surface).height, 32);
      expect(tester.getSize(stop).height, greaterThanOrEqualTo(48));
      await tester.tap(stop);
      await tester.pump();
      expect(settings.landscapeDemo.value, isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final variant in ['illustrated', 'realistic']) {
    testWidgets(
      'demo moves rain/snow and rotates stars with saved movement off in $variant',
      (tester) async {
        final saved = LandscapeConfiguration(
          variant: variant,
          motion: false,
          starRotation: false,
          clouds: false,
          precipitation: false,
        );
        SharedPreferences.setMockInitialValues({
          landscapeSettingsKey: saved.encode(),
        });
        final prefs = await SharedPreferences.getInstance();
        final settings = SettingsService(prefs);
        addTearDown(settings.dispose);
        final start = DateTime(2026, 10, 24);
        final day = LandscapeDemoTimeline(start).dayDuration;
        settings.landscapeDemo.value = LandscapeDemoFrame(
          day + const Duration(milliseconds: 7500),
          start,
        );
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: settings,
            child: const MaterialApp(
              home: Scaffold(body: AdaptiveLandscapeBackground()),
            ),
          ),
        );
        LandscapeEffectsPainter effects() => tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<LandscapeEffectsPainter>()
            .single;
        for (final (elapsed, weather) in [
          (day + const Duration(milliseconds: 7500), LandscapeWeather.rain),
          (day + const Duration(milliseconds: 12500), LandscapeWeather.snow),
        ]) {
          settings.landscapeDemo.value = LandscapeDemoFrame(elapsed, start);
          await tester.pump();
          final painter = effects();
          expect(painter.weather, weather);
          expect(painter.config.motion, true);
          final before = painter.frame.value;
          await tester.pump(const Duration(milliseconds: 600));
          expect(
            painter.frame.value,
            greaterThan(before),
            reason:
                'precipitation must keep repainting without outer demo ticks',
          );
        }
        settings.landscapeDemo.value = LandscapeDemoFrame(Duration.zero, start);
        await tester.pumpAndSettle();
        double angle() => variant == 'illustrated'
            ? tester
                  .widgetList<CustomPaint>(find.byType(CustomPaint))
                  .map((w) => w.painter)
                  .whereType<LandscapePainter>()
                  .last
                  .starAngle
            : tester
                  .widgetList<CustomPaint>(find.byType(CustomPaint))
                  .map((w) => w.painter)
                  .whereType<LandscapeStarsPainter>()
                  .last
                  .angle;
        final initial = angle();
        settings.landscapeDemo.value = LandscapeDemoFrame(
          const Duration(seconds: 1),
          start,
        );
        await tester.pump();
        expect(angle(), greaterThan(initial));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        final paused = effects().frame.value;
        await tester.pump(const Duration(milliseconds: 600));
        expect(effects().frame.value, paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await settings.setMemorySaverEnabled(true);
        await tester.pump();
        final stopped = effects().frame.value;
        await tester.pump(const Duration(milliseconds: 600));
        expect(effects().frame.value, stopped);
        expect(prefs.getString(landscapeSettingsKey), saved.encode());
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('source parameters persist each effect independently', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final appearance = AppearanceService(prefs);
    addTearDown(settings.dispose);
    addTearDown(appearance.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: appearance),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(
            body: Stack(
              children: [
                AdaptiveLandscapeBackground(),
                LandscapeDemoPresentation(
                  child: Stack(
                    children: [
                      LauncherPanelBackdrop(),
                      SidePanelDialog(width: 380, child: LandscapePage()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final beforeStart = DateTime.now();
    await tester.tap(find.text('Демонстрация изменений'));
    final afterStart = DateTime.now();
    await tester.pump();
    final initialTime = settings.landscapeDemo.value!.now;
    expect(initialTime.isBefore(beforeStart), false);
    expect(initialTime.isAfter(afterStart), false);
    expect(find.text('Стоп'), findsOneWidget);
    expect(settings.landscapeDemo.value, isNotNull);
    settings.landscapeDemo.value = LandscapeDemoFrame(
      LandscapeDemoFrame.weatherStart + const Duration(seconds: 5),
      DateTime(2026, 10, 23),
    );
    await tester.pump();
    final effects = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<LandscapeEffectsPainter>()
        .single;
    expect(effects.weather, LandscapeWeather.rain);

    await tester.pump(const Duration(seconds: 1));
    expect(prefs.getString(landscapeSettingsKey), isNull);
    await tester.tap(find.text('Стоп'));
    await tester.pump();
    expect(settings.landscapeDemo.value, isNull);
    await tester.tap(find.text('Демонстрация изменений'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(settings.landscapeDemo.value, isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.text('Облака'));
    await tester.pumpAndSettle();
    expect(settings.landscape.clouds, false);
    expect(settings.landscape.precipitation, true);
    expect(settings.landscape.timeOfDay, true);
    expect(
      LandscapeConfiguration.decode(prefs.getString(landscapeSettingsKey))
          .clouds,
      false,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Демонстрация изменений'));
    await tester.tap(find.text('Демонстрация изменений'));
    await tester.pump();
    await tester.pump(
      LandscapeDemoFrame.cycleDuration - const Duration(milliseconds: 100),
    );
    expect(settings.landscapeDemo.value, isNotNull);
    await tester.pump(const Duration(milliseconds: 200));
    expect(settings.landscapeDemo.value, isNull);
    expect(find.text('Демонстрация изменений'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(settings.landscapeDemo.value, isNull);
    await tester.ensureVisible(find.text('Демонстрация изменений'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Демонстрация изменений'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(settings.landscapeDemo.value, isNull);
  });
}
