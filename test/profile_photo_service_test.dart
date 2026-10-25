import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameview/services/profile_photo_service.dart';
import 'package:gameview/services/user_identity_service.dart';
import 'package:gameview/widgets/app_page_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProfilePhotoService.photoPath.value = null;
  });

  testWidgets('all app headers reflect profile photo updates', (
    WidgetTester tester,
  ) async {
    final photo = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'gameview-profile-photo-test.png',
    );
    await photo.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/lSsAAAAASUVORK5CYII=',
      ),
    );
    addTearDown(() async {
      if (await photo.exists()) await photo.delete();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPageHeader(title: 'Catálogo', onOpenProfile: () async {}),
        ),
      ),
    );

    await ProfilePhotoService.save(photo.path);
    await tester.pump();

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundImage, isA<FileImage>());
    expect((avatar.backgroundImage! as FileImage).file.path, photo.path);
  });

  test('stores different profile photos for different account IDs', () async {
    final photo = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'gameview-profile-photo-load-test.png',
    );
    await photo.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/lSsAAAAASUVORK5CYII=',
      ),
    );
    addTearDown(() async {
      if (await photo.exists()) await photo.delete();
    });
    final preferences = await SharedPreferences.getInstance();
    const firstAccountId = 'first-account';
    const secondAccountId = 'second-account';
    await preferences.setString(
      UserIdentityService.accountIdPreferenceKey,
      firstAccountId,
    );

    await ProfilePhotoService.save(photo.path);
    await preferences.setString(
      UserIdentityService.accountIdPreferenceKey,
      secondAccountId,
    );
    await ProfilePhotoService.load();

    expect(ProfilePhotoService.photoPath.value, isNull);
    expect(
      preferences.getString(
        ProfilePhotoService.storageKeyForAccount(firstAccountId),
      ),
      photo.path,
    );
    expect(
      preferences.getString(
        ProfilePhotoService.storageKeyForAccount(secondAccountId),
      ),
      isNull,
    );
  });

  test('migrates the legacy photo only once to its original account', () async {
    final photo = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'gameview-profile-photo-migration-test.png',
    );
    await photo.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/lSsAAAAASUVORK5CYII=',
      ),
    );
    addTearDown(() async {
      if (await photo.exists()) await photo.delete();
    });
    const firstAccountId = 'legacy-account';
    SharedPreferences.setMockInitialValues({
      UserIdentityService.accountIdPreferenceKey: firstAccountId,
      'profileImagePath': photo.path,
    });

    await ProfilePhotoService.load();
    expect(ProfilePhotoService.photoPath.value, photo.path);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      UserIdentityService.accountIdPreferenceKey,
      'different-account',
    );
    await ProfilePhotoService.load();

    expect(ProfilePhotoService.photoPath.value, isNull);
  });
}
