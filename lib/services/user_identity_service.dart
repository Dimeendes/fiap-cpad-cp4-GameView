import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class UserIdentityService {
  static const accountIdPreferenceKey = 'account_id';
  static const accountsPreferenceKey = 'accounts';
  static Future<void> _operationQueue = Future<void>.value();

  static String storageKeyFor(String accountId) => 'user_library_id_$accountId';

  static String legacyStorageKeyForEmail(String email) =>
      'user_library_${email.trim().toLowerCase()}';

  Future<bool> registerAccount({
    required String name,
    required String email,
    required String password,
  }) {
    return _serialize(() async {
      final preferences = await SharedPreferences.getInstance();
      final accounts = await _loadAccounts(preferences);
      final normalizedEmail = _normalizeEmail(email);
      if (accounts.any(
        (account) =>
            _normalizeEmail(account['email'] as String) == normalizedEmail,
      )) {
        return false;
      }

      final previousAccountId = preferences.getString(accountIdPreferenceKey);
      if (previousAccountId != null &&
          preferences.getString('profileImagePath') != null &&
          preferences.getString('profileImageOwnerId') == null) {
        await preferences.setString('profileImageOwnerId', previousAccountId);
      }

      final account = <String, dynamic>{
        'id': _generateAccountId(),
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      };
      accounts.add(account);
      await _saveAccounts(preferences, accounts);
      await preferences.setString(
        accountIdPreferenceKey,
        account['id'] as String,
      );
      await _setActiveAccount(preferences, account);
      return true;
    });
  }

  Future<bool> login({required String email, required String password}) {
    return _serialize(() async {
      final preferences = await SharedPreferences.getInstance();
      final accounts = await _loadAccounts(preferences);
      final normalizedEmail = _normalizeEmail(email);
      Map<String, dynamic>? account;
      for (final candidate in accounts) {
        if (_normalizeEmail(candidate['email'] as String) == normalizedEmail) {
          account = candidate;
          break;
        }
      }
      if (account == null || account['password'] != password) return false;

      await preferences.setString(
        accountIdPreferenceKey,
        account['id'] as String,
      );
      await _setActiveAccount(preferences, account);
      return true;
    });
  }

  Future<bool> emailExists(String email) {
    return _serialize(() async {
      final preferences = await SharedPreferences.getInstance();
      final accounts = await _loadAccounts(preferences);
      final normalizedEmail = _normalizeEmail(email);
      return accounts.any(
        (account) =>
            _normalizeEmail(account['email'] as String) == normalizedEmail,
      );
    });
  }

  Future<void> updateActiveAccount({
    String? name,
    String? email,
    String? password,
  }) {
    return _serialize(() async {
      final preferences = await SharedPreferences.getInstance();
      final accounts = await _loadAccounts(preferences);
      final accountId = await _getOrCreateAccountId(preferences);
      final index = accounts.indexWhere(
        (account) => account['id'] == accountId,
      );
      if (index < 0) {
        throw StateError('A conta ativa não foi encontrada.');
      }

      final account = Map<String, dynamic>.from(accounts[index]);
      final normalizedEmail = email == null ? null : _normalizeEmail(email);
      if (normalizedEmail != null &&
          accounts.any(
            (other) =>
                other['id'] != accountId &&
                _normalizeEmail(other['email'] as String) == normalizedEmail,
          )) {
        throw StateError('Este e-mail já está cadastrado em outra conta.');
      }
      if (name != null) account['name'] = name.trim();
      if (email != null) account['email'] = email.trim();
      if (password != null) account['password'] = password;
      accounts[index] = account;

      await _saveAccounts(preferences, accounts);
      await _setActiveAccount(preferences, account);
    });
  }

  Future<String> createAccountId() {
    return _serialize(() async {
      final preferences = await SharedPreferences.getInstance();
      final previousAccountId = preferences.getString(accountIdPreferenceKey);
      if (previousAccountId != null &&
          preferences.getString('profileImagePath') != null &&
          preferences.getString('profileImageOwnerId') == null) {
        await preferences.setString('profileImageOwnerId', previousAccountId);
      }
      final accountId = _generateAccountId();
      await preferences.setString(accountIdPreferenceKey, accountId);
      return accountId;
    });
  }

  Future<String> getOrCreateAccountId({String? legacyEmail}) {
    return _serialize(() async {
      final preferences = await SharedPreferences.getInstance();
      final accountId = await _getOrCreateAccountId(preferences);

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

  Future<List<Map<String, dynamic>>> _loadAccounts(
    SharedPreferences preferences,
  ) async {
    final rawAccounts = preferences.getString(accountsPreferenceKey);
    final accounts = <Map<String, dynamic>>[];
    if (rawAccounts != null && rawAccounts.isNotEmpty) {
      final decoded = jsonDecode(rawAccounts);
      if (decoded is! List) {
        throw const FormatException('Os dados das contas estão inválidos.');
      }
      accounts.addAll(
        decoded.whereType<Map>().map(
          (account) => Map<String, dynamic>.from(account),
        ),
      );
    }

    final legacyEmail = preferences.getString('email')?.trim();
    final legacyPassword = preferences.getString('senha');
    if (legacyEmail != null &&
        legacyEmail.isNotEmpty &&
        legacyPassword != null &&
        !accounts.any(
          (account) =>
              _normalizeEmail(account['email'] as String) ==
              _normalizeEmail(legacyEmail),
        )) {
      final accountId = await _getOrCreateAccountId(preferences);
      accounts.add({
        'id': accountId,
        'name': preferences.getString('nome') ?? 'Usuário',
        'email': legacyEmail,
        'password': legacyPassword,
      });
      await _saveAccounts(preferences, accounts);
    }

    return accounts;
  }

  Future<void> _saveAccounts(
    SharedPreferences preferences,
    List<Map<String, dynamic>> accounts,
  ) async {
    await preferences.setString(accountsPreferenceKey, jsonEncode(accounts));
  }

  Future<void> _setActiveAccount(
    SharedPreferences preferences,
    Map<String, dynamic> account,
  ) async {
    await preferences.setString('nome', account['name'] as String);
    await preferences.setString('email', account['email'] as String);
    await preferences.setString('senha', account['password'] as String);
  }

  Future<String> _getOrCreateAccountId(SharedPreferences preferences) async {
    var accountId = preferences.getString(accountIdPreferenceKey);
    if (accountId == null || accountId.isEmpty) {
      accountId = _generateAccountId();
      await preferences.setString(accountIdPreferenceKey, accountId);
    }
    return accountId;
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

  String _normalizeEmail(String email) => email.trim().toLowerCase();

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
