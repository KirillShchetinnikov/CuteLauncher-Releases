import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'launcher_dialog.dart';
import 'side_panel_dialog.dart';
import 'menu_header_action.dart';
import 'settings/settings_panel_style.dart';
import 'settings/information_settings_page.dart';
import 'settings/settings_panel.dart';

/// A local month view. It does not read device calendars or request permission.
class PanelCalendarDialog extends StatefulWidget {
  final DateTime? today;
  final Rect? anchor;
  const PanelCalendarDialog({super.key, this.today, this.anchor});
  @override
  State<PanelCalendarDialog> createState() => _PanelCalendarDialogState();
}

class _PanelCalendarDialogState extends State<PanelCalendarDialog> {
  late final DateTime _today = widget.today ?? DateTime.now();
  late DateTime _month = DateTime(_today.year, _today.month);
  void _move(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));
  bool _settingsOpen = false;
  final _settingsNode = FocusNode();
  @override
  void dispose() {
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
          const SettingsPanel(initialRoute: InformationSettingsPage.routeName),
    );
    if (!mounted) return;
    setState(() => _settingsOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) =>
      SettingsPanelStyle(builder: _buildCalendar);

  Widget _buildCalendar(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final offset = (_month.weekday % 7 - material.firstDayOfWeekIndex + 7) % 7;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((offset + days) / 7).ceil();
    final dialog = LauncherAlertDialog(
      title: Text(
        '${l.calendarTitle} · ${material.formatMonthYear(_month)}',
        key: const Key('calendar_month'),
      ),
      content: Table(
        children: [
          TableRow(
            children: [
              for (var i = 0; i < 7; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: Text(
                      material.narrowWeekdays[(material.firstDayOfWeekIndex +
                              i) %
                          7],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          for (var row = 0; row < rows; row++)
            TableRow(
              children: [
                for (var column = 0; column < 7; column++)
                  Builder(
                    builder: (_) {
                      final day = row * 7 + column - offset + 1;
                      if (day < 1 || day > days) return const SizedBox.shrink();
                      final date = DateTime(_month.year, _month.month, day);
                      final today = DateUtils.isSameDay(date, _today);
                      return Semantics(
                        label: material.formatFullDate(date),
                        selected: today,
                        child: Container(
                          key: ValueKey('calendar_day_$day'),
                          margin: const EdgeInsets.all(2),
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: today ? scheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                material.formatDecimal(day),
                                style: TextStyle(
                                  color: today ? scheme.onPrimary : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
      actions: [
        LauncherDialogButton(
          child: Semantics(
            label: material.previousMonthTooltip,
            child: const Icon(Icons.chevron_left),
          ),
          onPressed: () => _move(-1),
        ),
        LauncherDialogButton(
          autofocus: true,
          child: Text(material.currentDateLabel),
          onPressed: () =>
              setState(() => _month = DateTime(_today.year, _today.month)),
        ),
        LauncherDialogButton(
          child: Semantics(
            label: material.nextMonthTooltip,
            child: const Icon(Icons.chevron_right),
          ),
          onPressed: () => _move(1),
        ),
        if (widget.anchor == null)
          LauncherDialogButton(
            child: Text(l.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
    if (widget.anchor == null) return dialog;
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
              topInset: kToolbarHeight,
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DefaultTextStyle.merge(
                            style: Theme.of(context).textTheme.titleLarge,
                            child: dialog.title!,
                          ),
                        ),
                        MenuHeaderAction(
                          focusNode: _settingsNode,
                          tooltip: l.settings,
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: _openSettings,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    dialog.content!,
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      children: dialog.actions!,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
