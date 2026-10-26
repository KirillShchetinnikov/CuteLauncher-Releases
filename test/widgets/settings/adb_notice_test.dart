import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/settings/adb_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in ['ru', 'en']) {
    testWidgets(
      'owned Wi-Fi instruction stays open and closes by remote ($locale)',
      (tester) async {
        late BuildContext page;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                page = context;
                return Scaffold(
                  body: TextButton(
                    onPressed: () => showAdbNotice(context, 'wifiOwned'),
                    child: const Text('Run'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.tap(find.text('Run'));
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(page)!;
        expect(find.byType(LauncherAlertDialog), findsOneWidget);
        expect(find.text(l.adbWifiOwned), findsOneWidget);
        expect(l.adbWifiOwned, contains('1.'));
        expect(l.adbWifiOwned, contains('4.'));
        await tester.pump(const Duration(seconds: 20));
        expect(find.byType(LauncherAlertDialog), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(LauncherAlertDialog), findsNothing);
        showAdbNotice(page, 'wifiUnknown');
        await tester.pump();
        expect(find.byType(LauncherAlertDialog), findsNothing);
        expect(find.text(l.adbWifiUnknown), findsOneWidget);
        await tester.pump(const Duration(seconds: 6));
      },
    );
  }
}
