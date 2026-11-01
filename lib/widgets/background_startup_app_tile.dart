import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/background_startup_service.dart';
import 'rounded_switch_list_tile.dart';
import 'settings/focusable_settings_tile.dart';

/// Context-menu control backed by the same selection as BackgroundStartupPage.
class BackgroundStartupAppTile extends StatefulWidget {
  final String packageName;
  const BackgroundStartupAppTile({super.key, required this.packageName});

  @override
  State<BackgroundStartupAppTile> createState() =>
      _BackgroundStartupAppTileState();
}

class _BackgroundStartupAppTileState extends State<BackgroundStartupAppTile>
    with WidgetsBindingObserver {
  late final BackgroundStartupService _service;
  late final bool _owned;

  @override
  void initState() {
    super.initState();
    final shared = context.read<BackgroundStartupService?>();
    _owned = shared == null;
    _service = shared ?? BackgroundStartupService();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service.refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _service.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_owned) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _service,
    builder: (context, _) {
      final l = AppLocalizations.of(context)!;
      final selected = _service.selected(widget.packageName);
      final available = _service.available(widget.packageName);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundedSwitchListTile(
            key: const ValueKey('app_background_startup'),
            title: Text(l.backgroundStartupToggle),
            secondary: const Icon(Icons.power_settings_new_rounded),
            value: selected,
            enabled: _service.loaded && (available || selected),
            // The service guards repeat presses while saving, keeping this row focused.
            onChanged: (value) =>
                _service.setSelected(widget.packageName, value),
          ),
          SizedBox(
            height: 4,
            child: _service.loading || _service.saving
                ? const LinearProgressIndicator()
                : null,
          ),
          if (_service.failed) ...[
            Text(l.backgroundStartupFailed),
            FocusableSettingsTile(
              title: Text(l.backgroundStartupRetry),
              onPressed: () => _service.refresh(),
            ),
          ] else if (_service.loaded && !available)
            Text(l.backgroundStartupUnavailable),
        ],
      );
    },
  );
}
