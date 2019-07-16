import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_app/common.dart';
import 'package:web_app/db.dart';
import 'package:web_app/simple_voting.dart';

class SimpleVotingPage extends StatelessWidget {
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
