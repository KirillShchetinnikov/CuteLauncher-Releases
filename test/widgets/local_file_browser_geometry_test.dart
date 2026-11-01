import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/local_file_browser.dart';
import 'package:flauncher/widgets/settings/settings_menu_layout.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';

void main() {
  for (final right in [false, true]) {
    testWidgets('browser geometry right=$right', (tester) async {
      const channel = MethodChannel('me.efesser.flauncher/method');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => {
          'path': '/storage/emulated/0/Download',
          'parent': '/storage/emulated/0',
          'uri': 'file:///storage/emulated/0/Download',
          'folders': [
            {'name': 'Folder', 'path': '/storage/emulated/0/Download/Folder'},
          ],
          'files': [],
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                height: 540,
                child: SettingsMenuLayout(
                  onRight: right,
                  child: const LocalFileBrowser(saveName: 'report.json'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final save = tester.getRect(
        find.widgetWithText(FocusableSettingsTile, 'Сохранить'),
      );
      final row = tester.getRect(
        find.widgetWithText(FocusableSettingsTile, 'Folder'),
      );
      expect(save.width, row.width);
      expect(save.height, lessThan(row.height));
      expect(tester.getSize(find.byType(ListView)).height, greaterThan(330));
      expect(save.left - row.left, 0);
      expect(tester.takeException(), isNull);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });
  }
}
