import 'dart:convert';

import 'package:flauncher/theme/interface_style.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/panel_overlay_anchors.dart';
import 'package:flauncher/widgets/top_panel_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'publishes resolved panel style independently of widget centers',
    (tester) async {
      final calls = <MethodCall>[];
      const channel = MethodChannel('me.efesser.flauncher/method');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      Future<void> pump(int color, {bool publish = true}) => tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [InterfaceSkin(InterfaceStyle.glass)],
          ),
          home: PanelAppearanceScope(
            appearance: TileAppearance({
              'panelFont': 'monospace',
              'panelTextSize': 20,
              'panelTextColor': color,
              'panelTextBackgroundOpacity': .5,
            }),
            child: PanelOverlayAnchors(
              widgets: const {},
              publishAppearance: publish,
              child: const SizedBox(),
            ),
          ),
        ),
      );

      await pump(0xffabc123, publish: false);
      expect(calls, isEmpty);
      await pump(0xffabc123);
      expect(calls.single.method, 'setOverlayPanelAppearance');
      final style = jsonDecode(calls.single.arguments as String) as Map;
      expect(style['foreground'], 0xffabc123);
      expect(style['textSize'], 20);
      expect(style['gradientEnd'], 0x80242935);
      expect(style['background'], isNot(style['gradientEnd']));
      expect(style['font'], 'mono.ttf');
      await pump(0xffabc123);
      expect(calls, hasLength(1));
      await pump(0xffabcdef);
      expect(calls, hasLength(2));
      expect(
        jsonDecode(calls.last.arguments as String)['foreground'],
        0xffabcdef,
      );
    },
  );

  testWidgets(
    'reports physical centers when layout moves and stops when disabled',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final calls = <MethodCall>[];
      const channel = MethodChannel('me.efesser.flauncher/method');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      Future<void> pump(Alignment alignment, {bool enabled = true}) =>
          tester.pumpWidget(
            PanelOverlayAnchors(
              widgets: {if (enabled) 'volume': key},
              child: Align(
                alignment: alignment,
                child: SizedBox(key: key, width: 40, height: 20),
              ),
            ),
          );

      await pump(Alignment.topRight);
      expect(calls.single.method, 'setOverlayWidgetCenter');
      expect(calls.single.arguments, {'id': 'volume', 'x': 760, 'y': 20});
      await pump(Alignment.topRight);
      expect(calls, hasLength(1));

      await pump(Alignment.bottomLeft);
      expect(calls.last.arguments, {'id': 'volume', 'x': 40, 'y': 580});
      await pump(Alignment.topLeft, enabled: false);
      expect(calls, hasLength(2));
    },
  );
}
