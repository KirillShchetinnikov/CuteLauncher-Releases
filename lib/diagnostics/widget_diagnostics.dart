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
  static final _batteryAddress = RegExp(
    r'(?<![a-f0-9])(?:[a-f0-9]{2}[:-]){5}[a-f0-9]{2}(?![a-f0-9])',
    caseSensitive: false,
  );
  static const _batteryResults = {
    'inputDevice',
    'ble',
    'noInputRemote',
    'selectedDeviceUnavailable',
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
  Map<String, Object>? _batteryUnavailable;
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
            (response['batteryRead'] == 'screenOff' &&
                _latest.containsKey(operation)))) {
      return;
    }
    final values = _project(operation, response);
    final batteryRead = values['batteryRead'];
    final batteryError = _batteryErrors[batteryRead];
    final observed = {
      ...event,
      if (values.isNotEmpty) 'result': values,
      if (batteryError != null) ...{
        'status': batteryError,
        'code': batteryRead!,
      },
    };
    _latest[operation] = observed;
    if (operation == 'remote_battery.snapshot' &&
        batteryRead != null &&
        batteryRead != 'screenOff' &&
        !values.containsKey('percent')) {
      _batteryUnavailable = observed;
    }
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
    if (operation.startsWith('android.get') &&
        operation.endsWith('DataUsage')) {
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
    return {
      for (final key in flags)
        if (response[key] is bool) key: response[key] as bool,
      if (operation == 'remote_battery.snapshot') ...{
        if (_batteryResults.contains(outcome)) 'batteryRead': outcome as String,
        ..._projectBatteryInputs(response),
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

  static String _batteryName(String name) => String.fromCharCodes(
    name.replaceAll(_batteryAddress, '[mac]').trim().runes.take(96),
  );

  static Map<String, Object> _projectBatteryInputs(Map response) {
    final mode = response['selectionMode'];
    final lookup = response['bluetoothLookup'];
    return {
      if (mode == 'auto' || mode == 'manual') 'selectionMode': mode as String,
      if (lookup == 'ready' || _batteryResults.contains(lookup))
        'bluetoothLookup': lookup as String,
      for (final key in [
        'inputCandidates',
        'inputDeviceCount',
        'bondedBleCount',
        'selectedInput',
        'activeInput',
      ])
        if (response[key] case final int value when value >= 0) key: value,
      for (final key in ['selectedName', 'activeName'])
        if (response[key] case final String name when name.isNotEmpty)
          key: _batteryName(name),
      if (response['batteryInputs'] case final List rows)
        'inputs': [
          for (final row in rows.take(24).whereType<Map>())
            if (row['index'] case final int index when index >= 0)
              {
                'index': index,
                if (row['name'] case final String name)
                  'name': _batteryName(name),
                if (const {'remote', 'keyboard', 'other'}.contains(row['kind']))
                  'kind': row['kind'] as String,
                for (final key in ['considered', 'virtual', 'external'])
                  if (row[key] case final bool value) key: value,
                for (final key in [
                  'sources',
                  'keyboardType',
                  'controllerNumber',
                  'bondedMatches',
                  'bleMatches',
                ])
                  if (row[key] case final int value) key: value,
                if (row['inputPercent'] case final int percent
                    when percent >= 0 && percent <= 100)
                  'inputPercent': percent,
                if (const {
                  'unsupported',
                  'skipped',
                  'unavailable',
                  'inputDevice',
                  'platformError',
                }.contains(row['inputRead']))
                  'inputRead': row['inputRead'] as String,
              },
        ],
      if (response['batteryBondedNames'] case final List names)
        'bondedBleNames': names
            .take(24)
            .whereType<String>()
            .map(_batteryName)
            .toList(),
      if (response['bleAttempts'] case final List attempts)
        'bleAttempts': [
          for (final row in attempts.take(3).whereType<Map>())
            if (row
                case {'input': final int index, 'result': final String result}
                when index >= 0 && _batteryResults.contains(result))
              {'input': index, 'result': result},
        ],
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
          operation: {
            'last': latest,
            'lastError': ?_errors[operation],
            if (operation == 'remote_battery.snapshot')
              'lastUnavailable': ?_batteryUnavailable,
          },
    };
  }

  void clear() {
    _latest.clear();
    _errors.clear();
    _batteryUnavailable = null;
    _layout = null;
    _night = null;
    _weather = null;
  }
}
