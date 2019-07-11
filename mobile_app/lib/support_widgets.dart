import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fireworks/fireworks.dart';

class BasicImageButton extends StatelessWidget {
  BasicImageButton(
      {this.fontColor = Colors.black,
      this.background,
      this.text = '',
      this.onPressed,
      this.foreground});
  final Color fontColor;
  final VoidCallback onPressed;
  final String text;
  final Widget background;
  final Widget foreground;
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Container(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            Container(child: background, height: 300),
            Text(text, style: TextStyle(color: fontColor)),
            foreground ?? Container(),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                onLongPress: onPressed,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class BasicButton extends StatelessWidget {
  BasicButton(
      {this.fontSize: 30,
      this.fontColor = Colors.black,
      this.backgroundColor,
      this.onPressed,
      this.body});
  final Color fontColor;
  final Color backgroundColor;
  final double fontSize;
  final VoidCallback onPressed;
  final Widget body;
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      color: backgroundColor,
      child: InkWell(
        onTap: onPressed,
        onLongPress: onPressed,
        child: Center(
          child: body,
        ),
      ),
    );
  }
}

class RainbowButton extends StatelessWidget {
  RainbowButton({this.onPressed, this.text});

  final VoidCallback onPressed;
  final String text;
  @override
  Widget build(BuildContext context) {
    return BasicImageButton(
      fontColor: Colors.grey[800],
      background:
          Image.asset('assets/diagonal_rainbow_gradient.jpg', fit: BoxFit.fill),
      onPressed: onPressed,
      text: text,
    );
  }
}

class FireButton extends StatefulWidget {
  FireButton({this.onPressed, this.text});

  final VoidCallback onPressed;
  final String text;

  @override
  _FireButtonState createState() => _FireButtonState();
}

class _FireButtonState extends State<FireButton> {
  double _opacity = 0;
  Random random = Random();
  @override
  void initState() {
    setVisibility();
    super.initState();
  }

  setVisibility() {
    setState(() => _opacity = 0);
    Future.delayed(Duration(milliseconds: random.nextInt(1000)), () {
      setState(() => _opacity = .4);
      Future.delayed(
          Duration(milliseconds: random.nextInt(500)), () => setVisibility());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasicImageButton(
      onPressed: widget.onPressed,
      text: widget.text,
      fontColor: Colors.white,
      background: Stack(
        children: <Widget>[
          Image.asset('assets/fire.jpg', fit: BoxFit.fill, height: 200),
          AnimatedOpacity(
              opacity: _opacity,
              duration: Duration(milliseconds: 500),
              child: Container(
                color: Colors.black,
                height: 200,
                width: 200,
              )),
        ],
      ),
    );
  }
}

class SparkleButton extends StatelessWidget {
  SparkleButton({this.onPressed, this.text});
  final VoidCallback onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return BasicImageButton(
      fontColor: Colors.white,
      background: Opacity(
          opacity: .7,
          child: Image.asset('assets/snow_sparkle.jpg', fit: BoxFit.fill)),
      onPressed: onPressed,
      text: text,
      foreground: Fireworks.only(
        numberOfExplosions: 16,
        child: SpinKitPulse(
          itemBuilder: (_, __) => Icon(Icons.star, color: Colors.white),
        ),
        maxHeight: 200,
        maxWidth: 200,
      ),
    );
  }
}

class TwinkleButton extends StatelessWidget {
  TwinkleButton({this.onPressed, this.text});

  final VoidCallback onPressed;
  final String text;
  @override
  Widget build(BuildContext context) {
    return BasicImageButton(
      fontColor: Colors.black,
      background: Opacity(
          opacity: .4,
          child: Image.asset(
            'assets/colorful_lights.jpg',
            fit: BoxFit.cover,
          )),
      onPressed: onPressed,
      foreground: ScalingText(text, end: 1.3),
    );
  }
}

class ShimmerButton extends StatelessWidget {
  ShimmerButton({this.onPressed, this.text});

  final VoidCallback onPressed;
  final String text;
  @override
  Widget build(BuildContext context) {
    return BasicButton(
      onPressed: onPressed,
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey[600], Colors.grey[800]])),
        child: Center(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.yellow[100],
            child: Text(
              text,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MeteorButton extends StatelessWidget {
  MeteorButton({this.onPressed, this.text});

  final VoidCallback onPressed;
  final String text;
  @override
  Widget build(BuildContext context) {
    return BasicButton(
      onPressed: onPressed,
      backgroundColor: const Color(0xff8162f4),
      body: Stack(
        children: <Widget>[
          Positioned(bottom: 1, left: 20, child: Meteor(size: Size(20, 5))),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[800]),
          )
        ],
      ),
    );
  }
}

// Code adjusted from https://github.com/nhancv/nc_flutter_util/
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
    this.speed = Offset(5 + rd.nextDouble() * 10, -15.0 + rd.nextDouble() * 10);
    this.location =
        Offset(this.screenSize.width / 2, this.screenSize.height / 3 * 2);
    this.radius = 1 + rd.nextDouble() * 13;
    this.life = 20 + rd.nextDouble() * 10;
    this.remainingLife = this.life;

    for (int i = 70; i < 100; i++) {
      palette.add(HSLColor.fromAHSL(1.0, 253, .26, i / 100).toColor());
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

class BouncingBallButton extends StatelessWidget {
  BouncingBallButton({this.onPressed});

  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return BasicImageButton(
      background: Opacity(
          opacity: .5,
          child: Image.asset('assets/ball_pit.jpg', fit: BoxFit.cover)),
      foreground: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          JumpingText('Bouncing',
              end: Offset(0, -.07), style: TextStyle(fontSize: 36)),
          JumpingText('Balls',
              end: Offset(0, -.07), style: TextStyle(fontSize: 36))
        ],
      ),
      onPressed: onPressed,
    );
  }
}

typedef ToggleValue = void Function(bool value);

class OnOffSwitch extends StatefulWidget {
  OnOffSwitch({this.onPressed});

  final ToggleValue onPressed;
  @override
  _OnOffSwitchState createState() => _OnOffSwitchState();
}

class _OnOffSwitchState extends State<OnOffSwitch> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return BasicImageButton(
      background: AnimatedSwitcher(
        duration: Duration(seconds: 1),
        child: _on
            ? Container(
                key: ValueKey(1),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 0.7,
                    colors: [
                      Colors.yellow,
                      Colors.orange,
                    ],
                    stops: [0.4, 1.0],
                  ),
                ),
              )
            : Container(
                key: ValueKey(2),
                color: Colors.white,
                height: 300,
                width: 300,
              ),
      ),
      foreground: Column(children: [
        Image.asset('assets/light_bulb.png', fit: BoxFit.cover, height: 125),
        Text(_on ? 'Lights!' : 'Off', style: TextStyle(fontSize: 30))
      ]),
      text: '',
      onPressed: () {
        setState(() => _on = !_on);
        widget.onPressed(_on);
      },
    );
  }
}
