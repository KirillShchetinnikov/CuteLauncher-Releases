import 'dart:async';
import 'dart:convert';

import 'package:flauncher/feed_format.dart';
import 'package:flauncher/providers/app_channels_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/app_content_row.dart';
import 'package:flauncher/widgets/category_focus.dart';
import 'package:flauncher/widgets/tile_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

import '../support/app_channels.dart';

void main() {
  final newPoster = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAMAAAACCAIAAAASFvFNAAAAEklEQVR4nGNkaGCAACYozcAAAAk8AITOVm/vAAAAAElFTkSuQmCC',
  );
  for (final replaceId in [true, false]) {
    for (final tileStyle in [false, true]) {
      testWidgets(
        'visible feed commits poster, title and launch together (new ID: $replaceId, app tiles: $tileStyle)',
        (tester) async {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          SharedPreferences.setMockInitialValues({});
          final settings = SettingsService(
            await SharedPreferences.getInstance(),
          );
          await settings.setAppChannelFormat(
            'video.app:1',
            FeedFormat.landscape,
          );
          await settings.setSelectedAppChannels(['video.app:1']);
          Map<String, dynamic> catalog(String title, int id) {
            final row = feed(1, count: 1, poster: 'content://art/$title');
            row['programs'][0].addAll({
              'id': id,
              'title': title,
              'intentUri': 'video://$title',
            });
            return row;
          }

          final channel = FeedChannel()
            ..data = [catalog('old', 1)]
            ..posterResponse = () async => kTransparentImage;
          final service = AppChannelsService(channel, settings);
          final focus = CategoryFocusController();
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: settings),
                ChangeNotifierProvider.value(value: service),
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: CategoryFocus(
                    controller: focus,
                    child: Consumer<AppChannelsService>(
                      builder: (_, feeds, _) {
                        final row = feeds.channels.firstOrNull;
                        if (row == null) return const SizedBox();
                        focus.configure(
                          row.programs.map((p) => p.id.toString()),
                        );
                        return AppContentRow(
                          channel: row,
                          programs: row.programs,
                          appearance: TileAppearance({
                            'contentAppTileStyle': tileStyle,
                            'labels': 'all',
                          }),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
          Future<void> frames() async {
            for (var i = 0; i < 5; i++) {
              await tester.pump();
            }
          }

          Future<void> verifyCard(String title) async {
            expect(find.text(title), findsOneWidget);
            expect(find.byIcon(Icons.movie_outlined), findsNothing);
            final provider = tileStyle
                ? tester.widget<TileArtwork>(find.byType(TileArtwork)).image
                : tester.widget<Image>(find.byType(Image)).image;
            expect(
              (provider as MemoryImage).bytes,
              title == 'old' ? kTransparentImage : newPoster,
            );
            expect(
              tester
                  .widget<InkWell>(find.byType(InkWell))
                  .focusNode!
                  .hasPrimaryFocus,
              isTrue,
            );
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            expect(channel.launches.last.$1, 'video://$title');
          }

          await frames();
          tester
              .widget<InkWell>(find.byType(InkWell))
              .focusNode!
              .requestFocus();
          await frames();
          await verifyCard('old');
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          final latePoster = Completer<Uint8List?>();
          channel.data = [catalog('superseded', 2)];
          channel.posterResponse = () => latePoster.future;
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await frames();
          await verifyCard('old');

          channel.data = [catalog('new', replaceId ? 3 : 1)];
          channel.posterResponse = () async => null;
          await service.refresh();
          await frames();
          latePoster.complete(kTransparentImage);
          await frames();
          await verifyCard('old');
          // A transport success can still contain an undecodable frame.
          channel.posterResponse = () async => Uint8List.fromList([1, 2, 3]);
          await tester.pump(const Duration(seconds: 2));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await frames();
          await verifyCard('old');

          channel.posterResponse = () async => newPoster;
          await tester.pump(const Duration(seconds: 4));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await frames();
          await verifyCard('new');
          expect(find.text('superseded'), findsNothing);
          await tester.pumpWidget(const SizedBox());
          focus.dispose();
          service.dispose();
          settings.dispose();
          await channel.events.close();
        },
      );
    }
  }
}
