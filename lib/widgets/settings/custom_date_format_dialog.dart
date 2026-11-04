import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../custom_date_format.dart';
import '../../date_time_format.dart';
import '../../l10n/app_localizations.dart';
import '../launcher_dialog.dart';
import '../remote_text_input.dart';

class DatePatternEditingController extends TextEditingController {
  DatePatternEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final errors = validateCustomDatePattern(text).errors;
    final errorColor = Theme.of(context).colorScheme.error;
    final composing = value.composing;
    var i = 0;
    final spans = <TextSpan>[];
    for (final character in text.characters) {
      spans.add(
        TextSpan(
          text: character,
          style: TextStyle(
            color: errors.any((range) => i >= range.$1 && i < range.$2)
                ? errorColor
                : null,
            decoration:
                errors.any((range) => i >= range.$1 && i < range.$2) ||
                    withComposing &&
                        composing.isValid &&
                        i >= composing.start &&
                        i < composing.end
                ? TextDecoration.underline
                : null,
          ),
        ),
      );
      i += character.length;
    }
    return TextSpan(style: style, children: spans);
  }
}

class CustomDateFormatDialog extends StatefulWidget {
  final String pattern;
  const CustomDateFormatDialog({super.key, required this.pattern});

  @override
  State<CustomDateFormatDialog> createState() => _CustomDateFormatDialogState();
}

class _CustomDateFormatDialogState extends State<CustomDateFormatDialog> {
  late final _controller = DatePatternEditingController(text: widget.pattern);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    var valid = validateCustomDatePattern(_controller.text).valid;
    var preview = '';
    if (valid) {
      try {
        preview = formatLauncherDate(
          _controller.text,
          DateTime.now(),
          Localizations.localeOf(context).toString(),
        );
      } catch (_) {
        valid = false;
      }
    }
    return LauncherAlertDialog(
      title: Text(l.customDateFormat),
      scrollContent: false,
      content: SizedBox(
        width: 1000,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (valid) ...[
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${l.dateFormatPreview}: ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: preview),
                  ],
                ),
                key: const ValueKey('custom-date-preview'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            RemoteTextInput(
              child: TextField(
                autofocus: true,
                controller: _controller,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLength: maximumDatePatternLength,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  labelText: l.typeInTheDateFormat,
                  errorText: valid ? null : l.customDateFormatError,
                  errorMaxLines: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              key: const ValueKey('custom-date-legend'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    l.customDateFormatHelp.split('\n').take(6).join('\n'),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(height: 1.2),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    l.customDateFormatHelp.split('\n').skip(6).join('\n'),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(height: 1.2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        LauncherDialogButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        LauncherDialogButton(
          primary: true,
          // Expand intl skeletons before storing so Java receives the same pattern.
          onPressed: valid
              ? () => Navigator.pop(
                  context,
                  DateFormat(
                    _controller.text,
                    Localizations.localeOf(context).toString(),
                  ).pattern,
                )
              : null,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
