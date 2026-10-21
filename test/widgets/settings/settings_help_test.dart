import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';
import 'package:flauncher/widgets/settings/settings_page_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final longText = List.generate(60, (i) => 'Строка пояснения $i').join('\n');

  Future<void> mount(WidgetTester tester, {String? text}) async {
    tester.view.physicalSize = const Size(350, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SettingsPageLayout(
            title: const Text('Настройки'),
            child: ListView(
              children: [
                FocusableSettingsTile(
                  title: const Text('До'),
                  onPressed: () {},
                ),
                SettingsHelp(text: text ?? longText),
                FocusableSettingsTile(
                  title: const Text('После'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> key(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }

  testWidgets('help starts collapsed, shows info, and toggles with remote OK', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text(longText), findsNothing);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(Focus.of(tester.element(find.text('Подробнее'))).hasFocus, isTrue);
    await key(tester, LogicalKeyboardKey.enter);
    expect(find.text(longText), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    await key(tester, LogicalKeyboardKey.enter);
    expect(find.text(longText), findsNothing);
    expect(Focus.of(tester.element(find.text('Подробнее'))).hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'D-pad scrolls both ways, repeats, and exits at the text boundaries',
    (tester) async {
      await mount(tester);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.enter);
      await key(tester, LogicalKeyboardKey.arrowDown);
      final text = find.text(longText);
      final textFocus = FocusManager.instance.primaryFocus!;
      final scrollable = find.descendant(
        of: find.byType(SettingsHelp),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.pixels, 0);
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(position.pixels, greaterThan(0));
      final down = position.pixels;
      await key(tester, LogicalKeyboardKey.arrowUp);
      expect(position.pixels, lessThan(down));
      expect(textFocus.hasFocus, isTrue);
      await key(tester, LogicalKeyboardKey.arrowUp);
      expect(Focus.of(tester.element(find.text('Подробнее'))).hasFocus, isTrue);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      for (var i = 0; i < 45; i++) {
        await key(tester, LogicalKeyboardKey.arrowDown);
        if (Focus.of(tester.element(find.text('После'))).hasFocus) break;
      }
      expect(position.pixels, position.maxScrollExtent);
      expect(Focus.of(tester.element(find.text('После'))).hasFocus, isTrue);
      expect(text, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('short help has no focus trap and disposes while expanded', (
    tester,
  ) async {
    await mount(tester, text: 'Короткая подсказка');
    await key(tester, LogicalKeyboardKey.arrowDown);
    await key(tester, LogicalKeyboardKey.enter);
    await key(tester, LogicalKeyboardKey.arrowDown);
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(Focus.of(tester.element(find.text('После'))).hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('large RTL help stays bounded and readable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 400),
            textScaler: TextScaler.linear(1.8),
          ),
          child: Scaffold(
            body: SizedBox(
              width: 320,
              height: 400,
              child: SettingsPageLayout(
                title: const Text('إعدادات'),
                child: ListView(children: [SettingsHelp(text: longText)]),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await key(tester, LogicalKeyboardKey.enter);
    await key(tester, LogicalKeyboardKey.arrowDown);
    await key(tester, LogicalKeyboardKey.arrowDown);
    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(SettingsHelp),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    expect(position.pixels, greaterThan(0));
    expect(
      Directionality.of(tester.element(find.text(longText))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
