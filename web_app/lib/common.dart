import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CountdownClock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<int>(builder: (context, value, _) {
      if (value != null)
        return Text('Countdown: $value');
      else
        return Container();
    });
  }
}
