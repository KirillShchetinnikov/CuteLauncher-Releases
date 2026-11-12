import 'dart:async';
import 'dart:math' as math;

import 'package:flauncher/diagnostics/launcher_memory.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/memory_resources.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/action_notice.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_information.dart';
import 'settings_page_layout.dart';
import 'settings_read_only_value.dart';
import 'settings_section.dart';
import 'settings_route.dart';

class MemoryPage extends StatefulWidget {
  static const routeName = 'memory_panel';
  final FLauncherChannel? channel;
  final bool _advanced;
  const MemoryPage({super.key, this.channel}) : _advanced = false;
  const MemoryPage._advanced({this.channel}) : _advanced = true;
  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class MemoryAdvancedPage extends StatelessWidget {
  static const routeName = 'memory_advanced';
  final FLauncherChannel? channel;
  const MemoryAdvancedPage({super.key, this.channel});

  @override
  Widget build(BuildContext context) => MemoryPage._advanced(channel: channel);
}

class _MemoryPageState extends State<MemoryPage> with WidgetsBindingObserver {
  late final LauncherMemory _memory;
  final _advancedFocus = FocusNode();
  bool _images = false, _technical = false, _observation = false;
  bool _saving = false, _routeActive = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _memory = LauncherMemory(
      resources: context.read<MemoryResources>(),
      channel: widget.channel ?? FLauncherChannel(),
    );
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_memory.refresh());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeActive = ModalRoute.isCurrentOf(context) ?? true;
    _memory.setActive(_routeActive && _foreground);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _memory.setActive(_routeActive && _foreground);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _memory.dispose();
    _advancedFocus.dispose();
    super.dispose();
  }

  Future<void> _openAdvanced() async {
    await Navigator.of(context).push<void>(
      SettingsRoute(
        settings: const RouteSettings(name: MemoryAdvancedPage.routeName),
        builder: (_) => MemoryAdvancedPage(channel: widget.channel),
      ),
    );
    if (!mounted) return;
    _advancedFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_memory.refresh());
    });
  }

  String _bytes(int? bytes) {
    final l = AppLocalizations.of(context)!;
    return bytes == null
        ? l.memoryUnavailable
        : '${NumberFormat('0.0', l.localeName).format(bytes / (1024 * 1024))} ${l.memoryUnit}';
  }

  Widget _value(String label, String value) =>
      SettingsReadOnlyValue(label: label, value: value, wrapLines: true);

  Widget _expand({
    required String title,
    required bool expanded,
    required VoidCallback onPressed,
    IconData? icon,
    String? value,
    Key? key,
  }) => Semantics(
    expanded: expanded,
    child: FocusableSettingsTile(
      key: key,
      title: Text(title),
      leading: icon == null ? null : Icon(icon),
      trailing: value == null
          ? Icon(expanded ? Icons.expand_less : Icons.expand_more)
          : Text(value),
      valueIcon: expanded ? Icons.expand_less : Icons.expand_more,
      onPressed: onPressed,
    ),
  );

  Future<void> _saveEconomy(bool value) async {
    if (_saving || _memory.busy) return;
    setState(() => _saving = true);
    try {
      await context.read<SettingsService>().setMemorySaverEnabled(value);
      if (mounted) await _memory.refresh();
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.memorySaveFailed,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _summary(AppLocalizations l) {
    final theme = Theme.of(context);
    final snapshot = _memory.snapshot;
    final delta = _memory.deltaBytes;
    return SettingsSection(
      title: l.memoryUsage,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PSS', style: theme.textTheme.bodySmall),
              Text(
                snapshot == null && _memory.busy
                    ? l.memoryMeasuring
                    : _bytes(snapshot?.pssBytes),
                key: const Key('memory-primary'),
                style: snapshot == null
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.headlineLarge,
              ),
              if (delta != null)
                Text(
                  l.memoryChange(
                    '${delta > 0
                        ? '+'
                        : delta < 0
                        ? '−'
                        : ''}${_bytes(delta.abs())}',
                  ),
                ),
              if (snapshot != null)
                Text(
                  '${l.memoryMeasuredAt}: ${DateFormat.Hms(l.localeName).format(snapshot.measuredAt)}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        if (_memory.failed)
          SettingsMessage(
            kind: SettingsMessageKind.warning,
            text: snapshot == null ? l.memoryMeasurementFailed : l.memoryStale,
          ),
        FocusableSettingsTile(
          key: const Key('memory-refresh'),
          autofocus: true,
          busy: _memory.busy || _saving,
          leading: const Icon(Icons.refresh),
          title: Text(_memory.busy ? l.memoryMeasuring : l.memoryRefresh),
          onPressed: _memory.refresh,
        ),
      ],
    );
  }

  Widget _caches(AppLocalizations l) => SettingsSection(
    title: l.memoryImages,
    children: [
      _value(l.memoryCacheSize, _bytes(_memory.cacheBytes)),
      _expand(
        key: const Key('memory-images'),
        title: l.memoryCacheFiles,
        expanded: _images,
        value: _bytes(_memory.encoded.bytes),
        onPressed: () => setState(() => _images = !_images),
      ),
      if (_images) ...[
        for (final entry in <MemoryCacheKind, String>{
          MemoryCacheKind.appIcons: l.memoryAppIcons,
          MemoryCacheKind.appBanners: l.memoryAppBanners,
          MemoryCacheKind.watchNextPosters: l.memoryWatchNextPosters,
          MemoryCacheKind.other: l.memoryOtherCaches,
        }.entries)
          _value(
            entry.value,
            '${_bytes(_memory.breakdown[entry.key]?.bytes)} · ${l.memoryCacheEntries(_memory.breakdown[entry.key]?.entries ?? 0)}',
          ),
      ],
      _value(
        l.memoryDecodedCache,
        '${_bytes(_memory.decodedBytes)} / ${_bytes(_memory.decodedLimit)}',
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
        child: LinearProgressIndicator(
          value: _memory.decodedLimit == 0
              ? 0
              : (_memory.decodedBytes / _memory.decodedLimit).clamp(0.0, 1.0),
          semanticsLabel: l.memoryDecodedCache,
          borderRadius: BorderRadius.circular(4),
          minHeight: 4,
        ),
      ),
      FocusableSettingsTile(
        key: const Key('memory-clear'),
        busy: _memory.busy || _saving,
        leading: const Icon(Icons.cleaning_services_outlined),
        title: Text(l.memoryClear),
        onPressed: _memory.clearCaches,
      ),
      if (_memory.clearedCacheAfter != null) ...[
        SettingsMessage(
          text: l.memoryCacheResult(
            _bytes(_memory.clearedCacheBefore),
            _bytes(_memory.clearedCacheAfter),
          ),
        ),
        _value(
          l.memoryProcess,
          '${_bytes(_memory.clearedProcessBefore)} → ${_memory.busy ? l.memoryMeasuring : _bytes(_memory.clearedProcessAfter)}',
        ),
      ],
    ],
  );

  Widget _observe(AppLocalizations l) {
    final points = _memory.points;
    final values = points.map((p) => p.bytes).whereType<int>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _expand(
          key: const Key('memory-observation'),
          title: l.memoryObserve,
          icon: Icons.show_chart,
          expanded: _observation,
          onPressed: () => setState(() {
            _observation = !_observation;
            if (!_observation) _memory.stopObservation();
          }),
        ),
        if (_observation) ...[
          FocusableSettingsTile(
            key: const Key('memory-observe-toggle'),
            busy: !_memory.observing && (_memory.busy || _saving),
            leading: Icon(_memory.observing ? Icons.stop : Icons.play_arrow),
            title: Text(
              _memory.observing ? l.memoryObserveStop : l.memoryObserveStart,
            ),
            onPressed: _memory.observing
                ? _memory.stopObservation
                : _memory.startObservation,
          ),
          if (points.isNotEmpty || _memory.observing)
            SettingsMessage(
              text: _memory.observing
                  ? l.memoryObserveRunning
                  : l.memoryObserveFinished,
            ),
          if (values.isNotEmpty) ...[
            _value(
              'PSS',
              '${_bytes(values.reduce(math.min))} – ${_bytes(values.reduce(math.max))}',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Semantics(
                image: true,
                label:
                    '${l.memoryObserve}, PSS: ${_bytes(values.reduce(math.min))} – ${_bytes(values.reduce(math.max))}',
                child: SizedBox(
                  height: 92,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _MemoryChartPainter(
                      points,
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: .12),
                    ),
                  ),
                ),
              ),
            ),
            _value(l.memorySeconds(0), l.memorySeconds(60)),
          ],
          if (!_memory.observing && values.isEmpty)
            SettingsEmptyState(
              text: l.memoryObserveEmpty,
              icon: Icons.show_chart,
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    return AnimatedBuilder(
      animation: _memory,
      builder: (context, _) => SettingsPageLayout(
        title: Text(
          widget._advanced ? l.memoryAdvanced : l.memoryLauncherTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget._advanced) ...[
                _summary(l),
                _caches(l),
                RoundedSwitchListTile(
                  key: const Key('memory-economy'),
                  value: settings.memorySaverEnabled,
                  busy: _saving || _memory.busy,
                  secondary: const Icon(Icons.eco_outlined),
                  title: Text(l.memorySaver),
                  onChanged: _saveEconomy,
                ),
                SettingsHelp(
                  title: l.memorySaverHelp,
                  text: l.memorySaverDescription,
                ),
                FocusableSettingsTile(
                  key: const Key('memory-advanced'),
                  focusNode: _advancedFocus,
                  leading: const Icon(Icons.analytics_outlined),
                  title: Text(l.memoryAdvanced),
                  onPressed: _openAdvanced,
                ),
              ] else ...[
                if (_memory.failed)
                  SettingsMessage(
                    kind: SettingsMessageKind.warning,
                    text: _memory.snapshot == null
                        ? l.memoryMeasurementFailed
                        : l.memoryStale,
                  ),
                _observe(l),
                _expand(
                  key: const Key('memory-technical'),
                  title: l.memoryTechnical,
                  icon: Icons.tune,
                  expanded: _technical,
                  onPressed: () => setState(() => _technical = !_technical),
                ),
                if (_technical) ...[
                  FocusableSettingsTile(
                    key: const Key('memory-refresh'),
                    busy: _memory.busy,
                    leading: const Icon(Icons.refresh),
                    title: Text(
                      _memory.busy ? l.memoryMeasuring : l.memoryRefresh,
                    ),
                    onPressed: _memory.refresh,
                  ),
                  if (_memory.snapshot != null)
                    _value(
                      l.memoryMeasuredAt,
                      DateFormat.Hms(l.localeName)
                          .format(_memory.snapshot!.measuredAt),
                    ),
                  _value(l.memoryPss, _bytes(_memory.snapshot?.pssBytes)),
                  _value(l.memoryRss, _bytes(_memory.snapshot?.rssBytes)),
                  _value(
                    l.memoryGraphics,
                    _bytes(_memory.snapshot?.graphicsBytes),
                  ),
                ],
                SettingsHelp(
                  title: l.memoryReadingHelp,
                  text:
                      '${l.memoryExplanation}\n\n${l.memoryFeaturesExplanation}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryChartPainter extends CustomPainter {
  final List<LauncherMemoryPoint> points;
  final Color color, grid;
  _MemoryChartPainter(this.points, this.color, this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => p.bytes).whereType<int>().toList();
    if (values.isEmpty || size.isEmpty) return;
    final min = values.reduce(math.min).toDouble();
    final max = values.reduce(math.max).toDouble();
    final span = math.max(max - min, 1024 * 1024.0);
    final bottom = (min + max - span) / 2;
    final guide = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final y in [8.0, size.height / 2, size.height - 8]) {
      canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), guide);
    }
    final path = Path();
    var connected = false;
    final dots = <Offset>[];
    for (final point in points) {
      if (point.bytes == null) {
        connected = false;
        continue;
      }
      final x =
          4 +
          (size.width - 8) *
              point.elapsed.inMilliseconds /
              LauncherMemory.observationDuration.inMilliseconds;
      final y =
          size.height - 8 - (size.height - 16) * (point.bytes! - bottom) / span;
      if (connected) {
        path.lineTo(x, y);
      } else {
        path.moveTo(x, y);
      }
      dots.add(Offset(x, y));
      connected = true;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    for (final dot in dots) {
      canvas.drawCircle(dot, 2.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_MemoryChartPainter oldDelegate) =>
      !listEquals(oldDelegate.points, points) ||
      color != oldDelegate.color ||
      grid != oldDelegate.grid;
}

class MemorySaverPage extends StatelessWidget {
  static const routeName = 'memory_saver';
  const MemorySaverPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    return SettingsPageLayout(
      title: Text(l.memorySaver, style: Theme.of(context).textTheme.titleLarge),
      child: ListView(
        children: [
          RoundedSwitchListTile(
            autofocus: true,
            value: settings.memorySaverEnabled,
            onChanged: settings.setMemorySaverEnabled,
            title: Text(l.memorySaver),
          ),
          SettingsHelp(title: l.memoryTitle, text: l.memorySaverDescription),
        ],
      ),
    );
  }
}
