import 'app_fonts.dart';
import 'widgets/notification_popup_presentation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/appearance_service.dart';
import 'providers/remote_panel_service.dart';
import 'providers/weather_service.dart';
import 'package:flauncher/theme/launcher_style.dart';
import 'theme/interface_style.dart';
import 'package:flauncher/widgets/action_notice.dart';
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

import 'package:flauncher/actions.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flutter/material.dart';
import 'providers/night_mode_service.dart';
import 'package:flutter/services.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'flauncher.dart';
import 'widgets/remote_panel.dart';
import 'widgets/update_notification.dart';
import 'dart:async';

class FLauncherApp extends StatefulWidget
{
  final bool remotePanel;
  const FLauncherApp({super.key, this.remotePanel = false});
  @override
  State<FLauncherApp> createState() => _FLauncherAppState();
}

class _FLauncherAppState extends State<FLauncherApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _launcherKey = GlobalKey<FLauncherState>();
  StreamSubscription<dynamic>? _homeSubscription;
  VoidCallback? _closePanelNotice;

  @override
  void initState() {
    super.initState();
    if (widget.remotePanel) return;
    _homeSubscription = const EventChannel('me.efesser.flauncher/event_home')
        .receiveBroadcastStream().listen((event) async {
      if (!mounted) return;
      if (event == 'remote_panel_blocked') {
        final noticeContext = _navigatorKey.currentState?.overlay?.context;
        if (noticeContext == null || !noticeContext.mounted) return;
        _closePanelNotice?.call();
        _closePanelNotice = showActionNotice(
          noticeContext,
          AppLocalizations.of(noticeContext)!.remotePanelDisabledInLauncher,
          error: true,
          settingsOpen: NotificationPopupPresentation.settingsDepth.value > 0,
          onRight: context.read<SettingsService>().settingsMenuOnRight,
        );
        return;
      }
      if (event == 'preferences_changed') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        if (!mounted) return;
        context.read<SettingsService>().reload();
        context.read<AppearanceService>().reload();
        context.read<RemotePanelService>().reload();
        unawaited(context.read<NightModeService>().refreshSystem());
        unawaited(context.read<WeatherService>().reloadConfiguration());
        return;
      }
      if (event != true || !mounted) return;
      context.read<SettingsService>().landscapeDemo.value = null;
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      _launcherKey.currentState?.returnHome();
    }, onError: (Object error) => debugPrint('Home event unavailable: $error'));
  }

  @override
  void dispose() {
    _homeSubscription?.cancel();
    super.dispose();
  }
  static const PrioritizedIntents _backIntents = PrioritizedIntents(orderedIntents: [
    DismissIntent(),
    BackIntent()
  ]);

  @override
  Widget build(BuildContext context) {
    if (!widget.remotePanel) {
      final appsService = context.read<AppsService>();
      context.read<LauncherState>().refresh(appsService);
    }

    return Selector2<SettingsService, AppearanceService?, (Color, Locale?, String, String)>(
      selector: (_, settings, appearance) => (settings.accentColor, settings.appLocale,
        appearance?.appearance.interfaceStyle ?? 'standard',
        appearance?.appearance.interfaceFont ?? 'system'),
      builder: (context, tuple, _) {
        final accentColor = tuple.$1;
        final appLocale = tuple.$2;
        final skin = InterfaceSkin(interfaceStyleFrom(tuple.$3));
        final geometry = const LauncherStyle().copyWith(
          rowRadius: skin.radius,
          topButtonRadius: skin.standard ? 16 : skin.radius,
          panelRadius: skin.standard ? 28 : skin.radius + 8,
          dialogRadius: skin.standard ? 24 : skin.radius + 4,
          tileRadius: skin.radius,
        );

        return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => LanguageFontTheme(font: tuple.$4, child: Consumer<NightModeService?>(
        builder: (context, night, _) => NightModeFilter(
          service: night,
          child: ActionNoticeHost(
            child: widget.remotePanel
                ? child ?? const SizedBox.shrink()
                : UpdateNotification(child: child ?? const SizedBox.shrink()),
          ),
        ),
      )),
      navigatorKey: _navigatorKey,
      locale: appLocale,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
      ),
      shortcuts: {
        ...WidgetsApp.defaultShortcuts,
        const SingleActivator(LogicalKeyboardKey.escape): _backIntents,
        const SingleActivator(LogicalKeyboardKey.gameButtonB): _backIntents,
        const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.gameButtonSelect): const ActivateIntent(),
      },
      actions: {
        ...WidgetsApp.defaultActions,
        BackIntent: BackAction(context),
        DirectionalFocusIntent: SoundFeedbackDirectionalFocusAction(context)
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'CuteLauncher',
        theme: skin.apply(ThemeData(
          extensions: [geometry, skin],
          fontFamily: null,
          useMaterial3: true,
          brightness: Brightness.dark,
          // Use ColorScheme based on accent color
          colorScheme: ColorScheme.fromSeed(
            seedColor: accentColor,
            brightness: Brightness.dark,
            primary: accentColor,
            secondary: accentColor,
            tertiary: accentColor,
            surface: const Color(0xFF1C2029),
            onSurface: const Color(0xFFF4F5F8),
            onSurfaceVariant: const Color(0xFFB9BFCD),
          ),
          cardColor: const Color(0xFF242935),
          canvasColor: const Color(0xFF1C2029),
          scaffoldBackgroundColor: const Color(0xFF11141B),
          textTheme: Typography.material2018().white.copyWith(
            titleLarge: const TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w600, letterSpacing: -0.4, color: Color(0xFFF4F5F8)),
            titleMedium: const TextStyle(fontSize: 18, height: 1.3, fontWeight: FontWeight.w500, color: Color(0xFFF4F5F8)),
            bodyLarge: const TextStyle(fontSize: 16, height: 1.35, color: Color(0xFFF4F5F8)),
            bodyMedium: const TextStyle(fontSize: 15, height: 1.3, color: Color(0xFFF4F5F8)),
            bodySmall: const TextStyle(fontSize: 13, height: 1.3, color: Color(0xFFB9BFCD)),
          ),
          dividerTheme: const DividerThemeData(color: Color(0xFF343A47), thickness: 0.5, space: 24),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, // Revert to white for settings list
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(geometry.rowRadius)),
                splashFactory: NoSplash.splashFactory,
              )
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(geometry.dialogRadius)),
            backgroundColor: const Color(0xFF1C2029),
            surfaceTintColor: Colors.transparent,
            titleTextStyle: Typography.material2018().white.titleLarge,
            contentTextStyle: Typography.material2018().white.bodyMedium,
          ),
          appBarTheme: const AppBarTheme(elevation: 0, backgroundColor: Colors.transparent),
          typography: Typography.material2018(),
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor)),
            labelStyle: Typography.material2018().white.bodyMedium,
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: accentColor,
            selectionColor: accentColor.withValues(alpha: 0.4),
            selectionHandleColor: accentColor,
          ),
          progressIndicatorTheme: ProgressIndicatorThemeData(color: accentColor),
          sliderTheme: SliderThemeData(
            activeTrackColor: accentColor,
            thumbColor: accentColor,
            inactiveTrackColor: accentColor.withValues(alpha: 0.3),
          ),
          toggleButtonsTheme: ToggleButtonsThemeData(
            selectedColor: accentColor,
            fillColor: accentColor.withValues(alpha: 0.1),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return accentColor;
              return null;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return accentColor.withValues(alpha: 0.5);
              return null;
            }),
          ), tabBarTheme: TabBarThemeData(indicatorColor: accentColor),
        )),
      home: widget.remotePanel ? const RemotePanel() : Builder(
        builder: (context) => PopScope(
          canPop: false,
          child: FLauncher(key: _launcherKey),
          onPopInvokedWithResult: (didPop, result) {
            LauncherState launcherState = context.read<LauncherState>();
            launcherState.handleBackNavigation(context);
          }
        )
      ),
      );
    });
  }
}
