import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const colorMap = {
  'blue': Colors.blue,
  'green': Colors.green,
  'yellow': Colors.yellow,
  'red': Colors.red
};

void _resetDatabase() async {
  final collection = Firestore.instance.collection('votes');
  collection.getDocuments().then((query) => query.documents.forEach((doc) =>
      Firestore.instance
          .document('votes/${doc.documentID}')
          .setData({'votes': 0})));
}

void _prettifyWebApp([bool makePretty = true]) async => Firestore.instance
    .document('settings/web_app_settings')
    .updateData({'purdy': makePretty});

void _startCountdown() async =>
    Firestore.instance.document('settings/web_app_settings').updateData({
      'countdown': DateTime.now().add(
        const Duration(seconds: 30),
      )
    });

class Votes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<QuerySnapshot>(builder: (context, snapshot, _) {
      if (snapshot?.documents != null) {
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  children: snapshot.documents
                      .where((d) => colorMap.containsKey(d.documentID))
                      .map<Widget>((d) {
                    final color = d.documentID;
                    final votes = d['votes'] as num;
                    return Card(
                      color: colorMap[color],
                      child: Center(
                          child:
                              Text('$votes', style: TextStyle(fontSize: 34))),
                    );
                  }).toList(),
                ),
              ),
            ),
            ResetVotes(),
            PrettyWebApp(),
            StartCountdown(),
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

class PrettyWebApp extends StatefulWidget {
  @override
  _PrettyWebAppState createState() => _PrettyWebAppState();
}

class _PrettyWebAppState extends State<PrettyWebApp> {
  bool _pretty = false;
  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: _pretty ? Text('Uglify web app') : Text('Prettify web app'),
      onPressed: () {
        setState(() => _pretty = !_pretty);
        _prettifyWebApp(!_pretty);
      },
    );
  }
}

class StartCountdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: Text('Start Countdown'),
      onPressed: () => _startCountdown(),
    );
  }
}
