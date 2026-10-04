import 'package:flutter/material.dart';

import '../screens/profile.dart';

class AppNavigator {
  static void openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }
}
