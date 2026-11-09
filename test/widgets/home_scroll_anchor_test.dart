import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/widgets/home_scroll_anchor.dart';

void main() {
  testWidgets('insertion and removal above anchor correct before the first paint', (tester) async {
    final controller = HomeScrollController();
    final anchor = GlobalKey();
    final height = ValueNotifier(400.0);
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<double>(valueListenable: height,
        builder: (_, value, _) => SingleChildScrollView(controller: controller,
          child: Column(children: [SizedBox(height: value),
            SizedBox(key: anchor, height: 100), const SizedBox(height: 1600)])))));
    controller.jumpTo(300);
    await tester.pump();
    controller.anchorTo(anchor);
    final original = tester.getTopLeft(find.byKey(anchor)).dy;
    for (final value in [700.0, 250.0, 450.0]) {
      height.value = value;
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(anchor)).dy, original);
      expect(controller.offset, value - original);
    }
    controller.canPreserve = () => false;
    height.value = 550;
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(anchor)).dy, original + 100);
    await tester.pumpWidget(const SizedBox());
    controller.dispose(); height.dispose();
  });
}
