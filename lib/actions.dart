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

import 'key_sounds.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

class SoundFeedbackDirectionalFocusAction extends DirectionalFocusAction {
  final BuildContext context;

  SoundFeedbackDirectionalFocusAction(this.context);

  @override
  void invoke(DirectionalFocusIntent intent) {
    final soundContext = FocusManager.instance.primaryFocus?.context ?? context;
    super.invoke(intent);
    playKeySound(soundContext);
    silentForTap(context);
  }

  /// copied from Feedback.forTap, omitting playing a sound
  static void silentForTap(BuildContext context) async {
    context.findRenderObject()!.sendSemanticsEvent(const TapSemanticEvent());
  }
}

class BackAction extends Action<BackIntent> {
  final BuildContext context;
  final ValueChanged<bool>? onFirstSectionCard;

  BackAction(this.context, {this.onFirstSectionCard});

  @override
  Future<void> invoke(BackIntent intent) async {
    NavigatorState? navigator = Navigator.maybeOf(context);

    if (navigator != null) {
      navigator.maybePop();
    }
    else {
      LauncherState state = context.read<LauncherState>();
      state.handleBackNavigation(context, onFirstSectionCard: onFirstSectionCard);
    }
  }
}

class MoveFocusToSettingsIntent extends Intent {
  const MoveFocusToSettingsIntent();
}

class BackIntent extends Intent {
  const BackIntent();
}

Future<bool> isDefaultLauncher(BuildContext context) async => await context.read<AppsService>().isDefaultLauncher();
