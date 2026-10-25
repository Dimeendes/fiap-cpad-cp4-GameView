import 'package:flutter/material.dart';

import '../models/friend.dart';
import '../models/game.dart';
import '../screens/friend_profile.dart';
import '../screens/profile.dart';

class AppNavigator {
  static Future<void> openProfile(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  static Future<void> openFriendProfile(
    BuildContext context, {
    required Friend friend,
    required Future<Map<String, Game>> catalogFuture,
    Map<String, Game> initialCatalog = const {},
    bool isFollowing = false,
  }) async {
    if (friend.isCurrentUser) {
      await openProfile(context);
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => FriendProfileScreen(
          friend: friend,
          catalogFuture: catalogFuture,
          initialCatalog: initialCatalog,
          initiallyFollowing: isFollowing,
        ),
      ),
    );
  }
}
