import 'dart:math';

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

class Meteor extends StatefulWidget {
  final Size size;

  Meteor({Key key, @required this.size}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MeteorState();
  }
}

class _MeteorState extends State<Meteor> with TickerProviderStateMixin {
  AnimationController animationController;
  final particleSystem = <Particle>[];

  @override
  void initState() {
    super.initState();

    //Generate particles
    List.generate(100, (i) {
      particleSystem.add(Particle(widget.size));
    });

    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100))
          ..addListener(() {
            for (int i = 0; i < particleSystem.length; i++) {
              // Move particle
              particleSystem[i].move();

              // Restored particle
              if (particleSystem[i].remainingLife < 0 ||
                  particleSystem[i].radius < 0) {
                particleSystem[i] = Particle(widget.size);
              }
            }
          })
          ..repeat();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) => CustomPaint(
              size: widget.size,
              painter: _MeteorPainter(
                  Size(
                    widget.size.width,
                    widget.size.height,
                  ),
                  particleSystem),
            ),
      ),
    );
  }
}

class _MeteorPainter extends CustomPainter {
  final List<Particle> particleSystem;
  final Size size;

  _MeteorPainter(this.size, this.particleSystem);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particleSystem) {
      particle.display(canvas);
    }
  }

  @override
  bool shouldRepaint(_MeteorPainter oldDelegate) => true;
}

class Particle {
  Offset speed;
  Offset location;
  double radius;
  double life;
  Color color;
  double opacity;

  double remainingLife;
  Size screenSize;
  var palette = <Color>[];

  Particle(Size screenSize) {
    Random rd = Random();

    this.screenSize = screenSize;
    this.speed =
        Offset(-5 + rd.nextDouble() * 10, -15.0 + rd.nextDouble() * 10);
    this.location =
        Offset(this.screenSize.width / 2, this.screenSize.height / 3 * 2);
    this.radius = 10 + rd.nextDouble() * 20;
    this.life = 20 + rd.nextDouble() * 10;
    this.remainingLife = this.life;

    for (int i = 30; i < 100; i++) {
      palette.add(HSLColor.fromAHSL(1.0, 259, .33, i / 100).toColor());
    }

    this.color = palette[0];
  }

  move() {
    this.remainingLife--;
    this.radius--;
    this.location = this.location + this.speed;
    int colorI = palette.length -
        (this.remainingLife / this.life * palette.length).round();
    if (colorI >= 0 && colorI < palette.length) {
      this.color = palette[colorI];
    }
  }

  display(Canvas canvas) {
    this.opacity = (this.remainingLife / this.life * 100).round() / 100;
    var gradient = RadialGradient(
      colors: [
        Color.fromRGBO(
            this.color.red, this.color.green, this.color.blue, this.opacity),
        Color.fromRGBO(
            this.color.red, this.color.green, this.color.blue, this.opacity),
        Color.fromRGBO(this.color.red, this.color.green, this.color.blue, 0.0)
      ],
      stops: [0.0, 0.5, 1.0],
    );

    Paint painter = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient.createShader(
          Rect.fromCircle(center: this.location, radius: this.radius));

    canvas.drawCircle(this.location, this.radius, painter);
  }
}
