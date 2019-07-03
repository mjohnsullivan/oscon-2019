import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart' as blue;
import 'package:mobile_app/support_widgets.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/bluetooth_state.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:convert';

class BluetoothPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        builder: (_) => BluetoothState(),
        child: Consumer<BluetoothState>(builder: (BuildContext context,
            BluetoothState bluetoothState, Widget child) {
          switch (bluetoothState.currentState) {
            case BleAppState.invalid:
              return Text('This device does not support bluetooth.');
            case BleAppState.failedToConnect:
              return FailedToConnect();
            case BleAppState.connected:
              return LightControl();
            case BleAppState.searching:
              return ScanningPage();
          }
        }));
  }
}

/// Simple page stating that we are scanning for devices.
class ScanningPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Provider.of<BluetoothState>(context).scanForDevices(),
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return Scaffold(body: AvailableDevices(snapshot.data));
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
            onPressed: () => Provider.of<BluetoothState>(context)
                .setMode(BleAppState.searching))
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
  final int offSignal = 0x4e;
  final Map<String, int> colorCodeMap = {
    'blue': AsciiCodec().encode('b')[0],
    'green': AsciiCodec().encode('g')[0],
    'red': AsciiCodec().encode('r')[0],
    'yellow': AsciiCodec().encode('y')[0],
  };
  final int lightSpill = AsciiCodec().encode('l')[0];
  final int sparkle = AsciiCodec().encode('s')[0];
  final int rainbow = AsciiCodec().encode('o')[0];
  String _currentColor = 'blue';

  void updateMostPopularColor(
      BluetoothState bluetooth, QuerySnapshot snapshot) {
    if (snapshot?.documents != null) {
      String mostPopularColor;
      // Find the highest scoring Color currently.
      snapshot.documents.fold<int>(-1, (int curValue, DocumentSnapshot d) {
        String color = d.documentID;
        var votes = d['votes'] as num;
        if (votes > curValue) {
          curValue = votes;
          mostPopularColor = color;
        }
      });
      if (mostPopularColor != _currentColor) {
        _currentColor = mostPopularColor;
        bluetooth.sendMessage(colorCodeMap[_currentColor]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var sparkleStar = SpinKitPulse(
      itemBuilder: (_, __) => Icon(Icons.star),
    );
    var bluetooth = Provider.of<BluetoothState>(context);
    var column = Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Turn on the lights!'),
            Padding(
              padding: const EdgeInsets.only(top: 50, bottom: 50),
              child: Switch(
                value: _on,
                onChanged: (bool value) {
                  setState(() => _on = value);
                  // send the on/off signal: off: 0x4e
                  if (_on) {
                    bluetooth.sendMessage(offSignal);
                  } else {
                    bluetooth.sendMessage(lightSpill);
                  }
                },
                activeColor: Colors.orange,
              ),
            ),
          ],
        ),
        RaisedButton(
          color: Colors.yellow,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              sparkleStar,
              Text('Make it sparkle'),
              sparkleStar,
            ],
          ),
          onPressed: () => bluetooth.sendMessage(sparkle),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: RainbowButton(
            text: 'Rainbow',
            onPressed: () => bluetooth.sendMessage(rainbow),
          ),
        )
      ],
    );
    return Consumer<QuerySnapshot>(builder: (context, snapshot, constColumn) {
      updateMostPopularColor(bluetooth, snapshot);
      return constColumn;
    });
  }
}

class AvailableDevices extends StatelessWidget {
  AvailableDevices(this.availableBLEDevices);
  final Map<blue.DeviceIdentifier, blue.ScanResult> availableBLEDevices;
  @override
  Widget build(BuildContext context) {
    return ListView(
        children: availableBLEDevices.values
            .where((result) => result.device.name.length > 0)
            .map<Widget>((result) => ListTile(
                  title: Text(result.device.name),
                  subtitle: Text(result.device.id.toString()),
                  onTap: () => Provider.of<BluetoothState>(context)
                      .connectToDevice(result.device),
                ))
            .toList()
              ..add(IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => Provider.of<BluetoothState>(context)
                    .setMode(BleAppState.searching),
              )));
  }
}
