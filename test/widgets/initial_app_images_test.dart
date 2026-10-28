import 'dart:async';

import 'package:flauncher/widgets/initial_app_images.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a hung image cannot keep the launcher hidden', (tester) async {
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
      child: InitialAppImages(child: Builder(builder: (context) {
        context.dependOnInheritedWidgetOfExactType<AppImagesReadiness>()!.register();
        return const SizedBox();
      })),
    ));
    await tester.pump();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('an offscreen image does not delay the first screen', (tester) async {
    await tester.pumpWidget(MediaQuery(data: const MediaQueryData(size: Size(800, 600)),
      child: Directionality(textDirection: TextDirection.ltr,
        child: InitialAppImages(child: SingleChildScrollView(child: Column(children: [
          const SizedBox(height: 900),
          Builder(builder: (context) {
            context.dependOnInheritedWidgetOfExactType<AppImagesReadiness>()!.register(context);
            return const SizedBox(height: 100);
          }),
        ]))),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('reveals tiles only after images and initial focus are ready', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    final focusReady = Completer<void>();
    VoidCallback? decoded;
    var calls = 0;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: InitialAppImages(
        onReady: () async {
          calls++;
          await focusReady.future;
          node.requestFocus();
          await WidgetsBinding.instance.endOfFrame;
        },
        child: Builder(builder: (context) {
          decoded ??= context.dependOnInheritedWidgetOfExactType<AppImagesReadiness>()!.register();
          return Focus(focusNode: node, child: const SizedBox());
        }),
      ),
    ));
    expect(calls, 0);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    decoded!();
    await tester.pump();
    expect(calls, 1);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    focusReady.complete();
    await tester.pumpAndSettle();
    expect(node.hasFocus, isTrue);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    decoded!();
    await tester.pump();
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
