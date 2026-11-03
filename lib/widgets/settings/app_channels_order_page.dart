import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_channels_service.dart';
import '../../providers/settings_service.dart';
import '../action_notice.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';

class AppChannelsOrderPage extends StatefulWidget {
  static const routeName = 'app_channels_order';
  const AppChannelsOrderPage({super.key});

  @override
  State<AppChannelsOrderPage> createState() => _AppChannelsOrderPageState();
}

class _AppChannelsOrderPageState extends State<AppChannelsOrderPage> {
  final _nodes = <String, FocusNode>{};
  String? _moving;
  bool _busy = false;

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _move(String key, int delta) async {
    if (_busy) return;
    final settings = context.read<SettingsService>();
    final order = settings.selectedAppChannels.toList();
    final index = order.indexOf(key), next = index + delta;
    if (index < 0 || next < 0 || next >= order.length) return;
    order.removeAt(index);
    order.insert(next, key);
    _busy = true;
    try {
      await settings.setSelectedAppChannels(order);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final node = _nodes[key];
        node?.requestFocus();
        if (node?.context != null) Scrollable.ensureVisible(node!.context!);
      });
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.appChannelsSaveFailed,
          error: true,
        );
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final order = context.watch<SettingsService>().selectedAppChannels;
    final channels = context.watch<AppChannelsService>().channels;
    return PopScope(
      canPop: _moving == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _moving != null) setState(() => _moving = null);
      },
      child: SettingsPageLayout(
        title: Text('${l.reorder} · ${l.appChannelsTitle}'),
        child: ListView(
          children: [
            // These are active remote-control instructions, so they stay visible.
            Text(l.backgroundInformationOrderHint),
            for (final key in order)
              FocusableSettingsTile(
                key: ValueKey(key),
                autofocus: key == order.first,
                focusNode: _nodes.putIfAbsent(key, () => FocusNode()),
                title: Text(
                  channels
                          .where((c) => c.key == key)
                          .map((c) => '${c.name} · ${c.appName}')
                          .firstOrNull ??
                      '${l.appChannelsMissing}\n$key',
                ),
                selected: _moving == key,
                trailing: _moving == key
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l.reorder),
                          const Icon(Icons.unfold_more),
                        ],
                      )
                    : const Icon(Icons.swap_vert),
                onPressed: () =>
                    setState(() => _moving = _moving == key ? null : key),
                onLongPress: () => setState(() => _moving = key),
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                    return KeyEventResult.ignored;
                  }
                  final button = event.logicalKey;
                  if (event is KeyDownEvent &&
                      (button == LogicalKeyboardKey.arrowLeft ||
                          button == LogicalKeyboardKey.arrowRight)) {
                    setState(() => _moving = _moving == key ? null : key);
                    return KeyEventResult.handled;
                  }
                  if (_moving == key && button == LogicalKeyboardKey.escape) {
                    setState(() => _moving = null);
                    return KeyEventResult.handled;
                  }
                  if (button == LogicalKeyboardKey.arrowUp ||
                      button == LogicalKeyboardKey.arrowDown) {
                    final delta = button == LogicalKeyboardKey.arrowUp ? -1 : 1;
                    if (_moving == key) {
                      _move(key, delta);
                    } else {
                      final next = order.indexOf(key) + delta;
                    if (next < 0 || next >= order.length) {
                        return KeyEventResult.ignored;
                    }
                      _nodes[order[next]]?.requestFocus();
                    }
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
              ),
          ],
        ),
      ),
    );
  }
}
