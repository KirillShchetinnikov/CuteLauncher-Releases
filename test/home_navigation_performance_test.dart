import 'dart:async';

import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/app_card.dart';
import 'package:flauncher/widgets/category_focus.dart';
import 'package:flauncher/widgets/home_section.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'flauncher_test.dart' as fixtures;
import 'mocks.dart';

class _TrackingScrollController extends ScrollController {
  final targets = <double>[];
  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _TrackingScrollPosition(this, physics, context, oldPosition);
}

class _TrackingScrollPosition extends ScrollPositionWithSingleContext {
  final _TrackingScrollController owner;
  _TrackingScrollPosition(
    this.owner,
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) : super(physics: physics, context: context, oldPosition: oldPosition);
  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) {
    owner.targets.add(to);
    return super.animateTo(to, duration: duration, curve: curve);
  }
}

void main() {
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'grid focus has one scroll request and reuses idle labels ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(800, 450);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final appearance = AppearanceService(
          await SharedPreferences.getInstance(),
        );
        final category = fakeCategory(type: CategoryType.grid, columnsCount: 4)
          ..applications.addAll(
            List.generate(
              48,
              (i) => fakeApp(packageName: 'grid.$i', name: 'Grid app $i'),
            ),
          );
        await appearance.set('focusPulse', false);
        await appearance.set('labels', 'all');
        await appearance.setCategory(category.id, 'layout', 'grid');
        await appearance.setCategory(category.id, 'columns', 4);
        final focus = CategoryFocusController();
        final outside = FocusNode();
        addTearDown(outside.dispose);
        final outer = _TrackingScrollController();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: appearance),
              ChangeNotifierProvider<AppsService>.value(
                value: fixtures.mkAppService(),
              ),
              ChangeNotifierProvider<SettingsService>.value(
                value: fixtures.mkSettingsService(),
              ),
              ChangeNotifierProvider<NotificationsService>.value(
                value: fixtures.mkNotificationsService(),
              ),
            ],
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  controller: outer,
                  child: Column(
                    children: [
                      Focus(focusNode: outside, child: const SizedBox(height: 160)),
                      CategoryFocus(
                        controller: focus,
                        child: HomeSection(category: category),
                      ),
                      const SizedBox(height: 300),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        unawaited(focus.focusPackage('grid.0'));
        await tester.pumpAndSettle();
        // Entering a section whose destination is mounted must apply focus
        // before another frame, just like entering a recommendation row.
        final nextCard = find.byWidgetPredicate((widget) =>
            widget is AppCard && widget.application.packageName == 'grid.1');
        expect(focus.hasMountedPackage('grid.1'), isTrue);
        unawaited(focus.enter!(
          AxisDirection.down, tester.getCenter(nextCard).dx,
        ));
        await tester.idle();
        expect(focus.lastPackage, 'grid.1',
            reason: 'Mounted section entry must not wait for endOfFrame');
        await tester.pumpAndSettle();
        unawaited(focus.focusPackage('grid.0'));
        await tester.pumpAndSettle();
        var idleCardBuilds = 0;
        final previousRebuild = debugOnRebuildDirtyWidget;
        debugOnRebuildDirtyWidget = (element, builtOnce) {
          previousRebuild?.call(element, builtOnce);
          if (element.widget case AppCard(application: final app)
              when app.packageName == 'grid.3') {
            idleCardBuilds++;
          }
        };
        addTearDown(() => debugOnRebuildDirtyWidget = previousRebuild);
        for (var i = 0; i < 5; i++) {
          outside.requestFocus();
          await tester.pumpAndSettle();
          unawaited(focus.focusPackage('grid.0'));
          await tester.pumpAndSettle();
        }
        debugOnRebuildDirtyWidget = previousRebuild;
        expect(idleCardBuilds, 0,
            reason: 'Entering and leaving a section must reuse idle cards');
        final staticLabels = find
            .descendant(
              of: find.text('Grid app 3'),
              matching: find.byType(RichText),
            )
            .evaluate()
            .map((e) => e.renderObject)
            .toSet();
        expect(staticLabels, isNotEmpty);
        var labelPaints = 0;
        final original = debugOnProfilePaint;
        debugOnProfilePaint = (object) {
          original?.call(object);
          if (staticLabels.contains(object)) labelPaints++;
        };
        addTearDown(() => debugOnProfilePaint = original);
        for (final (key, index) in [
          (LogicalKeyboardKey.arrowDown, 4),
          (LogicalKeyboardKey.arrowDown, 8),
          (LogicalKeyboardKey.arrowDown, 12),
          (LogicalKeyboardKey.arrowUp, 8),
          (LogicalKeyboardKey.arrowUp, 4),
        ]) {
          outer.targets.clear();
          final samples = [outer.offset];
          await tester.sendKeyEvent(key);
          // Include focus materialization, post-frame reveal and its 200 ms motion.
          for (var frame = 0; frame < 18; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
            samples.add(outer.offset);
          }
          expect(
            FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<AppCard>()
                ?.application
                .packageName,
            'grid.$index',
          );
          expect(
            outer.targets.length,
            lessThanOrEqualTo(1),
            reason: 'A focus change must not restart the same scroll',
          );
          final direction = (samples.last - samples.first).sign;
          expect(outer.position.isScrollingNotifier.value, isFalse);
          for (var i = 1; i < samples.length; i++) {
            expect(
              (samples[i] - samples[i - 1]) * direction,
              greaterThanOrEqualTo(-.01),
            );
          }
        }
        debugOnProfilePaint = original;
        expect(
          labelPaints,
          0,
          reason: 'Unchanged card labels should reuse their paint layer during navigation',
        );
        for (final key in [
          LogicalKeyboardKey.arrowDown,
          LogicalKeyboardKey.arrowDown,
          LogicalKeyboardKey.arrowUp,
        ]) {
          await tester.sendKeyEvent(key);
          for (var frame = 0; frame < 3; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
        }
        await tester.pumpAndSettle();
        expect(focus.lastPackage, 'grid.8');
        await appearance.set('labels', 'selected');
        await tester.pumpAndSettle();
        unawaited(focus.focusPackage('grid.0'));
        await tester.pumpAndSettle();
        idleCardBuilds = 0;
        debugOnRebuildDirtyWidget = (element, builtOnce) {
          previousRebuild?.call(element, builtOnce);
          if (element.widget case AppCard(application: final app)
              when app.packageName == 'grid.3') {
            idleCardBuilds++;
          }
        };
        unawaited(focus.focusPackage('grid.1'));
        await tester.pumpAndSettle();
        debugOnRebuildDirtyWidget = previousRebuild;
        expect(idleCardBuilds, 0,
            reason: 'Updating the selected label must not rebuild idle cards');
        expect(find.text('Grid app 1'), findsOneWidget);
        // An already queued reveal must not scroll the wallpaper behind a menu.
        outer.jumpTo(0);
        await tester.pumpAndSettle();
        outer.targets.clear();
        final sectionContext = tester.element(find.byType(HomeSection));
        final navigator = Navigator.of(sectionContext);
        focus.reveal!();
        unawaited(
          navigator.push(
            DialogRoute<void>(
              context: sectionContext,
              requestFocus: false,
              builder: (_) => const SizedBox.shrink(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(outer.targets, isEmpty);
        navigator.pop();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        focus.dispose();
        outer.dispose();
        appearance.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
