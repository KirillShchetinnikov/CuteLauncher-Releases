import 'package:flauncher/widgets/action_notice.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/settings/settings_menu_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('notice uses settings surface without elevation tint', (tester) async {
    late BuildContext context;
    final theme = ThemeData.dark();
    await tester.pumpWidget(MaterialApp(theme: theme,
      builder: (_, child) => ActionNoticeHost(child: child!),
      home: Builder(builder: (value) {
        context = value;
        return const Scaffold();
      })));
    showActionNotice(context, 'Result');
    await tester.pump();
    final material = tester.widget<Material>(find.ancestor(
      of: find.text('Result'), matching: find.byType(Material)).first);
    expect(material.color, theme.colorScheme.surface);
    expect(material.surfaceTintColor, Colors.transparent);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('download notice stays until explicitly completed', (
    tester,
  ) async {
    late BuildContext context;
    final progress = ValueNotifier<double>(0);
    addTearDown(progress.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => ActionNoticeHost(child: child!),
        home: Builder(
          builder: (value) {
            context = value;
            return const Scaffold();
          },
        ),
      ),
    );
    final close = showActionNotice(
      context,
      'Download',
      persistent: true,
      content: ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (_, value, _) => LinearProgressIndicator(value: value),
      ),
    );
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    progress.value = .6;
    await tester.pump();
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      .6,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    close();
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    close();
  });
  for (final onRight in [false, true]) {
    testWidgets(
      'notice uses the opposite bottom corner with settings $onRight',
      (tester) async {
        late BuildContext context;
        await tester.pumpWidget(
          MaterialApp(
            builder: (_, child) => ActionNoticeHost(child: child!),
            home: SettingsMenuLayout(
              onRight: onRight,
              child: Builder(
                builder: (value) {
                  context = value;
                  return const Scaffold();
                },
              ),
            ),
          ),
        );
        showActionNotice(context, 'Result');
        await tester.pump();
        final card = find
            .ancestor(of: find.text('Result'), matching: find.byType(Material))
            .first;
        if (onRight) {
          expect(tester.getBottomLeft(card), const Offset(24, 576));
        } else {
          expect(tester.getBottomRight(card), const Offset(776, 576));
        }
        late BuildContext dialogContext;
        showLauncherDialog<void>(
          context: context,
          builder: (value) {
            dialogContext = value;
            return const LauncherAlertDialog(content: Text('Dialog'));
          },
        );
        await tester.pumpAndSettle();
        showActionNotice(dialogContext, 'Dialog result');
        await tester.pump();
        final dialogCard = find
            .ancestor(
              of: find.text('Dialog result'),
              matching: find.byType(Material),
            )
            .first;
        if (onRight) {
          expect(tester.getBottomLeft(dialogCard), const Offset(24, 576));
        } else {
          expect(tester.getBottomRight(dialogCard), const Offset(776, 576));
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
  testWidgets('host stays above new routes and dialogs', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => ActionNoticeHost(child: child!),
        home: Builder(
          builder: (value) {
            context = value;
            return const Scaffold();
          },
        ),
      ),
    );
    showActionNotice(context, 'Persisting result');
    await tester.pump();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Another page')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Persisting result'), findsOneWidget);
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(content: Text('Dialog')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Persisting result'), findsOneWidget);
    expect(find.text('Dialog'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('stack rises, expires independently and preserves focus', (
    tester,
  ) async {
    late BuildContext context;
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return TextButton(
                focusNode: focus,
                autofocus: true,
                onPressed: () {},
                child: const Text('Action'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    showActionNotice(context, 'First', duration: const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    showActionNotice(
      context,
      'Second',
      duration: const Duration(seconds: 4),
      error: true,
    );
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('First')).dy,
      lessThan(tester.getTopLeft(find.text('Second')).dy),
    );
    expect(tester.getBottomRight(find.text('Second')).dx, greaterThan(700));
    expect(focus.hasFocus, isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Second'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    focus.dispose();
  });

  testWidgets(
    'keeps bursts, clears on background and cancels timers on dispose',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        showActionNotice(context, 'Result $i');
      }
      await tester.pump();
      expect(find.text('Result 0'), findsOneWidget);
      expect(find.text('Result 3'), findsOneWidget);
      expect(find.text('Result 7'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.textContaining('Result'), findsNothing);
      showActionNotice(context, 'After resume');
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 6));
      expect(tester.takeException(), isNull);
    },
  );
}
