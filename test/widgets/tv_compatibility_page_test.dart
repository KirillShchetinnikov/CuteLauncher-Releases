import 'package:flauncher/diagnostics_store.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/tv_compatibility_report.dart';
import 'package:flauncher/widgets/settings/diagnostics_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_menu_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object> observations() => createTvCompatibilityReport(
  {
    'identity': {
      'manufacturer': 'TCL',
      'model': 'Smart TV Pro',
      'device': 'G10',
      'fingerprint': 'TCL/G10/G10:14/build/AU01:user/release-keys',
      'android': '14',
      'sdk': '34',
      'abis': 'armeabi-v7a',
    },
    'kind': 'physical',
    'checks': {'overlay': 'notGranted', 'androidTv': 'available'},
  },
  capturedAt: DateTime.utc(2026, 10, 21),
  version: '1.0.24',
  build: '73',
);

Map<String, Object> report() => combineDiagnosticsReport(
  DiagnosticsStore().snapshot(version: '1.0.24', build: '73'),
  observations(),
  capturedAt: DateTime.utc(2026, 10, 21),
);

void main() {
  for (final locale in ['ru', 'en']) {
    for (final onRight in [false, true]) {
      testWidgets(
        '$locale side=$onRight one report contains errors and compatibility and exports without rerunning',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 720);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var runs = 0;
          String? clipboard;
          final pending = Completer<Map<String, Object>>();
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async {
              if (call.method == 'Clipboard.setData') {
                clipboard = call.arguments['text'] as String;
              }
              return null;
            },
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(SystemChannels.platform, null),
          );
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: SettingsMenuLayout(
                onRight: onRight,
                child: Scaffold(
                  body: DiagnosticsPage(
                    collect: () {
                      runs++;
                      return pending.future;
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final l = AppLocalizations.of(
            tester.element(find.byType(DiagnosticsPage)),
          )!;
          FocusableSettingsTile tile(String title) => tester.widget(
            find
                .ancestor(
                  of: find.text(title),
                  matching: find.byType(FocusableSettingsTile),
                )
                .first,
          );
          expect(find.text(l.diagnosticsHubTitle), findsOneWidget);
          expect(find.text(l.tvCompatibilityTitle), findsNothing);
          expect(find.text(l.diagnosticsTitle), findsNothing);
          expect(runs, 0);
          expect(tile(l.tvCompatibilityResults).onPressed, isNull);
          expect(tile(l.diagnosticsExport).onPressed, isNull);
          expect(find.text(l.tvCompatibilityHelp), findsNothing);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(runs, 1);
          expect(tile(l.diagnosticsExport).onPressed, isNull);
          pending.complete(report());
          await tester.pumpAndSettle();
          await tester.tap(find.text(l.tvCompatibilityResults));
          await tester.pumpAndSettle();
          expect(find.byType(CompatibilityResultsPage), findsOneWidget);
          expect(find.textContaining('TCL Smart TV Pro'), findsOneWidget);
          expect(find.textContaining(l.compatibilityNotGranted), findsWidgets);
          final scroll = tester
              .widget<SingleChildScrollView>(
                find.byKey(const ValueKey('compatibility_results_scroll')),
              )
              .controller!;
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          expect(scroll.offset, greaterThan(0));
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await tester.tap(find.text(l.diagnosticsExport));
          await tester.pumpAndSettle();
          expect(clipboard, isNull);
          expect(find.text(l.diagnosticsSharingNotice), findsOneWidget);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(clipboard, isNull);
          await tester.tap(find.text(l.diagnosticsExport));
          await tester.pumpAndSettle();
          await tester.tap(find.text(l.diagnosticsCopyClipboard));
          await tester.pumpAndSettle();
          expect(jsonDecode(clipboard!)['reportType'], 'diagnostics');
          expect(find.text(l.diagnosticsSharingNotice), findsNothing);
          expect(runs, 1);
          await tester.tap(find.text(l.diagnosticsClear));
          await tester.pumpAndSettle();
          expect(tile(l.diagnosticsExport).onPressed, isNull);
          expect(tile(l.tvCompatibilityResults).onPressed, isNull);
          expect(runs, 1);
          await tester.ensureVisible(find.text(l.settingsHelp));
          await tester.tap(find.text(l.settingsHelp));
          await tester.pumpAndSettle();
          expect(find.textContaining(l.diagnosticsHint), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
  testWidgets(
    'failed recheck preserves the preceding report; leaving during a check is safe',
    (tester) async {
      var calls = 0;
      final pending = Completer<Map<String, Object>>();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DiagnosticsPage(
              collect: () {
                calls++;
                if (calls == 1) return Future.value(report());
                if (calls == 2) return Future.error(StateError('not exported'));
                return pending.future;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create report'));
      await tester.pumpAndSettle();
      expect(find.text('Report ready'), findsOneWidget);
      await tester.tap(find.text('Create report'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete(report());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
