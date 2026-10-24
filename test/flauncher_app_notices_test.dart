import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flauncher/widgets/notice_style.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/design_fixture.dart';

void main() {
  Future<void> blocked(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'me.efesser.flauncher/event_home',
      const StandardMethodCodec().encodeSuccessEnvelope('remote_panel_blocked'),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Home cancels the landscape preview before closing settings', (
    tester,
  ) async {
    await pumpDesignFixture(tester, language: 'ru');
    debugDisableShadows = true;
    final settings = tester
        .element(find.byType(FocusAwareAppBar))
        .read<SettingsService>();
    settings.landscapeDemo.value = LandscapeDemoFrame(
      Duration.zero,
      DateTime(2026, 10, 24),
    );
    await tester.pump();
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'me.efesser.flauncher/event_home',
      const StandardMethodCodec().encodeSuccessEnvelope(true),
      (_) {},
    );
    expect(settings.landscapeDemo.value, isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final language in ['ru', 'en']) {
    for (final onRight in [false, true]) {
      testWidgets(
        'blocked panel uses launcher notice: $language right=$onRight',
        (tester) async {
          await pumpDesignFixture(
            tester,
            language: language,
            settingsMenuOnRight: onRight,
            appearanceValues: const {
              'noticeColor': 0xff123456,
              'noticeOpacity': .8,
              'noticeTextColor': 0xff80cbc4,
              'noticeTextSize': 20,
            },
          );
          debugDisableShadows = true;
          final bar = tester.state<FocusAwareAppBarState>(
            find.byType(FocusAwareAppBar),
          );
          bar.focusSettings();
          await tester.pumpAndSettle();
          final l = AppLocalizations.of(
            tester.element(find.byType(FocusAwareAppBar)),
          )!;
          await blocked(tester);
          expect(find.text(l.remotePanelDisabledInLauncher), findsOneWidget);
          expect(
            find.ancestor(
              of: find.text(l.remotePanelDisabledInLauncher),
              matching: find.byType(NoticeSurface),
            ),
            findsOneWidget,
          );
          final noticeMaterial = tester.widget<Material>(
            find
                .descendant(
                  of: find.byType(NoticeSurface),
                  matching: find.byType(Material),
                )
                .first,
          );
          expect(
            noticeMaterial.color,
            const Color(0xff123456).withValues(alpha: .8),
          );
          final noticeText = tester.widget<Text>(
            find.text(l.remotePanelDisabledInLauncher),
          );
          expect(noticeText.style!.color, const Color(0xff80cbc4));
          expect(noticeText.style!.fontSize, 20);
          expect(bar.settingsFocusNode.hasFocus, isTrue);
          await tester.pump(const Duration(seconds: 6));
          expect(find.text(l.remotePanelDisabledInLauncher), findsNothing);
          await tester.tap(find.byIcon(Icons.settings_outlined));
          await tester.pumpAndSettle();
          final focused = FocusManager.instance.primaryFocus;
          await blocked(tester);
          expect(find.byType(SettingsPanel), findsOneWidget);
          expect(FocusManager.instance.primaryFocus, same(focused));
          final message = find.text(l.remotePanelDisabledInLauncher);
          final card = find.ancestor(
            of: message,
            matching: find.byType(NoticeSurface),
          );
          if (onRight) {
            expect(tester.getCenter(card).dx, lessThan(480));
          } else {
            expect(tester.getCenter(card).dx, greaterThan(480));
          }
          await blocked(tester);
          expect(message, findsOneWidget);
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await blocked(tester);
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
          expect(message, findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
