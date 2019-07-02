// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_web/material.dart';
import 'package:firebase/firebase.dart';
import 'package:firebase/firestore.dart' as fs;

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
  fontFamily: 'RobotoMono',
  color: Colors.black,
  fontSize: 16,
);

final colorMap = {
  'blue': Colors.blue,
  'green': Colors.green,
  'yellow': Colors.yellow,
  'red': Colors.red
};

/// Stateful widget to manage voting state
class VotesProvider extends StatefulWidget {
  VotesProvider({this.child});
  final Widget child;

  @override
  _VotesProviderState createState() => _VotesProviderState();
}

class _VotesProviderState extends State<VotesProvider> {
  App app;
  fs.Firestore store;
  final _messagesController = StreamController<String>();
  final _votesSink = StreamController<String>();
  final _yellowVotesController = StreamController<int>();
  final _blueVotesController = StreamController<int>();
  final _redVotesController = StreamController<int>();
  final _greenVotesController = StreamController<int>();

  @override
  void initState() {
    super.initState();
    // Hack to ensure two apps are not created at the same time
    final appName = DateTime.now().toString();
    app = initializeApp(
      name: appName,
      apiKey: "AIzaSyAG7wN-Zv4VgD6aSUP7N9xthvkZ6QKg3Rs",
      authDomain: "oscon-voter.firebaseapp.com",
      databaseURL: "https://oscon-voter.firebaseio.com",
      projectId: "oscon-voter",
      storageBucket: "",
      messagingSenderId: "150136682850",
      // appId: "1:150136682850:web:d14f3a68ab2b79f0",
    );

    store = firestore(app);
    final ref = store.collection('votes');
    ref.onSnapshot.listen((querySnapshot) {
      querySnapshot.docChanges().forEach((change) {
        switch (change.type) {
          case 'added':
          case 'modified':
            _documentUpdated(change);
            break;
        }
      });
    });

    // Initialize sink listeners
    _votesSink.stream.listen((color) => _castVote(color));
  }

  @override
  void dispose() {
    app?.delete();
    _messagesController?.close();
    _votesSink?.close();
    _yellowVotesController?.close();
    _blueVotesController?.close();
    _greenVotesController?.close();
    _redVotesController?.close();
    super.dispose();
  }

  void _documentUpdated(fs.DocumentChange change) {
    final data = change.doc.data();
    final color = change.doc.id;
    if (colorMap.containsKey(color)) {
      final votes = data['votes'] as num;
      switch (color) {
        case 'yellow':
          _yellowVotesController.add(votes);
          break;
        case 'green':
          _greenVotesController.add(votes);
          break;
        case 'blue':
          _blueVotesController.add(votes);
          break;
        case 'red':
          _redVotesController.add(votes);
      }
      _messagesController.add('$votes for $color');
    }
  }

  void _castVote(String color) {
    final ref = store.doc('votes/$color');
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

  @override
  Widget build(BuildContext context) => VotesConsumer(
        messages: _messagesController.stream,
        castVote: _votesSink,
        yellowVotes: _yellowVotesController.stream,
        greenVotes: _greenVotesController.stream,
        blueVotes: _blueVotesController.stream,
        redVotes: _redVotesController.stream,
        child: widget.child,
      );
}

/// Inherited widget to make state available throughout the app
class VotesConsumer extends InheritedWidget {
  VotesConsumer({
    @required this.messages,
    @required this.castVote,
    @required this.yellowVotes,
    @required this.greenVotes,
    @required this.blueVotes,
    @required this.redVotes,
    @required Widget child,
  })  : assert(messages != null),
        assert(castVote != null),
        assert(yellowVotes != null),
        assert(child != null),
        super(child: child);

  final Stream<String> messages;
  final Sink<String> castVote;
  final Stream<int> yellowVotes;
  final Stream<int> greenVotes;
  final Stream<int> blueVotes;
  final Stream<int> redVotes;

  static VotesConsumer of(BuildContext context) =>
      (context.inheritFromWidgetOfExactType(VotesConsumer) as VotesConsumer);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => oldWidget != this;

  Stream<int> voteStreamFromColor(String color) {
    switch (color) {
      case 'yellow':
        return yellowVotes;
      case 'green':
        return greenVotes;
      case 'red':
        return redVotes;
    }
    return blueVotes;
  }
}

void main() => runApp(VotingApp());

class VotingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSCON Voter!',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VotingPage(),
    );
  }
}

/// Main page for the voting app
class VotingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VotesProvider(
      child: Scaffold(
        body: DefaultTextStyle(
          style: defaultTextStyle,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  VotingTile(),
                  DatabaseMessage(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DatabaseMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final messages = VotesConsumer.of(context).messages;
    return StreamBuilder<String>(
        stream: messages,
        initialData: 'No messages',
        builder: (context, snapshot) {
          if (snapshot.hasData) return Text(snapshot.data);
        });
  }
}

class VotingTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        VotingLabel('Vote for colour'),
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
    return StreamBuilder<int>(
        stream: VotesConsumer.of(context).voteStreamFromColor(label),
        initialData: 0,
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return FlatButton(
                color: colorMap[label],
                child: Text('${snapshot.data}', style: buttonTextStyle),
                onPressed: () => VotesConsumer.of(context).castVote.add(label));
          else
            return Center(child: CircularProgressIndicator());
        });
  }
}
