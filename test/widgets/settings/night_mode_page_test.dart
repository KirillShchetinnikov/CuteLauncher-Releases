import 'package:flauncher/widgets/settings/settings_slider_tile.dart';
import 'adb_test_compatibility.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/widgets/settings/city_search_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/widgets/settings/night_mode_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';

void main() {
  Future<void> reveal(WidgetTester tester, String text) async {
    final target = find.text(text);
    await tester.scrollUntilVisible(target, 350,
        scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(tester.element(target), alignment: 0.2);
    await tester.pumpAndSettle();
  }

  const tcl = MethodChannel('cutelauncher/tcl_blue_light');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tcl, (_) async => {'status': 'unsupported'});
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tcl, null);
  });
  testWidgets(
    'automatic location is read-only and failure preserves coordinates',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        nightModeKey: jsonEncode(
          const NightModeConfiguration(
            solar: true,
            automaticLocation: true,
          ).toJson(),
        ),
      });
      const location = MethodChannel('cutelauncher/weather_location');
      const night = MethodChannel('cutelauncher/night');
      var denied = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(location, (
        call,
      ) async {
        expect(call.method, 'locate');
        if (denied) throw PlatformException(code: 'LOCATION_PERMISSION_DENIED');
        return {'latitude': 55.75, 'longitude': 37.61};
      });
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        night,
        (_) async => {'permission': false},
      );
      final service = NightModeService(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: service,
          child: MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) =>
                    const Scaffold(body: NightModePage(section: 'schedule')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await reveal(tester, 'Местоположение');
      await tester.tap(find.text('Получить местоположение'));
      await tester.pumpAndSettle();
      expect(service.configuration.latitude, 55.75);
      expect(service.configuration.longitude, 37.61);
      expect(find.byType(TextField), findsNothing);
      denied = true;
      await tester.tap(find.text('55.750, 37.610'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text(
          'Не удалось получить местоположение. Проверьте разрешение и системную геолокацию.',
        ),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('55.750, 37.610'), findsOneWidget);
      expect(service.configuration.latitude, 55.75);
      expect(service.configuration.longitude, 37.61);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpWidget(const SizedBox());
      service.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        location,
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        night,
        null,
      );
    },
  );
  for (final language in ['ru', 'en']) {
    testWidgets('battery settings use remote activation and explain unavailable menu ($language)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      const night = MethodChannel('cutelauncher/night');
      var requested = false;
      var status = 'unavailable';
      bool? exempt = false;
      final requests = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(night,
          (call) async {
        if (call.method == 'batterySettings') {
          requested = true;
          requests.add(call);
          return status;
        }
        return {'batteryExempt': exempt};
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(night, null));
      final service = NightModeService(await SharedPreferences.getInstance());
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: service,
          child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: NightModePage()))));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(NightModePage)))!;
      await reveal(tester, l.nightBatteryTitle);
      final batteryButton = find.ancestor(of: find.text(l.nightBatteryTitle),
          matching: find.byType(FocusableSettingsTile));
      expect(find.descendant(of: batteryButton, matching: find.text(l.nightBatteryOptimized)), findsOneWidget);
      exempt = true;
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.descendant(of: batteryButton, matching: find.text(l.nightBatteryExempt)), findsOneWidget);
      expect(find.descendant(of: batteryButton, matching: find.byIcon(Icons.check_circle_outline)), findsOneWidget);
      exempt = null;
      await service.refreshSystem();
      await tester.pumpAndSettle();
      expect(find.descendant(of: batteryButton, matching: find.text(l.nightBatteryUnknown)), findsOneWidget);
      exempt = false;
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.descendant(of: batteryButton, matching: find.text(l.nightBatteryOptimized)), findsOneWidget);
      Focus.of(tester.element(find.text(l.nightBatteryTitle))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(requested, isTrue);
      expect(find.text(l.nightBatteryUnavailable), findsOneWidget);
      expect(service.configuration.enabled, isFalse);
      expect(requests.single.arguments['guide']['hint'], l.nightBatteryGuide);
      status = 'hintRequired';
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(l.nightBatteryGuide), findsOneWidget);
      expect(service.batterySettingsUnavailable, isFalse);
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(requests.length, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      status = 'opened';
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(requests.last.arguments['withoutOverlay'], isTrue);
      expect(find.byType(AlertDialog), findsNothing);
      service.dispose();
    });
  }
  testWidgets(
      'sliders persist their range and city search configures solar location',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      nightModeKey: jsonEncode(
          const NightModeConfiguration(scheduled: true, solar: true).toJson())
    });
    const night = MethodChannel('cutelauncher/night');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(night,
        (call) async {
      if (call.method == 'cities') {
        return [
          {'city': 'Москва, Россия', 'latitude': 55.75, 'longitude': 37.61}
        ];
      }
      return {'permission': false, 'solarLoading': false};
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(night, null));
    final service = NightModeService(await SharedPreferences.getInstance());
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: service,
        child: const MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: NightModePage()))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Настройки фильтра'));
    await tester.pumpAndSettle();
    final slider = find.byType(Slider).first;
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    expect(tester.widget<SettingsSliderTile>(find.byType(SettingsSliderTile).first).options.last, 95);
    expect(tester.widget<Slider>(slider).divisions, 19);
    final rect = tester.getRect(slider);
    await tester.tapAt(Offset(rect.right - 25, rect.center.dy));
    await tester.pumpAndSettle();
    expect(service.configuration.dim, 95);
    FocusNode sliderFocus(int i) => Focus.of(tester.element(find.descendant(of: find.byType(SettingsSliderTile).at(i), matching: find.byType(Text)).first));
    sliderFocus(0).requestFocus();
    await tester.pumpAndSettle();
    final before = service.configuration;
    for (var i = 1; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(sliderFocus(i).hasFocus, isTrue);
    }
    expect(service.configuration.dim, before.dim);
    expect(service.configuration.warmth, before.warmth);
    expect(service.configuration.temperature, before.temperature);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(sliderFocus(1).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(service.configuration.warmth, before.warmth + 5);
    Navigator.of(tester.element(find.byType(Slider).first)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Расписание'));
    await tester.pumpAndSettle();
    await reveal(tester, 'Местоположение');
    await tester.tap(find.text('Местоположение'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ввести вручную').last);
    await tester.pumpAndSettle();
    await reveal(tester, 'Название города');
    await tester.tap(find.text('Название города'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).decoration!.hintText, isNull);
    expect(find.text('Введите название города по-английски'), findsNothing);
    expect(find.descendant(of: find.byType(CitySearchDialog), matching: find.text('Подробнее')), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Moscow');
    tester.testTextInput.hide();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(find.text('Найти'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Москва, Россия'));
    await tester.pumpAndSettle();
    expect(service.configuration.latitude, 55.75);
    expect(service.configuration.longitude, 37.61);
    expect(service.configuration.city, 'Москва, Россия');
    service.dispose();
  });
  testWidgets('one TCL switch links the filter without enabling night mode',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final until = DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({nightModeKey: jsonEncode(
      NightModeConfiguration(overrideMode: 'off', overrideUntil: until).toJson())});
    var enabled = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(tcl,
        (call) async {
      if (call.method == 'set') enabled = call.arguments['enabled'] as bool;
      return {'status': 'success', 'enabled': enabled};
    });
    const night = MethodChannel('cutelauncher/night');
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(night, (_) async => {'permission': false});
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(night, null));
    final service = NightModeService(await SharedPreferences.getInstance());
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: service,
        child: const MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: NightModePage()))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Настройки фильтра'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TCL: фильтр синего цвета'));
    await tester.pumpAndSettle();
    expect(enabled, isFalse);
    expect(service.configuration.tclScheduled, isFalse);
    expect(service.configuration.overrideMode, 'off');
    expect(service.configuration.overrideUntil, until);
    expect(service.configuration.enabled, isFalse);
    service.dispose();
  });
  testWidgets('notification access updates status without enabling filter',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const night = MethodChannel('cutelauncher/night');
    final calls = <MethodCall>[];
    var allowed = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(night,
        (call) async {
      calls.add(call);
      if (call.method == 'notifications') allowed = true;
      return {'permission': true, 'notifications': allowed};
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(night, null));
    final service = NightModeService(prefs);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: service,
        child: const MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: NightModePage()))));
    await tester.pumpAndSettle();
    expect(find.text('Разрешить уведомление ночного режима'), findsNothing);
    expect(find.text('Обновить статус разрешений'), findsNothing);
    expect(calls.where((call) => call.method == 'notifications'), isEmpty);
    expect(service.configuration.enabled, isFalse);
    service.dispose();
  });
  testWidgets('ADB grant checks connection and uses native configured port',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'adb_port': 5556});
    final prefs = await SharedPreferences.getInstance();
    final calls = <MethodCall>[];
    const adb = MethodChannel('cutelauncher/adb');
    const night = MethodChannel('cutelauncher/night');
    var granted = false;
    const platform = MethodChannel('me.efesser.flauncher/method');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(platform, (_) async => granted);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(platform, null));
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(night, (_) async => {'permission': granted});
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(adb,
        (call) async {
      if (call.method == 'info') { return {'compatibility': supportedAdbCompatibility, 'port': 5556, 'tls': false}; }
      if (call.arguments['action'] == 'check') return {'status': 'ready'};
      if (call.arguments['action'] == 'preview') { return {'status': 'ready', 'commands': ['grant overlay']}; }
      calls.add(call);
      granted = true;
      return {'status': 'success'};
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(night, null);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, null);
    });
    final service = NightModeService(prefs);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: service,
        child: const MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: NightModePage()))));
    await tester.pumpAndSettle();
    await reveal(tester, 'Выдать разрешение через ADB');
    await tester.tap(find.text('Выдать разрешение через ADB'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Применить')); await tester.pumpAndSettle();
    expect(calls.single.arguments, {'action': 'overlay', 'port': 5556, 'tls': false, 'commands': ['grant overlay']});
    await reveal(tester, 'Показ поверх других приложений разрешён');
    expect(
        find.text('Показ поверх других приложений разрешён'), findsOneWidget);
    service.dispose();
  });
  testWidgets('schedule offers only the opposite temporary mode', (tester) async {
    SharedPreferences.setMockInitialValues({nightModeKey: '{"enabled":false,"scheduled":true}'});
    const channel = MethodChannel('cutelauncher/night');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async => {'permission': false});
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    final service = NightModeService(await SharedPreferences.getInstance());
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: service,
      child: const MaterialApp(
        locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NightModePage(section: 'schedule')),
      ),
    ));
    await tester.pumpAndSettle();
    const enable = 'Включить ночной режим до следующего рассвета';
    const disable = 'Отключить ночной режим до следующего заката';
    expect(find.text(enable), findsOneWidget);
    expect(find.text(disable), findsNothing);
    await tester.tap(find.text(enable));
    await tester.pumpAndSettle();
    expect(find.text(enable), findsNothing);
    expect(find.text(disable), findsOneWidget);
    await tester.tap(find.text(disable));
    await tester.pumpAndSettle();
    expect(find.text(enable), findsOneWidget);
    expect(find.text(disable), findsNothing);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });

}
