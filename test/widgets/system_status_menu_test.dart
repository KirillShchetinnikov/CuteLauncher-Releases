import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/system_status_service.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
import 'package:flauncher/widgets/system_status_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  for (final waitBeforeScrolling in [false, true]) {
    for (final touch in [false, true]) {
      testWidgets('scroll ${touch ? 'by touch' : 'by remote'} keeps gutter and '
          'settings label hidden; wait=$waitBeforeScrolling', (tester) async {
        final semantics = tester.ensureSemantics();
        const channel = MethodChannel('cutelauncher/system_status');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (_) async => null,
        );
        final service = SystemStatusService();
        addTearDown(service.dispose);
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          );
        });
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: service,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: SystemStatusMenu(anchor: Rect.fromLTWH(20, 40, 40, 40)),
              ),
            ),
          ),
        );
        await tester.pump();
        final action = tester.widget<MenuHeaderAction>(
          find.byType(MenuHeaderAction),
        );
        final node = action.focusNode!;
        expect(node.hasFocus, isTrue);
        final hint = find.text(action.tooltip);
        if (waitBeforeScrolling) {
          await tester.pump(const Duration(seconds: 2));
          await tester.pump(const Duration(milliseconds: 200));
          expect(hint, findsNothing);
        }
        expect(find.bySemanticsLabel(action.tooltip), findsOneWidget);
        final view = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        final content = tester.getRect(find.byWidget(view.child!));
        final indicator = tester.getRect(find.byType(Scrollbar));
        expect(content.right, lessThanOrEqualTo(indicator.right - 14));
        final scroll = tester
            .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
            .controller!;
        if (touch) {
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -150),
          );
        } else {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        }
        await tester.pumpAndSettle();
        expect(scroll.offset, greaterThan(0));
        expect(node.hasFocus, isFalse);
        expect(hint, findsNothing);
        await tester.pump(const Duration(seconds: 3));
        expect(hint, findsNothing);

        // Remote scrolling remains available and restores settings at the top.
        for (var i = 0; i < 20 && scroll.offset > 0; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pump();
        }
        expect(scroll.offset, 0);
        expect(node.hasFocus, isTrue);
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(milliseconds: 200));
        expect(hint, findsNothing);
        await tester.pumpWidget(const SizedBox());
        semantics.dispose();
      });
    }
  }
}
