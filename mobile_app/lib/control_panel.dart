import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/bluetooth_intermediary_pages.dart';
import 'package:mobile_app/control_panel_coding.dart';
import 'package:mobile_app/votes.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/bluetooth_state.dart';

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
              return Controls();
            case BleAppState.searching:
              return ScanningPage();
          }
        }));
  }
}

class Controls extends StatefulWidget {
  @override
  _ControlsState createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
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
        bluetooth.sendMessage(colorCodeMap[_currentColor]);
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
                child: LightControl())));
  }

  @override
  void dispose() {
    Provider.of<Bluetooth>(context).disconnect();
    super.dispose();
  }
}
