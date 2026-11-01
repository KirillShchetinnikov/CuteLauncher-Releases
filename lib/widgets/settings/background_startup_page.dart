import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/background_startup_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/apps_service.dart';
import '../application_list_icon.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';

class BackgroundStartupPage extends StatefulWidget {
  static const routeName = 'background_startup';
  const BackgroundStartupPage({super.key});

  @override
  State<BackgroundStartupPage> createState() => _BackgroundStartupPageState();
}

class _BackgroundStartupPageState extends State<BackgroundStartupPage>
    with WidgetsBindingObserver {
  late final BackgroundStartupService _service;
  late final bool _owned;
  List<Map<dynamic, dynamic>> get _apps => _service.apps;
  bool get _loading =>
      _service.loading || (!_service.loaded && !_service.failed);
  bool get _saving => _service.saving;
  bool get _failed => _service.failed;

  @override
  void initState() {
    super.initState();
    final shared = context.read<BackgroundStartupService?>();
    _owned = shared == null;
    _service = shared ?? BackgroundStartupService();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading && !_saving) _load();
  }

  Future<void> _load() => _service.refresh();

  Future<void> _toggle(String app) =>
      _service.setSelected(app, !_service.selected(app));

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_owned) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _service,
    builder: (context, _) => _page(context),
  );

  Widget _page(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(
        l.backgroundStartupTitle,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _apps.length + 3,
        itemBuilder: (context, index) {
          if (index == 0) {
            return SizedBox(
              height: 4,
              child: _loading || _saving
                  ? const LinearProgressIndicator()
                  : null,
            );
          }
          if (index == 1) {
            return Column(
              children: [
                if (_failed) Text(l.backgroundStartupFailed),
                if (_failed)
                  FocusableSettingsTile(
                    title: Text(l.backgroundStartupRetry),
                    onPressed: _loading || _saving ? null : _load,
                  ),
                if (!_loading && !_failed && _apps.isEmpty)
                  Text(l.backgroundStartupEmpty),
              ],
            );
          }
          if (index == _apps.length + 2) {
            // Let the common page focus the first app after initial loading.
            if (_loading && _apps.isEmpty) return const SizedBox.shrink();
            return SettingsHelp(title: l.backgroundStartupTitle, text: l.backgroundStartupHelp);
          }
          final app = _apps[index - 2];
          final package = app['packageName'] as String;
          final selected = _service.selected(package);
          final available = app['available'] == true;
          final status =
              !available || _service.outcome(package) == 'unavailable'
              ? l.backgroundStartupUnavailable
              : _service.outcome(package) == 'requested'
              ? l.backgroundStartupRequested
              : null;
          return Semantics(
            checked: selected,
            child: FocusableSettingsTile(
              key: ValueKey(package),
              leading: context.read<AppsService?>() != null
                  ? ApplicationListIcon(packageName: package)
                  : const Icon(Icons.android, size: 32),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app['name'] as String),
                  if (status != null)
                    Text(status, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              trailing: Icon(
                selected ? Icons.check_box : Icons.check_box_outline_blank,
              ),
              enabled: available || selected,
              // Keep focus during short saves; the guard prevents duplicate commands.
              onPressed: () => _toggle(package),
            ),
          );
        },
      ),
    );
  }
}
