import '../menu_header.dart';
import '../menu_header_action.dart';
import '../launcher_dialog.dart';
import 'inputs_settings_page.dart';
import 'settings_panel.dart';
import '../tv_input_icon.dart';
import '../tv_input_connection_indicator.dart';
import 'settings_panel_style.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:provider/provider.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/models/tv_input.dart';
import 'package:flauncher/l10n/app_localizations.dart';

class InputsPanel extends StatefulWidget {
  final bool? isRightSide;
  final double topInset;
  final Rect? anchor;
  const InputsPanel({
    super.key,
    this.isRightSide,
    this.topInset = 0,
    this.anchor,
  });

  @override
  State<InputsPanel> createState() => _InputsPanelState();
}

class _InputsPanelState extends State<InputsPanel> {
  final _settingsNode = FocusNode();
  bool _settingsOpen = false;

  @override
  void dispose() {
    _settingsNode.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    setState(() => _settingsOpen = true);
    await showLauncherDialog<void>(
      context: context,
      parentPanelHidden: true,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) =>
          const SettingsPanel(initialRoute: InputsSettingsPage.routeName),
    );
    if (!mounted) return;
    setState(() => _settingsOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) =>
      SettingsPanelStyle(builder: _buildPanel);

  Widget _buildPanel(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ExcludeFocus(
      excluding: _settingsOpen,
      child: Offstage(
        offstage: _settingsOpen,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(child: const LauncherPanelBackdrop()),
              // Tap outside to close
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.transparent),
              ),
              SidePanelDialog(
                anchor: widget.anchor,
                topInset: widget.topInset,
                width: 350,
                isRightSide: widget.isRightSide,
                child: Consumer<TvInputsService>(
                  builder: (context, tvInputsService, _) {
                    final List<TvInput> inputs = tvInputsService.inputs;

                    return Column(
                      mainAxisSize: widget.anchor == null
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: MenuHeader(
                            title: Text(localizations.inputSources),
                            actions: [
                              MenuHeaderAction(
                                focusNode: _settingsNode,
                                autofocus: inputs.isEmpty,
                                tooltip: localizations.inputsSettings,
                                icon: const Icon(Icons.settings_outlined),
                                onPressed: _openSettings,
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Flexible(
                          fit: widget.anchor == null
                              ? FlexFit.tight
                              : FlexFit.loose,
                          child: inputs.isEmpty
                              ? Center(
                                  heightFactor: widget.anchor == null
                                      ? null
                                      : 1,
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .noInputsDetected,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: widget.anchor != null,
                                  scrollCacheExtent: ScrollCacheExtent.pixels(
                                    1000,
                                  ),
                                  itemCount: inputs.length,
                                  itemBuilder: (context, index) {
                                    final input = inputs[index];

                                    return FocusableSettingsTile(
                                      leading: Icon(
                                        tvInputIcon(input),
                                        color: theme.colorScheme.primary,
                                      ),
                                      title: Text(
                                        input.label,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TvInputConnectionIndicator(
                                            connection: input.connection,
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                          ),
                                        ],
                                      ),
                                      autofocus: index == 0,
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await tvInputsService.switchInput(
                                          input.id,
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
