import 'dart:typed_data';

import 'package:flauncher/models/watch_next_program.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/theme/launcher_colors.dart';
import 'package:flauncher/widgets/continue_watching_row.dart';
import 'package:flauncher/widgets/watch_next_card_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../mocks.mocks.dart';

void main() {
  for (final scale in [1.0, 1.6]) {
    for (final preset in ['64', 'compact', 'normal', 'large']) {
      for (final showDescription in [false, true]) {
        testWidgets(
          'card keeps readable roles at $preset / $scale / $showDescription',
          (tester) async {
            final settings = MockSettingsService();
            when(settings.themes).thenReturn('modern');
            when(settings.accentColorHex).thenReturn('9674FF');
            when(settings.appHighlightAnimationEnabled).thenReturn(false);
            when(settings.hideHighlightOutlineOnHomescreen).thenReturn(false);
            when(settings.appSelectorTransitionAnimationEnabled)
                .thenReturn(false);
            when(settings.continueWatchingCardSize).thenReturn(preset);
            when(settings.continueWatchingShowDescription)
                .thenReturn(showDescription);
            when(settings.continueWatchingShowPercentage).thenReturn(true);
            when(settings.continueWatchingShowProgress).thenReturn(true);
            final apps = MockAppsService();
            when(apps.getAppIcon(any)).thenAnswer((_) async => Uint8List(0));
            final watch = MockWatchNextService();
            final program = WatchNextProgram.fromMap({
              'id': 7,
              'packageName': 'test.video',
              'title': 'Продолжить любимый фильм — a long movie title',
              'description': 'Описание программы / Program description',
              'duration': 100,
              'playbackPosition': 50,
            });
            const foreground = Color(0xfff4f5f8);
            const detail = Color(0xffb9bfcd);
            const background = Color(0xff1c2029);
            for (final wallpaper in [
              Colors.white,
              Colors.black,
              Colors.yellow,
            ]) {
              await tester.pumpWidget(
                ChangeNotifierProvider<SettingsService>.value(
                  value: settings,
                  child: MaterialApp(
                    theme: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        surface: background,
                        onSurface: foreground,
                        onSurfaceVariant: detail,
                      ),
                      textTheme: const TextTheme(
                        bodyMedium: TextStyle(fontSize: 15, height: 1.3),
                        bodySmall: TextStyle(fontSize: 13, height: 1.3),
                      ),
                    ),
                    home: MediaQuery(
                      data: MediaQueryData(
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: Material(
                        color: wallpaper,
                        child: Center(
                          child: Builder(
                            builder: (context) => SizedBox(
                              height: watchNextCardSize(context, preset).height,
                              child: WatchNextCard(
                                program: program,
                                appsService: apps,
                                watchNextService: watch,
                                handleUpNavigationToSettings: false,
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
              expect(tester.takeException(), isNull);
              final title = tester.widget<Text>(find.text(program.title));
              expect(title.style!.fontSize, 15);
              expect(
                LauncherColors.contrast(title.style!.color!, background),
                greaterThanOrEqualTo(4.5),
              );
              if (showDescription) {
                final description = tester.widget<Text>(
                  find.text(program.description),
                );
                expect(description.style!.fontSize, 13);
                expect(
                  LauncherColors.contrast(
                    description.style!.color!,
                    background,
                  ),
                  greaterThanOrEqualTo(4.5),
                );
              }
              expect(
                tester
                    .widgetList<Container>(find.byType(Container))
                    .any(
                      (c) =>
                          c.decoration is BoxDecoration &&
                          (c.decoration as BoxDecoration).color == background,
                    ),
                isTrue,
              );
            }
          },
        );
      }
    }
  }
}
