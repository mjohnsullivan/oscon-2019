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
  fontSize: 32,
);

const labelTextStyle = TextStyle(
  fontFamily: 'RobotoMono',
  color: Colors.black,
  fontSize: 16,
);

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
            _documentAdded(change);
            break;
        }
      });
    });

    // Initialize sink listeners
    _votesSink.stream.listen((color) => _voteCast(color));
  }

  @override
  void dispose() {
    app?.delete();
    _messagesController?.close();
    super.dispose();
  }

  void _documentAdded(fs.DocumentChange change) {
    final data = change.doc.data();
    final color = change.doc.id;
    final votes = data['votes'] as num;
    _messagesController.add('$votes for $color');
  }

  void _voteCast(String color) {
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
        child: widget.child,
      );
}

class VotesConsumer extends InheritedWidget {
  VotesConsumer({
    @required this.messages,
    @required this.castVote,
    @required Widget child,
  })  : assert(messages != null),
        assert(castVote != null),
        assert(child != null),
        super(child: child);

  final Stream<String> messages;
  final Sink<String> castVote;

  static VotesConsumer of(BuildContext context) =>
      (context.inheritFromWidgetOfExactType(VotesConsumer) as VotesConsumer);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => oldWidget != this;
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSCON Voter!',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyWebPage(),
    );
  }
}

class MyWebPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VotesProvider(
      child: Scaffold(
        body: DefaultTextStyle(
          style: defaultTextStyle,
          child: Center(
            child: VotingPanel(),
          ),
        ),
      ),
    );
  }
}

class VotingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        VotingTile(),
        DatabaseMessage(),
      ],
    );
  }
}

class DatabaseMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final messages = VotesConsumer.of(context).messages;
    return StreamBuilder<String>(
        stream: messages,
        initialData: 'Got no messages',
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.data);
          }
        });
  }
}

class VotingTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        VotingLabel('Vote for colour'),
        VotingButton('blue'),
        VotingButton('red'),
        VotingButton('green'),
        VotingButton('yellow'),
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
    final castVote = VotesConsumer.of(context).castVote;
    return FlatButton(
        child: Text(
          label,
          style: buttonTextStyle,
        ),
        onPressed: () => castVote.add(label));
  }
}
