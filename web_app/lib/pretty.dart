import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:web_app/common.dart';
import 'package:web_app/db.dart';

const buttonTextStyle = TextStyle(
  fontFamily: 'RobotoMono-Regular',
  color: Colors.white,
  fontSize: 24,
);

const labelTextStyle = TextStyle(
  fontFamily: 'RobotoMono-Regular',
  fontWeight: FontWeight.w900,
  color: Colors.black,
  fontSize: 32,
);

class PrettyVotingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const VotingLabel('Haberdashery Voter!'),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            children: [
              BlueVotingButton(),
              GreenVotingButton(),
              RedVotingButton(),
              YellowVotingButton(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: CountdownClock(
            styling: labelTextStyle,
          ),
        ),
      ],
    );
  }
}

class VotingLabel extends StatelessWidget {
  const VotingLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(label, style: labelTextStyle);
}

class BlueVotingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BlueVoteNotifier>(builder: (context, notifier, _) {
      return VotingButton(notifier);
    });
  }
}

class GreenVotingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GreenVoteNotifier>(builder: (context, notifier, _) {
      return VotingButton(notifier);
    });
  }
}

class RedVotingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RedVoteNotifier>(builder: (context, notifier, _) {
      return VotingButton(notifier);
    });
  }
}

class YellowVotingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<YellowVoteNotifier>(builder: (context, notifier, _) {
      return VotingButton(notifier);
    });
  }
}

/// Styling for color voting buttons
class VotingButton extends StatelessWidget {
  VotingButton(this.votes);
  final VoteNotifier votes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () => votes.vote(),
        child: Material(
          color: votes.color,
          elevation: 4,
          shape: CircleBorder(
              side: BorderSide(
            width: 10,
            color: Colors.black38,
          )),
          //shape: RoundedRectangleBorder(
          //  side: BorderSide(color: Colors.white, width: 10),
          //  borderRadius: BorderRadius.circular(20),
          //),
          child: Center(
            child: ScalingText('${votes.value}'),
          ),
        ),
      ),
    );
  }
}

class ScalingText extends StatefulWidget {
  ScalingText(this.text);
  final String text;

  @override
  _ScalingTextState createState() => _ScalingTextState();
}

class _ScalingTextState extends State<ScalingText>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  initState() {
    super.initState();
    controller =
        AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    final CurvedAnimation curve =
        CurvedAnimation(parent: controller, curve: Curves.easeIn);
    animation = Tween(begin: 0.0, end: 1.0).animate(curve);
    controller.forward();
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      child: Text(
        widget.text,
        style: buttonTextStyle,
      ),
    );
  }
}
