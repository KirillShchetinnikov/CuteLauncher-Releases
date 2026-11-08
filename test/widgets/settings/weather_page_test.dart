import 'package:flauncher/widgets/settings/information_settings_page.dart';
import 'package:flauncher/widgets/settings/information_preview.dart';
import 'package:flauncher/widgets/weather_display_text.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flauncher/information_formats.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/diagnostics_store.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/widgets/settings/weather_page.dart';
import 'package:flauncher/widgets/settings/settings_menu_layout.dart';
import 'package:flauncher/widgets/settings/settings_route.dart';
import 'package:flauncher/widgets/settings/local_file_browser.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flauncher/weather_text_format.dart';
import 'package:flauncher/weather_format_template.dart';
import 'package:flauncher/widgets/settings/weather_text_format_dialog.dart';
import 'package:flauncher/widgets/background_information.dart';
import 'package:flauncher/widgets/combined_information.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/weather_status_bar_widget.dart';
import 'package:flauncher/widgets/weather_glyph.dart';
import 'package:flauncher/widgets/settings/color_palette_dialog.dart';
import 'package:flauncher/widgets/settings/settings_option_tile.dart';
import 'package:flauncher/tile_appearance.dart';

import 'package:flauncher/widgets/settings/settings_section.dart';

import '../../mocks.mocks.dart';

class _Paths extends PathProviderPlatform {
  final String path;
  _Paths(this.path);
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _Transport implements WeatherTransport {
  final requests = <Uri>[];
  WeatherFailure? failure;
  @override
  Future<Map<String, dynamic>> request(Uri uri, {String? key, bool customServer = false, String? bearerToken, WeatherResponseDecoder? decode}) async {
    requests.add(uri);
    if (failure case final failure?) throw WeatherException(failure);
    return customServer ? {'current': {'temperature_2m': 4}} : {};
  }
}

void main() {
  late WeatherService service;
  late SettingsService settings;
  late AppearanceService appearance;
  late StreamController<dynamic> events;
  late Directory directory;
  late PathProviderPlatform originalPaths;
  late _Transport transport;
  setUp(() async {
    DiagnosticsStore.instance.clear();
    directory = await Directory.systemTemp.createTemp('weather-ui-');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(directory.path);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final channel = MockFLauncherChannel();
    events = StreamController<dynamic>.broadcast();
    when(channel.isBreezyWeatherInstalled()).thenAnswer((_) async => false);
    when(channel.getLatestWeatherData()).thenAnswer((_) async => null);
    when(
      channel.addWeatherChangedListener(any),
    ).thenAnswer((call) => events.stream.listen(call.positionalArguments[0]));
    transport = _Transport();
    service = WeatherService(channel, preferences: prefs, transport: transport);
    settings = SettingsService(prefs);
    appearance = AppearanceService(prefs);
    while (!service.initialized) {
      await Future<void>.delayed(Duration.zero);
    }
  });
  tearDown(() async {
    service.dispose();
    settings.dispose();
    appearance.dispose();
    await events.close();
    PathProviderPlatform.instance = originalPaths;
    await directory.delete(recursive: true);
  });
  Future<void> mount(WidgetTester tester, {Widget page = const WeatherPage(),
      Locale locale = const Locale('ru'), double scale = 1, double topInset = 0}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: service),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: appearance),
        ],
        child: MaterialApp(
          locale: locale,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: topInset == 0 ? child! : LauncherDialogArea(
              settingsOpen: false, onRight: true, topInset: topInset,
              child: child!,
            ),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: page),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
    for (var attempt = 0; attempt < 100 && !ready(); attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(ready(), isTrue);
    await tester.pumpAndSettle();
  }

  Finder tile(String label) =>
      find.widgetWithText(FocusableSettingsTile, label);

  for (final source in WeatherSource.values) {
    testWidgets(
      'weather groups omit inapplicable location and update: $source',
      (tester) async {
        tester.view.physicalSize = const Size(960, 4000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(
          () =>
              service.configure(service.configuration.copyWith(source: source)),
        );
        await mount(tester);
        final l = AppLocalizations.of(
          tester.element(find.byType(WeatherPage)),
        )!;
        List<String> titles() => tester
            .widgetList<SettingsSection>(find.byType(SettingsSection))
            .map((section) => section.title)
            .toList();
        final hasLocation =
            source != WeatherSource.breezy &&
            source != WeatherSource.customOpenMeteo;
        expect(titles().contains(l.weatherLocation), hasLocation);
        expect(
          titles().contains(l.settingsGroupUpdate),
          source != WeatherSource.breezy,
        );
        expect(
          find.text(l.weatherGetLocation),
          hasLocation ? findsOneWidget : findsNothing,
        );
        final before = titles();
        await appearance.set('settingsSectionStyle', 'accentBand');
        await tester.pumpAndSettle();
        expect(titles(), before);
        expect(service.configuration.source, source);
        service.didChangeAppLifecycleState(AppLifecycleState.paused);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final background in [false, true]) {
    for (final locale in [const Locale('ru'), const Locale('ar')]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('weather editor fits all insertion buttons without scrolling: background=$background locale=$locale scale=$scale', (tester) async {
          tester.view.physicalSize = const Size(960, 540);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          await appearance.set('panelCombinedInformation', !background);
          await settings.setWeatherTextFormat(parseWeatherTemplate('Моя погода: {TEMP} / {MAX} / {MIN} ({WARN}){BR}{CITY} {COND}').format!);
          await mount(tester, page: InformationDataSettingsPage(background: background), locale: locale, scale: scale, topInset: kToolbarHeight);
          final l = AppLocalizations.of(tester.element(find.byType(InformationDataSettingsPage)))!;
          final open = tile(l.weatherTextFormat);
          await tester.scrollUntilVisible(open, 150);
          await tester.pumpAndSettle();
          await tester.tap(open);
          await tester.pumpAndSettle();
          final dialog = find.byType(WeatherTextFormatDialog);
          final title = find.byKey(const Key('weather_format_title'));
          expect(tester.widget<Text>(title).data, l.weatherTextFormat);
          final destination = find.byKey(const Key('weather_format_destination'));
          expect(tester.widget<Text>(destination).data,
            ' — ${background ? l.informationOnBackground : l.topPanel}');
          expect(tester.renderObject<RenderParagraph>(find.descendant(of: destination, matching: find.byType(RichText))).didExceedMaxLines, isFalse);
          final viewport = find.descendant(of: dialog, matching: find.byType(SingleChildScrollView)).first;
          final scrollable = Scrollable.of(tester.element(find.byKey(const Key('weather_format_insert_buttons'))));
          expect(scrollable.position.pixels, 0);
          final visible = tester.getRect(viewport);
          final buttons = find.descendant(of: dialog, matching: find.byWidgetPredicate(
            (w) => w is LauncherDialogButton && w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('weather_format_add_'),
          ));
          expect(buttons, findsNWidgets(12));
          final firstButton = tester.getRect(buttons.first);
          final lastButton = tester.getRect(buttons.last);
          for (final button in buttons.evaluate()) {
            final rect = tester.getRect(find.byWidget(button.widget));
            expect(rect.center.dy, closeTo(firstButton.center.dy, 1));
            expect(rect.left, greaterThanOrEqualTo(visible.left));
            expect(rect.right, lessThanOrEqualTo(visible.right));
          }
          final legends = find.descendant(of: dialog, matching: find.byWidgetPredicate(
            (w) => w is Text && w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('weather_format_legend_'),
          ));
          expect(legends, findsNWidgets(12));
          final legendItems = legends.evaluate().toList();
          for (var index = 0; index < legendItems.length; index += 2) {
            final first = tester.getRect(find.byWidget(legendItems[index].widget));
            final second = tester.getRect(find.byWidget(legendItems[index + 1].widget));
            expect(first.top, closeTo(second.top, 1));
            final firstCell = tester.getRect(find.ancestor(
              of: find.byWidget(legendItems[index].widget), matching: find.byType(Expanded)).first);
            final secondCell = tester.getRect(find.ancestor(
              of: find.byWidget(legendItems[index + 1].widget), matching: find.byType(Expanded)).first);
            expect((firstCell.center.dx - secondCell.center.dx).abs(), greaterThan(visible.width / 3));
            if (index > 0) {
              final previous = tester.getRect(find.byWidget(legendItems[index - 2].widget));
              expect(first.top, greaterThanOrEqualTo(previous.bottom));
            }
          }
          for (final legend in legends.evaluate()) {
            final rect = tester.getRect(find.byWidget(legend.widget));
            expect(rect.top, greaterThanOrEqualTo(firstButton.bottom));
            expect(rect.bottom, lessThanOrEqualTo(visible.bottom));
            expect(rect.left, greaterThanOrEqualTo(visible.left));
            expect(rect.right, lessThanOrEqualTo(visible.right));
          }
          expect(lastButton.center.dy, closeTo(firstButton.center.dy, 1));
          for (final button in buttons.evaluate()) {
            final rect = tester.getRect(find.byWidget(button.widget));
            expect(rect.top, greaterThanOrEqualTo(visible.top));
            expect(rect.bottom, lessThanOrEqualTo(visible.bottom));
          }
          final preview = find.descendant(of: dialog, matching: find.byType(InformationPreview));
          final previewRect = tester.getRect(preview);
          expect(tester.widget<WeatherDisplayText>(find.descendant(of: preview, matching: find.byType(WeatherDisplayText))).maxWidth,
            background ? 720 : 300);
          final label = find.byKey(const Key('weather_format_preview_label'));
          final labelRect = tester.getRect(label);
          expect(find.text('${l.dateFormatPreview}:'), findsOneWidget);
          expect(previewRect.height, inInclusiveRange(58, 64));
          expect(labelRect.center.dy, closeTo(previewRect.center.dy, 1));
          expect(previewRect.width, lessThan(tester.getSize(dialog).width - labelRect.width));
          final fitted = tester.widget<FittedBox>(
            find.descendant(of: preview, matching: find.byType(FittedBox)).first,
          );
          final contentRect = tester.getRect(find.byWidget(fitted.child!));
          expect(previewRect.width - contentRect.width, closeTo(22, 0.1));
          if (locale.languageCode == 'ar') {
            expect(labelRect.left, greaterThanOrEqualTo(previewRect.right));
          } else {
            expect(labelRect.right, lessThanOrEqualTo(previewRect.left));
          }
          final body = find.byKey(const Key('weather_format_body'));
          final before = tester.getRect(body);
          final input = find.byKey(const Key('weather_format_input'));
          await tester.tap(input);
          await tester.enterText(input, '{TEMP}{BR}({FEELS})');
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          final shifted = tester.getRect(body);
          expect(shifted.top, lessThan(before.top));
          expect(shifted.bottom, lessThanOrEqualTo(240));
          expect(tester.getRect(input).bottom, lessThanOrEqualTo(240));
          expect(tester.getRect(title).bottom, lessThanOrEqualTo(tester.getRect(preview).top));
          expect(tester.getSize(preview).height, inInclusiveRange(34, 40));
          expect(tester.getRect(preview).bottom, lessThanOrEqualTo(tester.getRect(input).top));
          expect(tester.getRect(label).center.dy, closeTo(tester.getRect(preview).center.dy, 1));
          final compactFitted = tester.widget<FittedBox>(
            find.descendant(of: preview, matching: find.byType(FittedBox)).first,
          );
          final compactContent = tester.getRect(find.byWidget(compactFitted.child!));
          expect(tester.getSize(preview).width - compactContent.width, closeTo(22, 0.1));
          expect(tester.takeException(), isNull, reason: 'title=${tester.getRect(title)} preview=${tester.getRect(preview)} input=${tester.getRect(input)} save=${tester.getRect(find.byKey(const Key('weather_format_save')))} body=${tester.getRect(body)}');
        });
      }
    }
  }

  for (final mode in ['panel', 'combined', 'background']) {
    for (final width in mode == 'background' ? [960.0, 1280.0] : [960.0]) {
      for (final overflowing in [false, true]) {
        testWidgets('preview matches real line clipping: $mode width=$width overflow=$overflowing', (tester) async {
          tester.view.physicalSize = Size(width, 540);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final background = mode == 'background';
          final combined = mode == 'combined';
          final snapshot = MockWeatherService();
          const current = WeatherData(currentTemp: 6, currentConditionCode: 803);
          when(snapshot.weatherData).thenReturn(current);
          when(snapshot.stale).thenReturn(false);
          await appearance.set('panelInformationPlacements', {
            'time': 'hidden', 'date': combined ? 'panel' : 'hidden',
            'weather': background ? 'background' : 'panel',
          });
          await appearance.set('panelCombinedInformation', combined);
          await appearance.set('panelInformationStyle', {'size': 24});
          await appearance.set('panelBackgroundInformationSize', 192);
          final length = overflowing ? (background ? 80 : combined ? 30 : 20) : 10;
          final format = parseWeatherTemplate('${List.filled(length, 'W').join()}{TEMP}').format!;
          final options = WeatherDisplayOptions(format: format, fahrenheit: false, warnings: false);
          await settings.setInformationWeather(options, background: background);
          final actual = background ? const BackgroundInformation()
            : combined ? CombinedInformation(appearance: appearance.appearance,
              showTime: false, showDate: true, showWeather: true,
              timeFormat: 'HH:mm', dateFormat: 'yyyy', weather: current,
              weatherTextFormat: format)
            : const WeatherStatusBarWidget(showWeather: true);
          await mount(tester, page: ChangeNotifierProvider<WeatherService>.value(
            value: snapshot,
            child: Column(children: [
              Expanded(child: actual),
              InformationPreview(background: background, dense: true, weatherOptions: options),
            ]),
          ));
          final previewText = find.descendant(of: find.byType(InformationPreview), matching: find.byType(WeatherDisplayText));
          final actualText = find.descendant(of: find.byWidget(actual), matching: find.byType(WeatherDisplayText));
          final real = tester.widget<WeatherDisplayText>(actualText);
          final preview = tester.widget<WeatherDisplayText>(previewText);
          expect(real.maxWidth, background ? width * .75 : 300);
          expect(preview.maxWidth, real.maxWidth);
          expect(preview.style?.fontSize, real.style?.fontSize);
          expect(preview.style?.fontFamily, real.style?.fontFamily);
          expect(preview.text, real.text);
          for (final text in [actualText, previewText]) {
            final paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: text, matching: find.byType(RichText)));
            expect(paragraph.didExceedMaxLines, overflowing);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('template editor previews, saves and cancels a complete draft', (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await mount(tester, page: const InformationDataSettingsPage());
    final open = tile('Формат текста погоды');
    await tester.scrollUntilVisible(open, 180);
    await tester.pumpAndSettle();
    await tester.tap(open);
    await tester.pumpAndSettle();
    final dialog = find.byType(WeatherTextFormatDialog);
    final input = find.byKey(const Key('weather_format_input'));
    final field = tester.widget<TextField>(input);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(field.controller!.text, '{ЗНАЧ} {ТЕМП} ({ПРЕД})');
    await tester.tap(input);
    await tester.enterText(input, 'На улице {ТЕМП}{ПЕР}({ОЩУЩ})');
    await tester.pumpAndSettle();
    final preview = find.descendant(of: dialog, matching: find.byType(WeatherDisplayText));
    expect(tester.widget<WeatherDisplayText>(preview).text, 'На улице 6°C\n(2°C)');
    expect(settings.weatherTextFormat, WeatherTextFormat.standard);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.getRect(preview).bottom, lessThanOrEqualTo(tester.getRect(input).top));
    expect(tester.getRect(input).bottom, lessThanOrEqualTo(240));
    expect(tester.takeException(), isNull);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(tester.widget<LauncherDialogButton>(find.byKey(const Key('weather_format_save'))).focusNode!.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    final saved = settings.weatherTextFormat.encode();
    expect(settings.weatherTextFormat.explicitLayout, isTrue);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).controller!.text, 'На улице {ТЕМП}{ПЕР}({ОЩУЩ})');
    await tester.tap(input);
    await tester.enterText(input, '{ГОРОД} {УСЛ}');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(settings.weatherTextFormat.encode(), saved);
    expect(transport.requests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final background in [false, true]) {
    testWidgets('reset format is a draft until saved: background=$background', (tester) async {
      final original = WeatherDisplayOptions(
        format: parseWeatherTemplate('{CITY}: {TEMP}{BR}{FEELS}').format!,
        fahrenheit: true, warnings: false,
      );
      await settings.setInformationWeather(original, background: background);
      final otherProfile = settings.informationWeather(background: !background).encode();
      await mount(tester, page: InformationDataSettingsPage(background: background));
      for (final save in [false, true]) {
        final open = tile('Формат текста погоды');
        await tester.scrollUntilVisible(open, 150);
        await tester.tap(open);
        await tester.pumpAndSettle();
        final input = find.byKey(const Key('weather_format_input'));
        await tester.tap(find.byKey(const Key('weather_format_reset')));
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(input).controller!.text, '{ЗНАЧ} {ТЕМП} ({ПРЕД})');
        expect(settings.informationWeather(background: background).encode(), original.encode());
        if (save) {
          await tester.tap(find.byKey(const Key('weather_format_save')));
        } else {
          final cancelLabel = MaterialLocalizations.of(tester.element(input)).cancelButtonLabel;
          await tester.tap(find.widgetWithText(LauncherDialogButton, cancelLabel));
        }
        await tester.pumpAndSettle();
        expect(find.byType(WeatherTextFormatDialog), findsNothing);
        if (!save) expect(settings.informationWeather(background: background).encode(), original.encode());
      }
      final saved = settings.informationWeather(background: background);
      expect(saved.format.encode(), parseWeatherTemplate('{ЗНАЧ} {ТЕМП} ({ПРЕД})').format!.encode());
      expect(saved.fahrenheit, isTrue);
      expect(saved.warnings, isFalse);
      expect(settings.informationWeather(background: !background).encode(), otherProfile);
      expect(transport.requests, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('temperature units are outside the editor and profiles save independently', (tester) async {
    await mount(tester, page: const InformationDataSettingsPage(background: true));
    final l = AppLocalizations.of(tester.element(find.byType(InformationDataSettingsPage)))!;
    await tester.scrollUntilVisible(find.text(l.temperatureUnit), 150);
    await tester.tap(find.text(l.temperatureUnit));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.fahrenheit).last);
    await tester.pumpAndSettle();
    expect(settings.informationWeather(background: true).fahrenheit, isTrue);
    expect(settings.useFahrenheit, isFalse);
    final before = settings.informationWeather(background: true).encode();
    for (final save in [false, true]) {
      await tester.scrollUntilVisible(tile(l.weatherTextFormat), 150);
      await tester.tap(tile(l.weatherTextFormat));
      await tester.pumpAndSettle();
      final dialog = find.byType(WeatherTextFormatDialog);
      expect(find.descendant(of: dialog, matching: find.text(l.temperatureUnit)), findsNothing);
      expect(find.text(l.showWeatherWarnings), findsNothing);
      expect(find.byKey(const ValueKey('weather_preset_0')), findsNothing);
      final input = find.byKey(const Key('weather_format_input'));
      await tester.tap(input);
      await tester.enterText(input, '{ТЕМП} ({ПРЕД}) {УСЛ}');
      await tester.pumpAndSettle();
      expect(settings.informationWeather(background: true).encode(), before);
      if (save) {
        await tester.tap(find.byKey(const Key('weather_format_save')));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      if (!save) expect(settings.informationWeather(background: true).encode(), before);
    }
    final background = settings.informationWeather(background: true);
    expect(background.fahrenheit, isTrue);
    expect(background.warnings, isFalse);
    expect(background.format.explicitLayout, isTrue);
    expect(background.format.blocks.any((b) => b.field == WeatherTextField.warning), isTrue);
    expect(settings.weatherTextFormat, WeatherTextFormat.standard);
    expect(transport.requests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('combined date and weather use two rows without changing the template', (tester) async {
    final format = WeatherTextFormat.fromBlocks(const [
      WeatherTextBlock(WeatherTextField.temperature), WeatherTextBlock(WeatherTextField.lineBreak),
      WeatherTextBlock(WeatherTextField.feelsLike, before: '(', after: ')'),
    ])!;
    final saved = format.encode();
    for (final date in [true, false]) {
      await mount(tester, page: CombinedInformation(appearance: appearance.appearance,
        showTime: true, showDate: date, showWeather: true, timeFormat: 'HH:mm', dateFormat: 'yyyy',
        fixedTime: DateTime(2026, 11, 6), weather: const WeatherData(currentTemp: 6, feelsLikeTemp: 2),
        weatherTextFormat: format));
      expect(find.text('6°C (2°C)'), date ? findsOneWidget : findsNothing);
      expect(find.text('(2°C)'), date ? findsNothing : findsOneWidget);
      expect(format.encode(), saved);
      expect(tester.takeException(), isNull);
    }
  });

  for (final template in [false, true]) {
  testWidgets('standalone panel, combined panel and background use the saved format: template=$template', (tester) async {
    final snapshot = MockWeatherService();
    const current = WeatherData(currentTemp: 6, feelsLikeTemp: 2);
    when(snapshot.weatherData).thenReturn(current);
    when(snapshot.stale).thenReturn(false);
    await appearance.set('panelInformationPlacements', {
      'time': 'hidden', 'date': 'hidden', 'weather': 'background',
    });
    await appearance.set('weatherIconPack', 'pixel');
    await appearance.set('weatherTextColor', 0xffaadebb);
    await settings.setWeatherTextFormat(template ? parseWeatherTemplate('{TEMP}{BR}({FEELS}){ICON}').format! : WeatherTextFormat.fromBlocks(const [
      WeatherTextBlock(WeatherTextField.temperature),
      WeatherTextBlock(WeatherTextField.lineBreak),
      WeatherTextBlock(WeatherTextField.feelsLike, before: '(', after: ')'),
    ])!);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WeatherService>.value(value: snapshot),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: appearance),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                const WeatherStatusBarWidget(showWeather: true),
                Builder(builder: (context) => CombinedInformation(
                  appearance: context.watch<AppearanceService>().appearance,
                  showTime: false, showDate: false, showWeather: true,
                  timeFormat: settings.timeFormat, dateFormat: settings.dateFormat,
                  weather: current, weatherTextFormat: settings.weatherTextFormat,
                )),
                const Expanded(child: BackgroundInformation()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('6°C'), findsNWidgets(3));
    if (!template) expect(find.text('(2°C)'), findsNWidgets(3));
    expect(tester.widgetList<WeatherDisplayText>(find.byType(WeatherDisplayText)).map((text) => text.text), everyElement(contains('(2°C)')));
    expect(tester.widgetList<Text>(find.text('6°C')).map((text) => text.style?.color),
        everyElement(const Color(0xffaadebb)));
    final glyphs = find.byType(WeatherGlyph);
    expect(glyphs, findsNWidgets(3));
    expect(tester.widgetList<WeatherGlyph>(glyphs).map((glyph) => glyph.pack),
        everyElement(WeatherIconPack.pixel));
    expect(tester.widgetList<WeatherGlyph>(glyphs).map((glyph) => glyph.color),
        everyElement(const Color(0xffaadebb)));
    await appearance.set('weatherIconColor', 0xfffabbed);
    await tester.pumpAndSettle();
    expect(tester.widgetList<WeatherGlyph>(glyphs).map((glyph) => glyph.color),
        everyElement(const Color(0xfffabbed)));
    expect(tester.widgetList<Text>(find.text('6°C')).map((text) => text.style?.color),
        everyElement(const Color(0xffaadebb)));
    expect(tester.takeException(), isNull);
  });

  }

  for (final rtl in [false, true]) {
   for (final scale in [1.0, 1.4]) {
  testWidgets('weather icon picker reveals the selected bottom row: rtl=$rtl scale=$scale', (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await appearance.setInformationAppearance('weatherIconPack', 'circled');
    await mount(tester, page: const InformationSectionPage(background: false, section: 'colors'),
        locale: Locale(rtl ? 'ar' : 'ru'), scale: scale);
    final l = AppLocalizations.of(tester.element(find.byType(InformationSectionPage)))!;
    final opener = tile(l.weatherIconPack);
    await tester.scrollUntilVisible(opener, 150);
    await tester.pumpAndSettle();
    await tester.tap(opener);
    await tester.pumpAndSettle();
    final dialog = find.byType(LauncherAlertDialog);
    final viewport = find.descendant(of: dialog, matching: find.byType(SingleChildScrollView));
    expect(viewport, findsOneWidget);
    void expectVisible(Finder row) {
      final visible = tester.getRect(viewport);
      final rect = tester.getRect(row);
      expect(rect.top, greaterThanOrEqualTo(visible.top - .5));
      expect(rect.bottom, lessThanOrEqualTo(visible.bottom + .5));
      if (rtl) {
        expect(rect.left, greaterThanOrEqualTo(visible.left + 14 - .5));
      } else {
        expect(rect.right, lessThanOrEqualTo(visible.right - 14 + .5));
      }
    }
    final selected = find.descendant(of: dialog, matching: find.byWidgetPredicate(
      (widget) => widget is SettingsOptionTile && widget.selected,
    ));
    expectVisible(selected);
    expect(Focus.of(tester.element(find.text(l.weatherIconsCircled).last)).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    final previous = find.widgetWithText(SettingsOptionTile, l.weatherIconsGeometric);
    expectVisible(previous);
    expect(appearance.appearance.weatherIconPack, WeatherIconPack.circled);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expectVisible(selected);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(Focus.of(tester.element(find.text(l.weatherIconPack))).hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
   }
  }

  testWidgets('weather settings preview the icon sets and save separate colors', (tester) async {
    await mount(tester, page: const InformationSectionPage(background: false, section: 'colors'));
    Future<void> open(String title) async {
      final row = tile(title);
      await tester.scrollUntilVisible(row, 150);
      await tester.pumpAndSettle();
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
    }

    await open('Набор значков погоды');
    expect(find.byType(WeatherGlyph), findsNWidgets(WeatherIconPack.values.length * 5));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(appearance.appearance.weatherIconPack, WeatherIconPack.standard);

    Future<void> chooseColor(String title, int value) async {
      await open(title);
      final color = find.byKey(ValueKey('palette-$value'));
      await tester.ensureVisible(color);
      await tester.tap(color);
      await tester.pumpAndSettle();
    }

    await chooseColor('Цвет текста погоды', appearancePalette[3]);
    await chooseColor('Цвет значков погоды', appearancePalette[7]);
    expect(appearance.appearance.weatherTextColor, Color(appearancePalette[3]));
    expect(appearance.appearance.weatherIconColor, Color(appearancePalette[7]));
    await open('Цвет значков погоды');
    await tester.tap(find.text('Как у текста погоды'));
    await tester.pumpAndSettle();
    final restored = TileAppearance.decode(appearance.preferences.getString(tileAppearanceKey));
    expect(restored.weatherIconPack, WeatherIconPack.standard);
    expect(restored.weatherTextColor, Color(appearancePalette[3]));
    expect(restored.weatherIconColor, isNull);
    expect(transport.requests, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('forecast period and view can be changed with the remote and persist', (tester) async {
    await mount(tester);
    await tester.ensureVisible(find.text('Период прогноза'));
    Focus.of(tester.element(find.text('Период прогноза'))).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(appearance.appearance.forecastDays, 7);
    await tester.ensureVisible(find.text('Вид прогноза'));
    await tester.tap(find.text('Вид прогноза'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Подробный список'));
    await tester.pumpAndSettle();
    expect(appearance.appearance.detailedForecast, isTrue);
    final restored = AppearanceService(appearance.preferences);
    expect(restored.appearance.forecastDays, 7);
    expect(restored.appearance.detailedForecast, isTrue);
    restored.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('custom server settings validate input and report a connection error', (tester) async {
    const secrets = MethodChannel('cutelauncher/weather_token');
    const location = MethodChannel('cutelauncher/weather_location');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(secrets, (_) async => null);
    messenger.setMockMethodCallHandler(location, (_) async => {'latitude': 50.0, 'longitude': 30.0});
    addTearDown(() {
      messenger.setMockMethodCallHandler(secrets, null);
      messenger.setMockMethodCallHandler(location, null);
    });
    await mount(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Свой сервер (Open-Meteo)'));
    await tester.pumpAndSettle();
    expect(service.configuration.source, WeatherSource.customOpenMeteo);
    expect(transport.requests, isEmpty);
    expect(tile('Ввести координаты'), findsNothing);
    final l = AppLocalizations.of(tester.element(find.byType(WeatherPage)))!;
    expect(find.text(l.weatherServerUrlHint), findsNothing);
    await tester.ensureVisible(find.text(l.widgetSettings));
    expect(find.text('Оформление'), findsNothing);

    Future<void> open(String label) async {
      final row = tile(label);
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
    }

    Future<void> submit(String value) async {
      await tester.enterText(find.byType(TextField), value);
      final l = MaterialLocalizations.of(tester.element(find.byType(AlertDialog)));
      await tester.tap(find.widgetWithText(LauncherDialogButton, l.okButtonLabel));
      await tester.pumpAndSettle();
    }

    await open('HTTPS-адрес сервера');
    await submit('http://weather.example.test');
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(service.configuration.server, isNull);
    await submit('https://weather.example.test/home');
    expect(find.byType(AlertDialog), findsNothing);
    expect(tile('Местоположение'), findsNothing);
    expect(tile('Название города'), findsNothing);
    expect(tile('Получить местоположение'), findsNothing);
    expect(transport.requests.single.path, '/home/v1/forecast');
    expect(transport.requests.single.queryParameters.containsKey('latitude'), isFalse);
    expect(transport.requests.single.queryParameters.containsKey('longitude'), isFalse);

    transport.failure = WeatherFailure.parameters;
    final check = tile('Проверить соединение');
    await tester.scrollUntilVisible(check, 100);
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(service.failure, WeatherFailure.parameters);
    expect(find.text('Сервер отклонил параметры запроса или координаты.'), findsWidgets);
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump(const Duration(hours: 2));
    expect(transport.requests, hasLength(2));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('server file import is on the weather page and validates before saving', (tester) async {
    const documents = MethodChannel('me.efesser.flauncher/method');
    const secrets = MethodChannel('cutelauncher/weather_token');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(secrets, (_) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(secrets, null));
    Uint8List? selected;
    String? importFailure;
    Completer<Uint8List?>? pending;
    var pickCount = 0;
    messenger.setMockMethodCallHandler(documents, (call) async {
      if (call.method == 'filePickerAvailable') return true;
      if (call.method == 'pickWeatherServerDocument') {
        pickCount++;
        if (pending != null) return pending.future;
        if (importFailure != null) throw PlatformException(code: importFailure);
        return selected;
      }
      throw MissingPluginException();
    });
    addTearDown(() => messenger.setMockMethodCallHandler(documents, null));
    await service.configure(const WeatherConfiguration(source: WeatherSource.customOpenMeteo));
    await mount(tester);
    final l = AppLocalizations.of(tester.element(find.byType(WeatherPage)))!;
    final address = tile(l.weatherServerUrl);
    final importButton = tile(l.weatherServerUrlImport);
    expect(tester.getRect(importButton).top, greaterThanOrEqualTo(tester.getRect(address).bottom));
    await tester.tap(address);
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(find.descendant(of: dialog, matching: find.text(l.weatherServerUrlImport)), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    Future<void> importFile(Uint8List? bytes) async {
      selected = bytes;
      await tester.tap(tile(l.weatherServerUrlImport));
      await tester.pumpAndSettle();
      await tester.tap(tile('Системный проводник'));
      await tester.pump();
      if (pending == null) {
        await waitFor(tester, () => tester.widget<FocusableSettingsTile>(tile(l.weatherServerUrlImport)).onPressed != null);
      } else {
        await tester.pumpAndSettle();
      }
    }

    await importFile(null);
    expect(service.configuration.server, isNull);
    for (final value in ['http://weather.example.test', 'https://one.test\nhttps://two.test', 'https://weather.test/v1/forecast']) {
      await importFile(Uint8List.fromList(utf8.encode(value)));
      expect(find.text(l.weatherServerUrlImportError), findsWidgets);
      expect(service.configuration.server, isNull);
    }
    await importFile(Uint8List.fromList([0xff]));
    expect(find.text(l.weatherImportEncodingError), findsOneWidget);
    importFailure = 'document_too_large';
    await importFile(null);
    expect(find.text(l.weatherImportTooLargeError), findsOneWidget);
    importFailure = 'document_failed';
    await importFile(null);
    expect(find.text(l.weatherImportReadError), findsOneWidget);
    importFailure = null;
    await importFile(Uint8List.fromList(utf8.encode('\uFEFFhttps://weather.example.test/home\r\n')));
    expect(service.configuration.server.toString(), 'https://weather.example.test/home');
    expect(find.byType(TextField), findsNothing);
    expect(transport.requests, hasLength(1));
    await importFile(null);
    expect(service.configuration.server.toString(), 'https://weather.example.test/home');
    await importFile(Uint8List.fromList(utf8.encode('http://invalid.example.test')));
    expect(service.configuration.server.toString(), 'https://weather.example.test/home');
    pending = Completer<Uint8List?>();
    await importFile(null);
    final beforeRepeat = pickCount;
    expect(tester.widget<FocusableSettingsTile>(tile(l.weatherServerUrlImport)).onPressed, isNull);
    await tester.tap(tile(l.weatherServerUrlImport));
    await tester.pump();
    expect(pickCount, beforeRepeat);
    await mount(tester, page: const SizedBox());
    pending.complete(Uint8List.fromList(utf8.encode('https://late.example.test')));
    await tester.pumpAndSettle();
    expect(service.configuration.server.toString(), 'https://weather.example.test/home');
    expect(tester.takeException(), isNull);
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
  });

  for (final onRight in [false, true]) {
    for (final mode in ['address', 'token', 'yandex', 'openWeather']) {
      testWidgets('$mode import keeps the built-in browser in the same panel, right=$onRight', (tester) async {
        const documents = MethodChannel('me.efesser.flauncher/method');
        const secrets = MethodChannel('cutelauncher/weather_token');
        final messenger = tester.binding.defaultBinaryMessenger;
        var imports = 0;
        final writes = <Map>[];
        final address = mode == 'address';
        final custom = address || mode == 'token';
        final source = custom ? WeatherSource.customOpenMeteo
            : mode == 'yandex' ? WeatherSource.yandex : WeatherSource.openWeather;
        final server = parseWeatherServer('https://weather.example.test/home')!;
        final keyFile = File('${directory.path}/${mode == 'yandex' ? 'weather-api-key' : 'weather-api-key-openweather'}');
        messenger.setMockMethodCallHandler(secrets, (call) async {
          if (call.method == 'save') writes.add(call.arguments as Map);
          return null;
        });
        messenger.setMockMethodCallHandler(documents, (call) async {
          switch (call.method) {
            case 'requestFileStorage':
              return true;
            case 'browseLocalFiles':
              expect(call.arguments['kind'], 'text');
              return {
                'path': '/storage/main', 'uri': 'file:///storage/main', 'parent': '',
                'folders': [],
                'files': [{'name': 'server.txt', 'path': '/storage/main/server.txt'}],
              };
            case 'localDocumentOperation':
              expect(call.arguments['operation'], address ? 'pickWeatherServerDocument' : 'pickWeatherTokenDocument');
              imports++;
              return Uint8List.fromList(utf8.encode(address ? server.toString() : 'fixture-token'));
            default:
              throw MissingPluginException();
          }
        });
        addTearDown(() {
          messenger.setMockMethodCallHandler(documents, null);
          messenger.setMockMethodCallHandler(secrets, null);
        });
        await settings.setFileManagerPreference(FileManagerPreference.builtIn);
        await tester.runAsync(() => service.configure(WeatherConfiguration(source: source, server: mode == 'token' ? server : null)));
        await mount(tester, page: SettingsMenuLayout(
          onRight: onRight,
          child: SidePanelDialog(
            width: 380,
            isRightSide: onRight,
            child: Navigator(onGenerateRoute: (_) => SettingsRoute(builder: (_) => const WeatherPage())),
          ),
        ));
        final label = address ? 'Импортировать адрес из файла' : 'Импортировать токен из файла';
        final button = tile(label);
        await tester.scrollUntilVisible(button, 120);
        await tester.ensureVisible(button);
        final panel = find.byType(SidePanelDialog);
        final bounds = tester.getRect(find.byType(WeatherPage));
        Future<void> open() async {
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          await tester.tap(button);
          await tester.pumpAndSettle();
          final browser = find.byType(LocalFileBrowser);
          expect(browser, findsOneWidget);
          expect(panel, findsOneWidget);
          expect(find.byType(AlertDialog), findsNothing);
          expect(find.byType(WeatherPage), findsNothing);
          expect(tester.getRect(browser), bounds);
        }
        await open();
        await tester.tap(find.byTooltip('Закрыть'));
        await tester.pumpAndSettle();
        expect(find.byType(LocalFileBrowser), findsNothing);
        expect(service.configuration.server, mode == 'token' ? server : null);
        expect(imports, 0);
        expect(Focus.of(tester.element(find.text(label))).hasFocus, isTrue);
        await open();
        await tester.tap(find.text('server.txt'));
        await tester.pumpAndSettle();
        expect(find.byType(LocalFileBrowser), findsNothing);
        expect(find.byType(WeatherPage), findsOneWidget);
        expect(imports, 1);
        await waitFor(tester, () => tester.widget<FocusableSettingsTile>(button).onPressed != null &&
            (address ? service.configuration.server == server
            : custom ? writes.isNotEmpty : keyFile.existsSync() && keyFile.readAsStringSync() == 'fixture-token'));
        if (mode == 'token') expect(writes.single, {'server': server.toString(), 'token': 'fixture-token'});
        expect(find.text('fixture-token'), findsNothing);
        expect(Focus.of(tester.element(find.text(label))).hasFocus, isTrue);
        expect(transport.requests, hasLength(address ? 1 : custom ? 1 : 0));
        expect(tester.takeException(), isNull);
        service.didChangeAppLifecycleState(AppLifecycleState.paused);
        await tester.pumpWidget(const SizedBox());
        if (!custom) {
          // Flush each fake-async file-read phase before Windows removes the fixture.
          for (var i = 0; i < 8; i++) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
            await tester.pump();
          }
        }
      });
    }
  }

  testWidgets('server editor traverses from input to help and confirmation buttons', (tester) async {
    await service.configure(const WeatherConfiguration(source: WeatherSource.customOpenMeteo));
    await mount(tester);
    await tester.tap(tile('HTTPS-адрес сервера'));
    await tester.pumpAndSettle();
    final editor = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
    expect(editor.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(editor.hasFocus, isFalse);
    final material = MaterialLocalizations.of(tester.element(find.byType(AlertDialog)));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text(material.cancelButtonLabel))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    final ok = find.widgetWithText(LauncherDialogButton, material.okButtonLabel);
    expect(tester.widget<LauncherDialogButton>(ok).focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final source in [WeatherSource.customOpenMeteo, WeatherSource.yandex, WeatherSource.openWeather]) {
    testWidgets('$source token import is separate, validates contents and preserves secrets on cancellation', (tester) async {
      const secrets = MethodChannel('cutelauncher/weather_token');
      const documents = MethodChannel('me.efesser.flauncher/method');
      final messenger = tester.binding.defaultBinaryMessenger;
      final writes = <Map>[];
      Uint8List? selected;
      messenger.setMockMethodCallHandler(secrets, (call) async {
        if (call.method == 'save') writes.add(call.arguments as Map);
        return call.method == 'has' ? writes.isNotEmpty : null;
      });
      messenger.setMockMethodCallHandler(documents, (call) async => switch (call.method) {
        'filePickerAvailable' => true,
        'pickWeatherTokenDocument' => selected,
        _ => throw MissingPluginException(),
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(secrets, null);
        messenger.setMockMethodCallHandler(documents, null);
      });
      final custom = source == WeatherSource.customOpenMeteo;
      final server = parseWeatherServer('https://weather.example.test/home')!;
      await tester.runAsync(() => service.configure(WeatherConfiguration(source: source, server: custom ? server : null, latitude: 50, longitude: 30)));
      await mount(tester);
      final l = AppLocalizations.of(tester.element(find.byType(WeatherPage)))!;
      final manual = tile(custom ? l.weatherServerToken
          : source == WeatherSource.yandex ? l.weatherApiKey : l.weatherOpenWeatherKey);
      await tester.scrollUntilVisible(manual, 150);
      final importButton = tile(l.weatherServerTokenImport);
      await tester.scrollUntilVisible(importButton, 120);
      await tester.ensureVisible(importButton);
      expect(tester.getRect(importButton).top, greaterThanOrEqualTo(tester.getRect(manual).bottom));
      await tester.tap(manual);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text(l.weatherServerTokenImport)), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      Future<void> importFile(Uint8List? bytes) async {
        selected = bytes;
        await tester.ensureVisible(importButton);
        await tester.pumpAndSettle();
        await tester.tap(importButton);
        await tester.pumpAndSettle();
        await tester.tap(tile('Системный проводник'));
        await tester.pumpAndSettle();
      }
      final keyFile = File('${directory.path}/${source == WeatherSource.yandex ? 'weather-api-key' : 'weather-api-key-openweather'}');
      await importFile(null);
      expect(writes, isEmpty);
      expect(keyFile.existsSync(), isFalse);
      for (final value in ['', 'first\nsecond', 'value with spaces', 'a' * 1025]) {
        await importFile(Uint8List.fromList(utf8.encode(value)));
        expect(find.text(l.weatherServerTokenImportError), findsWidgets);
        expect(writes, isEmpty);
        expect(keyFile.existsSync(), isFalse);
      }
      await importFile(Uint8List.fromList(utf8.encode('\uFEFFfixture-token\r\n')));
      await waitFor(tester, () => tester.widget<FocusableSettingsTile>(importButton).onPressed != null &&
          (custom ? writes.isNotEmpty : keyFile.existsSync() && keyFile.readAsStringSync() == 'fixture-token'));
      if (custom) {
        expect(writes, [{'server': server.toString(), 'token': 'fixture-token'}]);
      } else {
        expect(keyFile.readAsStringSync(), 'fixture-token');
        final other = File('${directory.path}/${source == WeatherSource.yandex ? 'weather-api-key-openweather' : 'weather-api-key'}');
        expect(other.existsSync(), isFalse);
      }
      expect(find.byType(TextField), findsNothing);
      expect(find.text('fixture-token'), findsNothing);
      await importFile(null);
      await importFile(Uint8List.fromList(utf8.encode('invalid\ntoken')));
      if (custom) {
        expect(writes, hasLength(1));
      } else {
        expect(keyFile.readAsStringSync(), 'fixture-token');
      }
      expect(transport.requests, hasLength(custom ? 1 : 0));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      if (!custom) {
        // Flush each fake-async file-read phase before Windows removes the fixture.
        for (var i = 0; i < 8; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
          await tester.pump();
        }
      }
    });
  }

  for (final source in [WeatherSource.customOpenMeteo, WeatherSource.yandex, WeatherSource.openWeather]) {
    testWidgets('$source saving a token waits for explicit refresh, including after resume and timer ticks', (tester) async {
      const secrets = MethodChannel('cutelauncher/weather_token');
      final messenger = tester.binding.defaultBinaryMessenger;
      var saves = 0;
      messenger.setMockMethodCallHandler(secrets, (call) async {
        if (call.method == 'save') saves++;
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(secrets, null));
      final custom = source == WeatherSource.customOpenMeteo;
      final server = parseWeatherServer('https://weather.example.test/home')!;
      await tester.runAsync(() => service.configure(WeatherConfiguration(source: source, server: custom ? server : null, latitude: 50, longitude: 30)));
      transport.requests.clear();
      transport.failure = WeatherFailure.authorization;
      await mount(tester);
      final manual = tile(custom ? 'Bearer-токен (необязательно)'
          : source == WeatherSource.yandex ? 'Ключ API Яндекса' : 'API-ключ OpenWeather');
      await tester.scrollUntilVisible(manual, 150);
      await tester.tap(manual);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'fixture-token');
      await tester.tap(find.text('ОК'));
      await tester.pumpAndSettle();
      await waitFor(tester, () => service.canRefresh && (custom ? saves == 1 : true));
      expect(saves, custom ? 1 : 0);
      expect(service.failure, isNull);
      expect(service.canRefresh, isTrue);
      expect(transport.requests, isEmpty);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(hours: 2));
      expect(transport.requests, isEmpty);
      final check = tile(custom ? 'Проверить соединение' : 'Обновить погоду');
      await tester.scrollUntilVisible(check, 100);
      await tester.pumpAndSettle();
      await tester.ensureVisible(check);
      await tester.pumpAndSettle();
      await tester.tap(check);
      await tester.pump();
      await waitFor(tester, () => !service.loading && service.failure == WeatherFailure.authorization);
      expect(transport.requests, hasLength(1));
      expect(service.failure, WeatherFailure.authorization);
      final l = AppLocalizations.of(tester.element(find.byType(WeatherPage)))!;
      expect(find.text(custom ? l.weatherServerAccessError : l.weatherAuthorizationError), findsWidgets);
      expect(find.text(l.weatherServerTokenImportError), findsNothing);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pumpWidget(const SizedBox());
      if (!custom) {
        for (var i = 0; i < 8; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
          await tester.pump();
        }
      }
    });
  }

  testWidgets('token file read, encoding, format and save failures have separate safe diagnostics', (tester) async {
    const secrets = MethodChannel('cutelauncher/weather_token');
    const documents = MethodChannel('me.efesser.flauncher/method');
    final messenger = tester.binding.defaultBinaryMessenger;
    Uint8List? selected;
    String? readError;
    var saveFails = false;
    messenger.setMockMethodCallHandler(secrets, (call) async {
      if (call.method == 'save' && saveFails) {
        throw PlatformException(code: 'save_failed', message: 'fixture-private-token');
      }
      return null;
    });
    messenger.setMockMethodCallHandler(documents, (call) async {
      if (call.method == 'filePickerAvailable') return true;
      if (call.method == 'pickWeatherTokenDocument') {
        if (readError != null) throw PlatformException(code: readError, message: 'fixture-private-token');
        return selected;
      }
      throw MissingPluginException();
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(secrets, null);
      messenger.setMockMethodCallHandler(documents, null);
    });
    final server = parseWeatherServer('https://weather.example.test/home')!;
    await service.configure(WeatherConfiguration(source: WeatherSource.customOpenMeteo, server: server));
    await mount(tester);
    final l = AppLocalizations.of(tester.element(find.byType(WeatherPage)))!;
    Future<void> importFile(String expected) async {
      final button = tile(l.weatherServerTokenImport);
      await tester.scrollUntilVisible(button, 100);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(tile('Системный проводник'));
      await tester.pumpAndSettle();
      expect(find.text(expected), findsWidgets);
    }
    readError = 'document_failed';
    await importFile(l.weatherImportReadError);
    readError = 'document_too_large';
    await importFile(l.weatherImportTooLargeError);
    readError = null;
    selected = Uint8List.fromList([0xff]);
    await importFile(l.weatherImportEncodingError);
    selected = Uint8List.fromList(utf8.encode('fixture-private-token\nsecond'));
    await importFile(l.weatherServerTokenImportError);
    selected = Uint8List.fromList(utf8.encode('fixture-private-token'));
    saveFails = true;
    await importFile(l.weatherImportSaveError);
    final report = DiagnosticsStore.instance.snapshot();
    final imports = (report['failures'] as List).cast<Map>().where((e) => e['operation'] == 'dart.weatherImport');
    expect(imports.map((e) => (e['details'] as Map)['reason']), [
      'weather_import_read', 'weather_import_too_large', 'weather_import_encoding',
      'weather_import_format', 'weather_import_save',
    ]);
    expect(jsonEncode(report), isNot(contains('fixture-private-token')));
    expect(transport.requests, hasLength(1)); // Initial fetch only.
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pumpWidget(const SizedBox());
  });

  for (final builtIn in [false, true]) {
    testWidgets('token import accepts an unmodifiable platform message, builtIn=$builtIn', (tester) async {
      const documents = MethodChannel('me.efesser.flauncher/method');
      const secrets = MethodChannel('cutelauncher/weather_token');
      const codec = StandardMethodCodec();
      final messenger = tester.binding.defaultBinaryMessenger;
      final writes = <Map>[];
      var bytes = Uint8List.fromList(utf8.encode('\uFEFFfixture-readonly-token\r\n'));
      messenger.setMockMethodCallHandler(secrets, (call) async {
        if (call.method == 'save') writes.add(call.arguments as Map);
        return null;
      });
      messenger.setMockMessageHandler(documents.name, (message) async {
        final call = codec.decodeMethodCall(message!);
        final Object? result = switch (call.method) {
          'filePickerAvailable' => true,
          'requestFileStorage' => true,
          'browseLocalFiles' => {
            'path': '/storage/main', 'uri': 'file:///storage/main', 'parent': '',
            'folders': [], 'files': [{'name': 'token.txt', 'path': '/storage/main/token.txt'}],
          },
          'pickWeatherTokenDocument' || 'localDocumentOperation' => bytes,
          _ => null,
        };
        // Engine platform messages are exposed through unmodifiable ByteData.
        return codec.encodeSuccessEnvelope(result).asUnmodifiableView();
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(secrets, null);
        messenger.setMockMessageHandler(documents.name, null);
      });
      await settings.setFileManagerPreference(builtIn
          ? FileManagerPreference.builtIn : FileManagerPreference.external);
      final server = parseWeatherServer('https://weather.example.test/home')!;
      await service.configure(WeatherConfiguration(source: WeatherSource.customOpenMeteo, server: server));
      transport.requests.clear();
      await mount(tester);
      final button = tile('Импортировать токен из файла');
      await tester.scrollUntilVisible(button, 100);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      if (builtIn) {
        await tester.tap(find.text('token.txt'));
        await tester.pumpAndSettle();
      }
      expect(writes, [{'server': server.toString(), 'token': 'fixture-readonly-token'}]);
      expect(find.text('fixture-readonly-token'), findsNothing);
      expect(transport.requests, isEmpty);
      bytes = Uint8List.fromList([0xff]);
      await tester.tap(button);
      await tester.pumpAndSettle();
      if (builtIn) {
        await tester.tap(find.text('token.txt'));
        await tester.pumpAndSettle();
      }
      final l = AppLocalizations.of(tester.element(find.byType(WeatherPage)))!;
      expect(find.text(l.weatherImportEncodingError), findsOneWidget);
      expect(writes, hasLength(1));
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final source in ['Open-Meteo', 'MET Norway', 'OpenWeather', 'Яндекс Погода (REST)', 'Gismeteo']) {
    testWidgets(
      '$source selection only chooses the source; parameters stay separate',
      (tester) async {
        await mount(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<FocusableSettingsTile>(
                find.descendant(
                  of: find.byType(AlertDialog),
                  matching: find.byType(FocusableSettingsTile),
                ),
              )
              .map((button) => (button.title as Text).data)
              .toList(),
          [
            'Open-Meteo',
            'Свой сервер (Open-Meteo)',
            'MET Norway',
            'OpenWeather',
            'Яндекс Погода (REST)',
            'Gismeteo',
            'Breezy Weather',
          ],
        );
        await tester.tap(find.text(source));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        expect(tile('Местоположение'), findsOneWidget);
        expect(tile('Получить местоположение'), findsOneWidget);
        expect(tile('Название города'), findsNothing);
        if (source == 'Gismeteo') {
          expect(service.configuration.source, WeatherSource.gismeteo);
          expect(tile('Ввести координаты'), findsOneWidget);
          expect(tile('Ключ API Яндекса'), findsNothing);
          expect(tile('API-ключ OpenWeather'), findsNothing);
        }
        expect(service.canRefresh, isFalse);
        await tester.ensureVisible(tile('Обновить погоду'));
        expect(
          tester
              .widget<FocusableSettingsTile>(tile('Обновить погоду'))
              .enabled,
          isFalse,
        );
        expect(transport.requests, isEmpty);
      },
    );
  }
  testWidgets(
    'location mode is separate and city search matches solar settings',
    (tester) async {
      const citiesChannel = MethodChannel('cutelauncher/night');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var searches = 0;
      messenger.setMockMethodCallHandler(citiesChannel, (call) async {
        expect(call.method, 'cities');
        expect(call.arguments['language'], 'en');
        searches++;
        return searches == 1
            ? []
            : [
                {
                  'city': 'Moscow, Russia',
                  'latitude': 55.75583,
                  'longitude': 37.61778,
                },
                {
                  'city': 'Moscow, Idaho, United States',
                  'latitude': 46.73239,
                  'longitude': -117.00017,
                },
              ];
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(citiesChannel, null),
      );
      await tester.runAsync(
        () => service.configure(
          const WeatherConfiguration(source: WeatherSource.yandex),
        ),
      );
      await mount(tester);
      await tester.tap(tile('Местоположение'));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('Получить автоматически'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Ввести вручную')),
      );
      await waitFor(
        tester,
        () => tile('Название города').evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      expect(tile('Получить местоположение'), findsNothing);
      expect(tile('Название города'), findsOneWidget);
      expect(searches, 0);
      expect(service.canRefresh, isFalse);
      await tester.tap(tile('Название города'));
      await tester.pumpAndSettle();
      expect(find.text('Выбрать город'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
        isNull,
      );
      await tester.enterText(find.byType(TextField), 'WrongCityDefinitely');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(
        find.text('Города не найдены. Попробуйте другое название.'),
        findsOneWidget,
      );
      expect(service.configuration.location, isEmpty);
      expect(transport.requests, isEmpty);
      await tester.enterText(find.byType(TextField), 'Moscow');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moscow, Idaho, United States'));
      await waitFor(
        tester,
        () => find
            .descendant(
              of: find.byType(WeatherPage),
              matching: find.text('Moscow, Idaho, United States'),
            )
            .evaluate()
            .isNotEmpty,
      );
      expect(service.configuration.cityLatitude, 46.73239);
      expect(service.configuration.cityLongitude, -117.00017);
      expect(transport.requests, isEmpty); // Yandex still requires a key.
      await tester.tap(tile('Местоположение'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Получить автоматически'),
        ),
      );
      await waitFor(
        tester,
        () => tile('Получить местоположение').evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      expect(tile('Название города'), findsNothing);
      expect(tile('Получить местоположение'), findsOneWidget);
      expect(service.configuration.cityLatitude, 46.73239);
      expect(service.configuration.location, 'Moscow, Idaho, United States');
      expect(service.canRefresh, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('API key editor hides keys; missing location prevents requests', (
    tester,
  ) async {
    await tester.runAsync(
      () => service.configure(
        const WeatherConfiguration(source: WeatherSource.openWeather),
      ),
    );
    await mount(tester);
    for (final key in ['replacement-test-key', '']) {
      await tester.ensureVisible(tile('API-ключ OpenWeather'));
      await tester.tap(tile('API-ключ OpenWeather'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(field.controller!.text, isEmpty);
      await tester.enterText(find.byType(TextField), key);
      await tester.runAsync(() async {
        await tester.tap(find.text('ОК'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      final saved = File('${directory.path}/weather-api-key-openweather');
      await waitFor(
        tester,
        () => key.isEmpty
            ? !saved.existsSync()
            : saved.existsSync() && saved.readAsStringSync() == key,
      );
      expect(
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return service.hasApiKey(source: WeatherSource.openWeather);
        }),
        key.isNotEmpty,
      );
      expect(service.canRefresh, isFalse);
      expect(transport.requests, isEmpty);
    }
  });
  testWidgets(
    'automatic location shows immutable coordinates and handles denied permission',
    (tester) async {
      const channel = MethodChannel('cutelauncher/weather_location');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {'latitude': 55.75583, 'longitude': 37.61778},
      );
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await tester.runAsync(
        () => service.configure(
          const WeatherConfiguration(source: WeatherSource.yandex),
        ),
      );
      await mount(tester);
      await tester.tap(tile('Получить местоположение'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(find.text('55.756, 37.618'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(service.configuration.validCoordinates, isTrue);
      expect(service.canRefresh, isFalse);
      expect(transport.requests, isEmpty);
      messenger.setMockMethodCallHandler(
        channel,
        (_) async =>
            throw PlatformException(code: 'LOCATION_PERMISSION_DENIED'),
      );
      await tester.tap(tile('Получить местоположение'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Разрешите доступ к местоположению в настройках Android и повторите попытку.',
        ),
        findsOneWidget,
      );
      expect(service.configuration.latitude, 55.75583);
      expect(service.locating, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
