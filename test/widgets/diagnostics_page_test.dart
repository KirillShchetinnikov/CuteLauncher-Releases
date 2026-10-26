import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/diagnostics_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in ['ru', 'en']) {
    testWidgets('sharing disclosure fits a small TV with large text $locale', (tester) async {
      tester.view.physicalSize = const Size(960, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: Scaffold(body: DiagnosticsPage(collect: () async => {'reportType': 'diagnostics'})),
      ));
      final l = AppLocalizations.of(tester.element(find.byType(DiagnosticsPage)))!;
      await tester.tap(find.text(l.diagnosticsCreate));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l.diagnosticsExport));
      await tester.tap(find.text(l.diagnosticsExport));
      await tester.pumpAndSettle();
      expect(find.text(l.diagnosticsSharingNotice), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text(l.diagnosticsSharingNotice), findsNothing);
    });
  }
  for (final outcome in ['saved', 'opened', 'cancelled', 'failed']) {
    testWidgets(
      'unified report export uses file picker and cleans temporary file: $outcome',
      (tester) async {
        final directory = await tester.runAsync(
          () => Directory.systemTemp.createTemp('diagnostics-test-'),
        );
        final messenger = tester.binding.defaultBinaryMessenger;
        const documents = MethodChannel('me.efesser.flauncher/method');
        const paths = MethodChannel('plugins.flutter.io/path_provider');
        String? source;
        late Completer<void> pickerOpened;
        late Completer<void> pickerResult;
        addTearDown(() async {
          messenger.setMockMethodCallHandler(documents, null);
          messenger.setMockMethodCallHandler(paths, null);
          await tester.runAsync(() => directory!.delete(recursive: true));
        });
        messenger.setMockMethodCallHandler(paths, (_) async => directory!.path);
        messenger.setMockMethodCallHandler(documents, (call) async {
          expect(call.method, 'saveDiagnosticsDocument');
          source = call.arguments['path'] as String;
          expect(
            call.arguments['name'],
            startsWith('cutelauncher_diagnostics_'),
          );
          expect(jsonDecode(File(source!).readAsStringSync()), {
            'operationCounts': {'success': 2},
          });
          pickerOpened.complete();
          await pickerResult.future;
          if (outcome == 'failed') {
            throw PlatformException(code: 'document_unavailable');
          }
          return outcome == 'cancelled' ? null : outcome;
        });
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DiagnosticsPage(
                collect: () async => {
                  'operationCounts': {'success': 2},
                },
              ),
            ),
          ),
        );
        await tester.tap(find.text('Создать отчёт'));
        await tester.pumpAndSettle();
        final exportTile = tester.widget<FocusableSettingsTile>(
          find.ancestor(
            of: find.text('Экспортировать отчёт'),
            matching: find.byType(FocusableSettingsTile),
          ),
        );
        late Future<void> export;
        await tester.runAsync(() async {
          export = (exportTile.onPressed! as Future<void> Function())();
        });
        await tester.pumpAndSettle();
        final saveTile = tester.widget<FocusableSettingsTile>(
          find.ancestor(
            of: find.text('Сохранить на диск'),
            matching: find.byType(FocusableSettingsTile),
          ),
        );
        await tester.runAsync(() async {
          // Await the actual page action, including cleanup and its notice.
          // A deleted file alone does not mean that its Future has completed.
          pickerOpened = Completer<void>();
          pickerResult = Completer<void>();
          final saving = (saveTile.onPressed! as Future<void> Function())();
          await pickerOpened.future.timeout(const Duration(seconds: 5));
          try {
            expect(await File(source!).exists(), isTrue);
          } finally {
            pickerResult.complete();
            await saving;
            await export;
          }
          expect(await File(source!).parent.exists(), isFalse);
        });
        await tester.pumpAndSettle();
        expect(find.text('Диагностика'), findsOneWidget);
        expect(
          find.text('Отчёт сохранён'),
          outcome == 'saved' ? findsOneWidget : findsNothing,
        );
        expect(
          find.textContaining('Не удалось сохранить отчёт.'),
          outcome == 'failed' ? findsOneWidget : findsNothing,
        );
        expect(
          find.textContaining(
            'Выберите папку в открывшемся файловом менеджере',
          ),
          outcome == 'opened' ? findsOneWidget : findsNothing,
        );
      },
    );
  }
  testWidgets(
    'report copies only after explicit action and clear removes preview',
    (tester) async {
      const diagnostics = MethodChannel('me.efesser.flauncher/method');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        diagnostics,
        (call) async =>
            call.method == 'clearNativeShellDiagnostics' ? true : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          diagnostics,
          null,
        ),
      );
      var copied = false;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = true;
        return null;
      });
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DiagnosticsPage(
              collect: () async => {
                'operationCounts': {'success': 2},
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Создать отчёт'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Отчёт готов'), findsOneWidget);
      expect(copied, false);
      await tester.tap(find.text('Экспортировать отчёт'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Копировать в буфер обмена'));
      await tester.pumpAndSettle();
      expect(copied, true);
      await tester.ensureVisible(find.text('Очистить отчёт'));
      await tester.tap(find.text('Очистить отчёт'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Отчёт готов'), findsNothing);
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    },
  );
}
