import 'package:flutter/material.dart';

import '../models/friend.dart';
import '../models/game.dart';
import '../screens/friend_profile.dart';
import '../screens/profile.dart';

class AppNavigator {
  static void openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  static void openFriendProfile(
    BuildContext context, {
    required Friend friend,
    required Future<Map<String, Game>> catalogFuture,
    Map<String, Game> initialCatalog = const {},
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FriendProfileScreen(
          friend: friend,
          catalogFuture: catalogFuture,
          initialCatalog: initialCatalog,
        ),
      ),
    );
  }
}
