import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gameview/services/user_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('creates and keeps a stable account ID independent of email', () async {
    final identity = UserIdentityService();

    final firstId = await identity.getOrCreateAccountId(
      legacyEmail: 'player@example.com',
    );
    final secondId = await identity.getOrCreateAccountId(
      legacyEmail: 'new-address@example.com',
    );

    expect(firstId, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(secondId, firstId);
  });

  test('keeps the same ID when account initialization is concurrent', () async {
    final identities = await Future.wait([
      UserIdentityService().getOrCreateAccountId(
        legacyEmail: 'player@example.com',
      ),
      UserIdentityService().getOrCreateAccountId(
        legacyEmail: 'player@example.com',
      ),
    ]);

    expect(identities[0], identities[1]);
  });

  test('migrates legacy email library data to the stable account ID', () async {
    const email = 'player@example.com';
    const legacyData = '[{"game_id":42,"user_score":10}]';
    SharedPreferences.setMockInitialValues({
      UserIdentityService.legacyStorageKeyForEmail(email): legacyData,
    });
    final identity = UserIdentityService();

    final accountId = await identity.getOrCreateAccountId(legacyEmail: email);
    final preferences = await SharedPreferences.getInstance();

    expect(
      preferences.getString(UserIdentityService.storageKeyFor(accountId)),
      legacyData,
    );
  });

  test(
    'merges legacy entries with entries already stored under the ID',
    () async {
      const email = 'player@example.com';
      const accountId = 'stable-account-id';
      const legacyData = '[{"game_id":1,"user_score":8}]';
      const accountData = '[{"game_id":2,"user_score":10}]';
      SharedPreferences.setMockInitialValues({
        UserIdentityService.accountIdPreferenceKey: accountId,
        UserIdentityService.legacyStorageKeyForEmail(email): legacyData,
        UserIdentityService.storageKeyFor(accountId): accountData,
      });

      await UserIdentityService().getOrCreateAccountId(legacyEmail: email);
      final preferences = await SharedPreferences.getInstance();
      final mergedData = jsonDecode(
        preferences.getString(UserIdentityService.storageKeyFor(accountId))!,
      ) as List;

      expect(mergedData, hasLength(2));
      expect(mergedData.map((entry) => (entry as Map)['game_id']).toSet(), {
        1,
        2,
      });
    },
  );

  test('creates a new ID for each newly registered account', () async {
    final identity = UserIdentityService();

    final firstId = await identity.createAccountId();
    final secondId = await identity.createAccountId();

    expect(secondId, isNot(firstId));
  });
}
