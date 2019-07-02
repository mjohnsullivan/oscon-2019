import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/control_panel.dart';
import 'package:mobile_app/votes.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart' as awesome;

void main() {
  runApp(WearablesApp());
}

class WearablesApp extends StatefulWidget {
  @override
  _WearablesAppState createState() => _WearablesAppState();
}

class _WearablesAppState extends State<WearablesApp> {
  int _selectedIndex = 0;
  final _pages = [Votes(), BluetoothPage()];

  @override
  Widget build(BuildContext context) {
    return StreamProvider<QuerySnapshot>(
        builder: (context) =>
            Firestore.instance.collection('votes').snapshots(),
        child: MaterialApp(
            home: Scaffold(
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
        )));
  }
}
