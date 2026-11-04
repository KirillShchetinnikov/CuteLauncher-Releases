import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/settings/date_time_format_page.dart';
import 'package:flauncher/widgets/settings/custom_date_format_dialog.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting();
    await (FontLoader('Roboto')..addFont(
          File('test/design/fonts/DejaVuSans.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
  });
  Future<SettingsService> open(
    WidgetTester tester, {
    double scale = 1,
    Locale locale = const Locale('ru'),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Scaffold(body: DateTimeFormatPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return settings;
  }

  Future<void> editor(WidgetTester tester) async {
    final l = AppLocalizations.of(
      tester.element(find.byType(DateFormatSettingsTile)),
    )!;
    await tester.tap(find.text(l.date).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.customDateFormat));
    await tester.pumpAndSettle();
  }

  for (final onRight in [false, true]) {
    for (final close in ['save', 'cancel', 'back']) {
      testWidgets(
        'real settings hide for editor and return after $close; right=$onRight',
        (tester) async {
          tester.view.physicalSize = const Size(960, 540);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({
            'settings_menu_on_right': onRight,
          });
          final settings = SettingsService(
            await SharedPreferences.getInstance(),
          );
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: settings,
              child: MaterialApp(
                locale: const Locale('ru'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const SettingsPanel(
                  initialRoute: DateTimeFormatPage.routeName,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final original = settings.dateFormat;
          final navigator = tester.state<NavigatorState>(
            find.descendant(
              of: find.byType(SidePanelDialog),
              matching: find.byType(Navigator),
            ),
          );
          final page = tester.element(find.byType(DateFormatSettingsTile));
          await editor(tester);
          expect(find.byType(CustomDateFormatDialog), findsOneWidget);
          expect(find.byType(SidePanelDialog), findsNothing);
          expect(find.byType(LauncherPanelBackdrop), findsNothing);
          expect(
            find.byType(DateFormatSettingsTile, skipOffstage: false),
            findsOneWidget,
          );
          expect(
            FocusManager.instance.primaryFocus!.context!
                .findAncestorWidgetOfExactType<CustomDateFormatDialog>(),
            isNotNull,
          );
          await tester.enterText(find.byType(TextField), 'yyyy-MM-dd');
          await tester.pumpAndSettle();
          if (close == 'back') {
            await tester.binding.handlePopRoute();
          } else {
            final material = MaterialLocalizations.of(
              tester.element(find.byType(CustomDateFormatDialog)),
            );
            await tester.tap(
              find.widgetWithText(
                LauncherDialogButton,
                close == 'save'
                    ? material.okButtonLabel
                    : material.cancelButtonLabel,
              ),
            );
          }
          await tester.pumpAndSettle();
          expect(find.byType(CustomDateFormatDialog), findsNothing);
          expect(find.byType(SidePanelDialog), findsOneWidget);
          expect(
            tester.element(find.byType(DateFormatSettingsTile)),
            same(page),
          );
          expect(
            tester.state<NavigatorState>(
              find.descendant(
                of: find.byType(SidePanelDialog),
                matching: find.byType(Navigator),
              ),
            ),
            same(navigator),
          );
          expect(
            settings.dateFormat,
            close == 'save' ? 'yyyy-MM-dd' : original,
          );
          expect(
            FocusManager.instance.primaryFocus!.context!
                .findAncestorWidgetOfExactType<DateFormatSettingsTile>(),
            isNotNull,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'custom comes first, preview validates, save persists without changing time',
    (tester) async {
      final settings = await open(tester);
      final original = settings.dateFormat;
      final time = settings.timeFormat;
      await tester.tap(find.text('Дата').first);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Свой формат')).dy,
        lessThan(tester.getTopLeft(find.textContaining('ПТН').last).dy),
      );
      expect(settings.dateFormat, original);
      await tester.tap(find.text('Свой формат'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Обозначения времени'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'dd.mm.yyyy');
      await tester.pump();
      final save = find.widgetWithText(LauncherDialogButton, 'ОК');
      expect(tester.widget<LauncherDialogButton>(save).onPressed, isNull);
      final controller =
          tester.widget<TextField>(find.byType(TextField)).controller!
              as DatePatternEditingController;
      final spans = controller
          .buildTextSpan(
            context: tester.element(find.byType(TextField)),
            withComposing: false,
          )
          .children!
          .cast<TextSpan>()
          .toList();
      expect(spans[3].style!.decoration, TextDecoration.underline);
      await tester.enterText(find.byType(TextField), 'EEEE, d. MMMM yyyy');
      await tester.pump();
      expect(find.byKey(const ValueKey('custom-date-preview')), findsOneWidget);
      expect(
        tester
            .getBottomLeft(find.byKey(const ValueKey('custom-date-preview')))
            .dy,
        lessThan(tester.getTopLeft(find.byType(TextField)).dy),
      );
      final preview = tester.widget<Text>(
        find.byKey(const ValueKey('custom-date-preview')),
      );
      expect(preview.textSpan!.toPlainText(), startsWith('Предпросмотр: '));
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(settings.dateFormat, 'EEEE, d. MMMM yyyy');
      expect(settings.timeFormat, time);
      expect(
        SettingsService(await SharedPreferences.getInstance()).dateFormat,
        settings.dateFormat,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'cancel keeps settings; large text legend stays visible without scrolling',
    (tester) async {
      final settings = await open(tester, scale: 1.5);
      final original = settings.dateFormat;
      await editor(tester);
      await tester.enterText(find.byType(TextField), 'yyyy-MM-dd');
      await tester.pumpAndSettle();
      expect(find.byType(SettingsHelp), findsNothing);
      expect(find.textContaining('Обозначения времени'), findsOneWidget);
      final dialog = find.byType(CustomDateFormatDialog);
      expect(
        find.descendant(
          of: dialog,
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      final legend = tester.getRect(
        find.byKey(const ValueKey('custom-date-legend')),
      );
      expect(
        legend.bottom,
        lessThan(
          tester.view.physicalSize.height / tester.view.devicePixelRatio,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(settings.dateFormat, original);
      expect(tester.takeException(), isNull);
    },
  );
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('legend and preview fit 960x540 without scrolling: $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(960, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester, locale: locale, scale: 1.5);
      await editor(tester);
      final dialog = find.byType(CustomDateFormatDialog);
      expect(
        find.descendant(
          of: dialog,
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      final legend = tester.getRect(
        find.byKey(const ValueKey('custom-date-legend')),
      );
      expect(legend.top, greaterThanOrEqualTo(0));
      expect(legend.bottom, lessThanOrEqualTo(540));
      final buttons = find.descendant(
        of: dialog,
        matching: find.byType(LauncherDialogButton),
      );
      for (final element in buttons.evaluate()) {
        expect(
          tester.getRect(find.byWidget(element.widget)).bottom,
          lessThanOrEqualTo(540),
        );
      }
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'HH:mm');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
