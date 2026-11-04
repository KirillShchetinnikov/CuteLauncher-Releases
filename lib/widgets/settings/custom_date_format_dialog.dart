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
  final _inputFocus = FocusNode();
  final _saveFocus = FocusNode();
  final _cancelFocus = FocusNode();
  final _legendScroll = ScrollController();

  @override
  void dispose() {
    _inputFocus.dispose();
    _saveFocus.dispose();
    _cancelFocus.dispose();
    _legendScroll.dispose();
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
    // Only the legend scrolls. EditableText may scroll its caret into view after
    // IME resize, so putting the preview and editor in that viewport hides them.
    return Dialog(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 300;
          return SizedBox(
            width: 1000,
            child: Padding(
              padding: compact
                  ? const EdgeInsets.fromLTRB(12, 8, 12, 4)
                  : const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!compact) ...[
                    Text(
                      l.customDateFormat,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${l.dateFormatPreview}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: valid ? preview : l.invalidDateFormat),
                      ],
                    ),
                    key: const ValueKey('custom-date-preview'),
                    maxLines: compact ? 1 : null,
                    overflow: compact ? TextOverflow.ellipsis : null,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  RemoteTextInput(
                    key: const ValueKey('custom-date-editor'),
                    child: TextField(
                      autofocus: true,
                      focusNode: _inputFocus,
                      controller: _controller,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLength: maximumDatePatternLength,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) =>
                          (valid ? _saveFocus : _cancelFocus).requestFocus(),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: compact
                            ? const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              )
                            : null,
                        counterText: '',
                        labelText: l.typeInTheDateFormat,
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      controller: _legendScroll,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!valid)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  l.customDateFormatError,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                ),
                              ),
                            Row(
                              key: const ValueKey('custom-date-legend'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    l.customDateFormatHelp
                                        .split('\n')
                                        .take(6)
                                        .join('\n'),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(height: 1.2),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Text(
                                    l.customDateFormatHelp
                                        .split('\n')
                                        .skip(6)
                                        .join('\n'),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(height: 1.2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  OverflowBar(
                    key: const ValueKey('custom-date-actions'),
                    alignment: MainAxisAlignment.end,
                    children: [
                      LauncherDialogButton(
                        focusNode: _cancelFocus,
                        style: compact
                            ? const ButtonStyle(
                                minimumSize: WidgetStatePropertyAll(
                                  Size(0, 36),
                                ),
                                padding: WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                              )
                            : null,
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          MaterialLocalizations.of(context).cancelButtonLabel,
                        ),
                      ),
                      LauncherDialogButton(
                        primary: true,
                        focusNode: _saveFocus,
                        style: compact
                            ? const ButtonStyle(
                                minimumSize: WidgetStatePropertyAll(
                                  Size(0, 36),
                                ),
                                padding: WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                              )
                            : null,
                        // Expand intl skeletons so Java receives the same pattern.
                        onPressed: valid
                            ? () => Navigator.pop(
                                context,
                                DateFormat(
                                  _controller.text,
                                  Localizations.localeOf(context).toString(),
                                ).pattern,
                              )
                            : null,
                        child: Text(
                          MaterialLocalizations.of(context).okButtonLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
