import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import '../../quick_actions.dart';
import '../quick_action_presentation.dart';
import '../rounded_switch_list_tile.dart';
import '../action_notice.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_information.dart';
import 'settings_page_layout.dart';

class QuickActionsSettingsPage extends StatelessWidget {
  static const routeName = 'quick_actions_settings';
  const QuickActionsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final order = settings.quickActionsOrder;
    final enabled = settings.quickActions;
    return SettingsPageLayout(
      title: Text(l.quickActionsSettings),
      child: ListView(
        children: [
          for (final action in order)
            RoundedSwitchListTile(
              key: ValueKey(action),
              autofocus: action == order.first,
              value: enabled.contains(action),
              title: Text(action.label(l)),
              secondary: Icon(action.icon),
              onChanged: (show) {
                final actions = settings.quickActions.toSet();
                if (show) {
                  actions.add(action);
                } else {
                  actions.remove(action);
                }
                settings.setQuickActions(actions.toList());
              },
            ),
          FocusableSettingsTile(
            title: Text(l.reorder),
            leading: const Icon(Icons.swap_vert),
            onPressed: () =>
                Navigator.of(context)
                    .pushNamed(QuickActionsOrderPage.routeName),
          ),
          SettingsHelp(title: l.tvPowerTitle, text: l.quickActionsPowerHelp),
        ],
      ),
    );
  }
}

class QuickActionsOrderPage extends StatefulWidget {
  static const routeName = 'quick_actions_order';
  const QuickActionsOrderPage({super.key});

  @override
  State<QuickActionsOrderPage> createState() => _QuickActionsOrderPageState();
}

class _QuickActionsOrderPageState extends State<QuickActionsOrderPage> {
  QuickAction? _moving;
  bool _saving = false;

  void _select(QuickAction action) {
    setState(() => _moving = _moving == action ? null : action);
  }

  Future<void> _move(QuickAction action, int delta) async {
    if (_saving) return;
    final settings = context.read<SettingsService>();
    final order = settings.quickActionsOrder;
    final index = order.indexOf(action);
    final target = index + delta;
    if (target < 0 || target >= order.length) return;
    order.removeAt(index);
    order.insert(target, action);
    _saving = true;
    try {
      await settings.setQuickActionsOrder(order);
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.appError,
          error: true,
        );
      }
    } finally {
      _saving = false;
    }
  }

  KeyEventResult _handleKey(QuickAction action, KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.arrowRight)) {
      _select(action);
      return KeyEventResult.handled;
    }
    if (_moving == action &&
        (event is KeyDownEvent || event is KeyRepeatEvent)) {
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown) {
        _move(action, key == LogicalKeyboardKey.arrowUp ? -1 : 1);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final order = context.watch<SettingsService>().quickActionsOrder;
    return PopScope(
      canPop: _moving == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _moving != null) setState(() => _moving = null);
      },
      child: SettingsPageLayout(
        title: Text(l.reorder),
        footer: SettingsControlHint(text: l.backgroundInformationOrderHint),
        child: ListView(
          children: [
            for (final action in order)
              FocusableSettingsTile(
                key: ValueKey(action),
                autofocus: action == order.first && _moving == null,
                title: Text(action.label(l)),
                leading: Icon(action.icon),
                selected: _moving == action,
                trailing: Icon(
                  _moving == action ? Icons.unfold_more : Icons.swap_vert,
                ),
                onPressed: () => _select(action),
                onKeyEvent: (_, event) => _handleKey(action, event),
              ),
          ],
        ),
      ),
    );
  }
}
