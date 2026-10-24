import 'dart:async';

import 'package:flauncher/widgets/initial_app_images.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
