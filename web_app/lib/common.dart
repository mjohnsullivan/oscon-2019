import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:web_app/db.dart';

class CountdownClock extends StatelessWidget {
  CountdownClock({this.styling});
  final TextStyle styling;
  @override
  Widget build(BuildContext context) {
    return Consumer<CountdownNotifier>(builder: (context, notifier, _) {
      if (notifier.value != null)
        return Text(
          'Countdown: ${notifier.value}',
          style: styling,
        );
      else
        return Container();
    });
  }
}
