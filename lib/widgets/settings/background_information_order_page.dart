import 'settings_information.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/appearance_service.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';

/// The wallpaper order is independent of either panel's object order.
class BackgroundInformationOrderPage extends StatefulWidget {
  static const routeName = 'background_information_order';
  const BackgroundInformationOrderPage({super.key});

  @override
  State<BackgroundInformationOrderPage> createState() =>
      _BackgroundInformationOrderPageState();
}

class _BackgroundInformationOrderPageState
    extends State<BackgroundInformationOrderPage> {
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

  Future<void> _move(String id, int delta) async {
    if (_busy) return;
    final service = context.read<AppearanceService>();
    final order = service.appearance.backgroundInformationOrder;
    final index = order.indexOf(id);
    final next = index + delta;
    if (index < 0 || next < 0 || next >= order.length) return;
    order.removeAt(index);
    order.insert(next, id);
    _busy = true;
    try {
      await service.set('panelBackgroundInformationOrder', order);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nodes[id]?.requestFocus();
      });
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final order = context
        .watch<AppearanceService>()
        .appearance
        .backgroundInformationOrder;
    return PopScope(
      canPop: _moving == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _moving != null) setState(() => _moving = null);
      },
      child: SettingsPageLayout(
        title: Text(l.panelObjectOrder),
        showObscuredInformationPreview: false,
        child: ListView(
          children: [
            for (final id in order)
              FocusableSettingsTile(
                key: ValueKey(id),
                focusNode: _nodes.putIfAbsent(id, () => FocusNode()),
                title: Text(switch (id) {
                  'time' => l.informationTime,
                  'date' => l.informationDate,
                  _ => l.weather,
                }),
                selected: _moving == id,
                trailing: _moving == id
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l.reorder),
                          const Icon(Icons.unfold_more),
                        ],
                      )
                    : const Icon(Icons.swap_vert),
                onPressed: () =>
                    setState(() => _moving = _moving == id ? null : id),
                onLongPress: () => setState(() => _moving = id),
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                    return KeyEventResult.ignored;
                  }
                  final key = event.logicalKey;
                  if (event is KeyDownEvent &&
                      (key == LogicalKeyboardKey.arrowLeft ||
                          key == LogicalKeyboardKey.arrowRight)) {
                    setState(() => _moving = _moving == id ? null : id);
                    return KeyEventResult.handled;
                  }
                  if (_moving == id && key == LogicalKeyboardKey.escape) {
                    setState(() => _moving = null);
                    return KeyEventResult.handled;
                  }
                  if (key == LogicalKeyboardKey.arrowUp ||
                      key == LogicalKeyboardKey.arrowDown) {
                    final delta = key == LogicalKeyboardKey.arrowUp ? -1 : 1;
                    if (_moving == id) {
                      _move(id, delta);
                    } else {
                      final next = order.indexOf(id) + delta;
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
            SettingsControlHint(text: l.backgroundInformationOrderHint),
          ],
        ),
      ),
    );
  }
}
