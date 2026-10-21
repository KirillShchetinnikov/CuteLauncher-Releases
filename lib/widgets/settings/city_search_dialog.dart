import 'package:flutter/material.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';

import '../../l10n/app_localizations.dart';
import '../remote_text_input.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';

class CitySearchDialog extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function(String) searchCities;
  const CitySearchDialog({super.key, required this.searchCities});
  @override
  State<CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<CitySearchDialog> {
  final query = TextEditingController();
  bool busy = false, failed = false, searched = false;
  List<Map<String, dynamic>> cities = [];
  Future<void> search() async {
    if (busy || query.text.trim().length < 2) return;
    setState(() {
      busy = true;
      failed = false;
      searched = true;
      cities = [];
    });
    try {
      final results = await widget.searchCities(query.text);
      if (mounted) setState(() => cities = results);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LauncherAlertDialog(
      title: Text(l.nightChooseCity),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RemoteTextInput(
              child: TextField(
                controller: query,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l.nightCityName,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => search(),
              ),
            ),
            SettingsHelp(text: l.nightCityEnglish),
            if (busy) const LinearProgressIndicator(),
            if (failed) Text(l.nightCitySearchFailed),
            if (searched && !busy && !failed && cities.isEmpty)
              Text(l.nightCityNotFound),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final city in cities)
                    FocusableSettingsTile(
                      title: Text(city['city'] as String),
                      onPressed: () => Navigator.pop(context, city),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        LauncherDialogButton(
          onPressed: () => Navigator.pop(context),
          isCancel: true,
          child: Text(l.cancel),
        ),
        LauncherDialogButton(
          onPressed: busy ? null : search,
          child: Text(l.nightSearchCity),
        ),
      ],
    );
  }
}
