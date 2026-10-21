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
  for (final compatibility in [false, true]) {
    for (final outcome in ['saved', 'opened', 'cancelled', 'failed']) {
      testWidgets(
        'report export compatibility=$compatibility uses file picker and cleans temporary file: $outcome',
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
          messenger.setMockMethodCallHandler(
            paths,
            (_) async => directory!.path,
          );
          messenger.setMockMethodCallHandler(documents, (call) async {
            expect(call.method, 'saveDiagnosticsDocument');
            source = call.arguments['path'] as String;
            expect(
              call.arguments['name'],
              startsWith(
                'cutelauncher_${compatibility ? 'compatibility' : 'errors'}_',
              ),
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
                  section: compatibility ? 'compatibility' : 'errors',
                  collectCompatibility: () async => {
                    'operationCounts': {'success': 2},
                  },
                  collect: () async => {
                    'operationCounts': {'success': 2},
                  },
                ),
              ),
            ),
          );
          await tester.tap(
            find.text(compatibility ? 'Запустить проверку' : 'Создать отчёт'),
          );
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
          expect(
            find.text(
              compatibility
                  ? 'Проверка TV на совместимость'
                  : 'Диагностика ошибок',
            ),
            findsOneWidget,
          );
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
  }
  testWidgets(
    'report copies only after explicit action and clear removes preview',
    (tester) async {
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
              section: 'errors',
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
