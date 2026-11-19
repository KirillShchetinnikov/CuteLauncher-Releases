import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import '../../quick_actions.dart';
import '../quick_action_presentation.dart';
import 'settings_reorder_controls.dart';
import '../action_notice.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_information.dart';
import 'settings_page_layout.dart';

class QuickActionsSettingsPage extends StatelessWidget {
  static const routeName = 'quick_actions_settings';
  const QuickActionsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const QuickActionsOrderPage(editVisibility: true);
}

class QuickActionsOrderPage extends StatefulWidget {
  static const routeName = 'quick_actions_order';
  final bool editVisibility;
  const QuickActionsOrderPage({super.key, this.editVisibility = false});

  @override
  State<QuickActionsOrderPage> createState() => _QuickActionsOrderPageState();
}

class _QuickActionsOrderPageState extends State<QuickActionsOrderPage> {
  QuickAction? _moving;
  bool _saving = false;

  Future<void> _toggle(QuickAction action) async {
    if (_saving) return;
    final settings = context.read<SettingsService>();
    final enabled = settings.quickActions.toSet();
    if (!enabled.remove(action)) enabled.add(action);
    setState(() => _saving = true);
    try {
      await settings.setQuickActions(enabled.toList());
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.appError,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
    final settings = context.watch<SettingsService>();
    final order = settings.quickActionsOrder;
    return PopScope(
      canPop: _moving == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _moving != null) setState(() => _moving = null);
      },
      child: SettingsPageLayout(
        title: Text(widget.editVisibility ? l.quickActionsTitle : l.reorder),
        footer: SettingsControlHint(
          text: widget.editVisibility
              ? (_moving == null
                    ? l.applicationInfoButtonsHint
                    : l.applicationInfoMovingHint)
              : l.backgroundInformationOrderHint,
        ),
        child: ListView(
          children: [
            for (final action in order)
              FocusableSettingsTile(
                key: ValueKey(action),
                autofocus: action == order.first && _moving == null,
                title: Text(action.label(l)),
                leading: Icon(action.icon),
                selected: _moving == action,
                toggled: widget.editVisibility
                    ? settings.quickActions.contains(action)
                    : null,
                busy: _saving || _moving != null && _moving != action,
                trailing: widget.editVisibility
                    ? SettingsReorderControls(
                        value: settings.quickActions.contains(action),
                        moving: _moving == action,
                        onReorder: _saving ? null : () => _select(action),
                      )
                    : Icon(
                        _moving == action ? Icons.unfold_more : Icons.swap_vert,
                      ),
                onPressed: () => widget.editVisibility && _moving == null
                    ? _toggle(action)
                    : _select(action),
                onLongPress: () => _select(action),
                onKeyEvent: (_, event) => _handleKey(action, event),
              ),
            if (widget.editVisibility)
              SettingsHelp(
                title: l.tvPowerTitle,
                text: l.quickActionsPowerHelp,
              ),
          ],
        ),
      ),
    );
  }
}
