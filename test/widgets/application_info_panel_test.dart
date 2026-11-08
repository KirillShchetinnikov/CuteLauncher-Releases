/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/add_to_category_dialog.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../mocks.dart';
import '../mocks.mocks.dart';
import 'panel_backdrop_assertions.dart';

void main() {
  for (final (active, status) in [
    (false, "success"),
    (true, "success"),
    (true, "denied"),
  ]) {
    testWidgets('Stop is visible only for a running app ($active, $status)', (
      tester,
    ) async {
      const channel = MethodChannel('cutelauncher/adb');
      var running = active;
      var stops = 0;
      var checks = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'info') return {'port': 5555};
            final args = call.arguments as Map;
            expect(args['packages'], ['test.app']);
            if (args['action'] == 'stopApp') {
              stops++;
              running = status != "success";
            } else {
              checks++;
            }
            return {
              'status': args['action'] == 'stopApp' ? status : 'success',
              'running': running,
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final apps = MockAppsService();
      when(apps.isTileHidden(any)).thenReturn(false);
      when(apps.categories).thenReturn([]);
      final app = fakeApp(packageName: 'test.app', name: 'Test', version: '1');
      when(apps.applications).thenReturn([app]);
      await _pumpWidgetWithProviders(
        tester,
        apps,
        null,
        app,
        locale: const Locale('ru'),
      );
      await tester.pumpAndSettle();
      expect(checks, 0);
      expect(find.text('Остановить'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('app_check_process')),
        150,
      );
      await tester.tap(find.byKey(const ValueKey('app_check_process')));
      await tester.pumpAndSettle();
      expect(checks, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(checks, 1);
      expect(find.text('Остановить'), active ? findsOneWidget : findsNothing);
      if (active) {
        await tester.ensureVisible(find.text('Остановить'));
        await tester.tap(find.text('Остановить'));
        await tester.pumpAndSettle();
        expect(stops, 1);
        expect(checks, 1, reason: 'stopApp returns the verified process state');
        expect(
          find.text('Остановить'),
          status == 'success' ? findsNothing : findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('opening, resuming, rebuilding and reopening never call ADB', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('cutelauncher/adb');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return {'status': 'success', 'running': true};
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final apps = _ObservableAppsService();
    when(apps.categories).thenReturn([]);
    when(apps.isTileHidden(any)).thenReturn(false);
    final app = fakeApp(packageName: 'test.app', name: 'Test');
    await _pumpWidgetWithProviders(tester, apps, null, app, asDialog: true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    apps.notifyListeners();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open info'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('app_check_process')),
      150,
    );
    expect(find.text('Status not checked'), findsOneWidget);
    expect(find.text('Stop'), findsNothing);
  });

  for (final failure in [
    'authorization',
    'unavailable',
    'exception',
    'malformed',
  ]) {
    testWidgets(
      'manual check distinguishes $failure from stopped and permits retry',
      (tester) async {
        const channel = MethodChannel('cutelauncher/adb');
        var checks = 0;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'info') return {'port': 5555};
            checks++;
            if (checks > 1) return {'status': 'success', 'running': false};
            if (failure == 'exception') {
              throw PlatformException(code: 'unavailable');
            }
            return {'status': failure == 'malformed' ? 'success' : failure};
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        final apps = MockAppsService();
        when(apps.categories).thenReturn([]);
        when(apps.isTileHidden(any)).thenReturn(false);
        await _pumpWidgetWithProviders(
          tester,
          apps,
          null,
          fakeApp(packageName: 'test.app', name: 'Test'),
        );
        final l = AppLocalizations.of(
          tester.element(find.byType(ApplicationInfoPanel)),
        )!;
        final check = find.byKey(const ValueKey('app_check_process'));
        await tester.scrollUntilVisible(check, 150);
        await tester.tap(check);
        await tester.pumpAndSettle();
        expect(checks, 1);
        expect(find.text(l.appProcessStopped), findsNothing);
        expect(find.text(l.stopApp), findsNothing);
        expect(
          find.text(
            failure == 'authorization'
                ? l.adbAuthorization
                : failure == 'malformed'
                ? l.appError
                : l.adbUnavailable,
          ),
          findsOneWidget,
        );
        await tester.tap(check);
        await tester.pumpAndSettle();
        expect(checks, 2);
        expect(find.text(l.appProcessStopped), findsOneWidget);
        expect(
          Focus.of(tester.element(find.text(l.appCheckProcess)))
              .hasPrimaryFocus,
          isTrue,
        );
      },
    );
  }

  testWidgets(
    'manual check is single-flight and late completion after close is safe',
    (tester) async {
      const channel = MethodChannel('cutelauncher/adb');
      final response = Completer<Map<String, dynamic>>();
      var checks = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'info') return {'port': 5555};
        checks++;
        return response.future;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final apps = MockAppsService();
      when(apps.categories).thenReturn([]);
      when(apps.isTileHidden(any)).thenReturn(false);
      await _pumpWidgetWithProviders(
        tester,
        apps,
        null,
        fakeApp(packageName: 'test.app', name: 'Test'),
        asDialog: true,
      );
      final check = find.byKey(const ValueKey('app_check_process'));
      await tester.scrollUntilVisible(check, 150);
      await tester.tap(check);
      await tester.pump();
      await tester.tap(check);
      await tester.pump();
      expect(checks, 1);
      expect(find.text('Loading'), findsOneWidget);
      expect(
        Focus.of(tester.element(find.text('Check status'))).hasPrimaryFocus,
        isTrue,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      response.complete({'status': 'success', 'running': true});
      await tester.pumpAndSettle();
      expect(find.byType(ApplicationInfoPanel), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.single.physicalSize = Size(1280, 720);
    binding.platformDispatcher.views.single.devicePixelRatio = 1.0;
    // Scale-down the font size because the font 'Ahem' used when running tests is much wider than Roboto
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  for (final locale in [const Locale('ru'), const Locale('en')]) {
    testWidgets(
      'grouped app actions remain accessible with large text: $locale',
      (tester) async {
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(
          () =>
              tester.binding.platformDispatcher.textScaleFactorTestValue = 0.8,
        );
        final apps = MockAppsService();
        when(apps.categories).thenReturn([]);
        when(apps.isTileHidden(any)).thenReturn(false);
        await _pumpWidgetWithProviders(
          tester,
          apps,
          null,
          fakeApp(
            packageName: 'test.app',
            name: 'Application with a long name',
          ),
          locale: locale,
        );
        final l = AppLocalizations.of(
          tester.element(find.byType(ApplicationInfoPanel)),
        )!;
        expect(find.text(l.homeScreen), findsOneWidget);
        for (final label in [
          l.appLaunchGroup,
          l.appearanceSettings,
          l.appManagementGroup,
          l.appCheckProcess,
          l.uninstall,
        ]) {
          await tester.scrollUntilVisible(find.text(label), 100);
          await tester.pumpAndSettle();
          expect(find.text(label), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'app sections expand with automatic and hidden memberships: $locale',
      (tester) async {
        final apps = _ObservableAppsService();
        final app = fakeApp(packageName: 'test.app', name: 'Test');
        final hidden = Category(
          id: 3,
          name: 'My hidden section',
          order: 2,
          visible: false,
        );
        app.categoryOrders[3] = 0;
        final games = Category(id: 2, name: 'Games', order: 1)
          ..applications.add(app);
        final automatic =
            Category(id: 1, name: 'All Apps', systemKey: 'all_apps', order: 0)
              ..applications.add(
                fakeApp(packageName: 'test.app', name: 'Old instance'),
              );
        final unrelated = Category(id: 4, name: 'Unrelated', order: 3);
        final feeds = Category(
          id: 5,
          name: 'App Feeds',
          systemKey: 'app_channels',
        )..applications.add(app);
        final absentAutomatic = Category(
          id: 6,
          name: 'Absent automatic section',
          systemKey: 'tv_apps',
        );
        app.categoryOrders[6] = 0;
        when(apps.categories).thenReturn([
          hidden,
          unrelated,
          games,
          feeds,
          automatic,
          absentAutomatic,
        ]);
        when(apps.applications).thenReturn([app]);
        when(apps.isTileHidden(any)).thenReturn(false);
        await _pumpWidgetWithProviders(tester, apps, null, app, locale: locale);
        final l = AppLocalizations.of(
          tester.element(find.byType(ApplicationInfoPanel)),
        )!;
        await tester.scrollUntilVisible(find.text(l.appSections), 150);
        expect(find.text('My hidden section'), findsNothing);
        await tester.tap(find.text(l.appSections));
        await tester.pumpAndSettle();
        expect(find.text('My hidden section'), findsOneWidget);
        expect(find.text(l.allApplications), findsOneWidget);
        expect(find.text(l.games), findsOneWidget);
        expect(
          tester.getTopLeft(find.text(l.allApplications)).dy,
          lessThan(tester.getTopLeft(find.text(l.games)).dy),
        );
        expect(
          tester.getTopLeft(find.text(l.games)).dy,
          lessThan(tester.getTopLeft(find.text('My hidden section')).dy),
        );
        expect(find.text('Unrelated'), findsNothing);
        expect(find.text('Absent automatic section'), findsNothing);
        expect(find.byIcon(Icons.visibility_off_outlined), findsWidgets);
        games.applications.clear();
        apps.notifyListeners();
        await tester.pumpAndSettle();
        expect(find.text(l.games), findsNothing);
        expect(find.text('My hidden section'), findsOneWidget);
        await tester.tap(find.text(l.appSections));
        await tester.pumpAndSettle();
        expect(find.text('My hidden section'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'empty section list explains absence without changing membership',
    (tester) async {
      final apps = MockAppsService();
      final app = fakeApp(packageName: 'test.app', name: 'Test');
      when(apps.categories).thenReturn([]);
      when(apps.applications).thenReturn([app]);
      when(apps.isTileHidden(any)).thenReturn(false);
      await _pumpWidgetWithProviders(tester, apps, null, app);
      final l = AppLocalizations.of(
        tester.element(find.byType(ApplicationInfoPanel)),
      )!;
      await tester.scrollUntilVisible(find.text(l.appSections), 150);
      await tester.tap(find.text(l.appSections));
      await tester.pumpAndSettle();
      expect(find.text(l.noAppSections), findsOneWidget);
      expect(app.categoryOrders, isEmpty);
    },
  );

  testWidgets('Russian app actions fit the panel and retain the app name', (
    tester,
  ) async {
    final appsService = MockAppsService();
    when(appsService.isTileHidden(any)).thenReturn(false);
    when(appsService.categories).thenReturn([]);
    final app = fakeApp(packageName: 'test.app', name: 'My App', version: '1');
    when(appsService.applications).thenReturn([app]);
    await _pumpWidgetWithProviders(
      tester,
      appsService,
      null,
      app,
      locale: const Locale('ru'),
    );
    expect(find.text('My App'), findsOneWidget);
    expect(find.text('Добавить в раздел'), findsOneWidget);
    expect(find.text('Добавить в избранное'), findsNothing);
    expect(find.text('test.app'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'system package without launch activity opens details without Open action',
    (tester) async {
      final apps = MockAppsService();
      when(apps.isTileHidden(any)).thenReturn(false);
      when(apps.categories).thenReturn([]);
      final app =
          fakeApp(
              packageName: 'com.google.android.partnersetup',
              name: 'Google Partner Setup',
            )
            ..isSystem = true
            ..isLaunchable = false;
      await _pumpWidgetWithProviders(tester, apps, null, app);
      final l = AppLocalizations.of(
        tester.element(find.byType(ApplicationInfoPanel)),
      )!;
      expect(find.text(app.packageName), findsOneWidget);
      expect(find.text(l.open), findsNothing);
      await tester.scrollUntilVisible(find.text(l.appInfo), 150);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l.appInfo));
      await tester.tap(find.text(l.appInfo));
      await tester.pumpAndSettle();
      verify(apps.openAppInfo(app)).called(1);
    },
  );

  testWidgets('header loads the app icon without a broken image placeholder', (
    tester,
  ) async {
    final apps = MockAppsService();
    when(apps.isTileHidden(any)).thenReturn(false);
    when(apps.categories).thenReturn([]);
    final app = fakeApp(packageName: 'sample', name: 'Sample');
    await _pumpWidgetWithProviders(
      tester,
      apps,
      null,
      app,
      iconBytes: kTransparentImage,
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsNothing);
    verify(apps.getAppIcon(app.packageName)).called(1);
  });

  for (final onRight in [false, true]) {
    testWidgets(
      'category picker stays beside info and Back restores focus; right=$onRight',
      (tester) async {
        final apps = MockAppsService();
        when(apps.isTileHidden(any)).thenReturn(false);
        when(apps.categories).thenReturn([]);
        final app = fakeApp(packageName: 'sample', name: 'Sample');
        final all = fakeCategory(name: 'Renamed catalog')
          ..systemKey = 'all_apps';
        final existing = fakeCategory(name: 'Existing')..applications.add(app);
        final target = fakeCategory(name: 'New section');
        when(apps.categories).thenReturn([all, existing, target]);
        when(apps.addToCategory(app, target)).thenAnswer((_) async {
          target.applications.add(app);
        });
        await _pumpWidgetWithProviders(
          tester,
          apps,
          existing,
          app,
          asDialog: true,
          onRight: onRight,
        );
        final l = AppLocalizations.of(
          tester.element(find.byType(ApplicationInfoPanel)),
        )!;
        await tester.tap(find.text(l.addToCategory));
        await tester.pumpAndSettle();
        expect(find.byType(ApplicationInfoPanel), findsOneWidget);
        expect(find.byType(AddToCategoryDialog), findsOneWidget);
        expect(find.text('Renamed catalog'), findsNothing);
        expect(find.text('Existing'), findsNothing);
        Finder surface(Finder panel) => find
            .descendant(
              of: panel,
              matching: find.byWidgetPredicate(
                (w) => w is Material && w.elevation == 16,
              ),
            )
            .first;
        final info = tester.getRect(
          surface(find.byType(SidePanelDialog).first),
        );
        final picker = tester.getRect(
          surface(find.byType(SidePanelDialog).last),
        );
        expect(
          onRight ? picker.right <= info.left : info.right <= picker.left,
          isTrue,
        );
        expectSinglePanelBackdrop(tester);
        expect(
          Focus.of(tester.element(find.text('New section'))).hasPrimaryFocus,
          isTrue,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(AddToCategoryDialog), findsNothing);
        expect(find.byType(ApplicationInfoPanel), findsOneWidget);
        expect(
          Focus.of(tester.element(find.text(l.addToCategory))).hasPrimaryFocus,
          isTrue,
        );
        await tester.tap(find.text(l.addToCategory));
        await tester.pumpAndSettle();
        await tester.tap(find.text('New section'));
        await tester.pumpAndSettle();
        verify(apps.addToCategory(app, target)).called(1);
        expect(find.byType(AddToCategoryDialog), findsNothing);
        expect(find.byType(ApplicationInfoPanel), findsOneWidget);
        expect(
          Focus.of(tester.element(find.text(l.addToCategory))).hasPrimaryFocus,
          isTrue,
        );
      },
    );
  }

  for (final noSections in [false, true]) {
    testWidgets(
      'no eligible sections shows a notice without opening picker; empty=$noSections',
      (tester) async {
        final apps = MockAppsService();
        when(apps.isTileHidden(any)).thenReturn(false);
        when(apps.categories).thenReturn([]);
        final app = fakeApp(packageName: 'sample', name: 'Sample');
        when(apps.categories).thenReturn(
          noSections
              ? []
              : [
                  fakeCategory(name: 'Renamed catalog')..systemKey = 'all_apps',
                  fakeCategory(name: 'Existing')..applications.add(app),
                ],
        );
        await _pumpWidgetWithProviders(
          tester,
          apps,
          null,
          app,
          asDialog: true,
          onRight: noSections,
        );
        final l = AppLocalizations.of(
          tester.element(find.byType(ApplicationInfoPanel)),
        )!;
        await tester.tap(find.text(l.addToCategory));
        await tester.pumpAndSettle();
        expect(find.byType(AddToCategoryDialog), findsNothing);
        expect(find.byType(ApplicationInfoPanel), findsOneWidget);
        expect(find.text(l.noAvailableCategories), findsOneWidget);
        expectSinglePanelBackdrop(tester);
        final noticeX = tester.getCenter(find.text(l.noAvailableCategories)).dx;
        final panelX = tester.getCenter(find.byType(SidePanelDialog)).dx;
        expect(noSections ? noticeX < panelX : noticeX > panelX, isTrue);
        await tester.pump(const Duration(seconds: 5));
      },
    );
  }

  testWidgets('first action receives focus and outlines follow the accent', (
    tester,
  ) async {
    final appsService = MockAppsService();
    when(appsService.isTileHidden(any)).thenReturn(false);
    when(appsService.categories).thenReturn([]);
    final app = fakeApp(packageName: 'sample.app', name: 'Sample');
    const accent = Color(0xffe91e63);
    await _pumpWidgetWithProviders(
      tester,
      appsService,
      null,
      app,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: accent,
          onSurface: Colors.white,
        ),
      ),
    );
    final l = AppLocalizations.of(
      tester.element(find.byType(ApplicationInfoPanel)),
    )!;
    expect(
      Focus.of(tester.element(find.text(l.addToCategory))).hasPrimaryFocus,
      isTrue,
    );
    BorderSide outline(String label) {
      final containers = tester.widgetList<Container>(
        find.ancestor(of: find.text(label), matching: find.byType(Container)),
      );
      final decoration = containers
          .map((widget) => widget.decoration)
          .whereType<BoxDecoration>()
          .first;
      return (decoration.border as Border?)?.top ?? BorderSide.none;
    }

    expect(outline(l.addToCategory).color, accent);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text(l.hide))).hasPrimaryFocus, isTrue);
    expect(outline(l.addToCategory).color.a, 0);
    expect(outline(l.hide).color, accent);
  });

  for (final key in ['all_apps', 'tv_apps', 'other_apps']) {
    testWidgets('info from $key removes manual membership and restores focus', (
      tester,
    ) async {
      final apps = MockAppsService();
      when(apps.isTileHidden(any)).thenReturn(false);
      final app = fakeApp(packageName: 'sample', name: 'Sample');
      final automatic = fakeCategory(name: 'Automatic')..systemKey = key;
      automatic.applications.add(app);
      final favorite = Category(id: 4, name: 'Favorites')
        ..systemKey = 'favorites'
        ..visible = false;
      // Persisted membership must remain removable even when the tile is filtered.
      app.categoryOrders[favorite.id] = 0;
      when(
        apps.categories,
      ).thenReturn([automatic, favorite, Category(id: 5, name: 'Unrelated')]);
      when(apps.removeFromCategory(app, favorite)).thenAnswer((_) async {
        app.categoryOrders.remove(favorite.id);
      });
      await _pumpWidgetWithProviders(
        tester,
        apps,
        automatic,
        app,
        asDialog: true,
        onRight: key == 'tv_apps',
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(ApplicationInfoPanel)),
      )!;
      await tester.tap(find.text(l.removeFromCategory));
      await tester.pumpAndSettle();
      expect(find.text('Automatic'), findsNothing);
      expect(find.text('Unrelated'), findsNothing);
      expect(find.text(l.favorites), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        Focus.of(tester.element(find.text(l.removeFromCategory)))
            .hasPrimaryFocus,
        isTrue,
      );
      await tester.tap(find.text(l.removeFromCategory));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.favorites));
      await tester.pumpAndSettle();
      verify(apps.removeFromCategory(app, favorite)).called(1);
      expect(find.byType(ApplicationInfoPanel), findsOneWidget);
      expect(find.text(l.removeFromCategory), findsOneWidget);
      await tester.tap(find.text(l.removeFromCategory));
      await tester.pumpAndSettle();
      expect(find.byType(AddToCategoryDialog), findsNothing);
      expect(find.text(l.noRemovableCategories), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets(
    'All Apps has no direct automatic removal action but keeps global Hide',
    (tester) async {
      final appsService = MockAppsService();
      when(appsService.isTileHidden(any)).thenReturn(false);
      when(appsService.categories).thenReturn([]);
      final app = fakeApp(packageName: 'sample.app', name: 'Sample');
      final category = fakeCategory(name: 'Renamed catalog')
        ..systemKey = 'all_apps';
      when(appsService.hideApplication(app)).thenAnswer((_) async {});
      await _pumpWidgetWithProviders(tester, appsService, category, app);
      final l = AppLocalizations.of(
        tester.element(find.byType(ApplicationInfoPanel)),
      )!;
      expect(find.text(l.removeFrom(category.name)), findsNothing);
      await tester.ensureVisible(find.text(l.hide));
      await tester.tap(find.text(l.hide));
      await tester.pumpAndSettle();
      verify(appsService.hideApplication(app)).called(1);
      verifyNever(appsService.removeFromCategory(any, any));
    },
  );

  testWidgets("'Open' calls launchApp on AppsService", (tester) async {
    final appsService = MockAppsService();
    when(appsService.isTileHidden(any)).thenReturn(false);
    when(appsService.categories).thenReturn([]);
    when(appsService.launchApp(any)).thenAnswer((_) async => true);
    final app = fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    );
    when(appsService.applications).thenReturn([app]);
    await _pumpWidgetWithProviders(tester, appsService, null, app);

    final finder = find.text("Open");
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    verify(appsService.launchApp(app));
  });

  testWidgets("'Hide' calls AppsService", (tester) async {
    final appsService = MockAppsService();
    when(appsService.isTileHidden(any)).thenReturn(false);
    when(appsService.categories).thenReturn([]);
    when(appsService.launchApp(any)).thenAnswer((_) async => true);
    final category = fakeCategory(name: "Category 1", order: 0);
    final app = fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    );
    category.applications.add(app);
    when(appsService.launcherSections).thenReturn([category]);
    when(appsService.applications).thenReturn([]);
    await _pumpWidgetWithProviders(tester, appsService, category, app);

    final finder = find.text("Hide");
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    verify(appsService.hideApplication(app));
  });

  testWidgets("'Remove from...' calls AppsService", (tester) async {
    final appsService = MockAppsService();
    when(appsService.isTileHidden(any)).thenReturn(false);
    when(appsService.categories).thenReturn([]);
    when(appsService.launchApp(any)).thenAnswer((_) async => true);
    final category = fakeCategory(name: "Category 1", order: 0);
    final app = fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    );
    category.applications.add(app);
    when(appsService.launcherSections).thenReturn([category]);
    when(appsService.applications).thenReturn([]);
    await _pumpWidgetWithProviders(tester, appsService, category, app);

    final finder = find.text("Remove from Category 1");
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    verify(appsService.removeFromCategory(app, category));
  });

  testWidgets("'App info' calls AppsService", (tester) async {
    final appsService = MockAppsService();
    when(appsService.isTileHidden(any)).thenReturn(false);
    when(appsService.categories).thenReturn([]);
    when(appsService.launchApp(any)).thenAnswer((_) async => true);
    final category = fakeCategory(name: "Category 1", order: 0);
    final app = fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    );
    category.applications.add(app);
    when(appsService.launcherSections).thenReturn([category]);
    when(appsService.applications).thenReturn([]);
    await _pumpWidgetWithProviders(tester, appsService, category, app);

    final finder = find.text("Application info");
    await tester.scrollUntilVisible(finder, 150);
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    verify(appsService.openAppInfo(app));
  });

  testWidgets("'Uninstall' calls AppsService", (tester) async {
    final appsService = MockAppsService();
    when(appsService.isTileHidden(any)).thenReturn(false);
    when(appsService.categories).thenReturn([]);
    when(appsService.launchApp(any)).thenAnswer((_) async => true);
    final category = fakeCategory(name: "Category 1", order: 0);
    final app = fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    );
    category.applications.add(app);
    when(appsService.launcherSections).thenReturn([category]);
    when(appsService.applications).thenReturn([]);
    await _pumpWidgetWithProviders(tester, appsService, category, app);

    final finder = find.text("Uninstall");
    await tester.scrollUntilVisible(finder, 200);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    verify(appsService.uninstallApp(app));
  });
}

class _ObservableAppsService extends MockAppsService {
  final _listeners = <VoidCallback>{};
  @override
  void addListener(VoidCallback? listener) {
    if (listener != null) _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback? listener) => _listeners.remove(listener);
  @override
  void notifyListeners() {
    for (final listener in _listeners.toList()) {
      listener();
    }
  }
}

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  AppsService appsService,
  Category? category,
  App application, {
  Locale locale = const Locale('en'),
  ThemeData? theme,
  Uint8List? iconBytes,
  bool asDialog = false,
  bool? onRight,
}) async {
  when(appsService.isAppInFavorites(application)).thenReturn(false);
  when(appsService.hasCustomBanner(application.packageName))
      .thenAnswer((_) async => false);
  when(appsService.getAppIcon(application.packageName))
      .thenAnswer((_) async => iconBytes ?? Uint8List(0));
  when(appsService.getAppBanner(application.packageName))
      .thenAnswer((_) async => Uint8List(0));

  final settings = MockSettingsService();
  when(settings.accentColorHex).thenReturn(ACCENT_COLOR_PURPLE);
  when(settings.settingsMenuOnRight).thenReturn(onRight ?? false);
  when(settings.appKeyClickEnabled).thenReturn(false);
  Widget info() =>
      ApplicationInfoPanel(category: category, application: application);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppsService>.value(value: appsService),
        if (onRight != null)
          ChangeNotifierProvider<SettingsService>.value(value: settings),
      ],
      builder: (_, _) => MaterialApp(
        theme: theme,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: asDialog
            ? Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showLauncherDialog<void>(
                      context: context,
                      builder: (_) => info(),
                    ),
                    child: const Text('Open info'),
                  ),
                ),
              )
            : info(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (asDialog) {
    await tester.tap(find.text('Open info'));
    await tester.pumpAndSettle();
  }
}
