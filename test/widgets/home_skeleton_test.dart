import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/app_content_row.dart';
import 'package:flauncher/widgets/home_skeleton.dart';
import 'package:provider/provider.dart';
import '../flauncher_test.dart' as fixtures;
import '../support/design_fixture.dart';

void main() {
  for (final rtl in [false, true]) {
    testWidgets('static Home skeleton ${rtl ? 'rtl' : 'ltr'}', (tester) async {
      await loadDesignFonts(tester);
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      await tester.pumpWidget(ChangeNotifierProvider<SettingsService>.value(
        value: fixtures.mkSettingsService(),
        child: MaterialApp(theme: ThemeData.dark().copyWith(
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: RepaintBoundary(key: boundary, child: Scaffold(
              body: SingleChildScrollView(child: Column(children: [
                for (final ratio in [16 / 9, 2 / 3, 1.0])
                  ContentPreviewRow.loading(title: 'Продолжить просмотр',
                    style: const TileAppearance({'size': 96}),
                    aspectRatio: ratio, reserveDescription: true),
              ])),
            ))))));
      await tester.pumpAndSettle();
      expect(find.byType(HomeSkeletonRow), findsNWidgets(3));
      expect(tester.binding.hasScheduledFrame, isFalse);
      await expectLater(find.byKey(boundary), matchesGoldenFile(
        '../design/goldens/home-skeleton-${rtl ? 'rtl' : 'ltr'}.png'));
      await tester.pump(const Duration(seconds: 5));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('numeric skeleton keeps the width when data arrives', (tester) async {
    final loading = ValueNotifier(true);
    await tester.pumpWidget(MaterialApp(home: Center(child: ValueListenableBuilder<bool>(
      valueListenable: loading, builder: (_, value, _) => HomeSkeletonValue(
        sample: 'CPU 100%', loading: value, child: const Text('CPU 5%'))))));
    final width = tester.getSize(find.byType(HomeSkeletonValue)).width;
    loading.value = false;
    await tester.pump();
    expect(tester.getSize(find.byType(HomeSkeletonValue)).width, width);
    await tester.pumpWidget(const SizedBox()); loading.dispose();
  });
}
