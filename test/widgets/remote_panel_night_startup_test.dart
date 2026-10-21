import 'dart:async';
import 'dart:convert';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flauncher/widgets/remote_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks.mocks.dart';

void main() {
  for (final excluded in [false, true]) {
    for (final eventFirst in [false, true]) {
      testWidgets(
        'first panel frame waits for night state: excluded=$excluded eventFirst=$eventFirst',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            nightModeKey: jsonEncode(
              const NightModeConfiguration(
                enabled: true,
                dim: 50,
                warmth: 0,
                tclScheduled: false,
              ).toJson(),
            ),
          });
          final prefs = await SharedPreferences.getInstance();
          final panel = RemotePanelService(prefs);
          for (final id in RemotePanelService.ids) {
            if (id != 'settings') await panel.show(id, false);
          }
          final settings = SettingsService(prefs);
          final initialStatus = Completer<Object?>();
          final messenger = tester.binding.defaultBinaryMessenger;
          const events = 'cutelauncher/night_panel_state';
          const nightChannel = MethodChannel('cutelauncher/night');
          const tclChannel = MethodChannel('cutelauncher/tcl_blue_light');
          messenger.setMockMethodCallHandler(
            nightChannel,
            (_) => initialStatus.future,
          );
          messenger.setMockMethodCallHandler(
            const MethodChannel(events),
            (_) async => null,
          );
          messenger.setMockMethodCallHandler(
            tclChannel,
            (_) async => {'status': 'unsupported'},
          );
          final calls = <String>[];
          messenger.setMockMethodCallHandler(remotePanelChannel, (call) async {
            calls.add(call.method);
            return null;
          });
          addTearDown(() {
            for (final channel in [
              nightChannel,
              const MethodChannel(events),
              tclChannel,
              remotePanelChannel,
            ]) {
              messenger.setMockMethodCallHandler(channel, null);
            }
          });
          final night = NightModeService(prefs, remotePanel: true);
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: panel),
                ChangeNotifierProvider.value(value: settings),
                ChangeNotifierProvider.value(value: night),
                ChangeNotifierProvider(create: (_) => AppearanceService(prefs)),
                ChangeNotifierProvider<TvInputsService>.value(
                  value: MockTvInputsService(),
                ),
                ChangeNotifierProvider<NotificationsService>.value(
                  value: MockNotificationsService(),
                ),
                ChangeNotifierProvider<WeatherService>.value(
                  value: MockWeatherService(),
                ),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (_, child) => ListenableBuilder(
                  listenable: night,
                  builder: (_, _) =>
                      NightModeFilter(service: night, child: child!),
                ),
                home: const RemotePanel(),
              ),
            ),
          );
          final state = {
            'visible': !excluded,
            'excluded': excluded,
            'presentationReady': true,
          };
          Future<void> emit() async {
            messenger.handlePlatformMessage(
              events,
              const StandardMethodCodec().encodeSuccessEnvelope(state),
              (_) {},
            );
            await tester.pump();
            await tester.pump();
          }

          // Reproduce a slow initial status read: no bright toolbar may appear.
          await tester.pump(const Duration(seconds: 1));
          expect(find.byType(FocusAwareAppBar), findsNothing);
          expect(calls, isNot(contains('ready')));
          if (eventFirst) {
            await emit();
            expect(find.byType(FocusAwareAppBar), findsNothing);
            expect(calls, isNot(contains('ready')));
            initialStatus.complete(state);
          } else {
            initialStatus.complete({...state, 'presentationReady': false});
            await tester.pump();
            await tester.pump();
            expect(find.byType(FocusAwareAppBar), findsNothing);
            await emit();
          }
          await tester.pump();
          await tester.pump();
          expect(find.byType(FocusAwareAppBar), findsOneWidget);
          expect(calls.where((call) => call == 'ready'), hasLength(1));
          expect(night.panelFilter, !excluded);
          // A later exclusion refresh must not hide the already open toolbar.
          messenger.handlePlatformMessage(
            events,
            const StandardMethodCodec().encodeSuccessEnvelope({
              ...state,
              'presentationReady': false,
            }),
            (_) {},
          );
          await tester.pump();
          await tester.pump();
          expect(find.byType(FocusAwareAppBar), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
          night.dispose();
          settings.dispose();
          panel.dispose();
        },
      );
    }
  }
}
