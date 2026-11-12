import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../launcher_dialog.dart';

import '../../backup_schedule.dart';
import '../../backup_sync.dart';
import '../../backup_sync_groups.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/automatic_backup_service.dart';
import '../../providers/backup_automation_service.dart';
import 'automatic_backup_page.dart';
import 'backup_feature_page.dart';
import 'backup_storage_page.dart';
import 'backup_sync_groups_page.dart';
import 'focusable_settings_tile.dart';
import 'settings_checkbox_tile.dart';
import 'settings_section.dart';
import 'settings_help.dart';
import 'settings_option_tile.dart';
import 'settings_page_layout.dart';
import 'settings_panel_style.dart';
import 'settings_read_only_value.dart';
import 'settings_text_tile.dart';
import 'settings_time_tile.dart';
import 'settings_value_stepper.dart';

Future<bool?> showBackupSetup(
  BuildContext context,
  BackupAutomationService service,
) async {
  Map<String, Object> snapshot;
  try {
    snapshot = await service.beginSetup();
  } catch (_) {
    return false;
  }
  if (!context.mounted) {
    await service.endSetup(snapshot, keep: false);
    return false;
  }
  (bool, bool)? result;
  try {
    result = await Navigator.of(context, rootNavigator: true)
        .push<(bool, bool)>(
          MaterialPageRoute(
            builder: (_) => backupServiceScope(
              service,
              ChangeNotifierProvider<AutomaticBackupService>.value(
                value: service.local,
                child: const BackupSetupWizard(),
              ),
            ),
          ),
        );
  } finally {
    await service.endSetup(snapshot, keep: result?.$2 ?? false);
  }
  return result?.$1 ?? false;
}

/// One explicit final action starts automation. Changing a step never transfers data.
class BackupSetupWizard extends StatefulWidget {
  const BackupSetupWizard({super.key});
  @override
  State<BackupSetupWizard> createState() => _BackupSetupWizardState();
}

class _BackupSetupWizardState extends State<BackupSetupWizard>
    with WidgetsBindingObserver {
  int _step = 0;
  bool _busy = false,
      _firstCopy = true,
      _all = true,
      _attempted = false,
      _configuredPassword = false,
      _allowPop = false;
  Set<BackupSyncGroup> _custom = {};
  String? _password;
  String _confirmation = '';
  String? _error;
  DateTime? _remote;
  BackupSyncResumeChoice? _choice;
  BackupAutomationService get service =>
      context.read<BackupAutomationService>();
  bool get sync => service.mode == BackupMode.synchronization;
  int get lastStep => sync ? 4 : 3;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _custom = {
      for (final g in BackupSyncGroup.values)
        if (!service.syncGroupEnabled(g)) g,
    };
    _all = _custom.isEmpty;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _run(() async {
        _configuredPassword = await service.protection.configured();
      }),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _password = null;
    _confirmation = '';
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() {
        _password = null;
        _confirmation = '';
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        _error = AppLocalizations.of(context)!.backupSyncGroupsFailed;
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _close(bool success) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop((success, success || _attempted));
    });
  }

  void _back() {
    if (_busy) return;
    if (_step > 0) {
      setState(() => _step--);
    } else {
      _close(false);
    }
  }

  Future<void> _next() => _run(() async {
    final l = AppLocalizations.of(context)!;
    if (_step == 2 && _password != null && _password != _confirmation) {
      _error = l.backupPasswordMismatch;
      return;
    }
    if (_step == 2 && sync) {
      _remote = await service.inspectSynchronization();
      _choice = null;
    }
    if (_step < lastStep) {
      _step++;
      return;
    }
    _attempted = true;
    await service.configure(enabled: false);
    if (_password != null) await service.setPassword(_password!);
    final ok = sync
        ? await service.resumeSynchronization((_, remote) async {
            if (_remote != remote) {
              _remote = remote;
              _choice = null;
              _step = 3;
              return null;
            }
            return _choice;
          })
        : !_firstCopy || await service.run(manual: true);
    if (!mounted) return;
    if (!ok) {
      _error = l.backupSyncRefreshFailed;
      return;
    }
    if (!sync) await service.configure(enabled: true);
    await service.completeSetup();
    _close(true);
  });
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<BackupAutomationService>();
    final local = context.watch<AutomaticBackupService>();
    final schedule = local.schedule;
    final busy = _busy || s.busy;
    final titles = [
      l.backupStorage,
      sync ? l.backupSyncSettings : l.backupOptions,
      l.backupPassword,
      if (sync) l.backupFirstExchange,
      l.backupSetupSummary,
    ];
    final choices = {
      BackupSyncResumeChoice.remote: l.backupSyncUseRemote,
      BackupSyncResumeChoice.local: l.backupSyncUseLocal,
      BackupSyncResumeChoice.mergeRemote: l.backupSyncMergeRemote,
      BackupSyncResumeChoice.mergeLocal: l.backupSyncMergeLocal,
    };
    Widget value(String label, String value) =>
        SettingsReadOnlyValue(label: label, value: value, wrapLines: true);
    Widget button(
      String label,
      Future<void> Function() action, {
      String? text,
    }) => FocusableSettingsTile(
      title: Text(label),
      trailing: text == null ? null : Text(text),
      busy: busy,
      onPressed: () => _run(action),
    );
    Future<void> scope() async {
      final v = await backupChoice(
        context,
        sync ? l.backupSyncScope : l.backupScope,
        {false: l.backupSeparate, true: l.backupShared},
        s.shared,
      );
      if (v != null) await s.configure(shared: v);
    }

    final contents = <Widget>[];
    if (_step == 0) {
      contents.add(const BackupStorageControls());
    }
    if (_step == 1) {
      if (sync) {
        contents.add(
          SettingsCheckboxTile(
            key: const ValueKey('syncAll'),
            title: Text(l.backupSyncAll),
            value: _all,
            busy: busy,
            onChanged: (v) => _run(() async {
              if (v) {
                _custom = {
                  for (final g in BackupSyncGroup.values)
                    if (!s.syncGroupEnabled(g)) g,
                };
              }
              await s.setSyncGroups(v ? {} : _custom);
              _all = v;
            }),
          ),
        );
        if (!_all) {
          final labels = backupSyncGroupLabels(l);
          final headings = backupSyncSectionLabels(l);
          for (final section in backupSyncSections.entries) {
            final count = section.value.where(s.syncGroupEnabled).length;
            contents.add(
              SettingsSection(
                key: ValueKey(section.key),
                title: headings[section.key]!,
                children: [
                  SettingsCheckboxTile(
                    key: ValueKey('syncSection-${section.key.name}'),
                    title: Text(
                      '${l.enabled} · $count/${section.value.length}',
                    ),
                    value: count > 0,
                    busy: busy,
                    onChanged: (enabled) => _run(() async {
                      final disabled = {
                        for (final group in BackupSyncGroup.values)
                          if (!s.syncGroupEnabled(group)) group,
                      };
                      if (enabled) {
                        disabled.removeAll(section.value);
                      } else {
                        disabled.addAll(section.value);
                      }
                      await s.setSyncGroups(disabled);
                    }),
                  ),
                  for (final group in section.value)
                    SettingsCheckboxTile(
                      key: ValueKey(group),
                      title: Text(labels[group]!),
                      value: s.syncGroupEnabled(group),
                      busy: busy,
                      onChanged: (v) =>
                          _run(() => s.setSyncGroupEnabled(group, v)),
                    ),
                ],
              ),
            );
          }
        }
        contents.add(
          SettingsValueStepper(
            title: l.backupSyncLimit,
            value: s.syncMinutes,
            options: const [1, 5, 15, 30, 60, 180, 1440],
            label: (v) => '$v ${l.backupMinutes}',
            busy: busy,
            onChanged: (v) => _run(() => s.configure(syncMinutes: v as int)),
          ),
        );
      } else {
        final frequencies = {
          BackupFrequency.hourly: l.backupHourly,
          BackupFrequency.daily: l.backupDaily,
          BackupFrequency.weekly: l.backupWeekly,
        };
        contents.add(
          button(l.backupFrequency, () async {
            final v = await backupChoice(
              context,
              l.backupFrequency,
              frequencies,
              schedule.frequency,
            );
            if (v != null) {
              await local.setSchedule(
                BackupSchedule(
                  frequency: v,
                  hour: schedule.hour,
                  minute: schedule.minute,
                  weekday: schedule.weekday,
                ),
              );
            }
          }, text: frequencies[schedule.frequency]),
        );
        if (schedule.frequency == BackupFrequency.hourly) {
          contents.add(
            SettingsValueStepper(
              title: l.backupTime,
              value: schedule.minute,
              options: [for (var n = 0; n < 60; n++) n],
              label: (v) => ':${v.toString().padLeft(2, '0')}',
              busy: busy,
              onChanged: (v) => _run(
                () => local.setSchedule(
                  BackupSchedule(
                    frequency: schedule.frequency,
                    hour: schedule.hour,
                    minute: v as int,
                    weekday: schedule.weekday,
                  ),
                ),
              ),
            ),
          );
        } else {
          contents.add(
            SettingsTimeTile(
              title: l.backupTime,
              value: schedule.hour * 60 + schedule.minute,
              onChanged: (v) => _run(
                () => local.setSchedule(
                  BackupSchedule(
                    frequency: schedule.frequency,
                    hour: v ~/ 60,
                    minute: v % 60,
                    weekday: schedule.weekday,
                  ),
                ),
              ),
            ),
          );
        }
        if (schedule.frequency == BackupFrequency.weekly) {
          contents.add(
            button(
              l.backupWeekday,
              () async {
                final v = await backupChoice(context, l.backupWeekday, {
                  for (var n = 1; n <= 7; n++)
                    n: DateFormat.EEEE(l.localeName)
                        .format(DateTime(2026, 10, 4 + n)),
                }, schedule.weekday);
                if (v != null) {
                  await local.setSchedule(
                    BackupSchedule(
                      frequency: schedule.frequency,
                      hour: schedule.hour,
                      minute: schedule.minute,
                      weekday: v,
                    ),
                  );
                }
              },
              text: DateFormat.EEEE(l.localeName)
                  .format(DateTime(2026, 10, 4 + schedule.weekday)),
            ),
          );
        }
        contents.add(
          SettingsValueStepper(
            title: l.automaticBackupsKeep,
            value: local.keepCount,
            options: const [1, 3, 5, 10],
            label: (v) => '$v',
            busy: busy,
            onChanged: (v) => _run(() => local.setKeepCount(v as int)),
          ),
        );
      }
      contents.add(
        button(
          sync ? l.backupSyncScope : l.backupScope,
          scope,
          text: s.shared ? l.backupShared : l.backupSeparate,
        ),
      );
    }
    if (_step == 2) {
      contents.addAll([
        value(
          l.backupPassword,
          _configuredPassword ? l.backupConfigured : l.backupNotConfigured,
        ),
        SettingsTextTile(
          title: l.backupPassword,
          value: _password ?? '',
          obscureText: true,
          maxLength: 1024,
          enabled: !busy,
          onChanged: (v) => setState(() => _password = v),
        ),
        SettingsTextTile(
          title: l.backupPasswordRepeat,
          value: _confirmation,
          obscureText: true,
          maxLength: 1024,
          enabled: !busy,
          onChanged: (v) => setState(() => _confirmation = v),
        ),
        SettingsHelp(
          title: l.backupPassword,
          text: l.backupPasswordOptionalHelp,
        ),
      ]);
    }
    if (sync && _step == 3) {
      contents.add(
        value(
          l.backupFirstExchange,
          _remote == null
              ? l.backupNoRemote
              : MaterialLocalizations.of(context).formatMediumDate(_remote!),
        ),
      );
      if (_remote != null) {
        contents.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(l.backupExistingSettingsHelp),
          ),
        );
        for (final entry in choices.entries) {
          contents.add(
            SettingsOptionTile(
              title: Text(entry.value),
              selected: _choice == entry.key,
              enabled: !busy,
              onPressed: () => setState(() => _choice = entry.key),
            ),
          );
        }
      }
    }
    if (_step == lastStep) {
      contents.addAll([
        value(l.backupStorage, backupDestinationLabel(l, s.destination)),
        if (s.destination != BackupDestination.local)
          value(l.backupAccount, backupAccountLabel(l, s)),
        value(
          sync ? l.backupSyncScope : l.backupScope,
          s.shared ? l.backupShared : l.backupSeparate,
        ),
        if (sync)
          value(
            l.backupSyncSettings,
            '${BackupSyncGroup.values.where(s.syncGroupEnabled).length}/${BackupSyncGroup.values.length}',
          ),
        if (sync)
          value(l.backupSyncLimit, '${s.syncMinutes} ${l.backupMinutes}'),
        if (sync)
          value(
            l.backupFirstExchange,
            _remote == null
                ? l.backupNoRemote
                : choices[_choice] ?? l.backupSyncUseRemote,
          ),
        if (!sync)
          value(
            l.backupFrequency,
            '${[l.backupHourly, l.backupDaily, l.backupWeekly][schedule.frequency.index]} · ${schedule.frequency == BackupFrequency.hourly ? '' : schedule.hour.toString().padLeft(2, '0')}:${schedule.minute.toString().padLeft(2, '0')}',
          ),
        if (!sync && schedule.frequency == BackupFrequency.weekly)
          value(
            l.backupWeekday,
            DateFormat.EEEE(l.localeName)
                .format(DateTime(2026, 10, 4 + schedule.weekday)),
          ),
        if (!sync) value(l.automaticBackupsKeep, '${local.keepCount}'),
        value(
          l.backupPassword,
          (_password?.isNotEmpty ?? _configuredPassword)
              ? l.enabled
              : l.disabled,
        ),
        if (!sync)
          SettingsCheckboxTile(
            title: Text(l.backupFirstCopy),
            value: _firstCopy,
            busy: busy,
            onChanged: (v) => setState(() => _firstCopy = v),
          ),
      ]);
    }
    final valid = _step != 0 || s.configured;
    final groupsValid =
        !sync || _step != 1 || BackupSyncGroup.values.any(s.syncGroupEnabled);
    final choiceValid =
        !sync || _step != 3 || _remote == null || _choice != null;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: SettingsPanelStyle(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SettingsPageLayout(
                    title: Text(l.backupSetupWizard),
                    subtitle: Text(
                      '${sync ? l.backupSyncMode : l.backupSaveMode} · ${_step + 1}/${titles.length} · ${titles[_step]}',
                    ),
                    footer: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        LauncherDialogButton(
                          onPressed: busy ? null : () => _close(false),
                          child: Text(l.cancel),
                        ),
                        if (_step > 0)
                          LauncherDialogButton(
                            onPressed: busy ? null : _back,
                            child: Text(l.backupSetupBack),
                          ),
                        LauncherDialogButton(
                          key: const ValueKey('backupSetupNext'),
                          primary: true,
                          onPressed:
                              busy || !valid || !groupsValid || !choiceValid
                              ? null
                              : _next,
                          child: Text(
                            _step == lastStep
                                ? l.backupSetupStart
                                : l.backupSetupNext,
                          ),
                        ),
                      ],
                    ),
                    child: ListView(
                      key: ValueKey(_step),
                      children: [
                        ...contents,
                        if (_error != null)
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        if (busy) const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
