import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../information_formats.dart';
import '../../l10n/app_localizations.dart';
import '../../models/weather_data.dart';
import '../../key_sounds.dart';
import '../../tile_appearance.dart';
import '../../weather_format_template.dart';
import '../../weather_text_format.dart';
import '../../weather_field_availability.dart';
import '../../weather_sources.dart';
import '../launcher_dialog.dart';
import '../panel_tooltip.dart';
import '../remote_text_input.dart';
import '../weather_display_text.dart';
import '../weather_glyph.dart';
import 'format_editor_exit_guard.dart';
import 'settings_help.dart';
import 'settings_information.dart';

class WeatherTemplateEditingController extends TextEditingController {
  WeatherTemplateEditingController({super.text});
  String? _parsedText;
  late WeatherTemplateResult _parsed;
  WeatherTemplateResult get parsed {
    if (_parsedText != text) {
      _parsedText = text;
      _parsed = parseWeatherTemplate(text);
    }
    return _parsed;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final errors = parsed.issues;
    final spans = <TextSpan>[];
    var offset = 0;
    for (final character in text.characters) {
      final invalid = errors.any(
        (issue) => offset >= issue.start && offset < issue.end,
      );
      final composing =
          withComposing &&
          value.composing.isValid &&
          offset >= value.composing.start &&
          offset < value.composing.end;
      spans.add(
        TextSpan(
          text: character,
          style: TextStyle(
            color: invalid ? Theme.of(context).colorScheme.error : null,
            decoration: invalid || composing ? TextDecoration.underline : null,
          ),
        ),
      );
      offset += character.length;
    }
    return TextSpan(style: style, children: spans);
  }
}

class WeatherTextFormatDialog extends StatefulWidget {
  const WeatherTextFormatDialog({
    super.key,
    required this.format,
    required this.fahrenheit,
    this.weather,
    this.source,
    this.missingAsDash = false,
    this.panelAlignment = 'left',
    this.warnings = false,
    this.singleLine = false,
    this.background = false,
    this.previewBuilder,
    this.imeVisibility,
  });
  final WeatherTextFormat format;
  final bool fahrenheit;
  final WeatherData? weather;
  final WeatherSource? source;
  final bool missingAsDash;
  final String panelAlignment;
  final bool warnings, singleLine, background;
  final Widget Function(WeatherDisplayOptions, bool compact)? previewBuilder;
  final Stream<bool>? imeVisibility;

  @override
  State<WeatherTextFormatDialog> createState() =>
      _WeatherTextFormatDialogState();
}

class _WeatherTextFormatDialogState extends State<WeatherTextFormatDialog> {
  WeatherTemplateEditingController? _controller;
  late String _initialTemplate;
  WeatherTextFormat? _initialFormat;
  final _inputFocus = FocusNode();
  final _saveFocus = FocusNode();
  final _cancelFocus = FocusNode();
  final _resetFocus = FocusNode();
  final _helpFocus = FocusNode();
  final _insertFocus = {
    for (final field in weatherTemplateNames.keys) field: FocusNode(),
  };
  FocusNode get _firstInsertFocus =>
      _insertFocus[WeatherTextField.temperature]!;
  FocusNode? _lastInsertFocus;
  FocusNode get _insertEntryFocus => _lastInsertFocus?.canRequestFocus == true
      ? _lastInsertFocus!
      : _firstInsertFocus;

  KeyEventResult _buttonKeys(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final nodes = _insertFocus.values
        .where((node) => node.canRequestFocus)
        .toList();
    final index = nodes.indexWhere((node) => node.hasPrimaryFocus);
    if (index < 0) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      _lastInsertFocus = nodes[index];
      playKeySound(context);
      FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
        key == LogicalKeyboardKey.arrowUp ? _inputFocus : _helpFocus,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      var step = key == LogicalKeyboardKey.arrowRight ? 1 : -1;
      if (Directionality.of(context) == TextDirection.rtl) step = -step;
      final next = (index + step).clamp(0, nodes.length - 1);
      _lastInsertFocus = nodes[next];
      playKeySound(context);
      FocusTraversalPolicy.defaultTraversalRequestFocusCallback(nodes[next]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _helpKeys(FocusNode _, KeyEvent event) {
    if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      playKeySound(context);
      FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
        _insertEntryFocus,
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  final _scroll = ScrollController();
  final _textScroll = ScrollController();
  final _caretBoundary = GlobalKey();
  late TextSelection _savedSelection;
  TextSelection? _pointerReturnSelection;
  TextEditingValue? _openingKeyboardValue;
  TextEditingValue? _queuedKeyboardOpening;
  bool _nativeKeyboardVisible = false;
  bool _editing = false;
  bool _hadErrors = false;

  @override
  void initState() {
    super.initState();
    // Run before EditableText's focus listener can replace an invalid selection
    // with an end-of-text caret when the IME has cleared its selection.
    _inputFocus.addListener(_restoreSelectionOnFocus);
  }

  void _restoreSelectionOnFocus() {
    if (_controller == null) return;
    if (!_inputFocus.hasFocus) {
      _cancelKeyboardOpening();
      return;
    }
    final selection = _selection;
    if (_controller!.selection != selection) {
      _controller!.selection = selection;
    }
    if (_editing && !_nativeKeyboardVisible && _openingKeyboardValue == null) {
      // Regaining editor focus can open Android's IME without ActivateIntent.
      _openingKeyboardValue = _controller!.value.copyWith(selection: selection);
    }
  }

  void _refreshDraft() {
    final hasErrors = _controller!.parsed.issues.isNotEmpty;
    final revealError = hasErrors && !_hadErrors;
    setState(() => _hadErrors = hasErrors);
    if (revealError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    _initialTemplate = weatherFormatTemplate(
      widget.format,
      russian: AppLocalizations.of(context)!.localeName.startsWith('ru'),
      warnings: widget.warnings,
    );
    _controller = WeatherTemplateEditingController(text: _initialTemplate);
    _savedSelection = TextSelection.collapsed(offset: _initialTemplate.length);
    _controller!.selection = _savedSelection;
    _controller!.addListener(_rememberSelection);
    // Preserve legacy conditional affixes when the draft has not been edited.
    _initialFormat = widget.format.explicitLayout
        ? widget.format
        : WeatherTextFormat.fromBlocks([
            const WeatherTextBlock(WeatherTextField.icon),
            const WeatherTextBlock(WeatherTextField.text, before: ' '),
            ...widget.format.blocks,
            if (widget.warnings)
              const WeatherTextBlock(
                WeatherTextField.warning,
                before: ' (',
                after: ')',
              ),
          ], explicitLayout: true);
  }

  @override
  void dispose() {
    _controller?.removeListener(_rememberSelection);
    _controller?.dispose();
    _inputFocus.removeListener(_restoreSelectionOnFocus);
    _inputFocus.dispose();
    _saveFocus.dispose();
    _cancelFocus.dispose();
    _resetFocus.dispose();
    _helpFocus.dispose();
    for (final node in _insertFocus.values) {
      node.dispose();
    }
    _scroll.dispose();
    _textScroll.dispose();
    super.dispose();
  }

  void _activateEditor() {
    final selection = _pointerReturnSelection ?? _selection;
    _pointerReturnSelection = null;
    _openingKeyboardValue = _controller!.value.copyWith(selection: selection);
    _queuedKeyboardOpening = null;
    if (_controller!.selection != selection) _controller!.selection = selection;
    setState(() => _editing = true);
    _inputFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_inputFocus.hasFocus) return;
      if (_controller!.selection != selection) {
        _controller!.selection = selection;
      }
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorStateOfType<EditableTextState>()
          ?.requestKeyboard();
    });
  }

  TextSelection get _selection {
    final current = _controller!.selection;
    final selection = current.isValid ? current : _savedSelection;
    final length = _controller!.text.length;
    return selection.copyWith(
      baseOffset: selection.baseOffset.clamp(0, length),
      extentOffset: selection.extentOffset.clamp(0, length),
    );
  }

  void _rememberSelection() {
    final opening = _openingKeyboardValue;
    if (opening != null) {
      if (_controller!.text != opening.text) {
        // The first real edit wins; never restore old text or its old caret.
        _cancelKeyboardOpening();
      } else if (_controller!.selection != opening.selection) {
        // Some TV IMEs publish a selection-only reset while connecting.
        _controller!.value = _controller!.value.copyWith(
          selection: opening.selection,
        );
        return;
      }
    }
    if (_controller!.selection.isValid) _savedSelection = _selection;
  }

  void _cancelKeyboardOpening() {
    _openingKeyboardValue = null;
    _queuedKeyboardOpening = null;
  }

  void _keyboardVisibilityChanged(bool visible) {
    if (_nativeKeyboardVisible != visible) {
      setState(() => _nativeKeyboardVisible = visible);
    }
    if (visible) _finishKeyboardOpening();
  }

  void _finishKeyboardOpening() {
    final opening = _openingKeyboardValue;
    if (opening == null || identical(opening, _queuedKeyboardOpening)) return;
    _queuedKeyboardOpening = opening;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_openingKeyboardValue, opening)) return;
      _rememberSelection();
      _cancelKeyboardOpening();
    });
  }

  KeyEventResult _editorKeys(FocusNode _, KeyEvent event) {
    if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
        !const [
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.select,
          LogicalKeyboardKey.numpadEnter,
        ].contains(event.logicalKey)) {
      _cancelKeyboardOpening();
    }
    return KeyEventResult.ignored;
  }

  void _resetFormat() {
    final template = weatherFormatTemplate(
      WeatherTextFormat.standard,
      russian: AppLocalizations.of(context)!.localeName.startsWith('ru'),
      warnings: true,
    );
    _cancelKeyboardOpening();
    _pointerReturnSelection = null;
    _resetFocus.requestFocus();
    _controller!.value = TextEditingValue(
      text: template,
      selection: TextSelection.collapsed(offset: template.length),
    );
    _refreshDraft();
  }

  void _insert(WeatherTextField field) {
    final controller = _controller!;
    final selection = _selection;
    final start = selection.start;
    final end = selection.end;
    final token = weatherTemplateToken(
      field,
      russian: AppLocalizations.of(context)!.localeName.startsWith('ru'),
    );
    _insertFocus[field]!.requestFocus();
    _lastInsertFocus = _insertFocus[field];
    controller.value = TextEditingValue(
      text: controller.text.replaceRange(start, end, token),
      selection: TextSelection.collapsed(offset: start + token.length),
    );
    _refreshDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _inputFocus.context
          ?.findAncestorStateOfType<EditableTextState>()
          ?.bringIntoView(_selection.extent);
    });
  }

  String _label(AppLocalizations l, WeatherTextField field) => switch (field) {
    WeatherTextField.temperature => l.weatherTextTemperature,
    WeatherTextField.feelsLike => l.weatherTextApparent,
    WeatherTextField.high => l.weatherTextHigh,
    WeatherTextField.low => l.weatherTextLow,
    WeatherTextField.warning => l.weatherTemplateWarning,
    WeatherTextField.lineBreak => l.weatherTextNewline,
    WeatherTextField.city => l.nightCityName,
    WeatherTextField.conditionsIcon => l.weatherTextConditions,
    WeatherTextField.conditions => l.weatherTemplateDescription,
    WeatherTextField.icon => l.weatherTemplateIcon,
    WeatherTextField.wind => l.weatherWind,
    WeatherTextField.humidity => l.weatherTextHumidity,
    WeatherTextField.text => l.weatherTextLiteral,
  };

  String _error(
    AppLocalizations l,
    WeatherTemplateIssue issue,
  ) => switch (issue.error) {
    WeatherTemplateError.braces => l.weatherTemplateBracesError,
    WeatherTemplateError.unknown =>
      '${l.weatherTemplateUnknownError} ${_controller!.text.substring(issue.start, issue.end)}',
    WeatherTemplateError.lineBreaks => l.weatherTemplateBreakError,
    WeatherTemplateError.missingValue => l.weatherTemplateValueError,
    WeatherTemplateError.length => l.weatherTemplateLengthError,
  };

  Widget _insertionLegend(
    AppLocalizations l,
    ThemeData theme,
    bool russian,
    bool hasBreak,
  ) {
    String? unavailable(WeatherTextField field) => widget.source == null ? null :
      switch (weatherFieldUnavailable(field, widget.source!, widget.weather)) {
        WeatherFieldUnavailable.unsupported => l.weatherFieldUnsupported,
        WeatherFieldUnavailable.missing => l.weatherFieldMissing,
        null => null,
      };
    final legend = {
      for (final field in weatherTemplateNames.keys)
        field:
            '${weatherTemplateToken(field, russian: russian)} — ${_label(l, field)}',
    };
    final fields = weatherTemplateNames.keys.toList();
    return Column(
      key: const Key('weather_format_insert_buttons'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          key: const Key('weather_format_button_row'),
          spacing: 2,
          children: [
            for (final field in weatherTemplateNames.keys)
              Expanded(
                child: PanelTooltip(
                  message: '${legend[field]}${unavailable(field) == null ? '' : ' · ${unavailable(field)}'}',
                  excludeFromSemantics: true,
                  child: LauncherDialogButton(
                    key: ValueKey('weather_format_add_${field.name}'),
                    focusNode: _insertFocus[field],
                    style: ButtonStyle(
                      minimumSize: const WidgetStatePropertyAll(Size(0, 20)),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 4),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: WidgetStatePropertyAll(
                        theme.textTheme.bodySmall,
                      ),
                    ),
                    onPressed: field == WeatherTextField.lineBreak && hasBreak
                        ? null
                        : () => _insert(field),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        russian
                            ? weatherTemplateNames[field]!.$1
                            : weatherTemplateNames[field]!.$2,
                        semanticsLabel: legend[field],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Column(
          key: const Key('weather_format_legend'),
          spacing: 2,
          children: [
            for (var index = 0; index < fields.length; index += 2)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  for (final field in fields.skip(index).take(2))
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.topStart,
                          child: Text(
                            legend[field]!,
                            key: ValueKey(
                              'weather_format_legend_${field.name}',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: unavailable(field) == null ? null : theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        for (final status in [l.weatherFieldUnsupported, l.weatherFieldMissing])
          if (fields.any((field) => unavailable(field) == status))
            SettingsMessage(text: '$status: ${fields.where((field) => unavailable(field) == status).map((field) => weatherTemplateToken(field, russian: russian)).join(', ')}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    final controller = _controller!;
    final parsed = controller.parsed;
    final format = controller.text == _initialTemplate && parsed.issues.isEmpty
        ? _initialFormat ?? parsed.format
        : parsed.format;
    final theme = Theme.of(context);
    final sample =
        widget.weather ??
        WeatherData(
          currentTemp: 6,
          feelsLikeTemp: 2,
          currentConditionCode: 803,
          windSpeed: 4,
          currentHumidity: 82,
          location: l.weatherTextSampleCity,
          todayMinTemp: 3,
          todayMaxTemp: 8,
        );
    final russian = l.localeName.startsWith('ru');
    final options = WeatherDisplayOptions(
      format: format ?? widget.format,
      fahrenheit: widget.fahrenheit,
      warnings: false,
      missingAsDash: widget.missingAsDash,
      panelAlignment: widget.panelAlignment,
    );
    final hasBreak =
        format?.blocks.any((b) => b.field == WeatherTextField.lineBreak) ==
        true;
    final keyboardOpen =
        _nativeKeyboardVisible || MediaQuery.viewInsetsOf(context).bottom > 0;
    if (keyboardOpen) _finishKeyboardOpening();
    final dialog = Dialog(
      alignment: keyboardOpen ? Alignment.topCenter : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 300 || keyboardOpen;
          return SizedBox(
            key: const Key('weather_format_body'),
            width: 900,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: FocusTraversalGroup(
                policy: ReadingOrderTraversalPolicy(),
                child: Semantics(
                  namesRoute: true,
                  label: l.weatherTextFormat,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.weatherTextFormat,
                        key: const Key('weather_format_title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: compact
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        spacing: 12,
                        children: [
                          Text(
                            '${l.dateFormatPreview}:',
                            key: const Key('weather_format_preview_label'),
                            style: theme.textTheme.bodyMedium,
                          ),
                          Flexible(
                            child: widget.previewBuilder != null
                                ? widget.previewBuilder!(options, compact)
                                : WeatherDisplayText(
                                    format?.format(
                                          sample,
                                          l,
                                          fahrenheit: widget.fahrenheit,
                                          missingAsDash: widget.missingAsDash,
                                        ) ??
                                        '—',
                                    key: const Key('weather_format_preview'),
                                    style: theme.textTheme.bodyLarge,
                                    singleLine: widget.singleLine,
                                    alignment: widget.panelAlignment,
                                    maxWidth: weatherTextMaxWidth(
                                      format ?? widget.format,
                                      backgroundScreenWidth: widget.background
                                          ? MediaQuery.sizeOf(context).width
                                          : null,
                                    ),
                                    inlineIcon: WeatherGlyph(
                                      condition: sample.getCondition(),
                                      pack: WeatherIconPack.outline,
                                      size: theme.textTheme.bodyLarge?.fontSize,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Actions(
                        actions: {
                          PreviousFocusIntent:
                              CallbackAction<PreviousFocusIntent>(
                                onInvoke: (_) {
                                  _inputFocus.focusInDirection(
                                    TraversalDirection.up,
                                  );
                                  return null;
                                },
                              ),
                          NextFocusIntent: CallbackAction<NextFocusIntent>(
                            onInvoke: (_) {
                              FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
                                _insertEntryFocus,
                              );
                              return null;
                            },
                          ),
                        },
                        child: RemoteTextInput(
                          onActivate: _activateEditor,
                          imeVisibility: widget.imeVisibility,
                          onKeyboardVisibilityChanged:
                              _keyboardVisibilityChanged,
                          child: Focus(
                            canRequestFocus: false,
                            skipTraversal: true,
                            onKeyEvent: _editorKeys,
                            child: Listener(
                              onPointerDown: (_) {
                                _cancelKeyboardOpening();
                                _pointerReturnSelection =
                                    _inputFocus.hasFocus && keyboardOpen
                                    ? null
                                    : _selection;
                              },
                              onPointerCancel: (_) =>
                                  _pointerReturnSelection = null,
                              child: RepaintBoundary(
                                key: _caretBoundary,
                                child: CustomPaint(
                                  key: const Key('weather_format_caret'),
                                  foregroundPainter: _WeatherCaretPainter(
                                    controller: controller,
                                    focus: _inputFocus,
                                    scroll: _textScroll,
                                    boundary: _caretBoundary,
                                    selection: () => _selection,
                                    color:
                                        theme.textSelectionTheme.cursorColor ??
                                        theme.colorScheme.primary,
                                  ),
                                  child: TextField(
                                    key: const Key('weather_format_input'),
                                    controller: controller,
                                    focusNode: _inputFocus,
                                    autofocus: true,
                                    readOnly: !_editing,
                                    showCursor: true,
                                    selectAllOnFocus: false,
                                    scrollController: _textScroll,
                                    onTap: _activateEditor,
                                    minLines: 1,
                                    maxLines: compact ? 1 : 2,
                                    // Disabling suggestions gives Android a
                                    // visible-password input type, which breaks
                                    // Gboard TV's language switch.
                                    autocorrect: false,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) =>
                                        (format != null
                                                ? _saveFocus
                                                : _cancelFocus)
                                            .requestFocus(),
                                    onChanged: (_) => _refreshDraft(),
                                    decoration: InputDecoration(
                                      labelText: l.weatherTextYourFormat,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          controller: _scroll,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (parsed.issues.isNotEmpty)
                                  SettingsMessage(
                                    key: const Key('weather_format_error'),
                                    text: parsed.issues
                                        .map((issue) => _error(l, issue))
                                        .toSet()
                                        .join('\n'),
                                    kind: SettingsMessageKind.error,
                                  ),
                                Focus(
                                  canRequestFocus: false,
                                  skipTraversal: true,
                                  onKeyEvent: _buttonKeys,
                                  child: _insertionLegend(
                                    l,
                                    theme,
                                    russian,
                                    hasBreak,
                                  ),
                                ),
                                SettingsHelp(
                                  focusNode: _helpFocus,
                                  onKeyEvent: _helpKeys,
                                  title: l.weatherTextFormat,
                                  text: [
                                    l.weatherTextHelp,
                                    if (widget.singleLine)
                                      l.weatherCompactLayout,
                                  ].join('\n\n'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          LauncherDialogButton(
                            key: const Key('weather_format_reset'),
                            focusNode: _resetFocus,
                            style: const ButtonStyle(
                              minimumSize: WidgetStatePropertyAll(Size(0, 32)),
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _resetFormat,
                            child: Text(l.weatherTextResetFormat),
                          ),
                          LauncherDialogButton(
                            focusNode: _cancelFocus,
                            style: const ButtonStyle(
                              minimumSize: WidgetStatePropertyAll(Size(0, 32)),
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(material.cancelButtonLabel),
                          ),
                          LauncherDialogButton(
                            key: const Key('weather_format_save'),
                            focusNode: _saveFocus,
                            primary: true,
                            style: const ButtonStyle(
                              minimumSize: WidgetStatePropertyAll(Size(0, 32)),
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: format == null
                                ? null
                                : () => Navigator.pop(
                                    context,
                                    widget.previewBuilder == null
                                        ? format
                                        : options,
                                  ),
                            child: Text(l.save),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    return FormatEditorExitGuard(child: dialog);
  }
}

/// Flutter hides its caret on blur. Keep a static insertion marker without
/// retaining input focus or running an unfocused cursor animation.
class _WeatherCaretPainter extends CustomPainter {
  _WeatherCaretPainter({
    required this.controller,
    required this.focus,
    required ScrollController scroll,
    required this.boundary,
    required this.selection,
    required this.color,
  }) : super(repaint: Listenable.merge([controller, focus, scroll]));

  final TextEditingController controller;
  final FocusNode focus;
  final GlobalKey boundary;
  final TextSelection Function() selection;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (focus.hasFocus) return;
    final editable = focus.context
        ?.findAncestorStateOfType<EditableTextState>()
        ?.renderEditable;
    final box = boundary.currentContext?.findRenderObject();
    if (editable == null ||
        !editable.attached ||
        !editable.hasSize ||
        box is! RenderBox) {
      return;
    }
    final offset = editable.localToGlobal(Offset.zero, ancestor: box);
    final rect = editable
        .getLocalRectForCaret(selection().extent)
        .shift(offset);
    canvas.save();
    canvas.clipRect(offset & editable.size);
    canvas.drawRect(rect, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WeatherCaretPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.controller != controller ||
      oldDelegate.focus != focus;
}
