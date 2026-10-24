import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/widgets/settings/panel_order_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final remote in [false, true]) {
    testWidgets('panel group headings keep Manrope line headroom: remote=$remote', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appearance = AppearanceService(prefs);
      final panel = RemotePanelService(prefs);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appearance),
          ChangeNotifierProvider.value(value: panel),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: DefaultTextStyle(
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 16, height: 1.3),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false, applyHeightToLastDescent: false,
            ),
            child: PanelOrderPage(remotePanel: remote),
          )),
        ),
      ));
      await tester.pumpAndSettle();
      for (final heading in ['Слева', 'Справа']) {
        expect(tester.getSize(find.text(heading)).height, greaterThanOrEqualTo(24));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
      panel.dispose();
    });
  }
}
