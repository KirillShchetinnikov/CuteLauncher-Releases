import 'dart:io';
import 'dart:ui' as ui;

import 'package:flauncher/widgets/settings/appearance_settings_page.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/widgets/settings/misc_panel_page.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:flauncher/widgets/settings/display_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/design_fixture.dart';

void main() {
  const stage = String.fromEnvironment('CAPTURE_STAGE');
  testWidgets('capture TV home and settings at matching viewport', (
    tester,
  ) async {
    final fixture = await pumpDesignFixture(
      tester,
      scale: stage.contains('large') ? 1.3 : 1,
      language: stage.contains('rtl') ? 'ar' : 'ru',
    );
    try {
      Future<void> capture(String screen) async {
        expect(tester.takeException(), isNull);
        final render =
            fixture.boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('docs/images/design/captures/$stage/$screen.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      tester
          .widget<InkWell>(
            find
                .descendant(
                  of: find.byKey(const Key('demo.0')).first,
                  matching: find.byType(InkWell),
                )
                .first,
          )
          .focusNode!
          .requestFocus();
      await tester.pumpAndSettle();
      await capture('home');
      final context = tester.element(find.byIcon(Icons.settings_outlined));
      for (final screen in [
        'settings',
        'interface',
        'display',
        'appearance',
        'tiles',
        'focus',
        'top-panel',
        'panel',
      ]) {
        final route = switch (screen) {
          'interface' => InterfaceSettingsPage.routeName,
          'display' => DisplaySettingsPage.routeName,
          'appearance' => AppearanceSettingsPage.routeName,
          'tiles' => AppearancePage.routeName,
          'focus' => MiscPanelPage.routeName,
          'top-panel' => StatusBarPanelPage.routeName,
          'panel' => 'panel_appearance',
          _ => null,
        };
        showDialog<void>(
          context: context,
          builder: (_) => SettingsPanel(initialRoute: route),
        );
        await tester.pumpAndSettle();
        await capture(screen);
        Navigator.of(context).pop();
        await tester.pumpAndSettle();
      }
    } finally {
      debugDisableShadows = true;
    }
  }, skip: stage.isEmpty);
}
