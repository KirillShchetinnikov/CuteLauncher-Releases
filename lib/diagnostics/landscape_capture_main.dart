// Local debug/profile target only. The production entry point never imports it.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../adaptive_landscape.dart';
import '../image_limits.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_service.dart';
import '../widgets/adaptive_landscape_background.dart';
import '../widgets/landscape_demo_presentation.dart';

Future<void> main() async {
  if (kReleaseMode) {
    throw UnsupportedError('Landscape capture is debug/profile only');
  }
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final settings = CaptureSettings(await SharedPreferences.getInstance());
  runApp(
    ChangeNotifierProvider<SettingsService>(
      create: (_) => settings,
      child: const CaptureApp(),
    ),
  );
}

class CaptureApp extends StatelessWidget {
  const CaptureApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: (context.watch<SettingsService>() as CaptureSettings).captureLocale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const LandscapeCapture(),
  );
}

/// The day preview starts at noon in summer, regardless of the host's month.
DateTime captureStart(DateTime now) =>
    DateTime(now.year, now.month, now.day, 12);

class CaptureDemoFrame extends LandscapeDemoFrame {
  CaptureDemoFrame(super.elapsed, super.start, {super.timeline});

  @override
  LandscapeSeason? get season =>
      showingTime ? LandscapeSeason.summer : super.season;
}

/// Use the device's existing local sun cache, without configuring the night filter.
Future<LandscapeDemoTimeline> captureTimeline(DateTime start) async {
  List<Map<String, dynamic>> days = const [];
  try {
    final cached = await const MethodChannel('cutelauncher/night')
        .invokeListMethod<dynamic>('solarCache')
        .timeout(const Duration(seconds: 2));
    days =
        cached
            ?.whereType<Map>()
            .map((day) => Map<String, dynamic>.from(day))
            .toList() ??
        const [];
  } on PlatformException {
    /* No cache: use the shared 06:00/18:00 fallback. */
  } on MissingPluginException {
    /* Local tests and older hosts. */
  } on TimeoutException {
    /* A missing native reply must not block capture. */
  }
  return LandscapeDemoTimeline(start, solarDays: days);
}

/// Read-only preferences: capture choices live in memory, outside user settings.
class CaptureSettings extends SettingsService {
  CaptureSettings(super.preferences);

  Locale _captureLocale = const Locale('ru');
  Locale get captureLocale => _captureLocale;

  void selectLanguage(String code) {
    if (!['ru', 'en'].contains(code)) throw ArgumentError.value(code, 'code');
    _captureLocale = Locale(code);
    notifyListeners();
  }

  LandscapeConfiguration _capture = const LandscapeConfiguration(
    motion: true,
    starRotation: true,
    hemisphere: 'north',
  );

  @override
  LandscapeConfiguration get landscape => _capture;
  @override
  bool get memorySaverEnabled => false;

  void select(String variant) {
    _capture = _capture.withValue('variant', variant);
    notifyListeners();
  }
}

/// Uses the real renderer and demo timeline, with only an effect/time caption.
/// 1/2 select the variant, 3/4 select RU/EN, Enter starts, Back/Home cancel.
class LandscapeCapture extends StatefulWidget {
  const LandscapeCapture({super.key});
  @override
  State<LandscapeCapture> createState() => _LandscapeCaptureState();
}

class _LandscapeCaptureState extends State<LandscapeCapture>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final DateTime start;
  late final LandscapeDemoTimeline timeline;
  late final Ticker ticker;
  late SettingsService settings;
  bool ready = false;
  bool preparing = false;
  StreamSubscription<dynamic>? homeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    homeSubscription = const EventChannel('me.efesser.flauncher/event_home')
        .receiveBroadcastStream()
        .listen((event) {
          if (event == true && ready) _reset(reason: 'home');
        });
    ticker = createTicker((elapsed) {
      final frame = CaptureDemoFrame(elapsed, start, timeline: timeline);
      if (frame.isComplete) {
        ticker.stop();
        debugPrint('LANDSCAPE_CAPTURE complete');
        // Keep the final clean frame until the next remote action.
        return;
      }
      settings.landscapeDemo.value = frame;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    settings = context.read<SettingsService>();
    if (!ready && !preparing) {
      preparing = true;
      _prepare();
    }
  }

  Future<void> _prepare() async {
    start = captureStart(DateTime.now());
    timeline = await captureTimeline(start);
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    for (final name in ['spring', 'valley', 'autumn', 'winter']) {
      await precacheImage(
        sizedImage(AssetImage('assets/landscapes/$name.png'), size, dpr),
        context,
      );
      if (!mounted) return;
    }
    ready = true;
    _reset();
    debugPrint(
      'LANDSCAPE_CAPTURE ready start=${start.toIso8601String()} season=summer',
    );
  }

  void _reset({String reason = 'reset'}) {
    ticker.stop();
    settings.landscapeDemo.value = CaptureDemoFrame(
      Duration.zero,
      start,
      timeline: timeline,
    );
    debugPrint('LANDSCAPE_CAPTURE $reason');
  }

  void _play() {
    if (!ready || ticker.isActive) return;
    _reset();
    ticker.start();
    debugPrint('LANDSCAPE_CAPTURE start ${settings.landscape.variant}');
  }

  void _select(String variant) {
    if (!ready) return;
    _reset();
    (settings as CaptureSettings).select(variant);
    debugPrint('LANDSCAPE_CAPTURE selected $variant');
  }

  void _selectLanguage(String code) {
    if (!ready) return;
    _reset();
    (settings as CaptureSettings).selectLanguage(code);
    debugPrint('LANDSCAPE_CAPTURE language $code');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && ready) {
      _reset(reason: 'lifecycle');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    homeSubscription?.cancel();
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && ready) _reset(reason: 'back');
    },
    child: Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.digit1) {
          _select('illustrated');
        } else if (key == LogicalKeyboardKey.digit2) {
          _select('realistic');
        } else if (key == LogicalKeyboardKey.digit3) {
          _selectLanguage('ru');
        } else if (key == LogicalKeyboardKey.digit4) {
          _selectLanguage('en');
        } else if (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.space) {
          _play();
        } else if (key == LogicalKeyboardKey.escape ||
            key == LogicalKeyboardKey.goBack) {
          if (ready) _reset(reason: 'back');
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AdaptiveLandscapeBackground(),
            PositionedDirectional(
              start: 24,
              end: 24,
              top: 16,
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ValueListenableBuilder<LandscapeDemoFrame?>(
                    valueListenable: settings.landscapeDemo,
                    builder: (context, demo, _) => demo == null
                        ? const SizedBox.shrink()
                        : CaptureCaption(demo: demo),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Text-only capture label; formatting is shared with the regular app demo.
class CaptureCaption extends StatelessWidget {
  final LandscapeDemoFrame demo;
  const CaptureCaption({super.key, required this.demo});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB31B2029),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          landscapeDemoDescription(AppLocalizations.of(context)!, demo),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    ),
  );
}
