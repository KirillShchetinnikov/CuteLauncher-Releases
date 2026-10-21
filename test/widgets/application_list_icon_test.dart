import 'dart:typed_data';

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/application_list_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import '../mocks.mocks.dart';

void main() {
  testWidgets('loads package icons and keeps the request across rebuilds', (
    tester,
  ) async {
    final apps = MockAppsService();
    when(apps.getAppIcon(any)).thenAnswer((_) async => kTransparentImage);
    Widget page(String package) => ChangeNotifierProvider<AppsService>.value(
      value: apps,
      child: MaterialApp(home: ApplicationListIcon(packageName: package)),
    );
    await tester.pumpWidget(page('first'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    await tester.pumpWidget(page('first'));
    await tester.pumpAndSettle();
    verify(apps.getAppIcon('first')).called(1);
    await tester.pumpWidget(page('second'));
    await tester.pumpAndSettle();
    verify(apps.getAppIcon('second')).called(1);
    expect(find.byType(Image), findsOneWidget);
  });

  for (final failure in ['missing', 'empty', 'corrupt']) {
    testWidgets('uses fallback for $failure icon', (tester) async {
      final apps = MockAppsService();
      when(apps.getAppIcon(any)).thenAnswer((_) async {
        if (failure == 'missing') throw StateError('Package removed');
        return failure == 'empty'
            ? Uint8List(0)
            : Uint8List.fromList([1, 2, 3]);
      });
      await tester.pumpWidget(
        ChangeNotifierProvider<AppsService>.value(
          value: apps,
          child: const MaterialApp(
            home: ApplicationListIcon(packageName: 'saved.package'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.android), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
