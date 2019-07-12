import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_app/bluetooth_state.dart';
import 'package:mobile_app/support_widgets.dart';
import 'package:provider/provider.dart';

class FadingButton extends StatefulWidget {
  FadingButton({this.onPressed, this.text});
  final VoidCallback onPressed;
  final String text;

  @override
  _FadingButtonState createState() => _FadingButtonState();
}

class _FadingButtonState extends State<FadingButton> {
  static final Color defaultColor = Colors.blue;
  static final Color darkGrey = Colors.grey[800];
  static final Color lightGrey = Colors.grey[200];
  final int breathe = AsciiCodec().encode('h')[0];

  Color _color = defaultColor;
  Timer _timer;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasicButton(
        onPressed: () => Provider.of<Bluetooth>(context).sendMessage(breathe),
        body: Center(
          child: Text(
            'Breathe',
            style: TextStyle(color: lightGrey),
          ),
        ));
  }
}

class ColorFillButton extends StatefulWidget {
  @override
  _ColorFillButtonState createState() => _ColorFillButtonState();
}

class _ColorFillButtonState extends State<ColorFillButton>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  final int lightSpill = AsciiCodec().encode('l')[0];
  final _greenGradient = Container(
    constraints: BoxConstraints.expand(),
    decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[600], Colors.green[800]])),
  );

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasicButton(
      onPressed: () => Provider.of<Bluetooth>(context).sendMessage(lightSpill),
      body: Stack(
        children: <Widget>[
          Center(
            child: Text(
              'Color Fill',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
