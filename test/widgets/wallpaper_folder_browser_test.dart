import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/slideshow_service.dart';
import 'package:flauncher/widgets/settings/slideshow_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/local_file_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const channel = MethodChannel('me.efesser.flauncher/method');
  final calls = <MethodCall>[];
  var granted = true;
  var unavailable = false;
  var systemUnavailable = false;

  setUp(() {
    calls.clear();
    granted = true;
    unavailable = false;
    systemUnavailable = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'requestFileStorage') return granted;
          if (call.method == 'filePickerAvailable') return !systemUnavailable;
          if (call.method == 'pickWallpaperFolder') {
            if (systemUnavailable) {
              throw PlatformException(code: 'document_unavailable');
            }
            return null;
          }
          if (call.method == 'browseLocalFiles') {
            if (unavailable) throw PlatformException(code: 'document_failed');
            final path =
                (call.arguments as Map)['path'] as String? ??
                '/storage/emulated/0';
            return {
              'path': path,
              'uri': Uri.file(path).toString(),
              'parent': path == '/storage/emulated/0/Фото'
                  ? '/storage/emulated/0'
                  : path == '/storage'
                  ? ''
                  : '/storage',
              'folders': [
                if (path == '/storage/emulated/0')
                  {'name': 'Фото', 'path': '$path/Фото'},
              ],
            };
          }
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  Widget app(Widget page) => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: page),
  );

  testWidgets('browse child and parent folders and reject failed navigation', (
    tester,
  ) async {
    await tester.pumpWidget(app(const LocalFileBrowser()));
    await tester.pumpAndSettle();
    expect(find.text('/storage/emulated/0'), findsOneWidget);
    await tester.tap(find.text('Фото'));
    await tester.pumpAndSettle();
    expect(find.text('/storage/emulated/0/Фото'), findsOneWidget);
    await tester.tap(find.byTooltip('На уровень выше'));
    await tester.pumpAndSettle();
    expect(find.text('/storage/emulated/0'), findsOneWidget);
    unavailable = true;
    await tester.tap(find.byTooltip('На уровень выше'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Не удалось открыть это расположение'),
      findsOneWidget,
    );
    final use = tester.widget<FocusableSettingsTile>(
      find.ancestor(
        of: find.text('Выбрать эту папку'),
        matching: find.byType(FocusableSettingsTile),
      ),
    );
    use.onPressed!();
    await tester.pumpAndSettle();
    expect(find.byType(LocalFileBrowser), findsOneWidget);
  });

  testWidgets('browser keeps focus on entry and on return with Back', (
    tester,
  ) async {
    await tester.pumpWidget(app(const LocalFileBrowser()));
    await tester.pumpAndSettle();
    expect(find.text('Ввести путь к папке'), findsNothing);
    expect(Focus.of(tester.element(find.text('Фото'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('/storage/emulated/0/Фото'), findsOneWidget);
    expect(
      Focus.of(tester.element(find.text('Выбрать эту папку'))).hasFocus,
      isTrue,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('/storage/emulated/0'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('Фото'))).hasFocus, isTrue);
  });

  testWidgets(
    'denied access and cancelled manual input preserve the old folder',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'slideshow_folder': 'content://old/tree/root',
      });
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final service = SlideshowService(prefs, settings);
      try {
        await tester.pumpWidget(
          app(
            ChangeNotifierProvider.value(
              value: service,
              child: const SlideshowPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        granted = false;
        await tester.tap(find.text('Просмотр папок'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Разрешите доступ к файлам'),
          findsOneWidget,
        );
        expect(service.folder, 'content://old/tree/root');
        await tester.tap(find.text('Ввести путь к папке'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(
            MaterialLocalizations.of(tester.element(find.byType(TextField)))
                .cancelButtonLabel,
          ),
        );
        await tester.pumpAndSettle();
        expect(service.folder, 'content://old/tree/root');
        expect(
          calls.where((call) => call.method == 'browseLocalFiles'),
          isEmpty,
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        service.dispose();
        settings.dispose();
      }
    },
  );

  testWidgets(
    'absent system picker directly opens built-in without changing saved folder',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'slideshow_folder': 'content://old/tree/root',
      });
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final service = SlideshowService(prefs, settings);
      try {
        systemUnavailable = true;
        await tester.pumpWidget(
          app(
            ChangeNotifierProvider.value(
              value: service,
              child: const SlideshowPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Просмотр папок'));
        await tester.pumpAndSettle();
        expect(find.byType(LocalFileBrowser), findsOneWidget);
        expect(find.text('Выбор проводника'), findsNothing);
        expect(service.folder, 'content://old/tree/root');
      } finally {
        await tester.pumpWidget(const SizedBox());
        service.dispose();
        settings.dispose();
      }
    },
  );

  testWidgets(
    'unavailable manual path preserves the old folder and its permission',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'slideshow_folder': 'content://old/tree/root',
      });
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final service = SlideshowService(prefs, settings);
      try {
        unavailable = true;
        await tester.pumpWidget(
          app(
            ChangeNotifierProvider.value(
              value: service,
              child: const SlideshowPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ввести путь к папке'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '/storage/missing');
        await tester.tap(find.text('ОК'));
        await tester.pumpAndSettle();
        expect(service.folder, 'content://old/tree/root');
        expect(find.textContaining('Папка недоступна'), findsOneWidget);
        expect(
          calls.any((call) => call.method == 'releaseWallpaperFolder'),
          isFalse,
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        service.dispose();
        settings.dispose();
      }
    },
  );

  testWidgets('manual selection is verified and stored as a local URI', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'slideshow_folder': 'content://old/tree/root',
    });
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final service = SlideshowService(prefs, settings);
    try {
      await tester.pumpWidget(
        app(
          ChangeNotifierProvider.value(
            value: service,
            child: const SlideshowPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ввести путь к папке'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '/storage/USB/Wallpapers');
      await tester.tap(find.text('ОК'));
      await tester.pumpAndSettle();
      expect(service.folder, 'file:///storage/USB/Wallpapers');
      expect(
        calls.any(
          (call) =>
              call.method == 'releaseWallpaperFolder' &&
              (call.arguments as Map)['uri'] == 'content://old/tree/root',
        ),
        isTrue,
      );
    } finally {
      await tester.pumpWidget(const SizedBox());
      service.dispose();
      settings.dispose();
    }
  });
}
