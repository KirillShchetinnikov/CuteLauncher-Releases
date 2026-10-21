import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../diagnostics_report.dart';
import '../../diagnostics_store.dart';
import '../../l10n/app_localizations.dart';
import '../../tv_compatibility_diagnostics.dart';
import '../../tv_compatibility_report.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';

/// Independent snapshots retained while the diagnostics menu is open.
class DiagnosticsPage extends StatefulWidget {
  static const routeName = 'diagnostics_panel';
  final String? section;
  final Future<Map<String, Object>> Function()? collect, collectCompatibility;
  const DiagnosticsPage({
    super.key,
    this.section,
    this.collect,
    this.collectCompatibility,
  });
  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  final _errors = ValueNotifier<Map<String, Object>?>(null);
  final _compatibility = ValueNotifier<Map<String, Object>?>(null);
  Widget _page(bool compatibility) => DiagnosticsReportPanel(
    compatibility: compatibility,
    report: compatibility ? _compatibility : _errors,
    collect: compatibility
        ? widget.collectCompatibility ?? collectTvCompatibility
        : widget.collect ?? collectDiagnostics,
  );
  @override
  void dispose() {
    _errors.dispose();
    _compatibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.section != null) return _page(widget.section == 'compatibility');
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.diagnosticsHubTitle),
      child: ListView(
        children: [
          FocusableSettingsTile(
            autofocus: true,
            leading: const Icon(Icons.tv_outlined),
            title: Text(l.tvCompatibilityTitle),
            onPressed: () =>
                Navigator.of(context)
                    .push(SettingsRoute<void>(builder: (_) => _page(true))),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(l.diagnosticsTitle),
            onPressed: () =>
                Navigator.of(context)
                    .push(SettingsRoute<void>(builder: (_) => _page(false))),
          ),
        ],
      ),
    );
  }
}

class DiagnosticsReportPanel extends StatefulWidget {
  final bool compatibility;
  final ValueNotifier<Map<String, Object>?> report;
  final Future<Map<String, Object>> Function() collect;
  const DiagnosticsReportPanel({
    super.key,
    required this.compatibility,
    required this.report,
    required this.collect,
  });
  @override
  State<DiagnosticsReportPanel> createState() => _DiagnosticsReportPanelState();
}

class _DiagnosticsReportPanelState extends State<DiagnosticsReportPanel> {
  bool _busy = false;
  bool _creating = false;
  bool _exportMenu = false;
  Future<void> _create() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _creating = true;
    });
    try {
      final report = await widget.collect();
      if (mounted) widget.report.value = report;
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.diagnosticsCreateFailed,
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _creating = false;
        });
      }
    }
  }

  Future<void> _export() async {
    final report = widget.report.value;
    if (_busy || _exportMenu || report == null) return;
    _exportMenu = true;
    final l = AppLocalizations.of(context)!;
    try {
      await showLauncherDialog<void>(
        context: context,
        builder: (dialog) => LauncherAlertDialog(
          title: Text(l.diagnosticsExport),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FocusableSettingsTile(
                autofocus: true,
                leading: const Icon(Icons.copy),
                title: Text(l.diagnosticsCopyClipboard),
                onPressed: () async {
                  Navigator.pop(dialog);
                  await _performExport(report, copy: true);
                },
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.save_alt),
                title: Text(l.diagnosticsSaveDisk),
                onPressed: () async {
                  Navigator.pop(dialog);
                  await _performExport(report, copy: false);
                },
              ),
            ],
          ),
        ),
      );
    } finally {
      _exportMenu = false;
    }
  }

  Future<void> _performExport(
    Map<String, Object> report, {
    required bool copy,
  }) async {
    if (!mounted || _busy) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context)!;
    try {
      if (copy) {
        try {
          await Clipboard.setData(
            ClipboardData(text: DiagnosticsStore.instance.encode(report)),
          );
          if (mounted) showActionNotice(context, l.diagnosticsCopied);
        } catch (_) {
          if (mounted) {
            showActionNotice(context, l.diagnosticsCopyFailed, error: true);
          }
        }
      } else {
        String? saved;
        try {
          saved = await saveDiagnosticsReport(
            report,
            compatibility: widget.compatibility,
          );
        } catch (_) {
          saved = 'failed';
        }
        if (!mounted || saved == null || saved == 'cancelled') return;
        showActionNotice(
          context,
          saved == 'saved'
              ? l.diagnosticsSaved
              : saved == 'opened'
              ? l.diagnosticsExportOpened
              : l.diagnosticsSaveFailed,
          error: saved != 'saved' && saved != 'opened',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final report = widget.report.value;
    return SettingsPageLayout(
      title: Text(
        widget.compatibility ? l.tvCompatibilityTitle : l.diagnosticsTitle,
      ),
      child: ListView(
        children: [
          FocusableSettingsTile(
            autofocus: true,
            leading: const Icon(Icons.refresh),
            title: Text(
              _creating
                  ? l.diagnosticsCreating
                  : widget.compatibility
                  ? l.tvCompatibilityRun
                  : l.diagnosticsCreate,
            ),
            onPressed: _busy ? null : _create,
          ),
          if (report != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l.diagnosticsReady),
            ),
          if (widget.compatibility)
            FocusableSettingsTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: Text(l.tvCompatibilityResults),
              onPressed: _busy || report == null
                  ? null
                  : () => Navigator.of(context).push(
                      SettingsRoute<void>(
                        builder: (_) =>
                            CompatibilityResultsPage(report: report),
                      ),
                    ),
            )
          else
            FocusableSettingsTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l.diagnosticsClear),
              onPressed: _busy
                  ? null
                  : () {
                      DiagnosticsStore.instance.clear();
                      setState(() => widget.report.value = null);
                      showActionNotice(
                        context,
                        '${l.diagnosticsClear}: ${l.actionCompleted}',
                      );
                    },
            ),
          FocusableSettingsTile(
            leading: const Icon(Icons.ios_share),
            title: Text(l.diagnosticsExport),
            onPressed: _busy || report == null ? null : _export,
          ),
          SettingsHelp(
            text: widget.compatibility
                ? l.tvCompatibilityHelp
                : l.diagnosticsHint,
          ),
        ],
      ),
    );
  }
}

String compatibilityCheckLabel(AppLocalizations l, String id) => switch (id) {
  'androidTv' => l.compatibilityAndroidTv,
  'androidVersion' => l.compatibilityAndroidVersion,
  'homeRegistered' => l.compatibilityHomeRegistered,
  'defaultHome' => l.compatibilityDefaultHome,
  'homeSelection' => l.compatibilityHomeSelection,
  'overlay' => l.compatibilityOverlay,
  'notifications' => l.compatibilityNotifications,
  'notificationListener' => l.compatibilityNotificationListener,
  'accessibility' => l.compatibilityAccessibility,
  'writeSettings' => l.compatibilityWriteSettings,
  'usageStats' => l.compatibilityUsageStats,
  'watchNext' => l.compatibilityWatchNext,
  'tvInputs' => l.compatibilityTvInputs,
  'documentExport' => l.compatibilityDocumentExport,
  'screensaverSelection' => l.compatibilityScreensaverSelection,
  _ => l.compatibilityUnknown,
};
String compatibilityStatusLabel(AppLocalizations l, dynamic status) =>
    switch (status) {
      'available' => l.compatibilityAvailable,
      'notGranted' => l.compatibilityNotGranted,
      'notConfigured' => l.compatibilityNotConfigured,
      'restricted' => l.compatibilityRestricted,
      'unsupported' => l.compatibilityUnsupported,
      _ => l.compatibilityUnknown,
    };

class CompatibilityResultsPage extends StatelessWidget {
  final Map<String, Object> report;
  const CompatibilityResultsPage({super.key, required this.report});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final identity = report['identity'] as Map? ?? {};
    final checks = report['checks'] as Map? ?? {};
    final app = report['installedLauncher'] as Map? ?? {};
    return SettingsPageLayout(
      title: Text(l.tvCompatibilityResults),
      child: Builder(
        builder: (context) {
          final scroll = PrimaryScrollController.of(context);
          return Focus(
            autofocus: true,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                return KeyEventResult.ignored;
              }
              final key = event.logicalKey;
              if (key != LogicalKeyboardKey.arrowDown &&
                  key != LogicalKeyboardKey.arrowUp) {
                return KeyEventResult.ignored;
              }
              if (scroll.hasClients) {
                scroll.animateTo(
                  (scroll.offset +
                          (key == LogicalKeyboardKey.arrowDown ? 100 : -100))
                      .clamp(0, scroll.position.maxScrollExtent),
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                );
              }
              return KeyEventResult.handled;
            },
            child: SingleChildScrollView(
              key: const ValueKey('compatibility_results_scroll'),
              controller: scroll,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.settingsHelpScroll),
                    Text(
                      '${l.compatibilityReportDate}: ${report['capturedAt'] ?? '—'}\n'
                      '${l.compatibilityLauncherVersion}: ${app['versionName'] ?? '—'}+${app['versionCode'] ?? '—'}',
                    ),
                    Text(
                      '${identity['manufacturer'] ?? '—'} ${identity['model'] ?? '—'}\nAndroid ${identity['android'] ?? '—'} / API ${identity['sdk'] ?? '—'}\n${identity['abis'] ?? '—'}\n${identity['fingerprint'] ?? '—'}',
                    ),
                    const Divider(),
                    for (final id in tvCompatibilityChecks)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${compatibilityCheckLabel(l, id)}: ${compatibilityStatusLabel(l, checks[id])}',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
