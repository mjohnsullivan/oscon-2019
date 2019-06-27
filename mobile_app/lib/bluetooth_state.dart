import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/control_panel.dart';

enum BleAppState {
  searching,
  deviceList,
  connected,
  invalid,
}

class BluetoothState with ChangeNotifier {
  BleAppState _currentState = BleAppState.searching;
  Widget page = ScanningPage();

  /// Operates as a state-machine based on whether we have found and connected to a BLE device.
  /// [customNewPage] is specifiable for pages that require configuration specific input to instantiate.
  void setMode(BleAppState newState, [Widget customNewPage]) {
    _currentState = newState;
    switch (newState) {
      case BleAppState.invalid:
        page = Text('This device does not support bluetooth.');
        break;
      case BleAppState.deviceList:
        page = customNewPage;
        break;
      case BleAppState.connected:
        page = customNewPage;
        break;
      case BleAppState.searching:
        page = ScanningPage();
    }
    notifyListeners();
  }

  BleAppState get currentState => _currentState;
}
