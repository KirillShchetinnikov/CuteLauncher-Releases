import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/interface_style.dart';
import 'launcher_dialog.dart';
import 'side_panel_dialog.dart';
import 'menu_header.dart';
import 'menu_header_action.dart';
import 'settings/settings_panel_style.dart';
import 'settings/information_settings_page.dart';
import 'settings/settings_panel.dart';

/// A local month view. It does not read device calendars or request permission.
class PanelCalendarDialog extends StatefulWidget {
  final DateTime? today;
  final Rect? anchor;
  final bool embedded;
  final bool autofocusSettings;
  final VoidCallback? onSettingsClosed;
  const PanelCalendarDialog({
    super.key,
    this.today,
    this.anchor,
    this.embedded = false,
    this.autofocusSettings = false,
    this.onSettingsClosed,
  });
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
      parentPanelHidden: true,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) =>
          const SettingsPanel(initialRoute: InformationSettingsPage.routeName),
    );
    if (!mounted) return;
    setState(() => _settingsOpen = false);
    widget.onSettingsClosed?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) => widget.embedded
      ? _buildCalendar(context)
      : SettingsPanelStyle(builder: _buildCalendar);

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
                      final weekend =
                          date.weekday == DateTime.saturday ||
                          date.weekday == DateTime.sunday;
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
                            color: today
                                ? weekend
                                      ? scheme.errorContainer
                                      : scheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                material.formatDecimal(day),
                                style: TextStyle(
                                  color: weekend
                                      ? scheme.error
                                      : today
                                      ? scheme.onPrimary
                                      : null,
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
        if (widget.anchor == null && !widget.embedded)
          LauncherDialogButton(
            child: Text(l.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
    if (widget.embedded) {
      return Container(
        key: const Key('embedded_calendar'),
        padding: const EdgeInsets.all(12),
        decoration: InterfaceSkin.of(context).surface(
          scheme.onSurface.withValues(alpha: .035),
          scheme.onSurface,
          borderWidth: 1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.calendar_month_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    material.formatMonthYear(_month),
                    key: const Key('calendar_month'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            dialog.content!,
            const Divider(height: 16),
            Wrap(alignment: WrapAlignment.center, children: dialog.actions!),
          ],
        ),
      );
    }
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
                    MenuHeader(
                      title: dialog.title!,
                      actions: [
                        MenuHeaderAction(
                          focusNode: _settingsNode,
                          autofocus: widget.autofocusSettings,
                          tooltip: l.settings,
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: _openSettings,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
