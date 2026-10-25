import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameview/services/profile_photo_service.dart';
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

  test('loads a saved profile photo into the shared notifier', () async {
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
    await preferences.setString('profileImagePath', photo.path);

    await ProfilePhotoService.load();

    expect(ProfilePhotoService.photoPath.value, photo.path);
  });
}
