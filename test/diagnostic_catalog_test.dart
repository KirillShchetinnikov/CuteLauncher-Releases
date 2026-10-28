import 'dart:convert';

import 'package:flauncher/diagnostic_catalog.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'mocks.mocks.dart';

void main() {
  test('installed packages retain matching identifiers and state, reject unlisted data', () {
    final apps = MockAppsService();
    final app = App(
      packageName: 'example.tv',
      name: 'TV',
      version: '1',
      hidden: true,
    );
    when(apps.applications).thenReturn([app]);
    final report = diagnosticApplications([
      {
        'packageName': 'example.tv',
        'name': 'TV',
        'version': '1.2',
        'versionCode': 42,
        'system': true,
        'launchable': false,
        'enabled': false,
        'enabledSetting': 3,
        'action': 'https://secret.example/token',
        'password': 'secret',
      },
      {'packageName': '/private/file'},
      {'packageName': 'example.tv'},
    ], apps);
    final row = (report['applications'] as List).single as Map;
    expect(row['packageName'], 'example.tv');
    expect(row['enabledSetting'], 3);
    expect(row['hidden'], isTrue);
    expect(row['system'], isTrue);
    expect(row['enabled'], isFalse);
    expect(row['versionCode'], 42);
    expect(report['skippedCount'], 2);
    expect(jsonEncode(report), isNot(contains('secret')));
  });

  test('missing catalog is distinguished from an empty installed catalog', () {
    expect(diagnosticApplications(null, null)['status'], 'unavailable');
    expect(diagnosticApplications([], null)['status'], 'complete');
    expect(diagnosticSections(null, null)['status'], 'unavailable');
  });

  test('large inventories are bounded explicitly and free-text labels are redacted', () {
    final report = diagnosticApplications(
      List.generate(
        diagnosticAppLimit + 1,
        (i) => {'packageName': 'example.app$i', 'name': 'user@example.com'},
      ),
      null,
    );
    expect(report['truncated'], isTrue);
    expect((report['applications'] as List).length, diagnosticAppLimit);
    expect(jsonEncode(report), isNot(contains('user@example.com')));
  });

  test('section snapshot preserves empty, hidden, renamed and manual filtered membership', () {
    final apps = MockAppsService();
    final settings = MockSettingsService();
    final app = App(
      packageName: 'example.tv',
      name: 'TV',
      version: '1',
      hidden: true,
    )..categoryOrders[5] = 0;
    final automatic = Category(
      id: 1,
      name: 'Renamed TV',
      systemKey: 'tv_apps',
      order: 0,
    );
    final manual = Category(
      id: 5,
      name: 'My section',
      order: 2,
      visible: false,
    );
    when(apps.initialized).thenReturn(true);
    when(apps.applications).thenReturn([app]);
    when(apps.launcherSections).thenReturn([
      automatic,
      LauncherSpacer(id: 2, order: 1, height: 99),
      manual,
    ]);
    when(settings.showContinueWatching).thenReturn(true);
    when(settings.continueWatchingOrder).thenReturn(2);
    final report = diagnosticSections(apps, settings);
    final rows = report['sections'] as List;
    expect(rows[0]['name'], 'Renamed TV');
    expect(rows[0]['systemKey'], 'tv_apps');
    expect(rows[0]['applications'], isEmpty);
    expect(rows[1]['type'], 'spacer');
    expect(rows[1]['height'], 99);
    expect(rows[2]['visible'], isFalse);
    expect(rows[2]['storedOrder'], ['example.tv']);
    expect(report['continueWatching'], {'enabled': true, 'order': 2});
    app.categoryOrders.clear();
    manual.name = 'Changed later';
    expect(rows[2]['name'], 'My section');
    expect(rows[2]['storedOrder'], ['example.tv']);
  });

  test('large section layouts and membership are explicitly bounded', () {
    final apps = MockAppsService();
    when(apps.initialized).thenReturn(true);
    when(apps.applications).thenReturn([]);
    final manyApps = List.generate(
      2000,
      (i) => App(
        packageName: 'example.app$i',
        name: 'App',
        version: '1',
        hidden: false,
      ),
    );
    final sections = List.generate(
      diagnosticSectionLimit + 1,
      (i) =>
          Category(id: i, name: 'Section')
            ..applications.addAll(i < 6 ? manyApps : <App>[]),
    );
    when(apps.launcherSections).thenReturn(sections);
    final report = diagnosticSections(apps, null);
    final rows = report['sections'] as List;
    expect(report['truncated'], isTrue);
    expect(rows.length, diagnosticSectionLimit);
    expect(
      rows.fold<int>(0, (n, row) => n + (row['applications'] as List).length),
      diagnosticMembershipLimit,
    );
  });
}
