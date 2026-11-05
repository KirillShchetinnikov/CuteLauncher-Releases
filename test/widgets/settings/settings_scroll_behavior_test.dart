import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:ui' as ui;

import 'package:flauncher/widgets/settings/settings_scroll_behavior.dart';
import 'package:flauncher/widgets/settings/settings_page_layout.dart';
import 'package:flauncher/widgets/settings/settings_panel_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<bool> paintsThumb(WidgetTester tester) async {
    final raw = find.byWidgetPredicate((widget) => widget is RawScrollbar);
    final painter = tester
        .widget<CustomPaint>(
          find.descendant(
            of: raw,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is CustomPaint &&
                  widget.foregroundPainter is ScrollbarPainter,
            ),
          ),
        )
        .foregroundPainter!;
    final size = tester.getSize(raw);
    return (await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.ceil(),
        size.height.ceil(),
      );
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      var visible = false;
      for (var i = 3; i < data.lengthInBytes; i += 4) {
        if (data.getUint8(i) != 0) {
          visible = true;
          break;
        }
      }
      image.dispose();
      picture.dispose();
      return visible;
    }))!;
  }

  for (final page in [false, true]) {
    testWidgets('scrollbar modes preserve scrolling; page=$page', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appearance = AppearanceService(prefs);
      addTearDown(appearance.dispose);
      final height = ValueNotifier(800.0);
      addTearDown(height.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appearance,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 250,
                  child: SettingsPanelStyle(
                    builder: (_) {
                      final content = SingleChildScrollView(
                        child: ValueListenableBuilder<double>(
                          valueListenable: height,
                          builder: (_, value, _) => SizedBox(
                            height: value,
                            child: const Text('Содержимое'),
                          ),
                        ),
                      );
                      return page
                          ? SettingsPageLayout(
                              title: const Text('Настройки'),
                              child: content,
                            )
                          : content;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scrollbar), findsOneWidget);
      final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
      expect(scrollbar.thumbVisibility, isTrue);
      expect(scrollbar.interactive, isFalse);
      expect(await paintsThumb(tester), isTrue);
      await tester.pump(const Duration(seconds: 10));
      expect(await paintsThumb(tester), isTrue);
      height.value = 20;
      await tester.pumpAndSettle();
      expect(await paintsThumb(tester), isFalse);
      height.value = 1000;
      await tester.pumpAndSettle();
      expect(await paintsThumb(tester), isTrue);
      await appearance.set('settingsScrollbarMode', 'onScroll');
      await tester.pumpAndSettle();
      expect(await paintsThumb(tester), isFalse);
      final reloaded = AppearanceService(prefs);
      expect(reloaded.appearance.settingsScrollbarMode, SettingsScrollbarMode.onScroll);
      reloaded.dispose();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(await paintsThumb(tester), isTrue);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(await paintsThumb(tester), isFalse);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(await paintsThumb(tester), isTrue);

      final beforeHiding = scrollable.position.pixels;
      await appearance.set('settingsScrollbarMode', 'hidden');
      await tester.pumpAndSettle();
      expect(await paintsThumb(tester), isFalse);
      expect(scrollable.position.pixels, beforeHiding);
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(await paintsThumb(tester), isFalse);
      expect(scrollable.position.pixels, greaterThan(beforeHiding));

      final offset = scrollable.position.pixels;
      await appearance.resetFields(['settingsScrollbarMode']);
      await tester.pumpAndSettle();
      expect(await paintsThumb(tester), isTrue);
      expect(scrollable.position.pixels, offset);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('loading and empty pages can attach and detach scrolling', (
    tester,
  ) async {
    final loaded = ValueNotifier(false);
    addTearDown(loaded.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 250,
            child: ValueListenableBuilder<bool>(
              valueListenable: loaded,
              builder: (_, value, _) => SettingsPageLayout(
                title: const Text('Страница'),
                child: value
                    ? ListView(children: const [SizedBox(height: 1000)])
                    : const Text('Пусто'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Scrollbar>(find.byType(Scrollbar)).thumbVisibility,
      isFalse,
    );
    for (final value in [true, false, true]) {
      loaded.value = value;
      await tester.pumpAndSettle();
      expect(
        tester.widget<Scrollbar>(find.byType(Scrollbar)).thumbVisibility,
        value,
      );
      expect(await paintsThumb(tester), value);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('horizontal content does not get an automatic scrollbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const SettingsScrollBehavior(),
        home: SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [SizedBox(width: 2000)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Scrollbar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
