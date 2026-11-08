// Capture production Flutter screens, including the real app theme and fonts.
// flutter test test/information_design_capture_test.dart --dart-define=INFORMATION_CAPTURE=before
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/information_settings_page.dart';
import 'package:flauncher/widgets/settings/weather_text_format_dialog.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import 'support/design_fixture.dart';

void main() {
  const stage = String.fromEnvironment('INFORMATION_CAPTURE');
  testWidgets('information navigation fits TV and preserves remote focus', (
    tester,
  ) async {
    final fixture = await pumpDesignFixture(
      tester,
      accent: const Color(0xff85d6f5),
      appearanceValues: {
        'interfaceFont': 'manrope',
        'panelCombinedInformation': true,
      },
    );
    final settings = SettingsService(await SharedPreferences.getInstance());
    addTearDown(settings.dispose);
    await settings.setShowWeatherInStatusBar(true);
    for (final background in [false, true]) {
      when(
        fixture.settings.noSuchMethod(
          Invocation.method(#informationDateTime, [], {
            #background: background,
          }),
        ),
      ).thenAnswer((_) => settings.informationDateTime(background: background));
      when(
        fixture.settings.noSuchMethod(
          Invocation.method(#informationWeather, [], {#background: background}),
        ),
      ).thenAnswer((_) => settings.informationWeather(background: background));
    }
    final context = tester.element(find.byIcon(Icons.settings_outlined));
    showLauncherDialog<void>(
      context: context,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: settings,
        child: const SettingsPanel(
          initialRoute: InformationSettingsPage.routeName,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(
      tester.element(find.byType(InformationSettingsPage)),
    )!;
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      if (stage.isEmpty) return;
      final render =
          fixture.boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('.local/information-audit/$stage/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    Future<void> open(String title) async {
      final row = find.text(title);
      await tester.scrollUntilVisible(row, 150,
          scrollable: find.descendant(
            of: find.byType(SettingsPanel), matching: find.byType(Scrollable),
          ).last);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
    }

    Future<void> back() async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    Future<void> captureDateColor(String name) async {
      await tester.scrollUntilVisible(find.text(l.informationDateColor), 120,
        scrollable: find.descendant(
          of: find.byType(SettingsPanel), matching: find.byType(Scrollable),
        ).last);
      await tester.pumpAndSettle();
      final row = find.widgetWithText(FocusableSettingsTile, l.informationDateColor);
      await Scrollable.ensureVisible(tester.element(row), alignment: .3);
      await tester.pumpAndSettle();
      await capture(name);
    }

    void expectVisibleRows(int count) {
      final rows = find.byType(FocusableSettingsTile);
      expect(rows, findsNWidgets(count));
      final viewport =
          Offset.zero &
          (tester.view.physicalSize / tester.view.devicePixelRatio);
      for (final row in rows.evaluate()) {
        final rect = tester.getRect(find.byWidget(row.widget));
        expect(viewport.contains(rect.topLeft), isTrue);
        expect(viewport.contains(rect.bottomRight), isTrue);
        expect(rect.height, greaterThanOrEqualTo(48));
      }
    }

    expectVisibleRows(6);
    for (final value in find.text(l.topPanel).evaluate()) {
      final paragraph = value.findRenderObject()! as RenderParagraph;
      final painter = TextPainter(
        text: paragraph.text,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: paragraph.size.width);
      expect(painter.computeLineMetrics(), hasLength(1));
      painter.dispose();
    }
    await capture('01-main');
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(PanelInformationSettingsPage), findsOneWidget);
    expectVisibleRows(4);
    await capture('02-panel');
    await open(l.informationComposition);
    await capture('03-formats');
    await open(l.weatherTextFormat);
    expect(find.byType(WeatherTextFormatDialog), findsOneWidget);
    await capture('04-weather');
    await back();
    await back();
    await open(l.informationTypography);
    await capture('05-typography');
    await tester.tap(find.text(l.informationInheritPanelTypography));
    await tester.pumpAndSettle();
    await capture('05a-font-controls');
    await tester.tap(find.text(l.informationInheritPanelTypography));
    await tester.pumpAndSettle();
    await back();
    await open(l.informationColors);
    await capture('06-colors');
    await captureDateColor('06a-date-color');
    await back();
    await back();
    expect(
      Focus.of(tester.element(find.text(l.informationPanelAppearance)))
          .hasFocus,
      isTrue,
    );
    await open(l.backgroundInformationAppearance);
    expectVisibleRows(4);
    await capture('07-background');
    await open(l.informationComposition);
    await capture('07a-background-formats');
    await back();
    await open(l.informationPositionSize);
    await capture('08-position');
    await tester.scrollUntilVisible(find.text(l.informationSize), 120,
      scrollable: find.descendant(
        of: find.byType(SettingsPanel), matching: find.byType(Scrollable),
      ).last);
    await tester.pumpAndSettle();
    final size = find.ancestor(
      of: find.text(l.informationSize),
      matching: find.byType(FocusableSettingsTile),
    );
    await Scrollable.ensureVisible(tester.element(size), alignment: .3);
    await tester.pumpAndSettle();
    await capture('09-size');
    await tester.scrollUntilVisible(find.text(l.informationResetPositionSize), 120,
      scrollable: find.descendant(
        of: find.byType(SettingsPanel), matching: find.byType(Scrollable),
      ).last);
    await tester.pumpAndSettle();
    await capture('09a-reset-in-list');
    await back();
    await open(l.informationColors);
    await capture('10-background-colors');
    await captureDateColor('11-background-date-color');
    Navigator.of(tester.element(find.byType(SettingsPanel)), rootNavigator: true).pop();
    await tester.pumpAndSettle();
    await fixture.appearance.set('panelInformationPlacements', {
      'time': 'background', 'date': 'background', 'weather': 'background',
    });
    await fixture.appearance.set('panelBackgroundInformationSize', 60);
    await fixture.appearance.setBackgroundInformationVerticalOffset(0);
    await tester.pumpAndSettle();
    await capture('12-background-zero');
    await fixture.appearance.setBackgroundInformationVerticalOffset(20);
    await tester.pumpAndSettle();
    await capture('13-background-shifted');
    await fixture.appearance.set('panelBackgroundInformationSize', 80);
    await tester.pumpAndSettle();
    await capture('14-background-larger');
    await tester.pumpWidget(const SizedBox());
    debugDisableShadows = true;
  }, skip: !Platform.isWindows);
}
