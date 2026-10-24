import 'package:flauncher/providers/settings_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/theme/interface_style.dart';

void main() {
  testWidgets('glass rows allow native Manrope metrics for wrapped values', (tester) async {
    final loader = FontLoader('Manrope')..addFont(rootBundle.load('assets/fonts/manrope.ttf'));
    await loader.load();
    for (final scale in [1.0, 1.5]) {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: [const InterfaceSkin(InterfaceStyle.glass)]),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: Center(child: SizedBox(width: 300,
            child: DefaultTextStyle(
              style: const TextStyle(fontFamily: 'Manrope', fontSize: 16, height: 1.3),
              child: FocusableSettingsTile(
                title: const Text('Сортировать'),
                trailing: const Text('По частоте запусков'),
                onPressed: () {},
              ),
            ),
          ))),
        ),
      ));
      await tester.pumpAndSettle();
      final paragraph = tester.renderObject<RenderParagraph>(find.text('По частоте запусков'));
      final text = paragraph.text as TextSpan;
      final natural = TextPainter(
        text: TextSpan(text: text.text, style: text.style!.copyWith(height: kTextHeightNone)),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.linear(scale),
      )..layout(maxWidth: paragraph.size.width);
      expect(paragraph.size.height, greaterThanOrEqualTo(natural.height - .01));
      expect(paragraph.didExceedMaxLines, isFalse);
      natural.dispose();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('custom value rows align text and arrow to the right edge', (tester) async {
    Future<double> rightEdge(String value) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
        child: SizedBox(width: 320, child: FocusableSettingsTile(
          title: const Text('Выбор'),
          trailing: Text(value),
          onPressed: () {},
        )),
      ))));
      await tester.pumpAndSettle();
      final paragraph = tester.renderObject<RenderParagraph>(find.text(value));
      expect(paragraph.textAlign, TextAlign.end);
      expect(tester.takeException(), isNull);
      return tester.getRect(find.byIcon(Icons.chevron_right_rounded)).right;
    }

    final shortRight = await rightEdge('Да');
    expect(await rightEdge('Длинный выбранный вариант'), closeTo(shortRight, 0.01));
  });

  testWidgets('activation sound follows the saved opt-in preference', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    const channel = MethodChannel('me.efesser.flauncher/method');
    var clicks = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'playClickSound') clicks++;
      return null;
    });
    addTearDown(() {
      settings.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(home: Scaffold(body: FocusableSettingsTile(
        autofocus: true, title: const Text('Action'), onPressed: () {},
      ))),
    ));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(clicks, 0);
    await settings.setAppKeyClickEnabled(true);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(clicks, 1);
    await settings.setAppKeyClickEnabled(false);
    await tester.tap(find.text('Action'));
    expect(clicks, 1);
  });

  testWidgets(
      'Remote focus keeps card geometry and scrolls long labels into view',
      (tester) async {
    tester.view.physicalSize = const Size(350, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var activated = -1;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
          body: SingleChildScrollView(
              child: Column(children: [
        for (var index = 0; index < 10; index++)
          FocusableSettingsTile(
            key: ValueKey(index),
            autofocus: index == 0,
            leading: const Icon(Icons.settings),
            title: Text('Длинная подпись настройки телевизора $index'),
            onPressed: () => activated = index,
          ),
      ]))),
    ));
    await tester.pumpAndSettle();
    final firstSize = tester.getSize(find.byKey(const ValueKey(0)));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.byType(AnimatedContainer), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey(0))), firstSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(activated, 1);
    for (var index = 0; index < 8; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activated, 9);
    expect(tester.getRect(find.byKey(const ValueKey(9))).bottom,
        lessThanOrEqualTo(540));
    expect(tester.takeException(), isNull);
  });
}
