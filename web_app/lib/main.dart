// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:firebase/firestore.dart' as fs;
import 'package:provider/provider.dart';

const defaultTextStyle = TextStyle(
  fontFamily: 'RobotoMono',
  color: Colors.black,
  fontSize: 24,
);

const buttonTextStyle = TextStyle(
  fontFamily: 'RobotoMono',
  color: Colors.black,
  fontSize: 24,
);

const labelTextStyle = TextStyle(
  fontFamily: 'Raleway',
  fontWeight: FontWeight.w900,
  color: Colors.black,
  fontSize: 32,
);

final colorMap = {
  'blue': Colors.blue,
  'green': Colors.green,
  'yellow': Colors.yellow,
  'red': Colors.red
};

/// Manages the Firestore data streams
class FirebaseInstance {
  FirebaseInstance() {
    _initializeFirebase();
  }
  fb.App app;
  fs.Firestore store;

  final pretty = ValueNotifier<bool>(false);
  final blueNotifier = ValueNotifier<int>(0);
  final greenNotifier = ValueNotifier<int>(0);
  final redNotifier = ValueNotifier<int>(0);
  final yellowNotifier = ValueNotifier<int>(0);

  void _initializeFirebase() {
    // Hack to ensure two apps are not created at the same time
    final appName = DateTime.now().toString();
    app = fb.initializeApp(
      name: appName,
      apiKey: 'AIzaSyAG7wN-Zv4VgD6aSUP7N9xthvkZ6QKg3Rs',
      authDomain: 'oscon-voter.firebaseapp.com',
      databaseURL: 'https://oscon-voter.firebaseio.com',
      projectId: 'oscon-voter',
      storageBucket: '',
      messagingSenderId: '150136682850',
      // appId: '1:150136682850:web:d14f3a68ab2b79f0',
    );

    store = fb.firestore(app);

    // Set up settings listener
    final settingsCollection = store.collection('settings');
    settingsCollection.onSnapshot.listen((querySnapshot) {
      querySnapshot.docChanges().forEach((change) {
        if (['added', 'modified'].contains(change.type))
          _settingsChanged(change);
      });
    });

    // Set up colour changes
    final ref = store.collection('votes');
    ref.onSnapshot.listen((querySnapshot) {
      querySnapshot.docChanges().forEach((change) {
        if (['added', 'modified'].contains(change.type)) _colourVote(change);
      });
    });
  }

  _settingsChanged(fs.DocumentChange change) {
    if (change.doc.id == 'web_app_settings') {
      print('Purdy is ${change.doc.data()['purdy']}');
      pretty.value = change.doc.data()['purdy'];
    }
  }

  void _colourVote(fs.DocumentChange change) {
    final data = change.doc.data();
    final color = change.doc.id;
    final votes = data['votes'] as num;
    colourNotifier(color).value = votes;
  }

  ValueNotifier<int> colourNotifier(String colour) {
    switch (colour) {
      case 'yellow':
        return yellowNotifier;
      case 'green':
        return greenNotifier;
      case 'blue':
        return blueNotifier;
      default:
        return redNotifier;
    }
  }

  void castVote(String colour) {
    final ref = store.doc('votes/$colour');
    ref.get().then((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final count = data['votes'] as num;
        ref.set({'votes': count + 1});
      } else {
        print('Color doesnt exist');
      }
    });
  }
}

void main() => runApp(
      Provider.value(
        value: FirebaseInstance(),
        child: VotingApp(),
      ),
    );

class VotingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firebase = Provider.of<FirebaseInstance>(context);
    return MaterialApp(
      title: 'OSCON Voter!',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: DefaultTextStyle(
          style: defaultTextStyle,
          child: ChangeNotifierProvider<ValueNotifier<bool>>.value(
            value: firebase.pretty,
            child: VotingPageSelector(),
          ),
        ),
      ),
    );
  }
}

/// Main page for the voting app
class VotingPageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ValueNotifier<bool>>(
      builder: (context, snapshot, _) =>
          snapshot.value ? PurdyVotingPage() : SimpleVotingPage(),
    );
  }
}

class PurdyVotingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('I\'m so purdy!!!!!'),
    );
  }
}

class SimpleVotingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            VotingTile(),
          ],
        ),
      ),
    );
  }
}

class VotingTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        VotingLabel('Haberdashery Color Voter!'),
        SizedBox(height: 10),
        Container(
          constraints: BoxConstraints(
            maxHeight: 600,
            maxWidth: 600,
          ),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            children: [
              VotingButton('blue'),
              VotingButton('red'),
              VotingButton('green'),
              VotingButton('yellow'),
            ],
          ),
        ),
      ],
    );
  }
}

class VotingLabel extends StatelessWidget {
  VotingLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(label, style: labelTextStyle);
}

class VotingButton extends StatelessWidget {
  VotingButton(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final firebase = Provider.of<FirebaseInstance>(context);
    return ChangeNotifierProvider.value(
      value: firebase.colourNotifier(label),
      child: Consumer<ValueNotifier<int>>(builder: (context, notifier, _) {
        return FlatButton(
          color: colorMap[label],
          child: Text('${notifier.value}', style: buttonTextStyle),
          onPressed: () => firebase.castVote(label),
        );
      }),
    );
  }
}
