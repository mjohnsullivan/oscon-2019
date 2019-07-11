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
        Provider.value(value: firebase),
        ChangeNotifierProvider<ValueNotifier<bool>>.value(
            value: firebase.pretty),
        ChangeNotifierProvider.value(
          value: firebase.blueNotifier,
        ),
        ChangeNotifierProvider.value(
          value: firebase.greenNotifier,
        ),
        ChangeNotifierProvider.value(
          value: firebase.redNotifier,
        ),
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
              child: isPretty.value ? PrettyVotingPage() : SimpleVotingPage(),
            ),
          ),
        ),
      ),
    );
  }
}
