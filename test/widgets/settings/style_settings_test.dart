import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/action_notice.dart';
import 'package:flauncher/widgets/notice_style.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/settings_style_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final onRight in [false, true]) {
    testWidgets(
      'style preview uses popup corner and closes on exit ($onRight)',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final appearance = AppearanceService(prefs);
        final settings = SettingsService(prefs);
        await settings.setSettingsMenuOnRight(onRight);
        addTearDown(appearance.dispose);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: appearance),
              ChangeNotifierProvider.value(value: settings),
            ],
            child: MaterialApp(
              locale: const Locale('ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (_, child) => ActionNoticeHost(child: child!),
              home: const SettingsPanel(initialRoute: 'appearance_settings'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Стиль уведомлений'));
        await tester.pumpAndSettle();
        final page = find.byType(SettingsStylePage);
        final l = AppLocalizations.of(tester.element(page))!;
        final preview = find.text(l.noticeStylePreview);
        expect(preview, findsOneWidget);
        expect(find.descendant(of: page, matching: preview), findsNothing);
        final card = find.ancestor(
          of: preview,
          matching: find.byType(NoticeSurface),
        );
        expect(tester.getBottomLeft(card).dy, 1056);
        if (onRight) {
          expect(tester.getBottomLeft(card).dx, 24);
        } else {
          expect(tester.getBottomRight(card).dx, 1896);
        }
        final focus = FocusManager.instance.primaryFocus;
        await appearance.set('noticeTextSize', 22);
        await tester.pumpAndSettle();
        expect(preview, findsOneWidget);
        expect(tester.widget<Text>(preview).style!.fontSize, 22);
        expect(FocusManager.instance.primaryFocus, same(focus));
        await tester.pump(const Duration(minutes: 1));
        expect(preview, findsOneWidget);
        await appearance.set('noticeWidth', 400);
        await tester.pumpAndSettle();
        expect(preview, findsOneWidget);
        final navigator = Navigator.of(tester.element(page));
        navigator.pop();
        await tester.pumpAndSettle();
        expect(preview, findsNothing);
        navigator.pushNamed(SettingsStylePage.notificationsRouteName);
        await tester.pumpAndSettle();
        expect(preview, findsOneWidget);
        navigator.pop();
        await tester.pumpAndSettle();
        expect(preview, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Flutter and Android notices share opaque default and live custom style',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(
        await SharedPreferences.getInstance(),
      );
      addTearDown(appearance.dispose);
      final payloads = <Map<dynamic, dynamic>>[];
      const channel = MethodChannel('me.efesser.flauncher/method');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'setNotificationPopupPresentation') {
          payloads.add(call.arguments as Map);
        }
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      late BuildContext hostContext;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appearance,
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.dark(surface: Colors.transparent),
            ),
            builder: (_, child) => ActionNoticeHost(child: child!),
            home: Builder(
              builder: (context) {
                hostContext = context;
                return const Scaffold();
              },
            ),
          ),
        ),
      );
      showActionNotice(hostContext, 'Sample');
      await tester.pumpAndSettle();
      expect(payloads.last['background'], 0xff000000);
      await appearance.set('noticeColor', 0xff14532d);
      await appearance.set('noticeOpacity', .4);
      await appearance.set('noticeTextColor', 0xffffd54f);
      await appearance.set('noticeTextSize', 22);
      await appearance.set('noticeWidth', 500);
      await tester.pumpAndSettle();
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(NoticeSurface),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, const Color(0xff14532d).withValues(alpha: .4));
      expect(payloads.last['background'], material.color!.toARGB32());
      expect(payloads.last['foreground'], 0xffffd54f);
      expect(payloads.last['textSize'], 22);
      expect(payloads.last['width'], 500);
      expect(tester.widget<Text>(find.text('Sample')).style!.fontSize, 22);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Sample'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'settings theme updates live and confirmed reset leaves notice and tile settings intact',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appearance = AppearanceService(prefs);
      final settings = SettingsService(prefs);
      addTearDown(appearance.dispose);
      addTearDown(settings.dispose);
      await appearance.set('settingsColor', 0xff14532d);
      await appearance.set('settingsOpacity', .5);
      await appearance.set('settingsTextColor', 0xffffd54f);
      await appearance.set('settingsTextSize', 24);
      await appearance.set('noticeOpacity', .7);
      await appearance.set('horizontalGap', 0);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appearance),
            ChangeNotifierProvider.value(value: settings),
          ],
          child: const MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsPanel(initialRoute: 'appearance_settings'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final element = tester.element(find.text('Стиль настроек'));
      expect(
        Theme.of(element).colorScheme.surface,
        const Color(0xff14532d).withValues(alpha: .5),
      );
      expect(Theme.of(element).colorScheme.onSurface, const Color(0xffffd54f));
      expect(MediaQuery.textScalerOf(element).scale(16), 24);
      await tester.tap(find.text('Стиль настроек'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Сбросить настройки этого раздела'));
      await tester.tap(find.text('Сбросить настройки этого раздела'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(appearance.appearance.number('settingsOpacity'), .5);
      await tester.tap(find.text('Сбросить настройки этого раздела'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сбросить настройки этого раздела').last);
      await tester.pumpAndSettle();
      expect(appearance.appearance.number('settingsOpacity'), isNull);
      expect(appearance.appearance.number('settingsTextSize'), isNull);
      expect(appearance.appearance.number('noticeOpacity'), .7);
      expect(appearance.appearance.horizontalGap, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
