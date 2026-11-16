import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../application_info_configuration.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import '../../theme/interface_style.dart';
import '../action_notice.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_information.dart';
import 'settings_page_layout.dart';

class ApplicationInfoSettingsPage extends StatefulWidget {
  const ApplicationInfoSettingsPage({super.key});

  @override
  State<ApplicationInfoSettingsPage> createState() =>
      _ApplicationInfoSettingsPageState();
}

class _ApplicationInfoSettingsPageState
    extends State<ApplicationInfoSettingsPage> {
  final _nodes = {
    for (final action in ApplicationInfoAction.values) action: FocusNode(),
  };
  ApplicationInfoAction? _moving;
  List<ApplicationInfoAction>? _draftOrder;
  bool _saving = false;

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _save(ApplicationInfoConfiguration configuration) async {
    if (_saving) return;
    final settings = context.read<SettingsService>();
    setState(() => _saving = true);
    try {
      await settings.setApplicationInfoConfiguration(configuration);
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

  void _startMove(
    ApplicationInfoAction action,
    List<ApplicationInfoAction> order,
  ) {
    if (_saving || _moving != null) return;
    setState(() {
      _moving = action;
      _draftOrder = List.of(order);
    });
    _nodes[action]!.requestFocus();
  }

  void _move(ApplicationInfoAction action, int delta) {
    final order = _draftOrder!;
    final index = order.indexOf(action);
    final target = index + delta;
    if (target < 0 || target >= order.length) return;
    setState(() {
      order.removeAt(index);
      order.insert(target, action);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _moving != action) return;
      final rowContext = _nodes[action]!.context;
      if (rowContext != null) {
        Scrollable.ensureVisible(
          rowContext,
          alignmentPolicy: delta < 0
              ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
              : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  void _finishMove(ApplicationInfoConfiguration configuration) {
    final order = _draftOrder;
    if (order == null) return;
    setState(() {
      _moving = null;
      _draftOrder = null;
    });
    _save(configuration.copyWith(order: order));
  }

  KeyEventResult _handleKey(
    ApplicationInfoAction action,
    ApplicationInfoConfiguration configuration,
    KeyEvent event,
  ) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      if (event is KeyDownEvent) {
        if (_moving == null) {
          _startMove(action, configuration.order);
        } else if (_moving == action) {
          _finishMove(configuration);
        }
      }
      return KeyEventResult.handled;
    }
    if (_moving == action &&
        (key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.arrowDown)) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        _move(action, key == LogicalKeyboardKey.arrowUp ? -1 : 1);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final skin = InterfaceSkin.of(context);
    final configuration = ApplicationInfoConfiguration.decode(
      context.select<SettingsService, String?>(
        (settings) => settings.storedApplicationInfoConfiguration,
      ),
    );
    final moving = _moving;
    final order = _draftOrder ?? configuration.order;
    return PopScope(
      canPop: moving == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finishMove(configuration);
      },
      child: SettingsPageLayout(
        title: Text(l.applicationInfoSettings),
        footer: SettingsControlHint(
          text: moving == null
              ? l.applicationInfoButtonsHint
              : l.applicationInfoMovingHint,
        ),
        child: ListView(
          children: [
            RoundedSwitchListTile(
              title: Text(l.applicationInfoCheckOnOpen),
              autofocus: true,
              busy: moving != null || _saving,
              value: configuration.checkOnOpen,
              onChanged: (value) =>
                  _save(configuration.copyWith(checkOnOpen: value)),
            ),
            SettingsHelp(
              title: l.applicationInfoSettings,
              text: l.applicationInfoProcessHelp,
            ),
            for (final action in order)
              FocusableSettingsTile(
                key: ValueKey(action),
                focusNode: _nodes[action],
                title: Text(action.label(l)),
                leading: Icon(action.icon),
                toggled: !configuration.hidden.contains(action),
                selected: moving == action,
                busy: _saving || moving != null && moving != action,
                onPressed: () {
                  if (moving != null) {
                    _finishMove(configuration);
                    return;
                  }
                  final hidden = {...configuration.hidden};
                  if (!hidden.remove(action)) hidden.add(action);
                  _save(configuration.copyWith(hidden: hidden));
                },
                onKeyEvent: (_, event) =>
                    _handleKey(action, configuration, event),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (moving != action)
                      ExcludeFocus(
                        child: ExcludeSemantics(
                          child: IgnorePointer(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: skin.standard ? 16 : 26,
                              ),
                              child: skin.standard
                                  ? Switch(
                                      value: !configuration.hidden.contains(
                                        action,
                                      ),
                                      onChanged: (_) {},
                                    )
                                  : SkinSwitch(
                                      value: !configuration.hidden.contains(
                                        action,
                                      ),
                                      enabled: true,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ExcludeFocus(
                      child: IconButton(
                        tooltip: l.reorder,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          moving == action
                              ? Icons.unfold_more
                              : Icons.swap_vert,
                        ),
                        onPressed: _saving || moving != null && moving != action
                            ? null
                            : moving == action
                            ? () => _finishMove(configuration)
                            : () => _startMove(action, order),
                      ),
                    ),
                  ],
                ),
              ),
            FocusableSettingsTile(
              title: Text(l.informationResetTypography),
              leading: const Icon(Icons.restart_alt),
              busy: moving != null || _saving,
              onPressed: () =>
                  _save(const ApplicationInfoConfiguration.defaults()),
            ),
          ],
        ),
      ),
    );
  }
}
