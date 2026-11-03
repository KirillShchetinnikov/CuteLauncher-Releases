import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/diagnostics_page.dart';
import 'package:flauncher/widgets/settings/file_storage_results_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('me.efesser.flauncher/method');

void main() {
  Future<void> open(WidgetTester tester, {String locale = 'ru'}) async {
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
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(width: 420, child: child!),
          ),
        ),
        home: const Scaffold(body: DiagnosticsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  for (final locale in ['ru', 'en', 'ar']) {
    testWidgets('on-screen diagnostics needs no report or file access $locale', (
      tester,
    ) async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
            calls.add(call.method);
            if (call.method == 'getFileStorageDiagnostics') {
              return 'allFilesAccess=false\n${List.filled(30, 'com.tcl.guard/.permissionshield.main.activity.PermissionShieldActivity enabled=true').join('\n')}';
            }
            throw PlatformException(code: 'forbidden');
          });
      await open(tester, locale: locale);
      final l = AppLocalizations.of(
        tester.element(find.byType(DiagnosticsPage)),
      )!;
      await tester.ensureVisible(find.text(l.fileStorageDiagnostics));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.fileStorageDiagnostics));
      await tester.pumpAndSettle();
      expect(find.byType(FileStorageResultsPage), findsOneWidget);
      expect(calls, ['getFileStorageDiagnostics']);
      final scroll = tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey('file_storage_results_scroll')),
          )
          .controller!;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(0));
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(FileStorageResultsPage), findsNothing);
    });
  }

  testWidgets(
    'repeated activation is ignored while collecting, failure allows retry',
    (tester) async {
      final pending = Completer<String>();
      var count = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
            if (call.method != 'getFileStorageDiagnostics') return null;
            count++;
            return count == 1 ? pending.future : 'allFilesAccess=false';
          });
      await open(tester);
      final l = AppLocalizations.of(
        tester.element(find.byType(DiagnosticsPage)),
      )!;
      final button = find.text(l.fileStorageDiagnostics);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      expect(count, 1);
      pending.completeError(PlatformException(code: 'denied'));
      await tester.pumpAndSettle();
      expect(find.byType(FileStorageResultsPage), findsNothing);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(count, 2);
      expect(find.byType(FileStorageResultsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('closing diagnostics drops late results', (tester) async {
    final pending = Completer<String>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async => pending.future);
    await open(tester);
    final l = AppLocalizations.of(
      tester.element(find.byType(DiagnosticsPage)),
    )!;
    await tester.ensureVisible(find.text(l.fileStorageDiagnostics));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.fileStorageDiagnostics));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    pending.complete('late');
    await tester.pumpAndSettle();
    expect(find.byType(FileStorageResultsPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
