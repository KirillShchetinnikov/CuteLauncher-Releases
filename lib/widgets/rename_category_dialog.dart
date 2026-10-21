import 'remote_text_input.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';
/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flauncher/l10n/app_localizations.dart';

class AddCategoryDialog extends StatefulWidget {
  final String initialValue;

  const AddCategoryDialog({super.key, required this.initialValue});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        } else {
          Navigator.of(context).pop();
        }
      },
      child: LauncherAlertDialog(
        title: Text(localizations.renameCategory),
        content: RemoteTextInput(
          child: TextFormField(
            focusNode: _focusNode,
            autofocus: true,
            controller: _controller,
            decoration: InputDecoration(labelText: localizations.name),
            validator: (value) =>
                value!.trim().isEmpty ? localizations.mustNotBeEmpty : null,
            autovalidateMode: AutovalidateMode.always,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            onFieldSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
          ),
        ),
        actions: [
          LauncherDialogButton(
            onPressed: () => Navigator.pop(context),
            isCancel: true,
            child: Text(localizations.cancel),
          ),
          LauncherDialogButton(
            primary: true,
            onPressed: () {
              if (_controller.text.trim().isNotEmpty) {
                Navigator.pop(context, _controller.text);
              }
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );
  }
}
