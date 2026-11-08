import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'launcher_dialog.dart';
import 'remote_text_input.dart';

class AppNameDialog extends StatefulWidget {
  final String initialName;
  final bool canRestoreSystemName;

  const AppNameDialog({
    super.key,
    required this.initialName,
    required this.canRestoreSystemName,
  });

  @override
  State<AppNameDialog> createState() => _AppNameDialogState();
}

class _AppNameDialogState extends State<AppNameDialog> {
  final _form = GlobalKey<FormState>();
  final _saveFocus = FocusNode();
  late final _name = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _saveFocus.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LauncherAlertDialog(
      title: Text(l.homeAppName),
      content: Form(
        key: _form,
        child: RemoteTextInput(
          child: TextFormField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: l.name),
            validator: (value) =>
                value!.trim().isEmpty ? l.mustNotBeEmpty : null,
            onFieldSubmitted: (_) => _saveFocus.requestFocus(),
          ),
        ),
      ),
      actions: [
        if (widget.canRestoreSystemName)
          LauncherDialogButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text(l.restoreSystemAppName),
          ),
        LauncherDialogButton(
          onPressed: () => Navigator.pop(context),
          isCancel: true,
          child: Text(l.cancel),
        ),
        LauncherDialogButton(
          focusNode: _saveFocus,
          primary: true,
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, _name.text.trim());
            }
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}
