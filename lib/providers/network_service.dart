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
import 'dart:async';
import 'dart:developer';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/material.dart';

enum NetworkType
{
  Cellular,
  Wifi,
  Vpn,
  Wired,
  Unknown
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
  bool                _foreground = true;
  /// Initial network, usage permission and (when allowed) traffic snapshot.
  late final Future<void> initialLoad;


  NetworkService(this._channel) :
        _hasInternetAccess = false,
        _cellularNetworkType = CellularNetworkType.Unknown,
        _networkType = NetworkType.Unknown,
        _wirelessNetworkSignalLevel = 0,
        _dailyDataUsage = -1,
        _hasUsageStatsPermission = false,
        _vpnActive = false
  {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _networkSubscription = _channel.addNetworkChangedListener(_onNetworkChanged);

    final networkLoad = _channel
        .getActiveNetworkInformation()
        .then((map) {
          if (!isDisposed && map.isNotEmpty) {
            _getNetworkInformation(map.cast<String, dynamic>());
            notifyListeners();
          }
        }).catchError((e) {
          log("Error getting active network info: $e");
        });

    initialLoad = Future.wait([networkLoad, _checkPermissionAndStartPolling()]);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      refreshPermissionAndUsage();
    } else {
      ++_callCount;
      ++_usageCallCount;
      _usageTimer?.cancel();
      _usageTimer = null;
    }
  }

  Future<void> _checkPermissionAndStartPolling() async {
    if (isDisposed || !_foreground) return;
    final localCallCount = ++_callCount;
    bool allowed;
    try {
      allowed = await _channel.checkUsageStatsPermission();
    } catch (e) {
      log("Error checking usage permission: $e");
      return;
    }
    if (isDisposed || !_foreground || localCallCount != _callCount) return;

    _hasUsageStatsPermission = allowed;
    if (_hasUsageStatsPermission) {
      await _fetchUsage();
      if (isDisposed || !_foreground || localCallCount != _callCount) return;
      if (_usageTimer == null || !_usageTimer!.isActive) {
        _usageTimer = Timer.periodic(const Duration(minutes: 5), (_) => _fetchUsage());
      }
    } else {
      _usageTimer?.cancel();
      _usageTimer = null;
    }
    notifyListeners();
  }

  Future<void> requestPermission() async {
    await _channel.requestUsageStatsPermission();
  }

  // Call this when app resumes
  Future<void> refreshPermissionAndUsage() => _checkPermissionAndStartPolling();

  Future<Map<String, dynamic>> getSummary() => _channel.getActiveNetworkInformation();

  Future<void> openWifiSettings() async {
    await _channel.openWifiSettings();
  }

  Future<void> openVpnSettings() async {
    await _channel.openVpnSettings();
  }

  Future<void> _fetchUsage() async {
    if (isDisposed || !_foreground) return;
    final localCallCount = ++_usageCallCount;
    int usage = -1;
    try {
      usage = await _channel.getDailyDataUsage();
    } catch (e) {
      log("Error fetching usage: $e");
    }
    if (isDisposed || !_foreground || localCallCount != _usageCallCount) return;

    _dailyDataUsage = usage;
    notifyListeners();
  }

  Future<int> getDataUsageForPeriod(String period) async {
    switch (period) {
      case 'daily':
        return await _channel.getDailyDataUsage();
      case 'weekly':
        return await _channel.getWeeklyDataUsage();
      case 'monthly':
        return await _channel.getMonthlyDataUsage();
      default:
        return await _channel.getDailyDataUsage();
    }
  }

  @override
  void dispose() {
    ++_callCount;
    ++_usageCallCount;
    _networkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _usageTimer?.cancel();
    super.dispose();
  }

  bool                  get   hasInternetAccess             => _hasInternetAccess;
  CellularNetworkType   get   cellularNetworkType           => _cellularNetworkType;
  NetworkType           get   networkType                   => _networkType;
  int                   get   wirelessNetworkSignalLevel    => _wirelessNetworkSignalLevel;
  int                 get   dailyDataUsage                => _dailyDataUsage;
  bool                get   hasUsageStatsPermission       => _hasUsageStatsPermission;
  bool                get   vpnActive                     => _vpnActive;

  CellularNetworkType _getCellularNetworkType(int index)
  {
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
      _networkType = NetworkType.values[networkTypeInt];
      _vpnActive = map["vpnActive"] as bool? ?? false;

      if (_networkType == NetworkType.Cellular || _networkType == NetworkType.Wifi) {
        _wirelessNetworkSignalLevel = map["wirelessSignalLevel"] as int;
      }
      log("NetworkService: parsed type $_networkType, signal $_wirelessNetworkSignalLevel, vpn $_vpnActive");
    } catch (e) {
      log("NetworkService error parsing: $e");
    }
  }

  void _onNetworkChanged(Map<String, dynamic> event)
  {
    if (isDisposed) return;
    switch (event["name"]) {
      case "NETWORK_AVAILABLE":
        Map<dynamic, dynamic> map = event["arguments"];
        _getNetworkInformation(map.cast<String, dynamic>());
        break;
      case "NETWORK_UNAVAILABLE":
        _hasInternetAccess = false;
        _networkType = NetworkType.Unknown;
        _vpnActive = false;
        break;
      case "CAPABILITIES_CHANGED":
        Map<dynamic, dynamic> map = event["arguments"];
        _getNetworkInformation(map.cast<String, dynamic>());
        break;
      case "CELLULAR_STATE_CHANGED":
        _cellularNetworkType = _getCellularNetworkType(event["arguments"]);
        notifyListeners();
        break;
    }

    notifyListeners();
  }
}
