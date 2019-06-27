import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:mobile_app/bluetooth_state.dart' as state;
import 'package:progress_indicators/progress_indicators.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class BluetoothPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      builder: (_) => state.BluetoothState(),
      child: LightsControl(),
    );
  }
}

class LightsControl extends StatelessWidget {
  final int offSignal = 0x4e;
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  void scanForDevices(BuildContext context) async {
    if (await flutterBlue.isAvailable) {
      var devices = Map<DeviceIdentifier, ScanResult>();
      flutterBlue
          .scan(
              timeout:
                  const Duration(seconds: 2) // need to be longer to connect? 5?
              // UART service on the Adafruit Feather M0 Bluefruit...
              /*withServices: [
          new Guid('6E400001-B5A3-F393-­E0A9-­E50E24DCCA9E')
        ],*/
              )
          .listen((ScanResult scanResult) {
        devices[scanResult.device.id] = scanResult;
      }, onDone: () {
        Provider.of<state.BluetoothState>(context).setMode(
            state.BleAppState.deviceList, AvailableDevicesPage(devices));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
        /*layoutBuilder: (Widget currentChild, List<Widget> previousChildren) {
            // TODO(efortuna); add a slide in effect.
            return SlideTransition();
          },*/
        duration: Duration(milliseconds: 500),
        child: Consumer<state.BluetoothState>(builder: (BuildContext context,
            state.BluetoothState bluetoothState, Widget child) {
          if (bluetoothState.currentState == state.BleAppState.searching) {
            scanForDevices(context);
          }
          return bluetoothState.page;
        }));
  }

  writeToLights(List<int> instructions) async {
    //TODO.
    //device.writeCharacteristic(instructions, instructions,
    //    type: CharacteristicWriteType.withResponse);
  }
}

/// Simple page stating that we are scanning for devices.
class ScanningPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: SpinKitWave(
              color: Colors.blue, type: SpinKitWaveType.end, size: 30),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Scanning for bluetooth devices'),
            FadingText('...'),
          ],
        ),
      ],
    );
  }
}

class LightControl extends StatefulWidget {
  LightControl(this.device);
  final BluetoothDevice device;
  @override
  _LightControlState createState() => _LightControlState();
}

class _LightControlState extends State<LightControl> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppBar(
            leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            widget.device.disconnect();
            Provider.of<state.BluetoothState>(context)
                .setMode(state.BleAppState.searching);
          },
        )),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Turn on the lights!'),
            Switch(
              value: _on,
              onChanged: (bool value) {
                setState(() => _on = value);
                // send the on/off signal: off: 0x4e
              },
              activeColor: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }
}

class AvailableDevicesPage extends StatelessWidget {
  AvailableDevicesPage(this.availableBLEDevices);
  final Map<DeviceIdentifier, ScanResult> availableBLEDevices;
  @override
  Widget build(BuildContext context) {
    return ListView(
        children: availableBLEDevices.values
            .where((result) => result.device.name.length > 0)
            .map<Widget>((result) => ListTile(
                  title: Text(result.device.name),
                  subtitle: Text(result.device.id.toString()),
                  onTap: () async {
                    // TODO: this seems not re-discoverable once I connect. Do I need to disconnect/ cancel or something?
                    await result.device
                        .connect(timeout: const Duration(seconds: 4));
                    Provider.of<state.BluetoothState>(context).setMode(
                        state.BleAppState.connected,
                        LightControl(result.device));
                  },
                ))
            .toList()
              ..add(IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => Provider.of<state.BluetoothState>(context)
                    .setMode(state.BleAppState.searching),
              )));
  }
}
