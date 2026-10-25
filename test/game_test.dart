import 'package:flutter_test/flutter_test.dart';
import 'package:gameview/models/game.dart';

void main() {
  group('Game.fromMap', () {
    test('reads the game description from Supabase data', () {
      final game = Game.fromMap({
        'id': 1,
        'name': 'Example',
        'platform': 'PC',
        'score': 8.5,
        'image_url': 'https://example.com/game.jpg',
        'description': 'A game description.',
      });

      expect(game.description, 'A game description.');
    });

    test('supports rows without a description', () {
      final game = Game.fromMap({
        'id': 1,
        'name': 'Example',
        'platform': 'PC',
        'score': 8.5,
        'image_url': 'https://example.com/game.jpg',
      });

      expect(game.description, isEmpty);
    });
  });
}
