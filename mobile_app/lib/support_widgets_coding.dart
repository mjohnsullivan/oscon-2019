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
      background: Image.asset('assets/road_stripes.jpg', fit: BoxFit.cover),
      foreground: TyperAnimatedTextKit(
        duration: Duration(seconds: 7),
        text: [buttonText],
        textStyle: TextStyle(color: Colors.white),
      ),
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
  Color _color;
  final Color defaultColor = Colors.blue;
  final Color darkGrey = Colors.grey[800];
  final Color lightGrey = Colors.grey[100];
  Timer _timer;
  @override
  void initState() {
    _color = defaultColor;
    _timer = Timer.periodic(Duration(seconds: 8), (_) {
      if (_color == defaultColor) {
        setState(() => _color = darkGrey);
      } else {
        setState(() => _color = defaultColor);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasicButton(
        onPressed: widget.onPressed,
        body: AnimatedContainer(
            duration: Duration(seconds: 4),
            color: _color,
            child: Center(
              child: Text(
                widget.text,
                style: TextStyle(color: lightGrey),
              ),
            )));
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
          Container(
            constraints: BoxConstraints.expand(),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.yellow[600], Colors.yellow[800]])),
          ),
          SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, -1),
                end: Offset(0, 1),
              ).animate(_controller),
              child: _greenGradient),
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
