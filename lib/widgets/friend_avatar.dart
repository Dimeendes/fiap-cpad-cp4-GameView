import 'dart:io';

import 'package:flutter/material.dart';

import '../models/friend.dart';

/// Avatar da conta: foto, se houver; senão a inicial sobre a cor de destaque.
class FriendAvatar extends StatelessWidget {
  final Friend friend;
  final double radius;

  const FriendAvatar({super.key, required this.friend, this.radius = 26});

  @override
  Widget build(BuildContext context) {
    final path = friend.photoPath;
    final hasPhoto = path != null && File(path).existsSync();

    return CircleAvatar(
      radius: radius,
      backgroundColor: friend.accent,
      backgroundImage: hasPhoto ? FileImage(File(path)) : null,
      child: hasPhoto
          ? null
          : Text(
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
