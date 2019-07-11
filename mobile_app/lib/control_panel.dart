import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart' as blue;
import 'package:mobile_app/bluetooth_intermediary_pages.dart';
import 'package:mobile_app/support_widgets.dart';
import 'package:mobile_app/support_widgets_coding.dart';
import 'package:mobile_app/votes.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/bluetooth_state.dart';
import 'dart:convert';

class BluetoothPage extends StatelessWidget {
  BluetoothPage({this.usesBluetooth = true});
  final bool usesBluetooth;
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        builder: (_) => Bluetooth(usesBluetooth),
        child: Consumer<Bluetooth>(builder:
            (BuildContext context, Bluetooth bluetoothState, Widget child) {
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

class LightControl extends StatefulWidget {
  LightControl({this.useBluetooth = true});
  final useBluetooth;

  @override
  _LightControlState createState() => _LightControlState();
}

class _LightControlState extends State<LightControl> {
  final Map<String, int> colorCodeMap = {
    'blue': AsciiCodec().encode('b')[0],
    'green': AsciiCodec().encode('g')[0],
    'red': AsciiCodec().encode('r')[0],
    'yellow': AsciiCodec().encode('y')[0],
  };
  String _currentColor;

  void updateMostPopularColor(Bluetooth bluetooth, QuerySnapshot snapshot) {
    if (snapshot?.documents != null) {
      String mostPopularColor;
      // Find the highest scoring Color currently.
      snapshot.documents
          .where((d) => colorMap.containsKey(d.documentID))
          .fold<int>(-1, (int curValue, DocumentSnapshot d) {
        String color = d.documentID;
        var votes = d['votes'] as num;

        if (votes > curValue && votes > 0) {
          curValue = votes;
          mostPopularColor = color;
        }
        return curValue;
      });
      if (mostPopularColor != _currentColor) {
        _currentColor = mostPopularColor;
        bluetooth?.sendMessage(colorCodeMap[_currentColor]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var bluetooth = Provider.of<Bluetooth>(context);

    return Consumer<QuerySnapshot>(
        builder: (context, snapshot, constColumn) {
          updateMostPopularColor(bluetooth, snapshot);
          return constColumn;
        },
        child: SafeArea(
          child: Theme(
            data: ThemeData(
                textTheme: TextTheme(
                    body1: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ))),
            child: GridView.count(
              padding: const EdgeInsets.all(10),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: <Widget>[
                OnOffSwitch(),
                RainbowButton(),
                MarchButton(),
                SparkleButton(),
                ShimmerButton(),
                TwinkleButton(),
                FireButton(),
                FadingButton(),
                ColorFillButton(),
                BouncingBallButton(),
                MeteorButton(),
              ],
            ),
          ),
        ));
  }

  @override
  void dispose() {
    if (widget.useBluetooth) Provider.of<Bluetooth>(context).disconnect();
    super.dispose();
  }
}

class AvailableDevices extends StatelessWidget {
  AvailableDevices(this.availableBLEDevices);
  final Iterable<blue.ScanResult> availableBLEDevices;
  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      RefreshButton(),
    ]);
  }
}

class RefreshButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.refresh),
      onPressed: () =>
          Provider.of<Bluetooth>(context).setMode(BleAppState.searching),
    );
  }
}
