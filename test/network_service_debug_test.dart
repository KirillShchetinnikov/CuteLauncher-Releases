// Benchmark and network diagnostic tests intentionally print their measurements.
// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:mockito/mockito.dart';

class MockFlauncherChannel extends Mock implements FLauncherChannel {
  @override
  StreamSubscription<dynamic>? addNetworkChangedListener(Function(Map<String, dynamic>) listener) => null;
  
  @override
  Future<Map<String, dynamic>> getActiveNetworkInformation() async {
    return {
      "networkType": 1,
      "internetAccess": true,
      "wirelessSignalLevel": 2,
    };
  }

  @override
  Future<bool> checkUsageStatsPermission() async {
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('NetworkService initial load', () async {
    final mockChannel = MockFlauncherChannel();
    final service = NetworkService(mockChannel);
    
    // allow async microtasks to run
    await Future.delayed(Duration(milliseconds: 100));
    
    print("Network Type: ${service.networkType}");
    print("Has Internet: ${service.hasInternetAccess}");
    print("Signal: ${service.wirelessNetworkSignalLevel}");
    
    expect(service.networkType, NetworkType.Wifi);
  });
}