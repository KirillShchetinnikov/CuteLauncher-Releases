import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../adaptive_landscape.dart';
import '../actions.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_service.dart';

/// Hides the live settings tree without losing its navigation, scroll or focus.
class LandscapeDemoScope extends InheritedWidget {
  final bool active;
  const LandscapeDemoScope({
    super.key,
    required this.active,
    required super.child,
  });
  static bool activeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<LandscapeDemoScope>()
          ?.active ??
      false;
  @override
  bool updateShouldNotify(LandscapeDemoScope oldWidget) =>
      active != oldWidget.active;
}

class LandscapeDemoPresentation extends StatefulWidget {
  final Widget child;
  const LandscapeDemoPresentation({super.key, required this.child});
  @override
  State<LandscapeDemoPresentation> createState() =>
      _LandscapeDemoPresentationState();
}

class _LandscapeDemoPresentationState extends State<LandscapeDemoPresentation> {
  SettingsService? _settings;
  FocusNode? _returnFocus;
  bool _active = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<SettingsService>();
    if (identical(settings, _settings)) return;
    _settings?.landscapeDemo.removeListener(_changed);
    _settings = settings;
    settings.landscapeDemo.addListener(_changed);
    _changed();
  }

  void _changed() {
    final active = _settings!.landscapeDemo.value != null;
    if (active == _active) return;
    _active = active;
    if (active) {
      _returnFocus = FocusManager.instance.primaryFocus;
    } else {
      final node = _returnFocus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !_active &&
            node?.context?.mounted == true &&
            node!.canRequestFocus) {
          node.requestFocus();
        }
      });
    }
  }

  void _stop() => _settings!.landscapeDemo.value = null;

  @override
  void dispose() {
    _settings?.landscapeDemo.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<LandscapeDemoFrame?>(
        valueListenable: _settings!.landscapeDemo,
        child: widget.child,
        builder: (context, demo, child) => PopScope<void>(
          canPop: demo == null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && demo != null) _stop();
          },
          child: Actions(
            actions: {
              if (demo != null)
                BackIntent: CallbackAction<BackIntent>(
                  onInvoke: (_) {
                    _stop();
                    return null;
                  },
                ),
            },
            child: LandscapeDemoScope(
              active: demo != null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeFocus(
                    excluding: demo != null,
                    child: Offstage(
                      offstage: demo != null,
                      child: TickerMode(enabled: demo == null, child: child!),
                    ),
                  ),
                  if (demo != null)
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 16,
                      left: 24,
                      right: 24,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: _DemoStatus(demo: demo, onStop: _stop),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Shared effect/time caption for the app demo and local capture target.
String landscapeDemoDescription(AppLocalizations l, LandscapeDemoFrame demo) {
  final effect = demo.showingTime
      ? l.landscapeTimeOfDay
      : demo.showingSeasons
      ? '${l.landscapeSeasons} · ${switch (demo.season!) {
          LandscapeSeason.spring => l.landscapeDemoSpring,
          LandscapeSeason.summer => l.landscapeDemoSummer,
          LandscapeSeason.autumn => l.landscapeDemoAutumn,
          LandscapeSeason.winter => l.landscapeDemoWinter,
        }}'
      : '${l.weather} · ${switch (demo.weather) {
          LandscapeWeather.clear => l.landscapeDemoClear,
          LandscapeWeather.cloudy => l.landscapeDemoCloudy,
          LandscapeWeather.rain => l.weatherRain,
          LandscapeWeather.snow => l.weatherSnow,
          LandscapeWeather.fog => l.landscapeDemoFog,
        }}';
  final time =
      '${demo.now.hour.toString().padLeft(2, '0')}:${demo.now.minute.toString().padLeft(2, '0')}';
  return '$effect · $time';
}

class _DemoStatus extends StatelessWidget {
  final LandscapeDemoFrame demo;
  final VoidCallback onStop;
  const _DemoStatus({required this.demo, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE61B2029),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                key: const ValueKey('landscape-demo-progress'),
                value: demo.progress,
                minHeight: 3,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Colors.white.withValues(alpha: .16),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    landscapeDemoDescription(l, demo),
                    key: const ValueKey('landscape-demo-time'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  key: const ValueKey('landscape-demo-stop'),
                  autofocus: true,
                  onPressed: onStop,
                  style:
                      FilledButton.styleFrom(
                        foregroundColor: const Color(0xff102030),
                        minimumSize: const Size(64, 32),
                        tapTargetSize: MaterialTapTargetSize.padded,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) =>
                              states.contains(WidgetState.focused) ||
                                  states.contains(WidgetState.pressed)
                              ? const Color(0xffbfdbfe)
                              : const Color(0xfff1f5f9),
                        ),
                        side: WidgetStateProperty.resolveWith(
                          (states) => BorderSide(
                            color: states.contains(WidgetState.focused)
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        overlayColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                      ),
                  child: Text(
                    l.landscapeDemoStop,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xff102030),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
