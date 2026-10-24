import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/theme/interface_style.dart';
import 'package:flauncher/widgets/settings/settings_page_layout.dart';
import 'package:flauncher/widgets/settings/settings_panel_style.dart';
import 'package:flauncher/widgets/settings/settings_menu_layout.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final locale in ['ru', 'en']) {
    testWidgets(
      'settings keep scroll and focus across style and side changes: $locale',
      (tester) async {
        tester.view.physicalSize = const Size(960, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final appearance = AppearanceService(
          await SharedPreferences.getInstance(),
        );
        await appearance.set('settingsTextColor', 0xff334455);
        await appearance.set('settingsColor', 0xffeeeeee);
        await appearance.set('settingsInterfaceFont', 'manrope');
        final nodes = List.generate(
          20,
          (index) => FocusNode(debugLabel: 'row $index'),
        );
        var invoked = -1;
        ScrollController? controller;
        var restoreOffset = 0.0;
        for (final skin in InterfaceStyle.values) {
          for (final onRight in [false, true]) {
            await tester.pumpWidget(
              ChangeNotifierProvider.value(
                value: appearance,
                child: MaterialApp(
                  locale: Locale(locale),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  theme: ThemeData.light().copyWith(
                    extensions: [InterfaceSkin(skin)],
                  ),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: const TextScaler.linear(1.6)),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: Align(
                      alignment: onRight
                          ? Alignment.topRight
                          : Alignment.topLeft,
                      child: SizedBox(
                        width: 380,
                        child: SettingsPanelStyle(
                          builder: (context) => SettingsMenuLayout(
                            onRight: onRight,
                            child: SettingsPageLayout(
                              title: const Text('Settings'),
                              child: ListView(
                                children: [
                                  const SettingsHelp(text: 'Long explanation'),
                                  for (var i = 0; i < nodes.length; i++)
                                    FocusableSettingsTile(
                                      focusNode: nodes[i],
                                      title: Text('Setting $i'),
                                      onPressed: () async {
                                        invoked = i;
                                        await Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (context) => Scaffold(
                                              body: SettingsPageLayout(
                                                title: const Text('Nested'),
                                                child: ListView(
                                                  children: [
                                                    FocusableSettingsTile(
                                                      title: const Text(
                                                        'Return',
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final firstPass = controller == null;
            final scroll = tester.state<ScrollableState>(
              find.byType(Scrollable).first,
            );
            final current = PrimaryScrollController.of(
              tester.element(find.byType(ListView).first),
            );
            if (firstPass) {
              expect(nodes.first.hasFocus, isTrue);
              nodes[8].requestFocus();
              await tester.pumpAndSettle();
              controller = current;
              restoreOffset = scroll.position.pixels;
              expect(restoreOffset, greaterThan(0));
            } else {
              expect(current, same(controller));
              expect(nodes[8].hasFocus, isTrue);
              expect(scroll.position.pixels, closeTo(restoreOffset, .01));
            }
            expect(
              tester
                  .widget<Scrollbar>(find.byType(Scrollbar))
                  .scrollbarOrientation,
              onRight ? ScrollbarOrientation.right : ScrollbarOrientation.left,
            );
            final labelContext = tester.element(find.text('Setting 8'));
            expect(
              DefaultTextStyle.of(labelContext).style.color,
              const Color(0xff334455),
            );
            expect(
              Theme.of(labelContext).textTheme.bodyMedium!.fontFamily,
              'Manrope',
            );
            expect(InterfaceSkin.of(labelContext).style, skin);
            if (skin == InterfaceStyle.standard) {
              final row = find.ancestor(
                of: find.text('Setting 8'),
                matching: find.byType(FocusableSettingsTile),
              );
              final surface = tester.widget<Container>(
                find
                    .descendant(of: row, matching: find.byType(Container))
                    .first,
              );
              final background = (surface.decoration as BoxDecoration).color!;
              expect(
                background.computeLuminance(),
                greaterThan(.5),
                reason: 'A focused row must preserve the chosen light surface for dark text',
              );
            }
            expect(tester.takeException(), isNull);
          }
        }
        // Returning from a nested page must preserve both focused row and scroll.
        await tester.tap(find.text('Setting 8'));
        await tester.pumpAndSettle();
        expect(invoked, 8);
        expect(find.text('Nested'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(nodes[8].hasFocus, isTrue);
        expect(controller!.offset, closeTo(restoreOffset, .01));
        await tester.pumpWidget(const SizedBox());
        for (final node in nodes) {
          node.dispose();
        }
        appearance.dispose();
      },
    );
  }
}
