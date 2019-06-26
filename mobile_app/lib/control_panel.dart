import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LightsControl extends StatefulWidget {
  @override
  _LightsControlState createState() => _LightsControlState();
}

class _LightsControlState extends State<LightsControl> {
  final int offSignal = 0x4e;
  BluetoothDevice device;
  FlutterBlue flutterBlue;
  Widget _displayPage;
  @override
  void initState() {
    super.initState();
    initBluetooth();
    _displayPage = ScanningStatus();
  }

  void initBluetooth() async {
    flutterBlue = FlutterBlue.instance;
    if (await flutterBlue.isAvailable) {
      scanForDevices();
    } else {
      setState(
          () => _displayPage = Text('This phone does not support bluetooth.'));
      flutterBlue = null;
    }
  }

  void scanForDevices() {
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
      setState(() => _displayPage = AvailableDevicesPage(devices, () {
            setState(() => _displayPage = ScanningStatus());
            scanForDevices();
          }));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
        /*layoutBuilder: (Widget currentChild, List<Widget> previousChildren) {
          // TODO(efortuna); add a slide in effect.
          return SlideTransition();
        },*/
        duration: Duration(milliseconds: 500),
        child: _displayPage);
  }

  writeToLights(List<int> instructions) async {
    //TODO.
    //device.writeCharacteristic(instructions, instructions,
    //    type: CharacteristicWriteType.withResponse);
  }
}

class ScanningStatus extends StatelessWidget {
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
  @override
  _LightControlState createState() => _LightControlState();
}

class _LightControlState extends State<LightControl> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class AvailableDevicesPage extends StatelessWidget {
  AvailableDevicesPage(this.availableBLEDevices, this.rescan);
  final Map<DeviceIdentifier, ScanResult> availableBLEDevices;
  final Function rescan;
  @override
  Widget build(BuildContext context) {
    return ListView(
        children: availableBLEDevices.values
            //.where((result) => result.device.name.length > 0)
            .map<Widget>((result) => ListTile(
                  title: Text(result.device.name),
                  subtitle: Text(result.device.id.toString()),
                ))
            .toList()
              ..add(IconButton(
                icon: Icon(Icons.refresh),
                onPressed: rescan,
              )));
  }
}
