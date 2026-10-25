import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_identity_service.dart';

class ProfilePhotoService {
  static const _legacyPhotoPathKey = 'profileImagePath';
  static const _legacyPhotoOwnerKey = 'profileImageOwnerId';

  static final ValueNotifier<String?> photoPath = ValueNotifier(null);

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final accountId = await UserIdentityService().getOrCreateAccountId();
    final photoKey = storageKeyForAccount(accountId);
    var path = preferences.getString(photoKey);

    if (path == null && preferences.getString(_legacyPhotoOwnerKey) == null) {
      final legacyPath = preferences.getString(_legacyPhotoPathKey);
      if (legacyPath != null && File(legacyPath).existsSync()) {
        path = legacyPath;
        await preferences.setString(photoKey, legacyPath);
        await preferences.setString(_legacyPhotoOwnerKey, accountId);
      }
    }

    photoPath.value = path != null && File(path).existsSync() ? path : null;
  }

  static Future<void> save(String path) async {
    final preferences = await SharedPreferences.getInstance();
    final accountId = await UserIdentityService().getOrCreateAccountId();
    await preferences.setString(storageKeyForAccount(accountId), path);
    photoPath.value = path;
  }

  static String storageKeyForAccount(String accountId) =>
      'profileImagePath_$accountId';
}
