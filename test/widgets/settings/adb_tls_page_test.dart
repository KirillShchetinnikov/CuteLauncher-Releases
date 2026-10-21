import 'adb_test_compatibility.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/adb_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ADB offers TCP only, preserves its port and never starts pairing', (tester) async {
    const channel = MethodChannel('cutelauncher/adb');
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'info') return {'compatibility': supportedAdbCompatibility, 'tls': false, 'port': 5556};
      return {'status': 'ready'};
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(const MaterialApp(locale: Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: AdbPage(section: 'connection'))));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<bool>), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Порт ADB по TCP'), findsOneWidget);
    expect(find.text('TLS / код сопряжения'), findsNothing);
    await tester.ensureVisible(find.text('Проверить подключение'));
    await tester.tap(find.text('Проверить подключение'));
    await tester.pumpAndSettle();
    expect(calls.last.arguments, {'action': 'check', 'port': 5556, 'tls': false});
    expect(calls.map((call) => call.method), ['info', 'action']);
    expect(tester.takeException(), isNull);
  });
}
