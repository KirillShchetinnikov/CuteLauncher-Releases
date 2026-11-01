import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/local_file_browser.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_read_only_value.dart';

void main() {
  const channel = MethodChannel('me.efesser.flauncher/method');
  for (final locale in ['ru', 'en', 'ar']) {
    testWidgets(
      'file rows show size and one available date at large text $locale',
      (tester) async {
        final created = DateTime(2025, 2, 3, 10, 20);
        final modified = DateTime(2026, 4, 5, 12, 30);
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (_) async => {
            'path': '/storage',
            'uri': 'file:///storage',
            'parent': '',
            'folders': [],
            'files': [
              {
                'name': 'created.json',
                'path': '/storage/created.json',
                'size': 1536,
                'created': created.millisecondsSinceEpoch,
                'modified': modified.millisecondsSinceEpoch,
              },
              {
                'name': 'modified.json',
                'path': '/storage/modified.json',
                'size': 0,
                'created': 0,
                'modified': modified.millisecondsSinceEpoch,
              },
              {
                'name': 'unknown.json',
                'path': '/storage/unknown.json',
                'size': -1,
                'created': 0,
                'modified': 0,
              },
            ],
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const Scaffold(
              body: LocalFileBrowser(kind: FileBrowserKind.document),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(LocalFileBrowser)),
        )!;
        final size = '${NumberFormat('0.##', locale).format(1.5)} KiB';
        expect(
          find.text(
            '$size · ${l.date}: ${DateFormat.yMd(locale).add_Hm().format(created)}',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            '${NumberFormat('0.##', locale).format(0)} B · ${l.date}: ${DateFormat.yMd(locale).add_Hm().format(modified)}',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            '${l.memoryUnavailable} · ${l.date}: ${l.memoryUnavailable}',
          ),
          findsOneWidget,
        );
        Focus.of(tester.element(find.text('created.json'))).requestFocus();
        await tester.pumpAndSettle();
        final row = find.widgetWithText(FocusableSettingsTile, 'created.json');
        final height = tester.getSize(row).height;
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        expect(tester.getSize(row).height, height);
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.textContaining(size), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  Future<void> mount(WidgetTester tester, String path) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 380,
              height: 450,
              child: LocalFileBrowser(
                initialPath: path,
                saveName: 'report.json',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in ['ru', 'ar']) {
    testWidgets('Left only expands clipped names and rechecks width $locale', (
      tester,
    ) async {
      const short = 'Фото';
      const long = 'A folder with a fairly long name for a narrow panel';
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => {
          'path': '/storage',
          'uri': 'file:///storage',
          'parent': '',
          'folders': [
            {'name': short, 'path': '/storage/short'},
            {'name': long, 'path': '/storage/long'},
          ],
          'files': [],
        },
      );
      Widget browser(double width) => MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: 500,
              child: const LocalFileBrowser(initialPath: '/storage'),
            ),
          ),
        ),
      );
      await tester.pumpWidget(browser(240));
      await tester.pumpAndSettle();
      final shortRow = find.widgetWithText(FocusableSettingsTile, short);
      Focus.of(tester.element(find.text(short))).requestFocus();
      await tester.pumpAndSettle();
      final height = tester.getSize(shortRow).height;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(tester.getSize(shortRow).height, height);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(Focus.of(tester.element(find.text(short))).hasFocus, isTrue);

      Focus.of(tester.element(find.text(long))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.pumpWidget(browser(760));
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsNothing);
      final longRow = find.widgetWithText(FocusableSettingsTile, long);
      final fittedHeight = tester.getSize(longRow).height;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(tester.getSize(longRow).height, fittedHeight);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  testWidgets(
    'long path expands, scrolls to its end and collapses with remote',
    (tester) async {
      final path = '/storage/${List.filled(70, 'long-folder-name').join('/')}';
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => {
          'path': path,
          'parent': '/storage',
          'uri': 'file://$path',
          'folders': [],
          'files': [],
        },
      );
      await mount(tester, path);
      expect(find.byIcon(Icons.info_outline), findsNothing);
      final value = find.widgetWithText(SettingsReadOnlyValue, path);
      await tester.tap(value);
      await tester.pumpAndSettle();
      final positions = tester
          .stateList<ScrollableState>(
            find.descendant(of: value, matching: find.byType(Scrollable)),
          )
          .map((s) => s.position)
          .where((p) => p.maxScrollExtent > 0)
          .toList();
      expect(positions, isNotEmpty);
      for (
        var i = 0;
        i < 100 && positions.single.pixels < positions.single.maxScrollExtent;
        i++
      ) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      expect(positions.single.pixels, positions.single.maxScrollExtent);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: value,
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('revisiting a scrolled folder focuses a visible row', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      final path = (call.arguments as Map)['path'] as String;
      return {
        'path': path,
        'parent': path == '/storage' ? '' : '/storage',
        'uri': 'file://$path',
        'folders': path == '/storage'
            ? [
                {'name': 'Child', 'path': '/storage/Child'},
              ]
            : List.generate(
                80,
                (i) => {'name': 'Row $i', 'path': '$path/Row$i'},
              ),
        'files': [],
      };
    });
    await mount(tester, '/storage');
    await tester.tap(find.text('Child'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Row 35'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Child'));
    await tester.pumpAndSettle();
    final tile = FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<FocusableSettingsTile>();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).last)
        .position;
    expect(position.pixels, greaterThan(0));
    expect(tile, isNotNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'large directory uses lazy focus and confirmation shortcut returns to row',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => {
          'path': '/storage',
          'parent': '',
          'uri': 'file:///storage',
          'truncated': true,
          'folders': List.generate(
            1000,
            (i) => {'name': 'Folder $i', 'path': '/storage/$i'},
          ),
          'files': [],
        },
      );
      await mount(tester, '/storage');
      expect(
        find.text('Показана только часть содержимого папки'),
        findsOneWidget,
      );
      expect(
        find.byType(FocusableSettingsTile).evaluate().length,
        lessThan(30),
      );
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.arrow_upward),
            )
            .onPressed,
        isNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        Focus.of(tester.element(find.text('Сохранить').last)).hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text('Folder 0'))).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed folder identifies attempted path and disables confirmation',
    (tester) async {
      var fail = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (fail) throw PlatformException(code: 'document_failed');
        return {
          'path': '/storage',
          'parent': '',
          'uri': 'file:///storage',
          'folders': [
            {'name': 'Missing', 'path': '/storage/missing'},
          ],
          'files': [],
        };
      });
      await mount(tester, '/storage');
      fail = true;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('/storage/missing'), findsOneWidget);
      expect(
        tester
            .widget<FocusableSettingsTile>(
              find.widgetWithText(FocusableSettingsTile, 'Сохранить'),
            )
            .enabled,
        isFalse,
      );
      expect(find.byTooltip('Закрыть'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final locale in ['ru', 'en', 'ar']) {
    testWidgets(
      'reading path and export name preserves list space with large text $locale',
      (tester) async {
        final path = '/storage/${List.filled(20, 'long-name').join('/')}';
        final name = '${List.filled(10, 'long-name').join('_')}.json';
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (_) async => {
            'path': path,
            'parent': '/storage',
            'uri': 'file://$path',
            'folders': [],
            'files': [],
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.8)),
              child: child!,
            ),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 380,
                  height: 450,
                  child: LocalFileBrowser(initialPath: path, saveName: name),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(SettingsReadOnlyValue, path));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(SettingsReadOnlyValue, name));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(ListView)).height, greaterThan(20));
      },
    );
  }
}
