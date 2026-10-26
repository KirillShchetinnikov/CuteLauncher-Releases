import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import '../../sleep_timer_configuration.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import '../rounded_switch_list_tile.dart';
import '../sleep_timer_label.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'settings_text_tile.dart';

Future<bool> _save(BuildContext context, SleepTimerConfiguration value) async {
  try {
    await context.read<SettingsService>().setSleepTimerConfiguration(value);
    return true;
  } catch (_) {
    if (context.mounted) {
      showActionNotice(
        context,
        AppLocalizations.of(context)!.sleepTimerSaveFailed,
        error: true,
      );
    }
    return false;
  }
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message,
) async {
  final l = AppLocalizations.of(context)!;
  return await showLauncherDialog<bool>(
        context: context,
        builder: (dialog) => LauncherAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            LauncherDialogButton(
              autofocus: true,
              isCancel: true,
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(l.cancel),
            ),
            LauncherDialogButton(
              primary: true,
              danger: true,
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(title),
            ),
          ],
        ),
      ) ==
      true;
}

class SleepTimerSettingsPage extends StatelessWidget {
  static const routeName = 'sleep_timer_settings';
  const SleepTimerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.sleepTimer),
      child: ListView(
        children: [
          FocusableSettingsTile(
            title: Text(l.settings),
            leading: const Icon(Icons.tune),
            onPressed: () => Navigator.push(
              context,
              SettingsRoute(
                settings: const RouteSettings(
                  name: SleepTimerOptionsPage.routeName,
                ),
                builder: (_) => const SleepTimerOptionsPage(),
              ),
            ),
          ),
          FocusableSettingsTile(
            title: Text(l.sleepTimerPresets),
            leading: const Icon(Icons.timer_outlined),
            onPressed: () => Navigator.push(
              context,
              SettingsRoute(
                settings: const RouteSettings(
                  name: SleepTimerPresetsPage.routeName,
                ),
                builder: (_) => const SleepTimerPresetsPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SleepTimerOptionsPage extends StatelessWidget {
  static const routeName = 'sleep_timer_options';
  static const displayRouteName = 'sleep_timer_display';
  const SleepTimerOptionsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final config = context.watch<SettingsService>().sleepTimerConfiguration;
    final labels = {
      'remaining': l.sleepTimerRemaining,
      'end': l.sleepTimerEndTime,
      'both': l.sleepTimerBoth,
    };
    return SettingsPageLayout(
      title: Text(l.settings),
      child: ListView(
        children: [
          FocusableSettingsTile(
            title: Text(l.sleepTimerDisplay),
            trailing: Text(labels[config.display]!),
            onPressed: () => Navigator.push(
              context,
              SettingsRoute(
                settings: const RouteSettings(
                  name: SleepTimerOptionsPage.displayRouteName,
                ),
                builder: (context) => _SleepTimerDisplayPage(labels: labels),
              ),
            ),
          ),
          RoundedSwitchListTile(
            title: Text(l.sleepTimerShowSeconds),
            value: config.showSeconds,
            onChanged: (value) =>
                _save(context, config.copyWith(showSeconds: value)),
          ),
          RoundedSwitchListTile(
            title: Text(l.sleepTimerCloseAfterSelection),
            value: config.closeAfterSelection,
            onChanged: (value) =>
                _save(context, config.copyWith(closeAfterSelection: value)),
          ),
        ],
      ),
    );
  }
}

class _SleepTimerDisplayPage extends StatelessWidget {
  final Map<String, String> labels;
  const _SleepTimerDisplayPage({required this.labels});
  @override
  Widget build(BuildContext context) {
    final config = context.watch<SettingsService>().sleepTimerConfiguration;
    return SettingsPageLayout(
      title: Text(AppLocalizations.of(context)!.sleepTimerDisplay),
      child: ListView(
        children: [
          for (final entry in labels.entries)
            FocusableSettingsTile(
              title: Text(entry.value),
              leading: Icon(
                config.display == entry.key
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              onPressed: () =>
                  _save(context, config.copyWith(display: entry.key)),
            ),
        ],
      ),
    );
  }
}

class SleepTimerPresetsPage extends StatefulWidget {
  static const routeName = 'sleep_timer_presets';
  const SleepTimerPresetsPage({super.key});
  @override
  State<SleepTimerPresetsPage> createState() => _SleepTimerPresetsPageState();
}

class _SleepTimerPresetsPageState extends State<SleepTimerPresetsPage> {
  String? _moving;
  bool _busy = false;
  final _nodes = <String, FocusNode>{};
  final _addNode = FocusNode();
  FocusNode _node(String id) => _nodes.putIfAbsent(id, () => FocusNode());
  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    _addNode.dispose();
    super.dispose();
  }

  void _focus(String? id) => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      (id == null ? _addNode : _node(id)).requestFocus();
    }
  });

  Future<void> _move(String id, int direction) async {
    if (_busy) return;
    setState(() => _busy = true);
    final config = context.read<SettingsService>().sleepTimerConfiguration;
    await _save(context, config.move(id, direction));
    if (!mounted) return;
    setState(() => _busy = false);
    _focus(id);
  }

  Future<void> _edit([SleepTimerPreset? preset]) async {
    final id = await Navigator.push<String>(
      context,
      SettingsRoute<String>(
        settings: const RouteSettings(name: SleepTimerEditorPage.routeName),
        builder: (_) => SleepTimerEditorPage(preset: preset),
      ),
    );
    if (!mounted) return;
    final presets = context
        .read<SettingsService>()
        .sleepTimerConfiguration
        .presets;
    _focus(
      presets.any((p) => p.id == (id ?? preset?.id)) ? id ?? preset?.id : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final config = context.watch<SettingsService>().sleepTimerConfiguration;
    return PopScope(
      canPop: _moving == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _moving != null) setState(() => _moving = null);
      },
      child: SettingsPageLayout(
        title: Text(l.sleepTimerPresets),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final visible in [true, false]) ...[
                Text(visible ? l.sleepTimerVisible : l.sleepTimerHidden),
                for (final preset in config.presets.where(
                  (p) => p.visible == visible,
                ))
                  FocusableSettingsTile(
                    key: ValueKey(preset.id),
                    focusNode: _node(preset.id),
                    selected: _moving == preset.id,
                    title: Text(sleepTimerPresetLabel(l, preset.seconds)),
                    leading: Icon(
                      _moving == preset.id
                          ? Icons.drag_indicator
                          : Icons.drag_handle,
                    ),
                    trailing: _moving == preset.id
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.keyboard_arrow_up),
                              Icon(Icons.keyboard_arrow_down),
                            ],
                          )
                        : null,
                    onLongPress: () => setState(() => _moving = preset.id),
                    onPressed: () {
                      if (_moving == preset.id) {
                        setState(() => _moving = null);
                      } else {
                        _edit(preset);
                      }
                    },
                    onKeyEvent: (_, event) {
                      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                        return KeyEventResult.ignored;
                      }
                      final key = event.logicalKey;
                      if (_moving == preset.id) {
                        if (key == LogicalKeyboardKey.arrowUp ||
                            key == LogicalKeyboardKey.arrowDown) {
                          _move(
                            preset.id,
                            key == LogicalKeyboardKey.arrowUp ? -1 : 1,
                          );
                          return KeyEventResult.handled;
                        }
                        if ([
                          LogicalKeyboardKey.enter,
                          LogicalKeyboardKey.select,
                          LogicalKeyboardKey.gameButtonA,
                          LogicalKeyboardKey.escape,
                          LogicalKeyboardKey.arrowLeft,
                          LogicalKeyboardKey.arrowRight,
                        ].contains(key)) {
                          setState(() => _moving = null);
                          return KeyEventResult.handled;
                        }
                      } else if (key == LogicalKeyboardKey.arrowLeft ||
                          key == LogicalKeyboardKey.arrowRight) {
                        setState(() => _moving = preset.id);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                  ),
              ],
              const Divider(),
              FocusableSettingsTile(
                focusNode: _addNode,
                leading: const Icon(Icons.add),
                title: Text(l.sleepTimerAdd),
                onPressed: _busy ? null : () => _edit(),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.restore),
                title: Text(l.sleepTimerReset),
                onPressed: _busy
                    ? null
                    : () async {
                        if (!await _confirm(
                              context,
                              l.sleepTimerReset,
                              l.sleepTimerResetConfirmation,
                            ) ||
                            !context.mounted) {
                          return;
                        }
                        setState(() {
                          _busy = true;
                          _moving = null;
                        });
                        final latest = context
                            .read<SettingsService>()
                            .sleepTimerConfiguration;
                        final saved = await _save(
                          context,
                          latest.copyWith(
                            presets: SleepTimerConfiguration.defaults,
                          ),
                        );
                        if (mounted) {
                          setState(() => _busy = false);
                          if (saved) {
                            _focus(SleepTimerConfiguration.defaults.first.id);
                          }
                        }
                      },
              ),
              Text(l.sleepTimerReorderHint),
            ],
          ),
        ),
      ),
    );
  }
}

class SleepTimerEditorPage extends StatefulWidget {
  static const routeName = 'sleep_timer_editor';
  final SleepTimerPreset? preset;
  const SleepTimerEditorPage({super.key, this.preset});
  @override
  State<SleepTimerEditorPage> createState() => _SleepTimerEditorPageState();
}

class _SleepTimerEditorPageState extends State<SleepTimerEditorPage> {
  late String _hours = '${(widget.preset?.seconds ?? 0) ~/ 3600}';
  late String _minutes = '${(widget.preset?.seconds ?? 0) ~/ 60 % 60}';
  late String _seconds = '${(widget.preset?.seconds ?? 0) % 60}';
  bool _busy = false;
  Future<void> _submit() async {
    if (_busy) return;
    final h = int.tryParse(_hours),
        m = int.tryParse(_minutes),
        s = int.tryParse(_seconds);
    if (h == null ||
        m == null ||
        s == null ||
        h < 0 ||
        h > 999999 ||
        m < 0 ||
        m > 59 ||
        s < 0 ||
        s > 59 ||
        !validSleepTimerSeconds(h * 3600 + m * 60 + s)) {
      showActionNotice(
        context,
        AppLocalizations.of(context)!.sleepTimerInvalidDuration,
        error: true,
      );
      return;
    }
    setState(() => _busy = true);
    final config = context.read<SettingsService>().sleepTimerConfiguration;
    final id =
        widget.preset?.id ?? 'custom_${DateTime.now().microsecondsSinceEpoch}';
    final replacement = SleepTimerPreset(
      id,
      h * 3600 + m * 60 + s,
      visible: widget.preset?.visible ?? true,
    );
    final presets = widget.preset == null
        ? [
            ...config.presets.where((p) => p.visible),
            replacement,
            ...config.presets.where((p) => !p.visible),
          ]
        : [
            for (final p in config.presets)
              if (p.id == id) replacement else p,
          ];
    final saved = await _save(context, config.copyWith(presets: presets));
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(widget.preset == null ? l.sleepTimerAdd : l.sleepTimerEdit),
      child: ListView(
        children: [
          SettingsTextTile(
            title: l.sleepTimerHoursLabel,
            value: _hours,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onChanged: (v) => setState(() => _hours = v),
          ),
          SettingsTextTile(
            title: l.sleepTimerMinutesLabel,
            value: _minutes,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            maxLength: 2,
            onChanged: (v) => setState(() => _minutes = v),
          ),
          SettingsTextTile(
            title: l.sleepTimerSecondsLabel,
            value: _seconds,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            maxLength: 2,
            onChanged: (v) => setState(() => _seconds = v),
          ),
          FocusableSettingsTile(
            title: Text(l.save),
            leading: const Icon(Icons.save_outlined),
            onPressed: _busy ? null : _submit,
          ),
          if (widget.preset != null)
            FocusableSettingsTile(
              title: Text(l.delete),
              leading: const Icon(Icons.delete_outline),
              onPressed: _busy
                  ? null
                  : () async {
                      if (!await _confirm(
                            context,
                            l.delete,
                            l.sleepTimerDeleteConfirmation,
                          ) ||
                          !context.mounted) {
                        return;
                      }
                      setState(() => _busy = true);
                      final config = context
                          .read<SettingsService>()
                          .sleepTimerConfiguration;
                      final saved = await _save(
                        context,
                        config.copyWith(
                          presets: config.presets
                              .where((p) => p.id != widget.preset!.id)
                              .toList(),
                        ),
                      );
                      if (!context.mounted) return;
                      setState(() => _busy = false);
                      if (saved) Navigator.pop(context);
                    },
            ),
        ],
      ),
    );
  }
}
