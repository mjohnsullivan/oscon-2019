import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart' as blue;
import 'package:mobile_app/support_widgets.dart';
import 'package:mobile_app/support_widgets_coding.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/bluetooth_state.dart';

class LightControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
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
    );
  }
}

class AvailableDevices extends StatelessWidget {
  AvailableDevices(this.availableBLEDevices);
  final Iterable<blue.ScanResult> availableBLEDevices;
  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      for (var result in availableBLEDevices)
        ListTile(
          title: Text(result.device.name),
          subtitle: Text(result.device.id.toString()),
          onTap: () =>
              Provider.of<Bluetooth>(context).connectToDevice(result.device),
        ),
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
