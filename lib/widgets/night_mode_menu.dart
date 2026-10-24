import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/night_mode_service.dart';
import 'side_panel_dialog.dart';
import 'settings/settings_panel_style.dart';
import 'menu_header_action.dart';
import 'launcher_dialog.dart';
import 'settings/night_mode_page.dart';
import 'settings/settings_panel.dart';
import 'rounded_switch_list_tile.dart';
import 'settings/focusable_settings_tile.dart';

class NightModeMenu extends StatefulWidget {
  final Rect anchor;
  const NightModeMenu({super.key, required this.anchor});

  @override
  State<NightModeMenu> createState() => _NightModeMenuState();
}

class _NightModeMenuState extends State<NightModeMenu> {
  final _actionNode = FocusNode();
  final _enabledNode = FocusNode();
  final _settingsNode = FocusNode();
  bool _settingsOpen = false;
  bool _busy = false;
  bool _failed = false;

  @override
  void dispose() {
    _actionNode.dispose();
    _enabledNode.dispose();
    _settingsNode.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    setState(() => _settingsOpen = true);
    await showLauncherDialog<void>(
      context: context,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) =>
          const SettingsPanel(initialRoute: NightModePage.routeName),
    );
    if (!mounted) return;
    setState(() => _settingsOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsNode.requestFocus();
    });
  }

  Future<void> _change(
    Future<void> Function() action, {
    bool closeMenu = true,
    FocusNode? restoreFocus,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await action();
      if (mounted && closeMenu) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (!closeMenu) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final node = restoreFocus ?? _actionNode;
            if (mounted && !_settingsOpen && node.canRequestFocus) {
              node.requestFocus();
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => SettingsPanelStyle(builder: _buildMenu);

  Widget _buildMenu(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<NightModeService>();
    final c = service.configuration;
    final now = DateTime.now();
    final intervals =
        c
            .intervals(now, solarDays: service.solarDays)
            .where((i) => i.$2.isAfter(now))
            .toList()
          ..sort((a, b) => a.$1.compareTo(b.$1));
    String date(DateTime? value) => value == null
        ? '—'
        : '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')} '
              '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    final active = service.intensity > 0;
    final until = active ? service.nextStart : service.nextEnd;
    final override =
        c.overrideMode != 'none' &&
        c.overrideUntil > now.millisecondsSinceEpoch;
    return ExcludeFocus(
      excluding: _settingsOpen,
      child: Offstage(
        offstage: _settingsOpen,
        child: Stack(
          children: [
            const Positioned.fill(child: LauncherPanelBackdrop()),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            SidePanelDialog(
              anchor: widget.anchor,
              width: 380,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(l.nightModeTitle)),
                          MenuHeaderAction(
                            focusNode: _settingsNode,
                            tooltip: l.settings,
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: _openSettings,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        c.scheduled
                            ? '${c.solar ? l.nightSolarSchedule : l.nightManualSchedule}\n'
                                  '${l.nightModeStart}: ${date(intervals.isEmpty ? null : intervals.first.$1)}\n'
                                  '${l.nightModeEnd}: ${date(intervals.isEmpty ? null : intervals.first.$2)}'
                            : l.nightScheduleInactive,
                        key: const ValueKey('night_mode_schedule'),
                      ),
                      if (override) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${c.overrideMode == 'on' ? l.nightTemporaryOn : l.nightTemporaryOff}: '
                          '${date(DateTime.fromMillisecondsSinceEpoch(c.overrideUntil))}',
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (_busy) const LinearProgressIndicator(),
                      if (_failed) Text(l.appError),
                      if (c.scheduled && !override && c.solar && until == null)
                        Text(l.nightSolarUnavailable),
                      if (c.scheduled)
                        FocusableSettingsTile(
                          key: const ValueKey('night_mode_temporary'),
                          focusNode: _actionNode,
                          autofocus: true,
                          // Traversal reveals the action when needed; opening
                          // must not center it by scrolling away the header.
                          scrollOnFocus: false,
                          enabled: !_busy && (override || until != null),
                          leading: Icon(
                            override
                                ? Icons.schedule
                                : active
                                ? Icons.pause_circle_outline
                                : Icons.wb_twilight,
                          ),
                          title: Text(
                            override
                                ? l.nightResumeSchedule
                                : active
                                ? l.nightSkipUntilNext
                                : l.nightEnableUntilMorning,
                          ),
                          trailing: override ? null : Text(date(until)),
                          onPressed: () => _change(
                            override
                                ? service.clearTemporaryMode
                                : () => service.temporaryMode(!active),
                            closeMenu: false,
                          ),
                        ),
                      RoundedSwitchListTile(
                        key: const ValueKey('night_mode_enabled'),
                        focusNode: _enabledNode,
                        autofocus: !c.scheduled || (!override && until == null),
                        enabled: !_busy,
                        title: Text(l.nightModeEnabled),
                        value: c.enabled,
                        onChanged: (value) => _change(
                          () => service.configure(
                            c.copyWith(enabled: value, clearOverrides: true),
                          ),
                          closeMenu: false,
                          restoreFocus: _enabledNode,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
