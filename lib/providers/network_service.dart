import '../diagnostics_store.dart';
// Historical constants and enum names are preserved for upstream and serialized data compatibility.
// ignore_for_file: constant_identifier_names

/*
 * FLauncher
 * Copyright (C) 2021  Oscar Rojas
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

import 'service_lifecycle.dart';
import 'foreground_work.dart';
import 'dart:async';
import 'dart:developer';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show mapEquals;

enum NetworkType
{
  Cellular,
  Wifi,
  Vpn,
  Wired,
  Unknown,
  Pending,
}

// https://developer.android.com/reference/android/telephony/TelephonyManager#NETWORK_TYPE_CDMA
enum CellularNetworkType
{
  Unknown,  // 0
  Gprs,     // 1
  Edge,     // 2
  Umts,     // 3
  Cdma,     // 4
  EvdoZero, // 5
  EvdoA,    // 6
  Unused_1, // 7
  Hsdpa,    // 8
  Hsupa,    // 9
  Hspa,     // 10
  Iden,     // 11
  EvdoB,    // 12
  Lte,      // 13
  Ehrpd,    // 14
  Hspap,    // 15
  Gsm,      // 16
  TdScdma,  // 17
  Iwlan,    // 18
  Unused_2, // 19
  Nr,       // 20
}

class NetworkService extends ChangeNotifier with ServiceLifecycle, WidgetsBindingObserver
{
  final FLauncherChannel  _channel;
  final ForegroundWork? work;
  final _trafficOwners = <Object, String>{};
  final _usageInFlight = <String, (int, Future<void>)>{};
  final _usageValues = <String, int>{};
  final _lastUsage = <String, DateTime>{};
  final _usageOwners = {for (final period in ['daily', 'weekly', 'monthly']) period: Object()};
  int _trafficRevision = 0;
  bool _usagePresentationInvalidated = false;
  int get trafficRevision => _trafficRevision;

  void _cancelPeriodWork() {
    for (final owner in _usageOwners.values) { work?.cancel(owner); }
  }
  bool _usageNeedsRefresh = false;
  final DateTime Function() now;
  bool get _pollUsage => !isDisposed && _foreground && _trafficOwners.isNotEmpty;

  bool                _hasInternetAccess;
  CellularNetworkType _cellularNetworkType;
  NetworkType         _networkType;
  int                 _wirelessNetworkSignalLevel;
  int                 _dailyDataUsage; // In bytes
  bool                _hasUsageStatsPermission;
  bool                _vpnActive;
  Timer?              _usageTimer;
  StreamSubscription<dynamic>? _networkSubscription;
  int                 _callCount = 0;
  int                 _usageCallCount = 0;
  int                 _networkRevision = 0;
  bool                _foreground = true;
  /// Network connectivity only; independent of usage permission and statistics.
  late final Future<void> initialNetworkLoad;
  /// Initial network and usage permission; traffic is loaded for visible owners.
  late final Future<void> initialLoad;


  NetworkService(this._channel, {this.work, DateTime Function()? now}) :
        now = now ?? DateTime.now,
        _hasInternetAccess = false,
        _cellularNetworkType = CellularNetworkType.Unknown,
        _networkType = NetworkType.Pending,
        _wirelessNetworkSignalLevel = 0,
        _dailyDataUsage = -1,
        _hasUsageStatsPermission = false,
        _vpnActive = false
  {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    final initialRevision = _networkRevision;
    _networkSubscription = _channel.addNetworkChangedListener(_onNetworkChanged);

    initialNetworkLoad = _readInitialNetwork(initialRevision);

    initialLoad = Future.wait([initialNetworkLoad, refreshPermissionAndUsage(force: false)]);
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _readInitialNetwork(int revision) async {
    Map<String, dynamic> data;
    try {
      data = await _channel.getActiveNetworkInformation();
    } catch (error) {
      log('Error getting active network info: $error');
      return;
    }
    if (isDisposed || revision != _networkRevision || data.isEmpty) return;
    final before = _networkState;
    _getNetworkInformation(data);
    if (before != _networkState) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      refreshPermissionAndUsage(force: false);
    } else {
      ++_callCount;
      ++_usageCallCount;
      _usagePresentationInvalidated = true;
      _cancelPeriodWork();
      _usageTimer?.cancel();
      _usageTimer = null;
      work?.cancel(this);
    }
  }

  Future<void> _checkPermissionAndStartPolling({bool force = false}) async {
    if (isDisposed || !_foreground) return;
    final localCallCount = ++_callCount;
    bool allowed;
    try {
      allowed = await _channel.checkUsageStatsPermission();
    } catch (e, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'networkService', e, diagnosticStack,
      );
      log("Error checking usage permission: $e");
      if (localCallCount == _callCount) _startUsageTimer();
      return;
    }
    if (isDisposed || !_foreground || localCallCount != _callCount) return;

    final before = (_hasUsageStatsPermission, _dailyDataUsage);
    final previousUsage = Map<String, int>.of(_usageValues);
    _hasUsageStatsPermission = allowed;
    if (_hasUsageStatsPermission && (force || _pollUsage)) {
      await _fetchUsage(force: force);
      for (final period in _trafficOwners.values.toSet()..remove('daily')) {
        if (isDisposed || !_foreground || localCallCount != _callCount) return;
        await _fetchUsage(period: period, force: force);
      }
      if (isDisposed || !_foreground || localCallCount != _callCount) return;
      if (_usageNeedsRefresh && _pollUsage) {
        _usageNeedsRefresh = false;
        unawaited(refreshPermissionAndUsage(force: false));
        return;
      }
      _startUsageTimer();
    } else if (!_hasUsageStatsPermission) {
      // Invalidate any traffic request started before permission was revoked.
      ++_usageCallCount;
      _dailyDataUsage = -1;
      _lastUsage.clear();
      _usageValues.clear();
      _cancelPeriodWork();
      _usageTimer?.cancel();
      _usageTimer = null;
    }
    if (before != (_hasUsageStatsPermission, _dailyDataUsage) ||
        !mapEquals(previousUsage, _usageValues) || _usagePresentationInvalidated) {
      _usagePresentationInvalidated = false;
      ++_trafficRevision;
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    await _channel.requestUsageStatsPermission();
  }

  void setTrafficVisible(Object owner, bool visible, {String period = 'daily'}) {
    if (isDisposed) return;
    final needed = _trafficOwners.isNotEmpty;
    if (visible) {
      _trafficOwners[owner] = period == 'weekly' || period == 'monthly' ? period : 'daily';
    } else {
      _trafficOwners.remove(owner);
    }
    if (needed == _trafficOwners.isNotEmpty) return;
    if (_trafficOwners.isEmpty) {
      ++_callCount;
      ++_usageCallCount;
      _cancelPeriodWork();
      _usageTimer?.cancel();
      _usageTimer = null;
      work?.cancel(this);
    } else if (_foreground) {
      unawaited(refreshPermissionAndUsage(force: false));
    }
  }

  Future<void> prepareTraffic(Object owner) {
    if (isDisposed) return Future.value();
    _trafficOwners[owner] = 'daily';
    return Future.wait([initialNetworkLoad, refreshPermissionAndUsage(force: false)]);
  }

  void _startUsageTimer() {
    if (_pollUsage && _usageTimer?.isActive != true) {
      _usageTimer = Timer(const Duration(minutes: 5), () {
        if (_pollUsage) unawaited(_scheduleUsage(force: true));
      });
    }
  }

  // User actions are immediate; automatic work shares Home's idle queue.
  Future<void> refreshPermissionAndUsage({bool force = true}) => force
      ? _checkPermissionAndStartPolling(force: true)
      : _scheduleUsage();

  Future<void> _scheduleUsage({bool force = false}) =>
      work?.schedule(this, () => _checkPermissionAndStartPolling(force: force)) ??
          _checkPermissionAndStartPolling(force: force);

  Future<Map<String, dynamic>> getSummary() => _channel.getActiveNetworkInformation();

  Future<void> openWifiSettings() async {
    await _channel.openWifiSettings();
  }

  Future<void> openVpnSettings() async {
    await _channel.openVpnSettings();
  }

  Future<void> _fetchUsage({String period = 'daily', bool force = false}) {
    final pending = _usageInFlight[period];
    if (pending != null) {
      if (pending.$1 == _usageCallCount) return pending.$2;
      // A resume joins old native I/O first, then retries without overlapping it.
      return pending.$2.then((_) => _fetchUsage(period: period, force: force));
    }
    final operation = _readUsage(period: period, force: force).whenComplete(() {
      _usageInFlight.remove(period);
    });
    _usageInFlight[period] = (_usageCallCount, operation);
    return operation;
  }

  bool _usageFresh(String period) {
    final last = _lastUsage[period];
    final age = last == null ? null : now().difference(last);
    return age != null && age >= Duration.zero && age < const Duration(seconds: 30);
  }

  Future<void> _readUsage({required String period, bool force = false}) async {
    if (isDisposed || !_foreground || !_hasUsageStatsPermission) return;
    if (!force && _usageFresh(period)) return;
    final localCallCount = _usageCallCount;
    int usage = -1;
    try {
      usage = await switch (period) {
        'weekly' => _channel.getWeeklyDataUsage(),
        'monthly' => _channel.getMonthlyDataUsage(),
        _ => _channel.getDailyDataUsage(),
      };
    } catch (e, diagnosticStack) {
      DiagnosticsStore.instance.recordException('networkService', e, diagnosticStack);
      log("Error fetching usage: $e");
    }
    if (isDisposed || !_foreground) return;
    if (localCallCount != _usageCallCount) {
      if (period == 'daily') _usageNeedsRefresh = true;
      return;
    }
    _usageValues[period] = usage;
    _lastUsage[period] = now();
    if (period == 'daily') {
      _usageNeedsRefresh = false;
      _dailyDataUsage = usage;
    }
  }

  Future<Map<String, dynamic>> getTrafficUsage(String period) async => _channel.getTrafficUsage(period);

  Future<int> getDataUsageForPeriod(String period, {bool force = false}) async {
    if (period != 'weekly' && period != 'monthly') period = 'daily';
    if (isDisposed || !_foreground || !_hasUsageStatsPermission) return -1;
    if (!force && _usageFresh(period)) return _usageValues[period] ?? -1;
    final generation = _usageCallCount;
    Future<void> read() => _fetchUsage(period: period, force: force);
    if (force || work == null) {
      await read();
    } else {
      await work!.schedule(_usageOwners[period]!, read);
    }
    if (isDisposed || !_foreground || !_hasUsageStatsPermission) return -1;
    if (generation != _usageCallCount) {
      // Join the old native call until it settles; never multiply in-flight work.
      if (_trafficOwners.isEmpty) return -1;
      return getDataUsageForPeriod(period, force: force);
    }
    return _usageValues[period] ?? -1;
  }

  @override
  void dispose() {
    work?.cancel(this);
    _cancelPeriodWork();
    ++_callCount;
    ++_usageCallCount;
    _networkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _usageTimer?.cancel();
    _trafficOwners.clear();
    super.dispose();
  }

  bool                  get   hasInternetAccess             => _hasInternetAccess;
  CellularNetworkType   get   cellularNetworkType           => _cellularNetworkType;
  NetworkType           get   networkType                   => _networkType;
  int                   get   wirelessNetworkSignalLevel    => _wirelessNetworkSignalLevel;
  int                 get   dailyDataUsage                => _dailyDataUsage;
  bool                get   hasUsageStatsPermission       => _hasUsageStatsPermission;
  bool                get   vpnActive                     => _vpnActive;

  // Value equality prevents duplicate Android callbacks from rebuilding consumers.
  (bool, CellularNetworkType, NetworkType, int, bool) get _networkState => (
    _hasInternetAccess, _cellularNetworkType, _networkType,
    _wirelessNetworkSignalLevel, _vpnActive,
  );

  CellularNetworkType _getCellularNetworkType(Object? index)
  {
    if (index is! int || index < 0 || index >= CellularNetworkType.values.length) {
      return CellularNetworkType.Unknown;
    }
    CellularNetworkType type = CellularNetworkType.values[index];
    if (type == CellularNetworkType.Unused_1 || type == CellularNetworkType.Unused_2) {
      type = CellularNetworkType.Unknown;
    }

    return type;
  }

  void _getNetworkInformation(Map<String, dynamic> map)
  {
    try {
      int networkTypeInt = map["networkType"] as int;
      _hasInternetAccess = map["internetAccess"] as bool;
      _networkType = networkTypeInt >= 0 && networkTypeInt <= NetworkType.Unknown.index
          ? NetworkType.values[networkTypeInt] : NetworkType.Unknown;
      _vpnActive = map["vpnActive"] as bool? ?? false;

      if (_networkType == NetworkType.Cellular || _networkType == NetworkType.Wifi) {
        _wirelessNetworkSignalLevel = map["wirelessSignalLevel"] as int;
      }
      DiagnosticsStore.instance.activePosterLoads?.network(transport: _networkType.name,
          internetAccess: _hasInternetAccess, vpnActive: _vpnActive);
      log("NetworkService: parsed type $_networkType, signal $_wirelessNetworkSignalLevel, vpn $_vpnActive");
    } catch (e, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'networkService', e, diagnosticStack,
      );
      log("NetworkService error parsing: $e");
    }
  }

  void _onNetworkChanged(Map<String, dynamic> event)
  {
    if (isDisposed) return;
    final before = _networkState;
    switch (event["name"]) {
      case "NETWORK_AVAILABLE":
        ++_networkRevision;
        Map<dynamic, dynamic> map = event["arguments"];
        _getNetworkInformation(map.cast<String, dynamic>());
        break;
      case "NETWORK_UNAVAILABLE":
        ++_networkRevision;
        _hasInternetAccess = false;
        _networkType = NetworkType.Unknown;
        _vpnActive = false;
        DiagnosticsStore.instance.activePosterLoads?.network(transport: _networkType.name,
            internetAccess: false, vpnActive: false);
        break;
      case "CAPABILITIES_CHANGED":
        ++_networkRevision;
        Map<dynamic, dynamic> map = event["arguments"];
        _getNetworkInformation(map.cast<String, dynamic>());
        break;
      case "CELLULAR_STATE_CHANGED":
        _cellularNetworkType = _getCellularNetworkType(event["arguments"]);
        break;
    }

    // A new route can have the same icon/signal, but VPN ownership may differ.
    if (before != _networkState || event["name"] == "NETWORK_AVAILABLE") notifyListeners();
  }
}
