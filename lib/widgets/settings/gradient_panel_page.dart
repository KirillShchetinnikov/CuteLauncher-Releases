import 'reset_style_tile.dart';
import 'settings_page_layout.dart';
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

import 'package:flauncher/gradients.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class GradientPanelPage extends StatefulWidget {
  static const String routeName = "gradient_panel";

  const GradientPanelPage({super.key});

  @override
  State<GradientPanelPage> createState() => _GradientPanelPageState();
}

class _GradientPanelPageState extends State<GradientPanelPage> {
  final _entryFocus = FocusNode();
  late final _entryGradient = context.read<WallpaperService>().gradient.uuid;

  @override
  void dispose() {
    _entryFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = context.select<WallpaperService, String>((s) => s.gradient.uuid);
    return SettingsPageLayout(
      initialFocus: _entryFocus,
      title: Text(
        AppLocalizations.of(context)!.gradient,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      footer: ResetStyleTile(
        onReset: () => context.read<WallpaperService>().setGradient(
          FLauncherGradients.pitchBlack,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textStyle = Theme.of(context).textTheme.bodySmall!;
          final cardWidth = (constraints.maxWidth - 8) / 2;
          final gradients = FLauncherGradients.all;
          var labelHeight = 0.0;
          for (final gradient in gradients) {
            final painter = TextPainter(
              text: TextSpan(text: gradient.name, style: textStyle),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: cardWidth - 8);
            if (painter.height > labelHeight) labelHeight = painter.height;
            painter.dispose();
          }
          final cardHeight = cardWidth * .75 + labelHeight;
          return GridView.count(
            crossAxisCount: 2,
            childAspectRatio: cardWidth / cardHeight,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            // Attach the saved swatch even when it starts outside the viewport.
            scrollCacheExtent: ScrollCacheExtent.pixels(((gradients.length + 1) ~/ 2) * (cardHeight + 8)),
            children: [
              for (final gradient in gradients)
                EnsureVisible(
                  alignment: 0.5,
                  child: _gradientCard(context, gradient, selected == gradient.uuid),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _gradientCard(BuildContext context, FLauncherGradient gradient, bool selected) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      label: gradient.name,
      child: Focus(
        key: Key('gradient-${gradient.uuid}'),
        canRequestFocus: false,
        child: Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: Focus.of(context).hasFocus
                        ? BorderSide(color: colors.primary, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    focusNode: gradient.uuid == _entryGradient ? _entryFocus : null,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    onTap: () => context.read<WallpaperService>().setGradient(gradient),
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: gradient.gradient),
                      child: SizedBox.expand(
                        child: selected
                            ? const Align(
                                alignment: AlignmentDirectional.topEnd,
                                child: Padding(
                                  padding: EdgeInsets.all(6),
                                  child: CircleAvatar(
                                    radius: 11,
                                    backgroundColor: Colors.black87,
                                    child: Icon(Icons.check, size: 16, color: Colors.white),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ExcludeSemantics(
                  child: Text(
                    gradient.name,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      decoration: TextDecoration.underline,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
