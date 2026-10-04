import 'package:flutter/material.dart';

import '../models/friend.dart';

/// Avatar do amigo: inicial do nome sobre a cor de destaque dele.
class FriendAvatar extends StatelessWidget {
  final Friend friend;
  final double radius;

  const FriendAvatar({super.key, required this.friend, this.radius = 26});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: friend.accent,
      child: Text(
        friend.initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.85,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
