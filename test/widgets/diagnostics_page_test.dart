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
    testWidgets('sharing disclosure fits a small TV with large text $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(960, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Scaffold(
            body: DiagnosticsPage(
              collect: () async => {'reportType': 'diagnostics'},
            ),
          ),
        ),
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(DiagnosticsPage)),
      )!;
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
  for (final outcome in ['saved', 'cancelled', 'failed']) {
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
          if (call.method == 'filePickerAvailable') return true;
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
            throw PlatformException(code: 'document_failed');
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
        var exportFinished = false;
        await tester.runAsync(() async {
          (exportTile.onPressed! as Future<void> Function())().then(
            (_) => exportFinished = true,
          );
        });
        await tester.pumpAndSettle();
        final saveTile = tester.widget<FocusableSettingsTile>(
          find.ancestor(
            of: find.text('Сохранить на диск'),
            matching: find.byType(FocusableSettingsTile),
          ),
        );
        pickerOpened = Completer<void>();
        pickerResult = Completer<void>();
        late Future<void> saving;
        await tester.runAsync(() async {
          saving = (saveTile.onPressed! as Future<void> Function())();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        await tester.tap(find.text('Системный проводник'));
        await tester.pumpAndSettle();
        for (
          var attempt = 0;
          attempt < 20 && !pickerOpened.isCompleted;
          attempt++
        ) {
          await tester.pump();
          await tester.runAsync(
            () async => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        expect(pickerOpened.isCompleted, isTrue);
        expect(await tester.runAsync(() => File(source!).exists()), isTrue);
        var finished = false;
        saving.then((_) => finished = true);
        pickerResult.complete();
        for (var attempt = 0; attempt < 20 && !finished; attempt++) {
          await tester.pump();
          await tester.runAsync(
            () async => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        await tester.pumpAndSettle();
        expect(finished, isTrue);
        expect(exportFinished, isTrue);
        expect(
          await tester.runAsync(() => File(source!).parent.exists()),
          isFalse,
        );
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
      await tester.ensureVisible(find.text('Копировать в буфер обмена'));
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
