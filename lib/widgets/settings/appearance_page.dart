import 'language_font_choice.dart';
import '../../providers/remote_panel_service.dart';
import '../../tile_appearance.dart';
import 'settings_help.dart';
import 'home_style_setting.dart';
import 'settings_choice_tile.dart';
import 'reset_style_tile.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';

import 'settings_page_layout.dart';
import '../../theme/launcher_style.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import '../../providers/appearance_service.dart';
import '../../providers/settings_service.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_value_stepper.dart';
import 'settings_percentage_slider.dart';
import 'color_palette_dialog.dart';

class AppearancePage extends StatefulWidget {
  static const routeName = 'appearance_panel';
  final String section;
  final bool remotePanel;
  static const remotePanelRouteName = 'remote_panel_appearance';
  final int? categoryId;
  const AppearancePage({super.key, this.section = 'tiles', this.categoryId,
    this.remotePanel = false})
      : assert(!remotePanel || (section == 'panel' && categoryId == null));

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}
class _AppearancePageState extends State<AppearancePage> {
  String get section => widget.section;
  int? get categoryId => widget.categoryId;
  AppearanceService? _service;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service = context.read<AppearanceService>();
    if (section == 'focus') {
      final size = MediaQuery.sizeOf(context);
      final style = LauncherStyle.of(context);
      final edge = style.settingsWidth + style.panelMargin * 2 + 20;
      final right = context.watch<SettingsService>().settingsMenuOnRight;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _service!.beginFocusPreview(Rect.fromLTRB(
            right ? 0 : edge, 0, right ? size.width - edge : size.width, size.height), categoryId: categoryId);
        }
      });
    }
  }
  @override
  void dispose() {
    if (section == 'focus') _service?.endFocusPreview();
    super.dispose();
  }
  Future<void> _set(AppearanceService service, String key, dynamic value) =>
      widget.remotePanel ? context.read<RemotePanelService>().setAppearance(key, value)
      : categoryId == null ? service.set(key, value)
          : service.setCategoryTile(categoryId!, key, value);

  TileAppearance _appearance(AppearanceService service) => widget.remotePanel
      ? context.read<RemotePanelService>().ownAppearance
      : categoryId == null ? service.appearance : service.tilesFor(categoryId!);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AppearanceService>();
    final settings = context.watch<SettingsService>();
    final panel = widget.remotePanel ? context.watch<RemotePanelService>() : null;
    final appearance = _appearance(service);
    return SettingsPageLayout(
      title: Text(
        section == 'panel'
            ? (widget.remotePanel ? l.appearanceSettings : l.panelAppearanceSettings)
            : section == 'focus'
            ? l.highlightAndAnimation
            : l.tilesAndLabels,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        children: [
          if (section == 'tiles') ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l.sizeAndLayout,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            _choice(context, service, l.tileSize, 'size', [
              for (var n = 64; n <= 256; n += 8) n,
            ], autofocus: true),
            _choice(
              context,
              service,
              l.tileProportions,
              'aspectRatio',
              [1, 4 / 3, 16 / 9],
              labels: {1: '1:1', 4 / 3: '4:3', 16 / 9: '16:9'},
            ),
            _choice(context, service, l.tileCornerRadius, 'radius', [
              null,
              0,
              8,
              16,
              32,
              100,
            ], autofocus: false),
            _choice(context, service, l.tileHorizontalGap, 'horizontalGap', [
              for (var n = 0; n <= 48; n += 2) n,
            ]),
            _choice(context, service, l.tileVerticalGap, 'verticalGap', [
              for (var n = 0; n <= 48; n += 2) n,
            ]),
            _choice(context, service, l.tileIconScale, 'iconScale', [
              0.5,
              0.65,
              0.8,
              1,
            ], percentage: true),
            SettingsHelp(text: l.homeStyleIconHint),
            ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l.labelsGroup,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            HomeStyleSetting(categoryId: categoryId, field: 'labels', builder: (enabled) => SettingsChoiceTile<String>(enabled: enabled,
              title: l.homeLabelMode, value: appearance.labels,
              options: const ['none', 'selected', 'all'],
              label: (v) => {'none': l.homeLabelNone, 'selected': l.homeLabelSelected, 'all': l.homeLabelAll}[v]!,
              onChanged: (v) => _set(service, 'labels', v))),
            _choice(
              context,
              service,
              l.tileLabelPosition,
              'labelPosition',
              ['below', 'inside'],
              labels: {'below': l.tileLabelBelow, 'inside': l.tileLabelInside},
            ),
            _choice(context, service, l.tileLabelSize, 'labelSize', [
              10,
              12,
              14,
              16,
              20,
            ]),
            _choice(context, service, l.tileLabelColor, 'labelColor', [
              null,
              0xffffffff,
              0xff000000,
              0xffffd54f,
              0xff80cbc4,
            ], color: true),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l.surfaceGroup,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            _choice(
              context,
              service,
              l.tileBackgroundColor,
              'backgroundColor',
              [
                null,
                0xff000000,
                0xff27272a,
                0xfffafafa,
                0xff1e3a8a,
                0xff14532d,
              ],
              color: true,
            ),
            _choice(context, service, l.tileOpacity, 'opacity', [
              0,
              0.25,
              0.5,
              0.75,
              1,
            ], percentage: true),
            _choice(context, service, l.tileShadow, 'shadow', [
              0,
              2,
              8,
              16,
            ]),
            if (settings.memorySaverEnabled)
              SettingsHelp(text: l.homeStyleShadowHint),
            HomeStyleSetting(categoryId: categoryId, field: 'blurTiles', builder: (enabled) => RoundedSwitchListTile(
              enabled: enabled,
              value: appearance.blurTiles,
              onChanged: (v) => _set(service, 'blurTiles', v),
              title: Text(l.tileBlur),
            )),
            ],
          ],
          if (section == 'focus') ...[
            _choice(
              context,
              service,
              l.tileFocusEffect,
              'focusEffect',
              ['scale', 'border', 'lift'],
              autofocus: true,
              labels: {
                'scale': l.tileFocusScale,
                'border': l.tileFocusBorder,
                'lift': l.tileFocusLift,
              },
            ),
            _choice(context, service, l.tileFocusEnlargement, 'focusScale', [
              for (var n = 0; n <= 50; n += 5) n / 100,
            ], percentage: true),
            HomeStyleSetting(categoryId: categoryId, field: 'focusShadow', builder: (enabled) => RoundedSwitchListTile(
              enabled: enabled,
              value: appearance.showFocusShadow,
              onChanged: (value) => _set(service, 'focusShadow', value),
              title: Text(l.tileShowFocusShadow),
            )),
            _choice(context, service, l.tileFocusLiftHeight, 'focusLift', [
              for (var n = 0; n <= 25; n += 5) n,
            ]),
            _choice(context, service, l.tileFocusBorderColor, 'focusBorderColor',
              ['accent', 'dynamic'], labels: {
                'accent': l.tileFocusAccentColor,
                'dynamic': l.tileFocusDynamicColor,
              }),
            _choice(context, service, l.tileFocusBorderStyle, 'focusBorderStyle',
              ['outline', 'glow', 'none'], labels: {
                'outline': l.tileFocusOutline,
                'glow': l.tileFocusGlow,
                'none': l.tileFocusNoBorder,
              }),
            HomeStyleSetting(categoryId: categoryId, field: 'focusPulse', builder: (enabled) => RoundedSwitchListTile(
              enabled: enabled,
              value: appearance.values['focusPulse'] as bool? ?? settings.appHighlightAnimationEnabled,
              onChanged: (v) => _set(service, 'focusPulse', v),
              title: Text(l.appCardHighlightAnimation),
            )),
            HomeStyleSetting(categoryId: categoryId, field: 'focusTransition', builder: (enabled) => RoundedSwitchListTile(
              enabled: enabled,
              value: appearance.values['focusTransition'] as bool? ?? settings.appSelectorTransitionAnimationEnabled,
              onChanged: (v) => _set(service, 'focusTransition', v),
              title: Text(l.appSelectorTransitionAnimation),
            )),
            HomeStyleSetting(categoryId: categoryId, field: 'animateReordering', builder: (enabled) => RoundedSwitchListTile(
              enabled: enabled,
              value: appearance.animateReordering,
              onChanged: (value) => _set(service, 'animateReordering', value),
              title: Text(l.animateTileReordering),
            )),
          ],
          if (section == 'panel') ...[
            if (panel != null)
              RoundedSwitchListTile(
                autofocus: true,
                title: Text(l.remotePanelInheritAppearance),
                value: panel.inheritAppearance,
                onChanged: (value) => panel.set('inheritAppearance', value),
              ),
            if (panel == null || !panel.inheritAppearance) ...[
              if (!widget.remotePanel)
                RoundedSwitchListTile(
                  autofocus: true,
                  value: settings.autoHideAppBarEnabled,
                  onChanged: settings.setAutoHideAppBarEnabled,
                  title: Text(l.autoHideTopPanel),
                ),
              _choice(context, service, l.panelBackground, 'panelColor', [
                0xff000000,
                0xff242935,
                0xfffafafa,
                0xff1e3a8a,
                0xff14532d,
                0xff7f1d1d,
                0xff581c87,
                0xff78350f,
              ], color: true),
              SettingsPercentageSlider(
                key: const Key('panel-transparency'),
                title: l.panelTransparency,
                value: 1 - (appearance.number('panelOpacity') ?? 0),
                onChanged: (v) => _set(service, 'panelOpacity', 1 - v),
              ),
              RoundedSwitchListTile(
                value: appearance.values['panelTextBackground'] != false,
                onChanged: (v) => _set(service, 'panelTextBackground', v),
                title: Text(l.panelTextBackground),
              ),
              if (appearance.values['panelTextBackground'] != false)
                _choice(
                  context,
                  service,
                  l.panelTextBackgroundColor,
                  'panelTextBackgroundColor',
                  [
                    0xff242935,
                    0xff000000,
                    0xfffafafa,
                    0xff1e3a8a,
                    0xff14532d,
                    0xff7f1d1d,
                    0xff581c87,
                    0xff78350f,
                  ],
                  color: true,
                ),
              if (appearance.values['panelTextBackground'] != false)
                SettingsPercentageSlider(
                  key: const Key('panel-text-transparency'),
                  title: l.panelTextBackgroundTransparency,
                  value: 1 - appearance.panelTextBackgroundOpacity,
                  onChanged: (v) =>
                      _set(service, 'panelTextBackgroundOpacity', 1 - v),
                ),
              _choice(context, service, l.panelTextColor, 'panelTextColor', [
                0xffffffff,
                0xff000000,
                0xffffd54f,
                0xff80cbc4,
                0xff90caf9,
                0xfff48fb1,
              ], color: true),
              _choice(context, service, l.panelTextSize, 'panelTextSize', [
                10,
                12,
                14,
                16,
                18,
                20,
                22,
                24,
              ]),
              LanguageFontChoice(
                title: l.panelFont,
                value: appearance.panelFont,
                panel: true,
                onChanged: (v) => _set(service, 'panelFont', v),
              ),
              RoundedSwitchListTile(
                value: service.appearance.panelWrapNavigation,
                onChanged: (v) => service.set('panelWrapNavigation', v),
                title: Text(l.panelWrapNavigation),
              ),
              SettingsHelp(text: l.panelWrapNavigationHelp),
              if (!widget.remotePanel)
                RoundedSwitchListTile(
                  value: appearance.blurPanel,
                  enabled: !settings.memorySaverEnabled,
                  onChanged: (v) => _set(service, 'blurPanel', v),
                  title: Text(l.panelBlur),
                ),
              if (!widget.remotePanel)
                SettingsHelp(text: l.blurPerformanceHint),
            ],
          ],
          ResetStyleTile(
            title: categoryId == null ? null : l.homeOwnReset,
            hint: categoryId == null ? null : l.homeResetTilesHint,
            onReset: () async {
            if (widget.remotePanel) {
              await context.read<RemotePanelService>().resetAppearance();
              return;
            }
            final keys = section == 'focus' ? ['focusEffect', 'focusStrength', 'focusScale', 'focusLift', 'focusShadow', 'focusBorderColor', 'focusBorderStyle', 'focusPulse', 'focusTransition', 'animateReordering']
                : section == 'panel' ? ['panelColor', 'panelOpacity', 'panelTextBackground',
                    'panelTextBackgroundColor', 'panelTextBackgroundOpacity', 'panelTextColor',
                    'panelTextSize', 'panelFont', 'blurPanel', 'panelWrapNavigation']
                : ['size', 'aspectRatio', 'radius', 'horizontalGap', 'verticalGap',
                    'iconScale', 'labels', 'labelPosition', 'labelSize', 'labelColor',
                    'backgroundColor', 'opacity', 'shadow', 'blurTiles'];
            await service.resetFields(keys, categoryId: categoryId);
            if (categoryId == null) await settings.resetAppearanceSection(section);
          }),
        ],
      ),
    );
  }

  Widget _scoped(String field, Widget Function(bool) builder) => section == 'panel'
      ? builder(true)
      : HomeStyleSetting(categoryId: categoryId, field: field, builder: builder);

  Widget _choice(
    BuildContext context,
    AppearanceService service,
    String title,
    String key,
    List<dynamic> options, {
    bool autofocus = false,
    bool enabled = true,
    bool color = false,
    bool percentage = false,
    Map<dynamic, String> labels = const {},
  }) {
    final l = AppLocalizations.of(context)!;
    final current =
        _appearance(service).values[key] ??
        {
          'shadow': 0,
          'opacity': 1,
          'horizontalGap': 16,
          'verticalGap': 16,
          'labelSize': 12,
          'iconScale': 1,
          'size': 128,
          'aspectRatio': 16 / 9,
          'labelPosition': 'below',
          'focusEffect': 'scale',
          'focusStrength': 0.1,
          'focusScale': (categoryId == null ? service.appearance : service.tilesFor(categoryId!)).number('focusStrength') ?? .1,
          'focusLift': 10,
          'focusBorderColor': 'accent',
          'focusBorderStyle': service.appearance.focusBorderStyle(legacyHidden: context.read<SettingsService>().hideHighlightOutlineOnHomescreen),
          'panelOpacity': 0,
          'panelColor': 0xff000000,
          'panelTextColor': 0xffffffff,
          'panelTextSize': 18,
          'panelFont': 'sans-serif',
          'panelTextBackgroundColor': 0xff242935,
        }[key];
    String label(dynamic value) =>
        labels[value] ??
        (value == null
            ? l.defaultOption
            : percentage
            ? '${((value as num) * 100).round()}%'
            : '$value');
    Widget valueWidget(dynamic value) => color && value is int
        ? Container(
            width: 36,
            height: 24,
            decoration: BoxDecoration(
              color: Color(value),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
          )
        : Text(label(value));
    if (!color && options.every((value) => value == null || value is num)) {
      return _scoped(key, (applicable) => SettingsValueStepper(
        title: title,
        options: options,
        value: current,
        label: label,
        autofocus: autofocus,
        enabled: enabled && applicable,
        onChanged: (value) => _set(service, key, value),
      ));
    }
    return _scoped(key, (applicable) => FocusableSettingsTile(
      autofocus: autofocus,
      enabled: enabled && applicable,
      title: Text(title),
      trailing: valueWidget(current),
      onPressed: () async {
        if (color) {
          final selected = await showLauncherDialog<(int?,)>(
            context: context,
            builder: (_) => ColorPaletteDialog(
              title: title,
              current: current as int?,
              allowDefault: options.contains(null),
              forPanel: section == 'panel',
            ),
          );
          if (selected != null) await _set(service, key, selected.$1);
          return;
        }
        final selected = await showLauncherDialog<(dynamic,)>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(title),
            children: [
              SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final value in options)
                      FocusableSettingsTile(
                        autofocus: value == current,
                        onPressed: () => Navigator.pop(context, (value,)),
                        title: valueWidget(value),
                        trailing: value == current
                            ? const Icon(Icons.check)
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
        if (selected != null) await _set(service, key, selected.$1);
      },
    ));
  }
}
