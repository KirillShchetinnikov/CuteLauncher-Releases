import '../remote_text_input.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'focusable_settings_tile.dart';

class SettingsTextTile extends StatelessWidget {
  final String title, value;
  final ValueChanged<String> onChanged;
  final bool enabled, obscureText;
  final int? maxLength;
  final TextInputType? keyboardType;
  const SettingsTextTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.obscureText = false,
    this.maxLength,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    title: Text(title),
    enabled: enabled,
    valueIcon: Icons.edit_outlined,
    trailing: Text(
      value.isEmpty
          ? AppLocalizations.of(context)!.settingsValueNotSet
          : obscureText
          ? '••••••'
          : value,
      overflow: TextOverflow.ellipsis,
    ),
    onPressed: () async {
      final result = await showLauncherDialog<String>(
        context: context,
        builder: (_) => _SettingsTextEditor(tile: this),
      );
      if (result != null && context.mounted) onChanged(result);
    },
  );
}

class _SettingsTextEditor extends StatefulWidget {
  final SettingsTextTile tile;
  const _SettingsTextEditor({required this.tile});
  @override
  State<_SettingsTextEditor> createState() => _SettingsTextEditorState();
}

class _SettingsTextEditorState extends State<_SettingsTextEditor> {
  late final _editor = TextEditingController(text: widget.tile.value);
  final _saveFocus = FocusNode();
  @override
  void dispose() {
    _editor.dispose();
    _saveFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.tile;
    final l = AppLocalizations.of(context)!;
    return LauncherAlertDialog(
      title: Text(tile.title),
      content: RemoteTextInput(
        child: TextField(
          controller: _editor,
          autofocus: true,
          onSubmitted: (_) => _saveFocus.requestFocus(),
          maxLength: tile.maxLength,
          keyboardType: tile.keyboardType,
          obscureText: tile.obscureText,
          autocorrect: false,
          enableSuggestions: !tile.obscureText,
        ),
      ),
      actions: [
        LauncherDialogButton(
          onPressed: () => Navigator.pop(context),
          isCancel: true,
          child: Text(l.cancel),
        ),
        LauncherDialogButton(
          focusNode: _saveFocus,
          primary: true,
          onPressed: () => Navigator.pop(context, _editor.text),
          child: Text(l.save),
        ),
      ],
    );
  }
}
