import '../panel_layout.dart';
import '../weather_sources.dart';

/// Keeps bounded evidence from normal widget activity after the global log rolls over.
class WidgetDiagnostics {
  static const _operations = <String, List<String>>{
    'inputs': [
      'android.getTvInputs',
      'android.launchTvInput',
      'dart.tvInputsService',
    ],
    'notifications': [
      'android.checkNotificationListenerPermission',
      'android.getActiveNotifications',
      'android.dismissNotification',
      'android.openNotification',
      'dart.notificationsService',
    ],
    'sleepTimer': [
      'sleepTimer.state',
      'sleepTimer.start',
      'sleepTimer.cancel',
      'dart.sleepTimerService',
    ],
    'nightMode': [
      'night.status',
      'night.configure',
      'night.permission',
      'dart.nightModeService',
    ],
    'nas': [
      'storage_status.snapshot',
      'storage_status.openNas',
      'dart.storageStatusService',
    ],
    'usb': [
      'storage_status.snapshot',
      'storage_status.openUsb',
      'dart.storageStatusService',
    ],
    'network': ['android.getActiveNetworkInformation', 'dart.networkService'],
    'vpn': ['vpn.snapshot', 'vpn.command', 'vpn.permission', 'dart.vpnService'],
    'traffic': [
      'android.checkUsageStatsPermission',
      'android.getDailyDataUsage',
      'android.getWeeklyDataUsage',
      'android.getMonthlyDataUsage',
      'dart.networkService',
    ],
    'networkSpeed': ['network_speed.snapshot', 'dart.networkSpeedService'],
    'system': ['system_status.snapshot', 'dart.systemStatusService'],
    'audio': ['audio_status.snapshot', 'dart.audioStatusService'],
    'remoteBattery': [
      'remote_battery.snapshot',
      'remote_battery.bluetoothPermission',
      'dart.remoteBattery',
    ],
    'weather': [
      'android.getLatestWeatherData',
      'dart.weatherInitialize',
      'dart.weatherFetch',
      'dart.weatherParse',
    ],
    'settings': ['updates.check', 'dart.updateCheck'],
    'systemSettings': ['android.openSettings'],
    'nowPlaying': [
      'media.snapshot',
      'media.action',
      'media.permission',
      'dart.nowPlayingService',
    ],
  };
  static final _trackedOperations = _operations.values
      .expand((ids) => ids)
      .toSet();
  static const _batteryResults = {
    'inputDevice',
    'ble',
    'noInputRemote',
    'ambiguousInputBattery',
    'bluetoothPermissionDenied',
    'noBluetoothAdapter',
    'bluetoothDisabled',
    'noMatchingBondedRemote',
    'ambiguousBondedRemotes',
    'gattConnectionFailed',
    'noBatteryCharacteristic',
    'gattReadFailed',
    'platformError',
    'timeout',
    'screenOff',
    'cancelled',
  };
  static const _batteryErrors = {
    'bluetoothPermissionDenied': 'denied',
    'gattConnectionFailed': 'error',
    'gattReadFailed': 'error',
    'platformError': 'error',
    'timeout': 'error',
  };

  final _latest = <String, Map<String, Object>>{};
  final _errors = <String, Map<String, Object>>{};
  int? _layout;
  ({bool active, bool panelFill})? _night;
  ({WeatherSource source, WeatherFailure? failure, bool hasData, bool stale})?
  _weather;

  // The panel already resolves this layout. Retain only the presence of known IDs.
  void observeLayout(
    Map<String, Object> objects, {
    bool? nightActive,
    bool? nightPanelFill,
  }) {
    var layout = 0;
    for (var i = 0; i < PanelLayout.ids.length; i++) {
      if (objects.containsKey(PanelLayout.ids[i])) layout |= 1 << i;
    }
    _layout = layout;
    if (nightActive != null && nightPanelFill != null) {
      _night = (active: nightActive, panelFill: nightPanelFill);
    }
  }

  void observeWeather(
    WeatherSource source,
    WeatherFailure? failure, {
    required bool hasData,
    required bool stale,
  }) {
    _weather = (
      source: source,
      failure: failure,
      hasData: hasData,
      stale: stale,
    );
  }

  void record(Map<String, Object> event, Object? response) {
    final operation = event['operation'] as String;
    if (!_trackedOperations.contains(operation)) return;
    if (operation == 'remote_battery.snapshot' &&
        response is Map &&
        (response['batteryRead'] == 'cancelled' ||
            (response['batteryRead'] == 'screenOff' && _latest.containsKey(operation)))) {
      return;
    }
    final values = _project(operation, response);
    final batteryRead = values['batteryRead'];
    final batteryError = _batteryErrors[batteryRead];
    final observed = {
      ...event,
      if (values.isNotEmpty) 'result': values,
      if (batteryError != null) ...{'status': batteryError, 'code': batteryRead!},
    };
    _latest[operation] = observed;
    if (observed['status'] != 'success' && observed['status'] != 'cancelled') {
      _errors[operation] = observed;
    }
  }

  static Map<String, Object> _project(String operation, Object? response) {
    if (operation == 'remote_battery.bluetoothPermission' ||
        operation == 'android.checkNotificationListenerPermission' ||
        operation == 'android.checkUsageStatsPermission') {
      return {if (response is bool) 'granted': response};
    }
    if (operation == 'android.getTvInputs' ||
        operation == 'android.getActiveNotifications') {
      return {if (response is List) 'count': response.length};
    }
    if (operation == 'android.getLatestWeatherData') {
      return {'dataPresent': response is String && response.isNotEmpty};
    }
    if (operation.startsWith('android.get') && operation.endsWith('DataUsage')) {
      return {'countersAvailable': response is int && response >= 0};
    }
    if (response is! Map) return {};
    final flags = switch (operation) {
      'remote_battery.snapshot' => const ['screenOn', 'bluetoothPermission'],
      'storage_status.snapshot' => const [
        'screenOn',
        'nasSupported',
        'nas',
        'usb',
      ],
      'audio_status.snapshot' => const ['screenOn', 'fixed', 'muted'],
      'vpn.snapshot' => const [
        'active',
        'supported',
        'permission',
        'canControl',
      ],
      'android.getActiveNetworkInformation' => const [
        'networkAccess',
        'internetAccess',
        'vpnActive',
      ],
      'media.snapshot' => const ['allowed'],
      'network_speed.snapshot' ||
      'system_status.snapshot' => const ['screenOn'],
      _ => const <String>[],
    };
    bool nonnegative(String key) =>
        response[key] is num &&
        (response[key] as num).isFinite &&
        (response[key] as num) >= 0;
    final outcome = response['batteryRead'];
    final percent = response['percent'];
    final candidates = response['inputCandidates'];
    return {
      for (final key in flags)
        if (response[key] is bool) key: response[key] as bool,
      if (operation == 'remote_battery.snapshot') ...{
        if (_batteryResults.contains(outcome)) 'batteryRead': outcome as String,
        if (candidates is int && candidates >= 0) 'inputCandidates': candidates,
      },
      if (operation == 'remote_battery.snapshot' ||
          operation == 'audio_status.snapshot')
        if (percent is int && percent >= 0 && percent <= 100)
          'percent': percent,
      if (operation == 'audio_status.snapshot' && response['outputs'] is List)
        'outputCount': (response['outputs'] as List).length,
      if (operation == 'network_speed.snapshot')
        'countersAvailable': nonnegative('rxBytes') && nonnegative('txBytes'),
      if (operation == 'media.snapshot' && response['allowed'] == true) ...{
        'sessionPresent': response['item'] is Map,
        if (response['item'] case final Map item)
          if (item['playing'] is bool) 'playing': item['playing'] as bool,
      },
      if (operation == 'system_status.snapshot')
        'availableMetrics': [
          for (final key in const [
            'cpuPercent',
            'ramAvailableBytes',
            'storageAvailableBytes',
            'uptimeMinutes',
            'temperatureCelsius',
          ])
            if (response[key] case final num value when value.isFinite) key,
        ],
      if (operation == 'sleepTimer.state' && nonnegative('remainingMs'))
        'active': (response['remainingMs'] as num) > 0,
    };
  }

  Map<String, Object> snapshot() => {
    for (var i = 0; i < PanelLayout.ids.length; i++)
      PanelLayout.ids[i]: _widget(PanelLayout.ids[i], i),
    'nowPlaying': _widget('nowPlaying', null),
  };

  Map<String, Object> _widget(String id, int? index) {
    final operations = _operations[id] ?? const <String>[];
    final layout = _layout;
    final weather = id == 'weather' ? _weather : null;
    final night = id == 'nightMode' ? _night : null;
    return {
      if (layout != null && index != null)
        'inLastLayout': layout & (1 << index) != 0,
      'hasRuntimeData':
          weather != null ||
          night != null ||
          operations.any(_latest.containsKey),
      if (weather != null)
        'state': {
          'source': weather.source.name,
          'hasData': weather.hasData,
          'stale': weather.stale,
          'failure': ?weather.failure?.name,
        },
      if (night != null)
        'state': {'active': night.active, 'panelFill': night.panelFill},
      for (final operation in operations)
        if (_latest[operation] case final latest?)
          operation: {'last': latest, 'lastError': ?_errors[operation]},
    };
  }

  void clear() {
    _latest.clear();
    _errors.clear();
    _layout = null;
    _night = null;
    _weather = null;
  }
}
