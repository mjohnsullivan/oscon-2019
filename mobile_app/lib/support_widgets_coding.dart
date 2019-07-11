import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/support_widgets.dart';

class MarchButton extends StatelessWidget {
  MarchButton({this.onPressed, this.buttonText});

  final VoidCallback onPressed;
  final String buttonText;
  @override
  Widget build(BuildContext context) {
    return BasicImageButton(
      foreground: Text(buttonText),
      onPressed: onPressed,
    );
  }
}

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
        onPressed: widget.onPressed,
        body: Center(
          child: Text(
            widget.text,
            style: TextStyle(color: lightGrey),
          ),
        ));
  }
}

class ColorFillButton extends StatefulWidget {
  ColorFillButton({this.onPressed, this.text});
  final VoidCallback onPressed;
  final String text;

  @override
  _ColorFillButtonState createState() => _ColorFillButtonState();
}

class _ColorFillButtonState extends State<ColorFillButton>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
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
      onPressed: widget.onPressed,
      body: Stack(
        children: <Widget>[
          Center(
            child: Text(
              widget.text,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
