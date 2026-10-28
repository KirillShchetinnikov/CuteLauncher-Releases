import 'package:flauncher/bridge_result.dart';
import 'dart:async';

import '../providers/network_service.dart';
import '../providers/tv_inputs_service.dart';
import '../providers/notifications_service.dart';
import '../providers/weather_service.dart';
import '../providers/sleep_timer_service.dart';
import '../providers/night_mode_service.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/remote_panel_service.dart';
import 'focus_aware_app_bar.dart';

const remotePanelChannel = BridgeChannel('cutelauncher/remote_panel', preserveErrorCodes: true);

class RemotePanel extends StatefulWidget {
  const RemotePanel({super.key});
  @override
  State<RemotePanel> createState() => _RemotePanelState();
}

class _RemotePanelState extends State<RemotePanel> {
  final _bar = GlobalKey<FocusAwareAppBarState>();
  bool _ready = false;
  final _removeListeners = <VoidCallback>[];

  Future<void> _waitFor(ChangeNotifier source, bool Function() ready) {
    if (ready()) return Future.value();
    final complete = Completer<void>();
    void listener() {
      if (!ready()) return;
      source.removeListener(listener);
      if (!complete.isCompleted) complete.complete();
    }

    source.addListener(listener);
    _removeListeners.add(() => source.removeListener(listener));
    return complete.future;
  }

  Future<void> _prepare() async {
    final panel = context.read<RemotePanelService>();
    final pending = <Future<void>>[];
    final night = context.read<NightModeService?>();
    if (night != null) {
      pending.add(_waitFor(night, () => night.panelPresentationReady));
    }
    if (panel.visible('inputs')) {
      final inputs = context.read<TvInputsService>();
      pending.add(_waitFor(inputs, () => inputs.initialized));
    }
    if (panel.visible('notifications')) {
      final notifications = context.read<NotificationsService>();
      pending.add(_waitFor(notifications, () => notifications.initialized));
    }
    if (panel.visible('traffic')) {
      pending.add(context.read<NetworkService>().initialLoad);
    } else if (panel.visible('network')) {
      pending.add(context.read<NetworkService>().initialNetworkLoad);
    }
    if (panel.visible('weather')) {
      final weather = context.read<WeatherService>();
      // Direct providers have read their local cache before starting HTTP.
      // Opening the panel must not wait for a remote weather request.
      pending.add(
        _waitFor(weather, () => weather.initialized || weather.loading),
      );
    }
    if (panel.visible('sleepTimer')) {
      final timer = context.read<SleepTimerService?>();
      if (timer != null) pending.add(timer.refresh());
    }
    await Future.wait(pending);
    if (!mounted) return;
    setState(() => _ready = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bar.currentState?.focusFirst();
        remotePanelChannel.invokeMethod<void>('ready');
      }
    });
  }

  @override
  void dispose() {
    for (final remove in _removeListeners) {
      remove();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) remotePanelChannel.invokeMethod<void>('close');
    },
    child: Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          if (_ready)
            Align(
              alignment: Alignment.topCenter,
              child: FocusAwareAppBar(
                key: _bar,
                remotePanel: context.watch<RemotePanelService>(),
              ),
            ),
        ],
      ),
    ),
  );
}
