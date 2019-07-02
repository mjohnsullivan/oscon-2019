import 'package:flutter/material.dart';

class RainbowButton extends StatelessWidget {
  RainbowButton({this.onPressed, this.text});

  final VoidCallback onPressed;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
        child: ConstrainedBox(
            constraints: BoxConstraints.expand(height: 70),
            child: FlatButton(
                onPressed: onPressed,
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: <Widget>[
                    Image.asset('assets/diagonal_rainbow_gradient2.jpg',
                        height: 70),
                    Text(text,
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 24)),
                  ],
                ))));
  }
}
