import 'settings_information.dart';
import 'settings_list_heading.dart';
import 'settings_route.dart';
import 'app_channels_settings_page.dart';

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
  AppChannelsService? _service;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service = context.read<AppChannelsService>()..openCatalog();
    });
  }

  @override
  void dispose() {
    _service?.closeCatalog();
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
        if (node?.context != null) {
          Scrollable.ensureVisible(
            node!.context!,
            alignmentPolicy: delta < 0
                ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
                : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
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
    final selected = context.watch<SettingsService>().selectedAppChannels;
    final channels = {
      for (final channel in context.watch<AppChannelsService>().channels)
        channel.key: channel,
    };
    final shown = selected.where((key) => channels[key]?.hidden != true).toList();
    final hidden = channels.keys.where((key) => !selected.contains(key) && !channels[key]!.hidden).toList();
    final order = [...shown, ...hidden];
    return PopScope(
      canPop: _moving == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _moving != null) setState(() => _moving = null);
      },
      child: SettingsPageLayout(
        footer: SettingsControlHint(text: l.backgroundInformationOrderHint),
        title: Text(l.feedsAndOrder),
        child: ListView(
          children: [
            for (final key in order) ...[
              if (key == shown.firstOrNull)
                SettingsListHeading(title: l.visibleFeeds),
              if (key == hidden.firstOrNull)
                SettingsListHeading(title: l.hiddenFeeds),
              FocusableSettingsTile(
                key: ValueKey(key),
                autofocus: key == order.first,
                focusNode: _nodes.putIfAbsent(key, () => FocusNode()),
                leading: Icon(
                  _moving == key ? Icons.drag_indicator : Icons.drag_handle,
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(channels[key]?.name ?? l.appChannelsMissing),
                    Text(
                      channels[key]?.appName ?? key,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                selected: _moving == key,
                showActionChevron: false,
                trailing: _moving == key
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l.reorder),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.keyboard_arrow_up),
                              Icon(Icons.keyboard_arrow_down),
                            ],
                          ),
                        ],
                      )
                    : null,
                onPressed: () => _moving == key
                    ? setState(() => _moving = null)
                    : Navigator.of(context).push(SettingsRoute(
                        builder: (_) => AppChannelsSettingsPage(channelKey: key),
                      )),
                onLongPress: selected.contains(key) ? () => setState(() => _moving = key) : null,
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                    return KeyEventResult.ignored;
                  }
                  final button = event.logicalKey;
                  if (event is KeyRepeatEvent &&
                      button != LogicalKeyboardKey.arrowUp &&
                      button != LogicalKeyboardKey.arrowDown) {
                    return KeyEventResult.handled;
                  }
                  if (event is KeyDownEvent &&
                      selected.contains(key) &&
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
            // Active remote-control instructions stay visible, like section order.
          ],
        ),
      ),
    );
  }
}
