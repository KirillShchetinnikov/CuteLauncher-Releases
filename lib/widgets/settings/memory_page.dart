import 'settings_help.dart';
import 'package:flauncher/widgets/action_notice.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/memory_resources.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';

class MemoryPage extends StatefulWidget {
  static const routeName = 'memory_panel';
  final FLauncherChannel? channel;
  const MemoryPage({super.key, this.channel});
  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  bool _busy = false;
  bool _failed = false;
  Map<String, dynamic> _process = {};
  int? _encodedBytes;
  int? _decodedBytes;
  Map<MemoryCacheKind, MemoryCacheStats>? _breakdown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });
  }

  void _readCaches() {
    final resources = context.read<MemoryResources>();
    _encodedBytes = resources.encodedImages.bytes;
    _breakdown = resources.cacheBreakdown;
    _decodedBytes = PaintingBinding.instance.imageCache.currentSizeBytes;
  }

  Future<void> _measure() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _readCaches();
    });
    Map<String, dynamic> result = {};
    var failed = false;
    try {
      result = await (widget.channel ?? FLauncherChannel())
          .getProcessMemoryUsage();
    } catch (_) {
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      _process = result;
      _failed = failed || result['pssBytes'] is! num;
      _readCaches();
      _busy = false;
    });
  }

  String _bytes(dynamic bytes, AppLocalizations l) {
    if (bytes is! num || !bytes.isFinite || bytes < 0) {
      return l.memoryUnavailable;
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ${l.memoryUnit}';
  }

  Widget _block(String title, IconData icon, List<(String, dynamic)> metrics) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0) const Divider(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(metrics[i].$1, style: theme.textTheme.bodyMedium),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    _bytes(metrics[i].$2, l),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    return SettingsPageLayout(
      title: Text(l.memoryTitle, style: Theme.of(context).textTheme.titleLarge),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FocusableSettingsTile(
              autofocus: true,
              leading: const Icon(Icons.memory),
              title: Text(l.memorySaver),
              trailing: Text(
                settings.memorySaverEnabled ? l.enabled : l.disabled,
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  SettingsRoute<void>(
                    settings: const RouteSettings(
                      name: MemorySaverPage.routeName,
                    ),
                    builder: (_) => const Material(
                      type: MaterialType.transparency,
                      child: MemorySaverPage(),
                    ),
                  ),
                );
                if (mounted) _measure();
              },
            ),
            FocusableSettingsTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: Text(l.memoryClear),
              onPressed: () {
                context.read<MemoryResources>().clearRecoverableCaches();
                setState(_readCaches);
                showActionNotice(context, '${l.memoryClear}: ${l.actionCompleted}');
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
              child: Text(
                '${l.memoryCacheSize}: ${_bytes(_encodedBytes == null || _decodedBytes == null ? null : _encodedBytes! + _decodedBytes!, l)}',
              ),
            ),
            FocusableSettingsTile(
              leading: const Icon(Icons.refresh),
              title: Text(_busy ? l.memoryMeasuring : l.memoryRefresh),
              onPressed: _busy ? null : _measure,
            ),
            _block(l.memoryProcess, Icons.analytics_outlined, [
              (l.memoryPss, _process['pssBytes']),
              (l.memoryRss, _process['rssBytes']),
              (l.memoryGraphics, _process['graphicsBytes']),
            ]),
            if (_failed)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(l.memoryMeasurementFailed),
              ),
            _block(l.memoryImages, Icons.image_outlined, [
              (l.memoryEncodedCache, _encodedBytes),
              (l.memoryDecodedCache, _decodedBytes),
            ]),
            _block(l.memoryFeatures, Icons.grid_view_outlined, [
              (l.memoryAppIcons, _breakdown?[MemoryCacheKind.appIcons]?.bytes),
              (
                l.memoryAppBanners,
                _breakdown?[MemoryCacheKind.appBanners]?.bytes,
              ),
              (
                l.memoryWatchNextPosters,
                _breakdown?[MemoryCacheKind.watchNextPosters]?.bytes,
              ),
              (l.memoryOtherCaches, _breakdown?[MemoryCacheKind.other]?.bytes),
            ]),
          ],
        ),
      ),
    );
  }
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
          SettingsHelp(text: l.memorySaverDescription),
        ],
      ),
    );
  }
}
