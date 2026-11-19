/*
 * FLauncher
 * Copyright (C) 2024 LeanBitLab
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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'link_qr_code.dart';

import '../launcher_dialog.dart';
import 'settings_option_tile.dart';

enum DonationService {
  cloudTips('CloudTips', 'https://pay.cloudtips.ru/p/118c2a7f'),
  yooMoney('ЮMoney', 'https://yoomoney.ru/fundraise/1LLAULV57ME.261119');

  const DonationService(this.label, this.url);
  final String label;
  final String url;
}

class DonateDialog extends StatefulWidget {
  const DonateDialog({super.key});

  @override
  State<DonateDialog> createState() => _DonateDialogState();
}

class _DonateDialogState extends State<DonateDialog> {
  DonationService selected = DonationService.cloudTips;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final qrSize = math.min(
                240.0,
                math.min(
                  constraints.maxWidth,
                  MediaQuery.sizeOf(context).height * .44,
                ),
              );
              final options = [
                for (final service in DonationService.values)
                  SettingsOptionTile(
                    title: Text(service.label),
                    selected: selected == service,
                    autofocus: service == DonationService.cloudTips,
                    onPressed: () => setState(() => selected = service),
                  ),
              ];
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        namesRoute: true,
                        header: true,
                        child: Text(
                          l.supportDeveloper,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(l.scanToDonate),
                      const SizedBox(height: 8),
                      if (constraints.maxWidth < 280)
                        ...options
                      else
                        Row(
                          children: [
                            Expanded(child: options.first),
                            const SizedBox(width: 8),
                            Expanded(child: options.last),
                          ],
                        ),
                      const SizedBox(height: 12),
                      LinkQrCode(
                        key: ValueKey(selected.url),
                        url: selected.url,
                        label: selected.label,
                        size: qrSize,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: LauncherDialogButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l.close),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
