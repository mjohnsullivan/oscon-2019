// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_app/db.dart';

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
        const VotingLabel('Haberdashery Color Voter!'),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(
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
  const VotingLabel(this.label);
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
