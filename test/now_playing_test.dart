import 'dart:async';
import 'package:flauncher/providers/now_playing_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/now_playing_card.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> packet(int revision, {bool allowed = true, bool pause = true, bool next = true}) => {
  'allowed': allowed, 'revision': revision, 'item': allowed ? {
    'id': 'session', 'packageName': 'player', 'title': 'Тестовый трек', 'artist': 'Автор',
    'playing': pause, 'canPause': pause, 'canPlay': !pause, 'canNext': next,
  } : null,
};
class TestMediaTransport implements MediaTransport {
  int subscriptions = 0, cancellations = 0, snapshots = 0, actions = 0;
  final updates = StreamController<dynamic>.broadcast();
  Future<dynamic> Function()? query;
  final commands = <String>[];
  TestMediaTransport() {
    updates.onListen = () { subscriptions++; };
    updates.onCancel = () { cancellations++; };
  }
  @override Stream<dynamic> get events => updates.stream;
  @override Future<dynamic> snapshot() async { snapshots++; return query != null ? query!() : packet(snapshots); }
  @override Future<bool> action(String id, String action) async { actions++; commands.add('$id:$action'); return true; }
  @override Future<bool> permission() async => true;
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SettingsService settings;
  late TestMediaTransport transport;
  late NowPlayingService service;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsService(await SharedPreferences.getInstance());
    transport = TestMediaTransport();
    service = NowPlayingService(settings, transport: transport);
  });
  tearDown(() async { service.dispose(); await transport.updates.close(); settings.dispose(); });
  test('opt in is persisted/exported/validated and disabled mode has no subscriptions', () async {
    expect(transport.subscriptions, 0); expect(transport.snapshots, 0);
    await settings.setShowNowPlaying(true); await Future<void>.delayed(Duration.zero);
    expect(service.media!.title, 'Тестовый трек'); expect(transport.subscriptions, 1);
    expect(settings.exportSettingsMap()['show_now_playing'], true);
    expect(compatibleSettings({'show_now_playing': 1}, {}), isEmpty);
    await settings.setShowNowPlaying(false);
    expect(service.media, isNull); expect(transport.cancellations, 1);
  });
  test('background cancels observers, late responses and resume rechecks access', () async {
    final pending = Completer<dynamic>(); transport.query = () => pending.future;
    await settings.setShowNowPlaying(true);
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    pending.complete(packet(1)); await Future<void>.delayed(Duration.zero);
    expect(service.media, isNull); expect(transport.cancellations, 1);
    transport.query = () async => packet(2, allowed: false);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed); await Future<void>.delayed(Duration.zero);
    expect(service.allowed, false); expect(service.media, isNull); expect(transport.subscriptions, 2);
  });
  test('out of order snapshots cannot restore obsolete actions or track', () async {
    await settings.setShowNowPlaying(true); await Future<void>.delayed(Duration.zero);
    transport.updates.add(packet(20, pause: false, next: false));
    transport.updates.add(packet(10)); await Future<void>.delayed(Duration.zero);
    expect(service.media!.canPlay, true); expect(service.media!.canNext, false);
    expect(await service.control('next'), false); expect(transport.actions, 0);
    expect(await service.control('play'), true); expect(transport.commands, ['session:play']);
  });
  testWidgets('remote buttons expose only supported commands; long labels fit', (tester) async {
    await settings.setShowNowPlaying(true);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: settings), ChangeNotifierProvider.value(value: service),
    ], child: const MaterialApp(locale: Locale('ru'), localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: NowPlayingCard()))));
    await tester.pumpAndSettle();
    expect(find.text('Пауза'), findsOneWidget); expect(find.text('Следующий трек'), findsOneWidget);
    expect(find.text('Продолжить'), findsNothing);
    await tester.tap(find.text('Пауза')); await tester.pumpAndSettle();
    expect(transport.commands, ['session:pause']);
    final value = packet(50, pause: false, next: false);
    value['item']['title'] = 'Очень длинное название композиции ' * 30;
    transport.updates.add(value); await tester.pumpAndSettle();
    expect(find.text('Следующий трек'), findsNothing); expect(find.text('Продолжить'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab); await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle(); expect(transport.commands.last, 'session:play');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('missing access explains notification permission without starting playback', (tester) async {
    transport.query = () async => packet(1, allowed: false);
    await settings.setShowNowPlaying(true);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: settings), ChangeNotifierProvider.value(value: service),
    ], child: const MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: NowPlayingCard()))));
    await tester.pumpAndSettle(); expect(find.textContaining('Media controls require'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing); expect(transport.actions, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
