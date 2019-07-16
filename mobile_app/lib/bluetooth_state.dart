import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';

enum BleAppState {
  searching,
  connected,
  invalid,
  failedToConnect,
}

class Bluetooth with ChangeNotifier {
  BleAppState _currentState;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final devices = Map<DeviceIdentifier, ScanResult>();
  final uartWriteCharacteristic = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  BluetoothCharacteristic _characteristic;
  BluetoothDevice _currentDevice;
  // A hack to allow us to develop without connecting to a bluetooth device
  // in case of equipment failure.
  bool usesBluetooth;

  Bluetooth(this.usesBluetooth) {
    if (usesBluetooth)
      _currentState = BleAppState.searching;
    else
      _currentState = BleAppState.connected;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    setMode(BleAppState.connected);
    /*try {
      _currentDevice = device;
      await device.connect(timeout: const Duration(seconds: 5));
      await _findCharacteristic(device);
      setMode(BleAppState.connected);
    } on TimeoutException {
      setMode(BleAppState.failedToConnect);
    }*/
  }

  Future disconnect() {
    return _currentDevice?.disconnect();
  }

  Stream<Map<DeviceIdentifier, ScanResult>> scanForDevices() async* {
    var done = Completer<Map<DeviceIdentifier, ScanResult>>();
    var device = FakeBluetoothDevice();
    devices[device.id] = ScanResult(device: device);
    if (await flutterBlue.isAvailable) {
      if (!await flutterBlue.isScanning.first) {
        //devices.clear();
        flutterBlue
            .scan(timeout: const Duration(seconds: 1) // need longer to connect?
                // UART service on the Adafruit Feather M0 Bluefruit...
                /*withServices: [
          new Guid('6E400001-B5A3-F393-­E0A9-­E50E24DCCA9E')
        ],*/
                )
            .listen((ScanResult scanResult) {
          devices[scanResult.device.id] = scanResult;
        }, onDone: () => done.complete(devices));
      }
    } else {
      setMode(BleAppState.invalid);
    }
    yield await done.future;
  }

  sendMessage(int instruction) async {
    if (usesBluetooth) {
      try {
        _characteristic?.write([instruction]);
      } on TimeoutException {
        // fail silently if we don't connect :-P
      }
    }
  }

  /// Find the UART Write characteristic to send messages between the app and the BLE devicd
  _findCharacteristic(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    // worst API ever.
    for (BluetoothService service in services) {
      _characteristic = service.characteristics.firstWhere(
          (BluetoothCharacteristic c) =>
              c.uuid.toString() == uartWriteCharacteristic,
          orElse: () => null);
      if (_characteristic != null) break;
    }
  }

  void setMode(BleAppState newState) {
    _currentState = newState;
    notifyListeners();
  }

  BleAppState get currentState => _currentState;
}

class FakeBluetoothDevice implements BluetoothDevice {
  @override
  Future<bool> get canSendWriteWithoutResponse => null;

  @override
  Future<void> connect({Duration timeout, bool autoConnect = true}) {
    return null;
  }

  @override
  Future disconnect() {
    return null;
  }

  @override
  Future<List<BluetoothService>> discoverServices() {
    return null;
  }

  @override
  DeviceIdentifier get id => DeviceIdentifier('E1:BB:93:22:68:B8');

  @override
  Stream<bool> get isDiscoveringServices => null;

  @override
  String get name => 'Adafruit Bluefruit LE';

  @override
  Stream<List<BluetoothService>> get services => null;

  @override
  Stream<BluetoothDeviceState> get state => null;

  @override
  BluetoothDeviceType get type => null;
}
