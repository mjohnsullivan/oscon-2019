import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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

class ShimmerButton extends StatelessWidget {
  ShimmerButton({this.onPressed, this.text});

  final VoidCallback onPressed;
  final String text;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      onLongPress: onPressed,
      child: Container(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.yellow[100],
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          color: Colors.grey,
        ),
      ),
    );
  }
}
