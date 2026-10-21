import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/flauncher_about_dialog.dart';

void main() {
  for (final language in ['ru', 'en']) {
    testWidgets('Repository QR opens and closes with remote in $language', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => CuteLauncherAboutDialog(
                        packageInfo: PackageInfo(
                          appName: 'CuteLauncher',
                          packageName: 'test.launcher',
                          version: '1.0.0',
                          buildNumber: '1',
                        ),
                      ),
                    ),
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(CuteLauncherAboutDialog)),
      )!;
      expect(find.text(l.showRepositoryQrCode), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(find.text(CuteLauncherAboutDialog.repositoryUrl), findsOneWidget);
      expect(qr.backgroundColor, Colors.white);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsNothing);
      expect(find.byType(CuteLauncherAboutDialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsNothing);
      expect(find.byType(CuteLauncherAboutDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
