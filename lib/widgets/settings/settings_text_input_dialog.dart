import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../launcher_dialog.dart';
import '../remote_text_input.dart';
import 'settings_help.dart';

class SettingsTextInputDialog extends StatefulWidget {
  final String title, helper;
  final String initialValue;
  final String? Function(String)? validator;
  final bool secret;
  final int maxLength;
  final TextInputType? keyboardType;

  const SettingsTextInputDialog({
    super.key,
    required this.title,
    required this.helper,
    this.initialValue = '',
    this.validator,
    this.secret = false,
    this.maxLength = 1024,
    this.keyboardType,
  });

  @override
  State<SettingsTextInputDialog> createState() =>
      _SettingsTextInputDialogState();
}

class _SettingsTextInputDialogState extends State<SettingsTextInputDialog> {
  late final controller = TextEditingController(text: widget.initialValue);
  final okFocus = FocusNode();
  String? error;

  @override
  void dispose() {
    controller.dispose();
    okFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LauncherAlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RemoteTextInput(
          child: TextField(
            autofocus: true,
            obscureText: widget.secret,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textDirection: TextDirection.ltr,
            enableSuggestions: false,
            autocorrect: false,
            controller: controller,
            textInputAction: TextInputAction.done,
            onEditingComplete: () {
              SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
              okFocus.requestFocus();
            },
            decoration: InputDecoration(errorText: error, errorMaxLines: 3),
            onChanged: (_) {
              if (error != null) setState(() => error = null);
            },
          ),
        ),
        SettingsHelp(title: widget.title, text: widget.helper),
      ],
    ),
    actions: [
      LauncherDialogButton(
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      LauncherDialogButton(
        primary: true,
        focusNode: okFocus,
        onPressed: () {
          final message = widget.validator?.call(controller.text);
          if (message != null) {
            setState(() => error = message);
          } else {
            Navigator.pop(context, controller.text);
          }
        },
        child: Text(MaterialLocalizations.of(context).okButtonLabel),
      ),
    ],
  );
}
