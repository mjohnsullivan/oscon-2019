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
      flutterBlue = null;
    } else {
      setState(
          () => _displayPage = Text('This phone does not support bluetooth.'));
    }
  }

  void scanForDevices() {
    var scanSubscription = flutterBlue.scan().listen((scanResult) {
      // do something with scan result
      // TODO(efortuna)
      device = scanResult.device;
      print('${device.name} found! rssi: ${scanResult.rssi}');
    });

    /// Stop scanning
    scanSubscription.cancel();
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
