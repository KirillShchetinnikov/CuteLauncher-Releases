import 'package:flauncher/cover_memory_image.dart';
import 'package:flauncher/models/watch_next_program.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/app_content_row.dart';
import 'package:flauncher/widgets/application_list_icon.dart';
import 'package:flauncher/widgets/continue_watching_row.dart';
import 'package:flauncher/widgets/content_card_label.dart';
import 'package:flauncher/widgets/tile_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

import '../mocks.dart';
import '../mocks.mocks.dart';

void main() {
  for (final appTiles in [false, true]) {
    testWidgets(
      'Watch Next keeps source and progress in app tile mode=$appTiles',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final settings = SettingsService(await SharedPreferences.getInstance());
        final watch = MockWatchNextService();
        final refreshes = ValueNotifier<int>(0);
        when(watch.posterRefreshes).thenReturn(refreshes);
        when(watch.poster(any)).thenAnswer((_) async => kTransparentImage);
        final apps = MockAppsService();
        const package = 'video.app';
        when(apps.getApp(package))
            .thenReturn(fakeApp(packageName: package, name: 'Cinema'));
        when(apps.getAppIcon(package))
            .thenAnswer((_) async => kTransparentImage);
        addTearDown(settings.dispose);
        addTearDown(refreshes.dispose);
        final style = TileAppearance({
          'labelSize': 20,
          'labelColor': 0xffe3b9ff,
          'labels': 'all',
          'contentAppTileStyle': appTiles,
          'scrollContentLabels': true,
        });
        const movieTitle =
            'A very long movie title that extends far beyond the cover';
        final program = WatchNextProgram.fromMap({
          'id': 7,
          'packageName': package,
          'title': movieTitle,
          'description': 'Episode 2',
          'posterArtUri': 'content://cover',
          'duration': 100,
          'playbackPosition': 50,
        });
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsService>.value(value: settings),
              ChangeNotifierProvider<AppsService>.value(value: apps),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 240,
                  child: WatchNextCard(
                    program: program,
                    appsService: apps,
                    watchNextService: watch,
                    handleUpNavigationToSettings: false,
                    style: style,
                    size: const Size(240, 135),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ContentPreviewCard), findsOneWidget);
        final cover = appTiles
            ? find.byType(TileArtwork)
            : find.byWidgetPredicate(
                (widget) => widget is Image && widget.image is CoverMemoryImage,
              );
        expect(cover, findsOneWidget);
        final title = find.text(movieTitle);
        expect(tester.widget<Text>(title).style, style.labelStyle);
        expect(
          tester.getBottomLeft(cover).dy,
          lessThan(tester.getTopLeft(title).dy),
        );
        expect(find.text('Episode 2'), findsOneWidget);
        expect(
          tester.widget<ContentCardLabel>(find.byType(ContentCardLabel)).subtitle,
          'Episode 2',
        );
        final badgeIcon = find.byType(ApplicationListIcon);
        final badgeName = find.text('Cinema');
        expect(badgeIcon, findsOneWidget);
        expect(
          find.descendant(of: badgeIcon, matching: find.byType(Image)),
          findsOneWidget,
        );
        expect(badgeName, findsOneWidget);
        expect(
          tester.getTopLeft(badgeIcon),
          tester.getTopLeft(cover) + const Offset(12, 9),
        );
        expect(
          tester.getTopLeft(badgeName).dx,
          greaterThan(tester.getTopRight(badgeIcon).dx),
        );
        expect(find.textContaining(RegExp(r'\d+%')), findsNothing);
        final progress = find.byType(LinearProgressIndicator);
        expect(
          tester.getBottomLeft(progress).dy,
          tester.getBottomLeft(cover).dy,
        );
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          .5,
        );

        await settings.setContinueWatchingShowDescription(false);
        await settings.setContinueWatchingShowProgress(false);
        await tester.pumpAndSettle();
        expect(find.text('Episode 2'), findsNothing);
        expect(badgeName, findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(tester.widget<Text>(title).maxLines, appTiles ? 1 : 2);
        final titleLeft = tester.getTopLeft(title).dx;
        final focus = tester.widget<InkWell>(find.byType(InkWell)).focusNode!;
        focus.requestFocus();
        await tester.pump();
        await tester.pump();
        expect(focus.hasPrimaryFocus, isTrue);
        final label = find.ancestor(
          of: title,
          matching: find.byType(ContentCardLabel),
        );
        expect(tester.widget<ContentCardLabel>(label).scroll, isTrue);
        await tester.pump(const Duration(milliseconds: 850));
        expect(tester.widget<Text>(title).softWrap, isFalse);
        await tester.pump(const Duration(seconds: 1));
        expect(tester.getTopLeft(title).dx, lessThan(titleLeft));
        focus.unfocus();
        await tester.pump();
        await tester.pump();
        expect(tester.getTopLeft(title).dx, titleLeft);
        expect(tester.widget<Text>(title).overflow, TextOverflow.ellipsis);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
