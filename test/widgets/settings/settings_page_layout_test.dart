import 'package:flauncher/widgets/settings/settings_page_layout.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('entry focuses first control despite later autofocus', (
    tester,
  ) async {
    final first = FocusNode();
    final last = FocusNode();
    addTearDown(first.dispose);
    addTearDown(last.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPageLayout(
            title: const Text('Menu'),
            child: ListView(
              children: [
                FocusableSettingsTile(
                  focusNode: first,
                  title: const Text('First'),
                  onPressed: () {},
                ),
                FocusableSettingsTile(
                  focusNode: last,
                  autofocus: true,
                  title: const Text('Last'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(first.hasFocus, isTrue);
  });
  testWidgets('remote reads text before, between and after controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(350, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final first = FocusNode();
    final last = FocusNode();
    addTearDown(first.dispose);
    addTearDown(last.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPageLayout(
            title: const Text('Настройки'),
            child: ListView(
              children: [
                const SizedBox(height: 250, child: Text('Вводное пояснение')),
                FocusableSettingsTile(
                  focusNode: first,
                  autofocus: true,
                  title: const Text('Первая кнопка'),
                  onPressed: () {},
                ),
                const SizedBox(
                  height: 650,
                  child: Text('Пояснение между кнопками'),
                ),
                FocusableSettingsTile(
                  focusNode: last,
                  title: const Text('Последняя кнопка'),
                  onPressed: () {},
                ),
                const SizedBox(
                  height: 650,
                  child: Text('Заключительное пояснение'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Первая кнопка'));
    first.requestFocus();
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    final initial = position.pixels;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(position.pixels, lessThan(initial));
    for (var i = 0; i < 30; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
    }
    expect(position.pixels, position.minScrollExtent);
    var reachedLast = false;
    for (var i = 0; i < 40; i++) {
      final before = position.pixels;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(position.pixels - before, lessThanOrEqualTo(400));
      reachedLast |= last.hasFocus;
    }
    expect(reachedLast, isTrue);
    expect(position.pixels, position.maxScrollExtent);
    for (var i = 0; i < 40; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
    }
    expect(position.pixels, position.minScrollExtent);
    expect(first.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final direction in TextDirection.values) {
    testWidgets('scrollbar has a separate left gutter in $direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: direction,
              child: SettingsPageLayout(
                title: const Text('Настройки'),
                child: ListView(
                  children: [
                    for (var i = 0; i < 30; i++)
                      FocusableSettingsTile(
                        autofocus: i == 0,
                        title: Text('Настройка $i'),
                        onPressed: () {},
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
      final outer = tester.getRect(find.byType(Scrollbar));
      final list = tester.getRect(find.byType(ListView));
      final tile = tester.getRect(find.byType(FocusableSettingsTile).first);
      expect(scrollbar.scrollbarOrientation, ScrollbarOrientation.left);
      expect(list.left - outer.left, 14);
      expect(tile.left, greaterThanOrEqualTo(list.left));
      expect(tile.left - outer.left, greaterThan(scrollbar.thickness!));
      expect(list.right, outer.right);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('remote scroll and focus survive a rebuild of the page header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(350, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var activated = -1;
    final title = ValueNotifier('Настройки');
    addTearDown(title.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<String>(
            valueListenable: title,
            builder: (_, value, _) => SettingsPageLayout(
              title: Text(value),
              child: ListView(
                children: [
                  for (var i = 0; i < 20; i++)
                    FocusableSettingsTile(
                      key: ValueKey(i),
                      autofocus: i == 0,
                      title: Text('Длинная подпись телевизионной настройки $i'),
                      onPressed: () => activated = i,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 15; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    final state = tester.state<ScrollableState>(find.byType(Scrollable));
    final offset = state.position.pixels;
    expect(offset, greaterThan(0));
    title.value = 'Обновлённый заголовок';
    await tester.pumpAndSettle();
    expect(state.position.pixels, offset);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activated, 15);
    expect(
      tester.getRect(find.byKey(const ValueKey(15))).bottom,
      lessThanOrEqualTo(540),
    );
    expect(tester.widget<Scrollbar>(find.byType(Scrollbar)).interactive, false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long RTL header wraps with large text without clipping', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 340,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
                child: SettingsPageLayout(
                  title: const Text(
                    'Настройки интерфейса и оформления главного экрана',
                  ),
                  child: ListView(children: const [Text('Содержимое')]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(
            find.text('Настройки интерфейса и оформления главного экрана'),
          )
          .height,
      greaterThan(30),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('lazy list entry precedes eagerly attached reset footer', (
    tester,
  ) async {
    final first = FocusNode(debugLabel: 'first');
    final reset = FocusNode(debugLabel: 'reset');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPageLayout(
            title: const Text('Menu'),
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => FocusableSettingsTile(
                      focusNode: first,
                      title: const Text('First'),
                      onPressed: () {},
                    ),
                    childCount: 1,
                  ),
                ),
                SliverToBoxAdapter(
                  child: FocusableSettingsTile(
                    focusNode: reset,
                    title: const Text('Reset'),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(first.hasFocus, isTrue);
    expect(reset.hasFocus, isFalse);
    await tester.pumpWidget(const SizedBox());
    first.dispose();
    reset.dispose();
  });
}
