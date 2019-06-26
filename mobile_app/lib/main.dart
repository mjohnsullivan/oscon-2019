import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart' as awesome;
import 'package:flutter_blue/flutter_blue.dart';

final colorMap = {
  'blue': Colors.blue,
  'green': Colors.green,
  'yellow': Colors.yellow,
  'red': Colors.red
};

void main() {
  runApp(HighlightsApp());
}

void _resetDatabase() async {
  final collection = Firestore.instance.collection('votes');
  collection.getDocuments().then((query) => query.documents.forEach((doc) {
        if (doc.data.containsKey('votes')) {
          Firestore.instance
              .document('votes/${doc.documentID}')
              .setData({'votes': 0});
        }
      }));
}

class HighlightsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<QuerySnapshot>(
      builder: (context) => Firestore.instance.collection('votes').snapshots(),
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HighlightsPages(),
      ),
    );
  }
}

class HighlightsPages extends StatefulWidget {
  @override
  _HighlightsPagesState createState() => _HighlightsPagesState();
}

class _HighlightsPagesState extends State<HighlightsPages> {
  int _selectedIndex = 0;
  final _pages = [Votes(), LightsControl()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              title: Text('Votes'),
              icon: Icon(awesome.FontAwesomeIcons.voteYea)),
          BottomNavigationBarItem(
              title: Text('Lights'),
              icon: Icon(MaterialCommunityIcons.lightbulb_on_outline))
        ],
        onTap: (int index) => setState(() => _selectedIndex = index),
        currentIndex: _selectedIndex,
      ),
    );
  }
}

class Votes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<QuerySnapshot>(builder: (context, snapshot, _) {
      if (snapshot?.documents != null) {
        return Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                children: snapshot.documents.map<Widget>((d) {
                  final color = d.documentID;
                  final votes = d['votes'] as num;
                  return Card(
                    color: colorMap[color],
                    child: Center(
                        child: Text('$votes', style: TextStyle(fontSize: 34))),
                  );
                }).toList(),
              ),
            ),
            ResetVotes(),
          ],
        );
      } else {
        return Text('No data');
      }
    });
  }
}

class ResetVotes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: Text('Reset Database'),
      onPressed: () => _resetDatabase(),
    );
  }
}

class LightsControl extends StatefulWidget {
  @override
  _LightsControlState createState() => _LightsControlState();
}

class _LightsControlState extends State<LightsControl> {
  final int offSignal = 0x4e;
  bool _on = false;
  BluetoothDevice device;
  FlutterBlue flutterBlue;
  @override
  void initState() {
    super.initState();
    flutterBlue = FlutterBlue.instance;
  }

  void scanForDevices() {
    /// Start scanning
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

  writeToLights(List<int> instructions) async {
    //TODO.
    //device.writeCharacteristic(instructions, instructions,
    //    type: CharacteristicWriteType.withResponse);
  }
}
