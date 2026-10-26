import 'dart:async';

import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/widgets/action_notice.dart';
import 'package:flauncher/widgets/notice_placement.dart';
import 'package:flauncher/widgets/notice_style.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(
    () => TestWidgetsFlutterBinding.ensureInitialized()
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed),
  );

  for (final corner in NoticeCorner.values) {
    testWidgets(
      '${corner.name}: timeout and explicit close slide out before removing cards',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final appearance = AppearanceService(
          await SharedPreferences.getInstance(),
        );
        addTearDown(appearance.dispose);
        await appearance.set('noticeCorner', corner.name);
        late BuildContext context;
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: appearance,
            child: MaterialApp(
              builder: (_, child) => ActionNoticeHost(child: child!),
              home: Builder(
                builder: (value) {
                  context = value;
                  return const Scaffold();
                },
              ),
            ),
          ),
        );
        for (final manual in [false, true]) {
          final close = showActionNotice(
            context,
            'Closing',
            persistent: manual,
            duration: const Duration(seconds: 1),
          );
          await tester.pumpAndSettle();
          final resting = tester.getRect(find.byType(NoticeSurface));
          if (manual) {
            close();
            close();
          } else {
            await tester.pump(const Duration(seconds: 1));
          }
          await tester.pump();
          expect(find.text('Closing'), findsOneWidget);
          await tester.pump(const Duration(milliseconds: 100));
          final moving = tester.getRect(find.byType(NoticeSurface));
          expect(moving.top, resting.top);
          expect(
            moving.left,
            corner.left ? lessThan(resting.left) : greaterThan(resting.left),
          );
          expect(moving.left, greaterThan(-resting.width));
          expect(moving.right, lessThan(800 + resting.width));
          await tester.pumpAndSettle();
          expect(find.text('Closing'), findsNothing);
        }
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      '${corner.name}: mixed notices share corner, spacing and expiry',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final appearance = AppearanceService(
          await SharedPreferences.getInstance(),
        );
        addTearDown(appearance.dispose);
        await appearance.set('noticeCorner', corner.name);
        final popups = StreamController<Map<dynamic, dynamic>>();
        addTearDown(popups.close);
        late BuildContext context;
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: appearance,
            child: MaterialApp(
              builder: (_, child) =>
                  ActionNoticeHost(popupStream: popups.stream, child: child!),
              home: Builder(
                builder: (value) {
                  context = value;
                  return const Scaffold();
                },
              ),
            ),
          ),
        );
        showActionNotice(context, 'Internal', persistent: true);
        popups.add({
          'key': 'a',
          'title': 'Android',
          'text': 'Body',
          'durationMs': 1000,
        });
        await tester.pumpAndSettle();
        final cards = find.byType(NoticeSurface);
        expect(cards, findsNWidgets(2));
        final first = tester.getRect(cards.at(0));
        final second = tester.getRect(cards.at(1));
        expect(first.left, second.left);
        expect(first.width, second.width);
        expect(second.top - first.bottom, 8);
        if (corner.left) {
          expect(first.left, 24);
        } else {
          expect(first.right, 776);
        }
        if (corner.top) {
          expect(first.top, 24);
        } else {
          expect(second.bottom, 576);
        }
        // Updating one Android notification replaces it without adding a card.
        popups.add({'key': 'a', 'title': 'Updated', 'durationMs': 1000});
        await tester.pumpAndSettle();
        expect(find.text('Android'), findsNothing);
        expect(find.text('Updated'), findsOneWidget);
        expect(cards, findsNWidgets(2));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(cards, findsOneWidget);
        expect(find.text('Internal'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      '${corner.name}: visible panels move existing stack and restore it',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final appearance = AppearanceService(
          await SharedPreferences.getInstance(),
        );
        addTearDown(appearance.dispose);
        await appearance.set('noticeCorner', corner.name);
        late BuildContext context;
        late StateSetter update;
        var visible = false;
        var onRight = !corner.left;
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: appearance,
            child: MaterialApp(
              builder: (_, child) => ActionNoticeHost(child: child!),
              home: StatefulBuilder(
                builder: (value, setState) {
                  context = value;
                  update = setState;
                  return Scaffold(
                    body: Offstage(
                      offstage: !visible,
                      child: SidePanelDialog(
                        isRightSide: onRight,
                        child: const Text('Panel'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        showActionNotice(context, 'Moving', persistent: true);
        await tester.pumpAndSettle();
        final card = find.byType(NoticeSurface);
        final original = tester.getRect(card);
        update(() => visible = true);
        await tester.pumpAndSettle();
        final moved = tester.getRect(card);
        expect(moved.top, original.top);
        expect(moved.left, isNot(original.left));
        update(() => visible = false);
        await tester.pumpAndSettle();
        expect(tester.getRect(card), original);
        update(() {
          visible = true;
          onRight = !onRight;
        });
        await tester.pumpAndSettle();
        expect(tester.getRect(card), original);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'Android update cancels an in-flight dismissal without removing its replacement',
    (tester) async {
      final popups = StreamController<Map<dynamic, dynamic>>();
      addTearDown(popups.close);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) =>
              ActionNoticeHost(popupStream: popups.stream, child: child!),
          home: const Scaffold(),
        ),
      );
      popups.add({'key': 'a', 'title': 'Old', 'durationMs': 1000});
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Old'), findsOneWidget);
      popups.add({'key': 'a', 'title': 'Replacement', 'durationMs': 5000});
      await tester.pumpAndSettle();
      expect(find.text('Old'), findsNothing);
      expect(find.byType(NoticeSurface), findsOneWidget);
      expect(tester.getRect(find.byType(NoticeSurface)).right, 776);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Replacement'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('outside launcher placement ignores widget panels', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            ActionNoticeHost(avoidPanels: false, child: child!),
        home: Builder(
          builder: (value) {
            context = value;
            return const SidePanelDialog(
              isRightSide: true,
              child: Text('Panel'),
            );
          },
        ),
      ),
    );
    showActionNotice(context, 'Fixed', persistent: true);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(NoticeSurface)).right, 776);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion displays the final position immediately', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: ActionNoticeHost(child: child!),
        ),
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    final close = showActionNotice(context, 'Immediate', persistent: true);
    await tester.pump();
    expect(tester.getRect(find.byType(NoticeSurface)).right, 776);
    close();
    await tester.pump();
    await tester.pump();
    expect(find.text('Immediate'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'new notices fly in from the nearest physical side without taking focus',
    (tester) async {
      late BuildContext context;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => ActionNoticeHost(child: child!),
          home: Builder(
            builder: (value) {
              context = value;
              return TextButton(
                focusNode: focus,
                autofocus: true,
                onPressed: () {},
                child: const Text('Button'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      showActionNotice(context, 'Flying', persistent: true);
      await tester.pump();
      final start = tester.getRect(find.byType(NoticeSurface));
      expect(start.left, greaterThanOrEqualTo(800));
      await tester.pump(const Duration(milliseconds: 100));
      final midway = tester.getRect(find.byType(NoticeSurface));
      expect(midway.left, lessThan(start.left));
      expect(midway.right, greaterThan(776));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(NoticeSurface)).right, 776);
      expect(focus.hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
