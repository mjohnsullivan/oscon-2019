import 'package:flutter/material.dart';
import 'package:web_app/db.dart';

const buttonTextStyle = TextStyle(
  fontFamily: 'Raleway',
  color: Colors.black,
  fontSize: 24,
);

const labelTextStyle = TextStyle(
  fontFamily: 'Raleway',
  fontWeight: FontWeight.w900,
  color: Colors.black,
  fontSize: 32,
);

/// Styling for color voting buttons
class VotingButton extends StatelessWidget {
  VotingButton(this.votes);
  final VoteNotifier votes;

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      color: votes.color,
      child: Text('${votes.value}', style: buttonTextStyle),
      onPressed: () => votes.vote(),
    );
  }
}
