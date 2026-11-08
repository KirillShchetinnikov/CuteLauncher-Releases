import 'package:flauncher/file_browser_options.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/file_browser_settings_page.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';
import 'package:flauncher/widgets/settings/settings_panel_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final locale in ['ru', 'en', 'ar']) {
    testWidgets(
      'browser settings save with large text and remote Back: $locale',
      (tester) async {
        tester.view.physicalSize = const Size(960, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final settings = SettingsService(prefs);
        final appearance = AppearanceService(prefs);
        addTearDown(settings.dispose);
        addTearDown(appearance.dispose);
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
                    .copyWith(textScaler: const TextScaler.linear(1.7)),
                child: child!,
              ),
              home: Scaffold(
                body: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    width: 400,
                    child: SettingsPanelStyle(
                      builder: (_) => const FileBrowserSettingsPage(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(FileBrowserSettingsPage)),
        )!;
        expect(find.text(l.fileBrowserLastFolder), findsOneWidget);
        Future<void> choose(String title, String value) async {
          await tester.scrollUntilVisible(find.text(title).last, 120);
          await tester.pumpAndSettle();
          await tester.tap(find.text(title).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text(value));
          await tester.pumpAndSettle();
        }

        await choose(l.fileBrowserStartFolder, l.fileBrowserDownloads);
        await choose(l.fileBrowserSort, l.fileBrowserSortSize);
        await choose(l.fileBrowserOrder, l.fileBrowserDescending);
        for (final title in [
          l.fileBrowserFoldersFirst,
          l.fileBrowserShowHidden,
          l.fileBrowserShowDetails,
        ]) {
          await tester.scrollUntilVisible(find.text(title).last, 120);
          await tester.pumpAndSettle();
          await tester.tap(find.text(title).last);
          await tester.pumpAndSettle();
        }
        const expected = FileBrowserOptions(
          start: FileBrowserStart.downloads,
          sort: FileBrowserSort.size,
          descending: true,
          foldersFirst: false,
          showHidden: true,
          showDetails: false,
        );
        expect(settings.fileBrowserOptions, expected);
        await tester.scrollUntilVisible(find.byType(SettingsHelp), 120);
        await tester.pumpAndSettle();
        expect(find.byType(SettingsHelp), findsOneWidget);
        expect(find.text(l.fileBrowserOptionsHelp), findsNothing);
        await tester.scrollUntilVisible(find.text(l.fileBrowserOrder), -120);
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.fileBrowserOrder));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(settings.fileBrowserOptions, expected);
        final reloaded = SettingsService(prefs);
        expect(reloaded.fileBrowserOptions, expected);
        reloaded.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
