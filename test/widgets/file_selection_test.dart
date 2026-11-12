import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/file_selection.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
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
  var available = false;
  var granted = true;
  Object? systemResult;
  Object? localResult;
  String? systemError;
  String? storageError;
  Completer<void>? loading;
  var many = false;
  setUp(() {
    calls.clear();
    available = false;
    granted = true;
    systemResult = null;
    localResult = 'staged';
    systemError = null;
    storageError = null;
    loading = null;
    many = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'filePickerAvailable':
              return available;
            case 'requestFileStorage':
              if (storageError != null) throw PlatformException(code: storageError!);
              return granted;
            case 'browseLocalFiles':
              await loading?.future;
              final args = call.arguments as Map;
              final path = args['path'] as String? ?? '/storage/main';
              final name = switch (args['kind']) {
                'document' => 'sample.json',
                'text' => 'sample.txt',
                _ => 'sample.png',
              };
              return {
                'path': path,
                'uri': Uri.file(path).toString(),
                'parent': path == '/storage'
                    ? ''
                    : path == '/storage/main'
                    ? '/storage'
                    : '/storage/main',
                'folders': path == '/storage/main'
                    ? [
                        for (var i = 0; i < (many ? 80 : 1); i++)
                          {'name': 'Folder $i', 'path': '$path/Folder $i'},
                      ]
                    : [],
                'files': args['kind'] != 'folder'
                    ? [
                        {'name': name, 'path': '$path/$name'},
                      ]
                    : [],
              };
            case 'localDocumentOperation':
              return localResult;
            case 'backupFolderOperation':
              return true;
            default:
              if (systemError != null) {
                throw PlatformException(code: systemError!);
              }
              return systemResult;
          }
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  Future<void> start(
    WidgetTester tester,
    String operation,
    void Function(Object?) result, {
    String locale = 'ru',
    double scale = 1,
    ValueChanged<String>? onSaved,
    FileManagerPreference? preference,
  }) async {
    final app = MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => FocusableSettingsTile(
            autofocus: true,
            title: const Text('Open'),
            onPressed: () async => result(
              await FileSelection.select<Object>(
                context,
                operation,
                onSaved: onSaved,
                arguments: const {
                  'path': '/private/report.json',
                  'name': 'report.json',
                },
              ),
            ),
          ),
        ),
      ),
    );
    if (preference == null) {
      await tester.pumpWidget(app);
    } else {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      await settings.setFileManagerPreference(preference);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(value: settings, child: app),
      );
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('built-in preference skips external availability and chooser', (
    tester,
  ) async {
    available = true;
    await start(
      tester,
      'pickImageDocument',
      (_) {},
      preference: FileManagerPreference.builtIn,
    );
    expect(find.text('Выбор проводника'), findsNothing);
    expect(find.byType(LocalFileBrowser), findsOneWidget);
    expect(calls.any((call) => call.method == 'filePickerAvailable'), isFalse);
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
  });

  for (final operation in [
    'pickImageDocument',
    'pickBackupFolder',
    'saveBackupDocument',
  ]) {
    testWidgets('external preference opens $operation directly', (
      tester,
    ) async {
      available = true;
      systemResult = 'external-result';
      Object? result;
      await start(
        tester,
        operation,
        (value) => result = value,
        preference: FileManagerPreference.external,
      );
      expect(result, 'external-result');
      expect(calls.map((call) => call.method), [
        'filePickerAvailable',
        operation,
      ]);
      expect(find.text('Выбор проводника'), findsNothing);
      expect(find.byType(LocalFileBrowser), findsNothing);
    });
  }

  testWidgets('external cancellation preserves null without opening built-in', (
    tester,
  ) async {
    available = true;
    Object? result = 'unchanged';
    await start(
      tester,
      'pickImageDocument',
      (value) => result = value,
      preference: FileManagerPreference.external,
    );
    expect(result, isNull);
    expect(find.byType(LocalFileBrowser), findsNothing);
    expect(calls.map((call) => call.method), [
      'filePickerAvailable',
      'pickImageDocument',
    ]);
  });

  for (final missingHandler in [true, false]) {
    testWidgets(
      'external preference falls back when handler ${missingHandler ? 'is missing' : 'disappears'}',
      (tester) async {
        available = !missingHandler;
        systemError = 'document_unavailable';
        await start(
          tester,
          'pickWallpaperFolder',
          (_) {},
          preference: FileManagerPreference.external,
        );
        expect(find.byType(LocalFileBrowser), findsOneWidget);
        expect(find.text('Выбор проводника'), findsNothing);
        await tester.tap(find.byTooltip('Закрыть'));
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('ask preference keeps the chooser', (tester) async {
    available = true;
    await start(
      tester,
      'pickImageDocument',
      (_) {},
      preference: FileManagerPreference.ask,
    );
    expect(find.text('Выбор проводника'), findsOneWidget);
    expect(calls.map((call) => call.method), ['filePickerAvailable']);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  });

  for (final operation in [
    'pickImageDocument',
    'pickWallpaperDocument',
    'pickBackupDocument',
    'pickDriveClientDocument',
    'pickWebhookDocument',
    'pickWeatherTokenDocument',
    'pickWeatherServerDocument',
    'pickCleanerListDocument',
    'pickWallpaperFolder',
    'pickBackupFolder',
    'saveBackupDocument',
    'saveDiagnosticsDocument',
  ]) {
    testWidgets(
      '$operation opens built-in directly when no compatible system handler exists',
      (tester) async {
        Object? result;
        final kind = switch (operation) {
          'pickImageDocument' => 'image',
          'pickWallpaperDocument' => 'media',
          'pickBackupDocument' || 'pickDriveClientDocument' => 'document',
          'pickWebhookDocument' || 'pickWeatherTokenDocument' || 'pickWeatherServerDocument' || 'pickCleanerListDocument' => 'text',
          _ => 'folder',
        };
        final name = kind == 'document'
            ? 'sample.json'
            : kind == 'text'
            ? 'sample.txt'
            : 'sample.png';
        localResult = switch (operation) {
          'saveBackupDocument' => true,
          'pickCleanerListDocument' => {'path': 'staged', 'name': name},
          'pickWeatherTokenDocument' || 'pickWeatherServerDocument' => Uint8List.fromList([65, 66]),
          _ => 'staged',
        };
        await start(tester, operation, (value) => result = value);
        expect(find.text('Выбор проводника'), findsNothing);
        expect(find.byType(LocalFileBrowser), findsOneWidget);
        expect(
          (calls.firstWhere((c) => c.method == 'browseLocalFiles').arguments
              as Map)['kind'],
          kind,
        );
        final folder = operation.endsWith('Folder');
        final save = operation.startsWith('save');
        expect(
          (calls.firstWhere((c) => c.method == 'requestFileStorage').arguments
              as Map)['write'],
          save || operation == 'pickBackupFolder',
        );
        await tester.tap(
          find
              .text(
                folder
                    ? 'Выбрать эту папку'
                    : save
                    ? 'Сохранить'
                    : name,
              )
              .last,
        );
        await tester.pumpAndSettle();
        expect(find.byType(LocalFileBrowser), findsNothing);
        expect(result, folder ? 'file:///storage/main' : localResult);
        expect(calls.where((c) => c.method == operation), isEmpty);
        if (operation == 'pickBackupFolder') {
          expect(calls.last.method, 'backupFolderOperation');
        }
        if (!folder) {
          final args = calls.last.arguments as Map;
          expect(
            args['selected'],
            save ? 'file:///storage/main' : 'file:///storage/main/$name',
          );
          expect(args['operation'], operation);
        }
        expect(Focus.of(tester.element(find.text('Open'))).hasFocus, isTrue);
      },
    );
  }

  for (final operation in ['pickWallpaperFolder', 'saveBackupDocument']) {
    testWidgets(
      'remote reaches and activates the fixed confirmation: $operation',
      (tester) async {
        Object? result;
        if (operation == 'saveBackupDocument') localResult = true;
        await start(tester, operation, (value) => result = value);
        expect(
          Focus.of(tester.element(find.text('Folder 0'))).hasFocus,
          isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        final label = operation == 'pickWallpaperFolder'
            ? 'Выбрать эту папку'
            : 'Сохранить';
        for (
          var i = 0;
          i < 2 && !Focus.of(tester.element(find.text(label).last)).hasFocus;
          i++
        ) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
        }
        expect(
          Focus.of(tester.element(find.text(label).last)).hasFocus,
          isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(LocalFileBrowser), findsNothing);
        expect(
          result,
          operation == 'pickWallpaperFolder' ? 'file:///storage/main' : true,
        );
        expect(Focus.of(tester.element(find.text('Open'))).hasFocus, isTrue);
      },
    );
  }

  for (final operation in ['pickWallpaperFolder', 'pickImageDocument']) {
    testWidgets(
      'remote reaches parent and close controls from the list: $operation',
      (tester) async {
        Object? result = 'unchanged';
        await start(tester, operation, (value) => result = value);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        final headers = tester
            .widgetList<MenuHeaderAction>(find.byType(MenuHeaderAction))
            .toList();
        for (
          var i = 0;
          i < 2 && !headers.any((button) => button.focusNode?.hasFocus == true);
          i++
        ) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
        }
        expect(
          headers.any((button) => button.focusNode?.hasFocus == true),
          isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        expect(headers.first.focusNode!.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('/storage'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        for (var i = 0; i < 2 && !headers[1].focusNode!.hasFocus; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
        }
        expect(headers[1].focusNode!.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(LocalFileBrowser), findsNothing);
        expect(result, isNull);
        expect(Focus.of(tester.element(find.text('Open'))).hasFocus, isTrue);
      },
    );
  }

  testWidgets('remote scrolls a long directory before reaching confirmation', (
    tester,
  ) async {
    many = true;
    await start(tester, 'pickWallpaperFolder', (_) {});
    final confirmation = tester.widget<FocusableSettingsTile>(
      find.ancestor(
        of: find.text('Выбрать эту папку'),
        matching: find.byType(FocusableSettingsTile),
      ),
    );
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).last)
        .position;
    for (var i = 0; i < 200 && !confirmation.focusNode!.hasFocus; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(scroll.pixels, scroll.maxScrollExtent);
    expect(confirmation.focusNode!.hasFocus, isTrue);
    expect(find.text('Folder 9'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Folder 9'))).hasFocus, isTrue);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LocalFileBrowser), findsNothing);
  });

  testWidgets(
    'system choice uses exact action and cancellation does not open built-in',
    (tester) async {
      available = true;
      await start(tester, 'pickImageDocument', (_) {});
      expect(find.text('Выбор проводника'), findsOneWidget);
      expect(calls.map((c) => c.method), ['filePickerAvailable']);
      await tester.tap(find.text('Внешний проводник'));
      await tester.pumpAndSettle();
      expect(calls.map((c) => c.method), [
        'filePickerAvailable',
        'pickImageDocument',
      ]);
      expect(find.byType(LocalFileBrowser), findsNothing);
    },
  );

  testWidgets(
    'cancel choice changes nothing and built-in remains explicitly available',
    (tester) async {
      available = true;
      await start(tester, 'pickWallpaperFolder', (_) {});
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(calls.length, 1);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Встроенный проводник'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      expect(find.byType(LocalFileBrowser), findsNothing);
      expect(calls.any((c) => c.method == 'pickWallpaperFolder'), isFalse);
    },
  );

  testWidgets('missing all-files settings reports a usable alternative without browsing', (tester) async {
    storageError = 'storage_settings_unavailable';
    Object? result = 'unchanged';
    await start(tester, 'pickBackupDocument', (value) => result = value);
    expect(result, isNull);
    expect(find.textContaining('недоступен экран доступа ко всем файлам'), findsOneWidget);
    expect(find.byType(LocalFileBrowser), findsNothing);
    expect(calls.map((call) => call.method), ['filePickerAvailable', 'requestFileStorage']);
    // Failed permission routing must not leave the single-selection gate locked.
    storageError = null;
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(LocalFileBrowser), findsOneWidget);
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'denied storage preserves the choice and does not enumerate files',
    (tester) async {
      granted = false;
      Object? result = 'unchanged';
      await start(tester, 'pickWallpaperFolder', (value) => result = value);
      expect(result, isNull);
      expect(find.textContaining('Разрешите доступ к файлам'), findsOneWidget);
      expect(calls.map((call) => call.method), [
        'filePickerAvailable',
        'requestFileStorage',
      ]);
    },
  );

  testWidgets('handler disappearing before launch falls back to built-in', (
    tester,
  ) async {
    available = true;
    systemError = 'document_unavailable';
    await start(tester, 'pickWallpaperFolder', (_) {});
    await tester.tap(find.text('Внешний проводник'));
    await tester.pumpAndSettle();
    expect(find.byType(LocalFileBrowser), findsOneWidget);
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
  });

  testWidgets('Back at storage root exits and returns focus to the opener', (
    tester,
  ) async {
    await start(tester, 'pickWallpaperFolder', (_) {});
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('/storage'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LocalFileBrowser), findsNothing);
    expect(Focus.of(tester.element(find.text('Open'))).hasFocus, isTrue);
  });

  testWidgets(
    'Back restores a scrolled directory and its focus; close works during loading',
    (tester) async {
      many = true;
      await start(tester, 'pickWallpaperFolder', (_) {});
      await tester.scrollUntilVisible(
        find.text('Folder 35'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Folder 35'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text('Folder 35'))).hasFocus, isTrue);
      loading = Completer<void>();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.context, isNotNull);
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      loading!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LocalFileBrowser), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in ['ru', 'en', 'ar']) {
    testWidgets('browser controls fit a narrow panel with large text $locale', (
      tester,
    ) async {
      await start(
        tester,
        'saveBackupDocument',
        (_) {},
        locale: locale,
        scale: 1.8,
      );
      expect(tester.takeException(), isNull);
      final l = AppLocalizations.of(
        tester.element(find.byType(LocalFileBrowser)),
      )!;
      await tester.tap(find.byTooltip(l.close));
      await tester.pumpAndSettle();
    });
  }
  for (final operation in ['saveBackupDocument', 'saveDiagnosticsDocument']) {
    testWidgets(
      '$operation reports actual destination after a name collision',
      (tester) async {
        String? destination;
        Object? result;
        final expected = operation == 'saveBackupDocument' ? true : 'saved';
        localResult = {
          'result': expected,
          'path': '/storage/main/report-1.json',
        };
        await start(
          tester,
          operation,
          (value) => result = value,
          onSaved: (path) => destination = path,
        );
        await tester.tap(
          find.widgetWithText(FocusableSettingsTile, 'Сохранить'),
        );
        await tester.pumpAndSettle();
        expect(result, expected);
        expect(destination, '/storage/main/report-1.json');
      },
    );
  }
}
