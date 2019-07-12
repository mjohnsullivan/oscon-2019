import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mobile_app/bluetooth_state.dart';
import 'package:mobile_app/control_panel_coding.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:flutter_blue/flutter_blue.dart' as blue;
import 'package:provider/provider.dart';

/// Simple page stating that we are scanning for devices.
class ScanningPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Provider.of<Bluetooth>(context).scanForDevices(),
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return Scaffold(
                body: AvailableDevices(snapshot.data.values.where(
                    (blue.ScanResult result) =>
                        result.device.name.length > 0)));
          return Scaffold(
            body: Column(
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
            ),
          );
        });
  }
}

class FailedToConnect extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text('Unable to connect to the peripheral Bluetooth device.'),
        RaisedButton.icon(
          label: Text('Try again'),
          icon: Icon(Icons.refresh),
          onPressed: () => null,
        ),
        RaisedButton(
            child: Text('Look for another device.'),
            onPressed: () =>
                Provider.of<Bluetooth>(context).setMode(BleAppState.searching))
      ],
    );
  }
}
