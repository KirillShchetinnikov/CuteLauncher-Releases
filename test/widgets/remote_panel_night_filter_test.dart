import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/night_mode_service.dart';

void main() {
  const channel = MethodChannel('cutelauncher/night');
  const events = 'cutelauncher/night_panel_state';

  testWidgets(
    'panel follows foreground exclusions and preserves transparent pixels',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        nightModeKey: jsonEncode(
          const NightModeConfiguration(
            enabled: true,
            dim: 50,
            warmth: 30,
            tclScheduled: false,
          ).toJson(),
        ),
      });
      final calls = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return {
          'permission': true,
          'visible': true,
          'excluded': false,
          'presentationReady': true,
        };
      });
      messenger.setMockMethodCallHandler(
        const MethodChannel(events),
        (_) async => null,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('cutelauncher/tcl_blue_light'),
        (_) async => {'status': 'unsupported'},
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
        messenger.setMockMethodCallHandler(const MethodChannel(events), null);
        messenger.setMockMethodCallHandler(
          const MethodChannel('cutelauncher/tcl_blue_light'),
          null,
        );
      });
      final service = NightModeService(
        await SharedPreferences.getInstance(),
        remotePanel: true,
      );
      final boundary = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: boundary,
              child: SizedBox(
                width: 100,
                height: 100,
                child: ListenableBuilder(
                  listenable: service,
                  builder: (_, _) => NightModeFilter(
                    service: service,
                    child: const Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: ColoredBox(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        calls,
        isNot(contains('configure')),
        reason: 'Opening a panel must not reconfigure the shared filter',
      );
      expect(service.systemFilter, isTrue);
      expect(service.localFilter, isFalse);
      expect(find.byType(ColorFiltered), findsOneWidget);

      Future<List<int>> pixel(int x, int y) async =>
          (await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 1);
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            final result = List<int>.generate(
              4,
              (i) => bytes.getUint8((y * 100 + x) * 4 + i),
            );
            image.dispose();
            return result;
          }))!;
      expect(
        (await pixel(60, 60))[3],
        0,
        reason: 'The HDMI/background area must stay transparent',
      );
      final filtered = await pixel(10, 10);
      expect(filtered[0], closeTo(128, 1));
      expect(filtered[1], lessThan(filtered[0]));
      expect(filtered[3], 255);

      Future<void> state({
        required bool excluded,
        bool ready = true,
        bool visible = false,
      }) async {
        messenger.handlePlatformMessage(
          events,
          const StandardMethodCodec().encodeSuccessEnvelope({
            'visible': visible,
            'excluded': excluded,
            'presentationReady': ready,
          }),
          (_) {},
        );
        await tester.pump();
        await tester.pump();
      }

      // An excluded HDMI or app suppresses both dimming and warmth on the panel.
      await state(excluded: true);
      expect(service.active, isFalse);
      expect(service.panelFilter, isFalse);
      expect(await pixel(10, 10), [255, 255, 255, 255]);
      expect((await pixel(60, 60))[3], 0);
      await state(excluded: false, ready: false);
      expect(service.panelFilter, isFalse);
      // Local color conversion also works when no native fullscreen window exists.
      await state(excluded: false);
      expect(find.byType(ColorFiltered), findsOneWidget);
      expect(service.panelFilter, isTrue);
      expect(service.localFilter, isFalse);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => ListenableBuilder(
            listenable: service,
            builder: (_, _) => NightModeFilter(service: service, child: child!),
          ),
          navigatorKey: navigator,
          home: const Text('panel'),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Text('settings')),
      );
      await tester.pumpAndSettle();
      await state(excluded: true);
      expect(find.text('settings'), findsOneWidget);
      expect(navigator.currentState!.canPop(), isTrue);
      await state(excluded: false, visible: true);
      expect(find.text('settings'), findsOneWidget);
      await service.configure(service.configuration.copyWith(enabled: false));
      await tester.pump();
      expect(service.panelFilter, isFalse);
      expect(find.text('settings'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
    },
  );
}
