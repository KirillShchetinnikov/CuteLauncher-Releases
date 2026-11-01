import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/audio_status_service.dart';
import 'package:flauncher/widgets/audio_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'shows percent/output, Mute and unknown; pult skips the entire block',
    (tester) async {
      const channel = MethodChannel('cutelauncher/audio_status');
      Map<String, dynamic> value = {
        'percent': 15,
        'muted': false,
        'outputs': ['arc'],
      };
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'snapshot' ? value : null,
      );
      final audio = AudioStatusService();
      final before = FocusNode(), after = FocusNode();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: audio,
          child: MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      focusNode: before,
                      onPressed: () {},
                      child: const Text('Before'),
                    ),
                    const AudioStatusWidget(),
                    TextButton(
                      focusNode: after,
                      onPressed: () {},
                      child: const Text('After'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('15%'), findsOneWidget);
      expect(find.text('ARC'), findsOneWidget);
      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(after.hasFocus, isTrue);
      value = {
        'percent': 15,
        'muted': true,
        'outputs': ['bluetooth'],
      };
      await audio.refresh();
      await tester.pump();
      expect(find.text('15%'), findsNothing);
      expect(find.byIcon(Icons.volume_off_outlined), findsOneWidget);
      expect(find.text('Bluetooth'), findsOneWidget);
      value = {};
      await audio.refresh();
      await tester.pump();
      expect(find.text('—'), findsNWidgets(2));
      expect(find.byIcon(Icons.tv), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      audio.dispose();
      before.dispose();
      after.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
  );
  testWidgets('large text and RTL keep the informational block usable', (
    tester,
  ) async {
    final audio = AudioStatusService();
    audio.state = (
      percent: 100,
      muted: false,
      fixed: false,
      output: 'bluetooth',
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: audio,
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 240,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: AudioStatusWidget(visible: false),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Bluetooth'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    audio.dispose();
  });
  testWidgets(
    'hidden widget detaches polling and a visible widget refreshes immediately',
    (tester) async {
      const channel = MethodChannel('cutelauncher/audio_status');
      var reads = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method != 'snapshot') return null;
        reads++;
        return {
          'percent': 0,
          'outputs': ['tv'],
        };
      });
      final audio = AudioStatusService();
      Future<void> pump(bool visible) async {
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: audio,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AudioStatusWidget(visible: visible),
            ),
          ),
        );
        await tester.pump();
      }

      await pump(false);
      await tester.pump(const Duration(seconds: 2));
      expect(reads, 0);
      await pump(true);
      expect(reads, 1);
      expect(find.text('0%'), findsOneWidget);
      await pump(false);
      await tester.pump(const Duration(seconds: 2));
      expect(reads, 1);
      await pump(true);
      expect(reads, 2);
      await tester.pumpWidget(const SizedBox());
      audio.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
  );
}
