import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePhotoService {
  static const _photoPathKey = 'profileImagePath';

  static final ValueNotifier<String?> photoPath = ValueNotifier(null);

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final path = preferences.getString(_photoPathKey);
    photoPath.value = path != null && File(path).existsSync() ? path : null;
  }

  static Future<void> save(String path) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_photoPathKey, path);
    photoPath.value = path;
  }
}
