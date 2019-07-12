// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:web_app/db.dart';
import 'package:web_app/pretty.dart';
import 'package:web_app/simple.dart';

void main() {
  final firebase = FirebaseInstance();
  runApp(
    MultiProvider(
      providers: [
        // pretty/ugly ui
        ChangeNotifierProvider<ValueNotifier<bool>>.value(
            value: firebase.pretty),
        // active/inactive voting
        ChangeNotifierProvider.value(
          value: firebase.activeNotifier,
        ),
        // Countdown stream
        ChangeNotifierProvider.value(
          value: firebase.countdownNotifier,
        ),
        // blue votes
        ChangeNotifierProvider.value(
          value: firebase.blueNotifier,
        ),
        // green votes
        ChangeNotifierProvider.value(
          value: firebase.greenNotifier,
        ),
        // red votes
        ChangeNotifierProvider.value(
          value: firebase.redNotifier,
        ),
        // yellow votes
        ChangeNotifierProvider.value(
          value: firebase.yellowNotifier,
        ),
      ],
      child: VotingApp(),
    ),
  );
}

class VotingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isPretty = Provider.of<ValueNotifier<bool>>(context);
    return MaterialApp(
      title: 'Haberdashery voting app',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: 800,
              ),
              child: InactiveOverlay(
                child: isPretty.value ? PrettyVotingPage() : SimpleVotingPage(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InactiveOverlay extends StatelessWidget {
  InactiveOverlay({this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveNotifier>(builder: (context, notifier, _) {
      return notifier.value
          ? child
          : Stack(
              children: [
                child,
                Container(color: Colors.black54),
                Center(
                  child: Text(
                    'Voting Inactive',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                    ),
                  ),
                ),
              ],
            );
    });
  }
}
