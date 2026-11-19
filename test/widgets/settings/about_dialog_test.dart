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
import 'package:flauncher/widgets/launcher_dialog.dart';

void main() {
  for (final language in ['ru', 'en']) {
    for (final layout in [
      (const Size(960, 540), 1.0),
      (const Size(800, 450), 1.0),
      (const Size(960, 540), 1.5),
      (const Size(640, 360), 2.0),
    ]) {
      testWidgets('About layout ${layout.$1} at ${layout.$2} in $language', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(layout.$1);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(layout.$2)),
              child: child!,
            ),
            home: Scaffold(
              body: LauncherDialogArea(
                settingsOpen: true,
                onRight: false,
                child: CuteLauncherAboutDialog(
                  packageInfo: PackageInfo(
                    appName: 'CuteLauncher',
                    packageName: 'com.leanbitlab.cutelauncher.debug',
                    version: '1.4.0',
                    buildNumber: '100',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
        final compact = layout.$1.height < 450;
        final fitsWithoutScroll = layout.$1.height >= 540 && layout.$2 == 1;
        expect(scroll.position.maxScrollExtent, fitsWithoutScroll ? 0 : greaterThan(0));
        final l = AppLocalizations.of(
          tester.element(find.byType(CuteLauncherAboutDialog)),
        )!;
        for (final text in [
          if (!compact) l.discussionQrCode,
          if (!compact) l.showRepositoryQrCode,
          l.close,
        ]) {
          await tester.ensureVisible(find.text(text));
          await tester.pumpAndSettle();
          final rect = tester.getRect(find.text(text));
          expect(rect.top, greaterThanOrEqualTo(20));
          expect(rect.bottom, lessThanOrEqualTo(layout.$1.height - 20));
        }
        expect(Focus.of(tester.element(find.text(l.close))).hasFocus, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final language in ['ru', 'en']) {
    testWidgets('About QR destinations open and close with remote in $language', (
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
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.textContaining('v1.0.0+1'), findsNothing);
      expect(find.text(l.launcherRepository), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      for (final (label, url) in [
        (l.discussionQrCode, 'https://4pda.to/forum/index.php?showtopic=1128313'),
        (l.showRepositoryQrCode, 'https://github.com/KirillShchetinnikov/CuteLauncher-Releases'),
      ]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(Focus.of(tester.element(find.text(label))).hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        final qr = tester.widget<QrImageView>(find.byType(QrImageView));
        expect(find.text(url), findsOneWidget);
        expect(qr.backgroundColor, Colors.white);
        expect(qr.eyeStyle.eyeShape, QrEyeShape.circle);
        expect(qr.dataModuleStyle.dataModuleShape, QrDataModuleShape.circle);
        final closeQr = find.descendant(
          of: find.byType(LauncherAlertDialog), matching: find.text(l.close),
        );
        expect(Focus.of(tester.element(closeQr)).hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(QrImageView), findsNothing);
        expect(Focus.of(tester.element(find.text(label))).hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(QrImageView), findsNothing);
        expect(Focus.of(tester.element(find.text(label))).hasFocus, isTrue);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
