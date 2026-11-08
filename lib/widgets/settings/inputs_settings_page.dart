import 'settings_information.dart';
import 'settings_choice_dialog.dart';
import 'settings_help.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/tv_input.dart';
import '../../providers/tv_inputs_service.dart';
import '../../tv_inputs_configuration.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import '../remote_text_input.dart';
import '../rounded_switch_list_tile.dart';
import '../tv_input_icon.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';

class InputsSettingsPage extends StatefulWidget {
  static const routeName = 'inputs_settings';
  final TvInput? input;
  const InputsSettingsPage({super.key, this.input});
  @override
  State<InputsSettingsPage> createState() => _InputsSettingsPageState();
}

class _InputsSettingsPageState extends State<InputsSettingsPage> {
  @override
  void initState() {
    super.initState();
    if (widget.input == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          await context.read<TvInputsService>().refreshInputs();
        } catch (e) {
          debugPrint('Unable to refresh TV inputs: $e');
        }
      });
    }
  }

  Future<void> _save(TvInputsConfiguration value) async {
    if (!context.read<TvInputsService>().hasInputs) return;
    try {
      await context.read<TvInputsService>().configure(value);
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.inputsSaveFailed,
          error: true,
        );
      }
    }
  }

  Future<void> _name(TvInput input, TvInputOverride current) async {
    final value = await showLauncherDialog<String>(
      context: context,
      builder: (_) => _InputNameDialog(initialName: current.name),
    );
    if (value != null && mounted) {
      final config = context.read<TvInputsService>().configuration;
      await _save(
        config.copyWith(
          id: input.id,
          value: TvInputOverride(
            name: value.trim(),
            icon: config.overrides[input.id]?.icon ?? 'default',
          ),
        ),
      );
    }
  }

  String _iconLabel(AppLocalizations l, String icon) => switch (icon) {
    'hdmi' => 'HDMI',
    'tv' => l.inputIconTv,
    'game' => l.inputIconGame,
    'computer' => l.inputIconComputer,
    'receiver' => l.inputIconReceiver,
    'disc' => l.inputIconDisc,
    'stream' => l.inputIconStream,
    _ => l.defaultOption,
  };

  Future<void> _icon(TvInput input) async {
    final l = AppLocalizations.of(context)!;
    final value = await showLauncherDialog<String>(
      context: context,
      builder: (dialog) => SettingsChoiceDialog<String>(
        title: Text(l.inputIcon),
        value: input.icon,
        options: tvInputIcons,
        leadingBuilder: (icon) => Icon(
          tvInputIcon(input.withPresentation(label: input.label, icon: icon)),
        ),
        optionBuilder: (icon) => Text(_iconLabel(l, icon)),
        onSelected: (icon) => Navigator.pop(dialog, icon),
      ),
    );
    if (value != null && mounted) {
      final config = context.read<TvInputsService>().configuration;
      await _save(
        config.copyWith(
          id: input.id,
          value: TvInputOverride(
            name: config.overrides[input.id]?.name ?? '',
            icon: value,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<TvInputsService>();
    final config = service.configuration;
    final input = widget.input == null
        ? null
        : service.present([widget.input!]).single;
    final current = input == null
        ? const TvInputOverride()
        : config.overrides[input.id] ?? const TvInputOverride();
    return SettingsPageLayout(
      title: Text(input?.label ?? l.inputsSettings),
      child: ListView(
        children: [
          if (input == null) ...[
            RoundedSwitchListTile(
              autofocus: true,
              value: config.useCecNames,
              enabled: service.hasInputs,
              title: Text(l.inputsUseCecNames),
              onChanged: (v) => _save(config.copyWith(useCecNames: v)),
            ),
            SettingsHelp(title: l.inputs, text: l.inputsNamesHint),
            RoundedSwitchListTile(
              value: config.cecStateOnly,
              enabled: service.hasInputs,
              title: Text(l.inputsCecStateOnly),
              onChanged: (v) => _save(config.copyWith(cecStateOnly: v)),
            ),
            SettingsHelp(
              title: l.inputsCecStateOnly,
              text: l.inputsCecStateOnlyHelp,
            ),
            if (!service.initialized)
              const LinearProgressIndicator()
            else if (!service.hasInputs)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsMessage(
                    text: l.inputsUnavailableStatus,
                    kind: SettingsMessageKind.warning,
                  ),
                  SettingsHelp(title: l.inputs, text: l.inputsUnavailableHint),
                ],
              ),
            for (final source in service.inputs)
              FocusableSettingsTile(
                leading: Icon(tvInputIcon(source)),
                title: Text(source.label),
                onPressed: () => Navigator.of(context).push(
                  SettingsRoute(
                    settings: const RouteSettings(
                      name: InputsSettingsPage.routeName,
                    ),
                    builder: (_) => InputsSettingsPage(input: source),
                  ),
                ),
              ),
          ] else ...[
            FocusableSettingsTile(
              autofocus: true,
              title: Text(l.customName),
              enabled: service.hasInputs,
              trailing: Text(
                current.name.isEmpty ? l.settingsValueNotSet : current.name,
              ),
              onPressed: () => _name(input, current),
            ),
            FocusableSettingsTile(
              leading: Icon(tvInputIcon(input)),
              title: Text(l.inputIcon),
              enabled: service.hasInputs,
              trailing: Text(_iconLabel(l, current.icon)),
              onPressed: () => _icon(input),
            ),
          ],
        ],
      ),
    );
  }
}

class _InputNameDialog extends StatefulWidget {
  final String initialName;
  const _InputNameDialog({required this.initialName});
  @override
  State<_InputNameDialog> createState() => _InputNameDialogState();
}

class _InputNameDialogState extends State<_InputNameDialog> {
  late final _editor = TextEditingController(text: widget.initialName);
  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LauncherAlertDialog(
      title: Text(l.customName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RemoteTextInput(
            child: TextField(
              controller: _editor,
              autofocus: true,
              maxLength: 80,
              decoration: const InputDecoration(),
            ),
          ),
          SettingsHelp(title: l.inputsSettings, text: l.inputNameHint),
        ],
      ),
      actions: [
        LauncherDialogButton(
          isCancel: true,
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        LauncherDialogButton(
          onPressed: () => Navigator.pop(context, ''),
          child: Text(l.defaultOption),
        ),
        LauncherDialogButton(
          primary: true,
          onPressed: () => Navigator.pop(context, _editor.text),
          child: Text(l.ok),
        ),
      ],
    );
  }
}
