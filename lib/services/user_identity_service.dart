import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class UserIdentityService {
  static const accountIdPreferenceKey = 'account_id';
  static Future<void> _operationQueue = Future<void>.value();

  static String storageKeyFor(String accountId) => 'user_library_id_$accountId';

  static String legacyStorageKeyForEmail(String email) =>
      'user_library_${email.trim().toLowerCase()}';

  Future<String> createAccountId() async {
    return _serialize(() async {
      final preferences = await SharedPreferences.getInstance();
      final accountId = _generateAccountId();
      await preferences.setString(accountIdPreferenceKey, accountId);
      return accountId;
    });
  }

  Future<String> getOrCreateAccountId({String? legacyEmail}) async {
    return _serialize(() async {
      final preferences = await SharedPreferences.getInstance();
      var accountId = preferences.getString(accountIdPreferenceKey);

      if (accountId == null || accountId.isEmpty) {
        accountId = _generateAccountId();
        await preferences.setString(accountIdPreferenceKey, accountId);
      }

      final email = legacyEmail?.trim();
      if (email != null && email.isNotEmpty) {
        final legacyKey = legacyStorageKeyForEmail(email);
        final accountLibraryKey = storageKeyFor(accountId);
        final legacyEntries = preferences.getString(legacyKey);
        if (legacyEntries != null) {
          final mergedEntries = _mergeLibraryEntries(
            legacyEntries,
            preferences.getString(accountLibraryKey),
          );
          await preferences.setString(
            accountLibraryKey,
            jsonEncode(mergedEntries),
          );
        }
      }

      return accountId;
    });
  }

  List<Map<String, dynamic>> _mergeLibraryEntries(
    String legacyData,
    String? accountData,
  ) {
    final legacyEntries = _decodeLibraryEntries(legacyData);
    final accountEntries = accountData == null
        ? <Map<String, dynamic>>[]
        : _decodeLibraryEntries(accountData);
    final entriesByGameId = <int, Map<String, dynamic>>{};

    for (final entry in legacyEntries) {
      final gameId = entry['game_id'];
      if (gameId is int) entriesByGameId[gameId] = entry;
    }
    for (final entry in accountEntries) {
      final gameId = entry['game_id'];
      if (gameId is int) entriesByGameId[gameId] = entry;
    }

    return entriesByGameId.values.toList();
  }

  List<Map<String, dynamic>> _decodeLibraryEntries(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! List) {
      throw const FormatException(
        'Os dados da biblioteca devem ser uma lista.',
      );
    }

    return decoded
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  Future<T> _serialize<T>(Future<T> Function() action) async {
    final previous = _operationQueue;
    final completer = Completer<void>();
    _operationQueue = completer.future;
    await previous;
    try {
      return await action();
    } finally {
      completer.complete();
    }
  }

  String _generateAccountId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
