import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/remote_mapping_configuration.dart';
import 'package:flauncher/widgets/settings/volume_keys_page.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('cutelauncher/remote_mappings');
  late RemoteMappingConfiguration config;
  bool fail = false;
  setUp(() {
    config = const RemoteMappingConfiguration(
      enabled: true,
      bindings: [RemoteMapping(keyCode: 83)],
    );
    fail = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'save') {
        if (fail) throw PlatformException(code: 'unavailable');
        config = RemoteMappingConfiguration.fromMap(call.arguments as Map);
      }
      return config.toMap();
    });
  });
  tearDown(
    () =>
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
  );
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1440);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: VolumeKeysPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('mapping edits and master preserve volume settings', () {
    final original = config.copyWith(volumeMode: 'off', volumePauseSeconds: 15);
    final edited = original
        .replace(const RemoteMapping(keyCode: 190))
        .remove(83)
        .copyWith(enabled: false);
    final reloaded = RemoteMappingConfiguration.fromMap(edited.toMap())
        .copyWith(enabled: true);
    expect(reloaded.volumeMode, 'off');
    expect(reloaded.volumePauseSeconds, 15);
    expect(reloaded.bindings.single.keyCode, 190);
    expect(
      RemoteMappingConfiguration.fromMap({'enabled': true, 'bindings': []})
          .volumeMode,
      'auto',
    );
  });
  testWidgets(
    'saves modes and duration without changing mappings; help starts collapsed',
    (tester) async {
      await open(tester);
      expect(find.byType(SettingsHelp), findsOneWidget);
      expect(
        find.text(
          AppLocalizations.of(tester.element(find.byType(VolumeKeysPage)))!
              .volumeKeysHelp,
        ),
        findsNothing,
      );
      await tester.tap(find.text('Способ исправления'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Пауза по таймеру'));
      await tester.pumpAndSettle();
      expect(config.volumeMode, 'timed');
      await tester.tap(find.text('Длительность паузы'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15 секунд'));
      await tester.pumpAndSettle();
      expect(config.volumePauseSeconds, 15);
      expect(config.bindings.single.keyCode, 83);
      await tester.tap(find.text('Способ исправления'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Собственный повтор'));
      await tester.pumpAndSettle();
      expect(config.volumeMode, 'repeat');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('save failure preserves last confirmed choice', (tester) async {
    await open(tester);
    fail = true;
    await tester.tap(find.text('Способ исправления'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Собственный повтор'));
    await tester.pumpAndSettle();
    expect(config.volumeMode, 'auto');
    expect(find.text('Авто: пока видна панель'), findsOneWidget);
  });
  testWidgets('remote control opens choice and Back cancels it', (
    tester,
  ) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Собственный повтор'), findsOneWidget);
    await binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(config.volumeMode, 'auto');
    expect(tester.takeException(), isNull);
  });
}
