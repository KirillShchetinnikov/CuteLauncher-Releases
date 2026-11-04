import 'dart:ui' show PointerDeviceKind;

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
import 'package:flauncher/widgets/network_summary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  testWidgets(
    'network settings stay accessible without focus or hover tooltip',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final network = MockNetworkService();
      when(network.getSummary()).thenAnswer((_) async => {});
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NetworkSummaryDialog(
              service: network,
              anchor: const Rect.fromLTWH(20, 40, 40, 40),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = tester.widget<MenuHeaderAction>(
        find.byType(MenuHeaderAction),
      );
      final button = find.byType(IconButton);
      expect(FocusManager.instance.primaryFocus!.hasFocus, isTrue);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(button));
      addTearDown(mouse.removePointer);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text(action.tooltip), findsNothing);
      expect(find.bySemanticsLabel(action.tooltip), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      verify(network.openWifiSettings()).called(1);
      await tester.pumpWidget(const SizedBox());
    semantics.dispose();
    },
  );
}
