import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/general_settings_page.dart';
import 'package:flauncher/widgets/settings/settings_panel_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final locale in ['ru', 'en']) {
    for (final scale in [1.0, 1.7]) {
      testWidgets(
        'file manager choice saves and restores focus ($locale, $scale)',
        (tester) async {
          tester.view.physicalSize = const Size(960, 540);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({});
          final preferences = await SharedPreferences.getInstance();
          final settings = SettingsService(preferences);
          final appearance = AppearanceService(preferences);
          addTearDown(settings.dispose);
          addTearDown(appearance.dispose);
          const channel = MethodChannel('me.efesser.flauncher/method');
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            (_) async => {
              'automatic': false,
              'enabled': false,
              'active': false,
            },
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(channel, null),
          );
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: settings),
                ChangeNotifierProvider.value(value: appearance),
              ],
              child: MaterialApp(
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox(
                      width: 400,
                      child: SettingsPanelStyle(
                        builder: (_) => const GeneralSettingsPage(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final l = AppLocalizations.of(
            tester.element(find.byType(GeneralSettingsPage)),
          )!;
          final title = find.text(l.fileManagerPreference);
          await tester.ensureVisible(title);
          await tester.pumpAndSettle();
          expect(find.text(l.fileManagerAsk), findsOneWidget);
          await tester.tap(title);
          await tester.pumpAndSettle();
          expect(find.text(l.fileManagerBuiltIn), findsOneWidget);
          expect(find.text(l.fileManagerExternal), findsOneWidget);
          await tester.tap(find.text(l.fileManagerExternal));
          await tester.pumpAndSettle();
          expect(
            settings.fileManagerPreference,
            FileManagerPreference.external,
          );
          expect(preferences.getString('file_manager_preference'), 'external');
          expect(Focus.of(tester.element(title)).hasFocus, isTrue);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            settings.fileManagerPreference,
            FileManagerPreference.external,
          );
          expect(Focus.of(tester.element(title)).hasFocus, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
