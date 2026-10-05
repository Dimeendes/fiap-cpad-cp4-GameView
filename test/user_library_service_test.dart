import 'package:flutter_test/flutter_test.dart';
import 'package:gameview/services/user_library_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final service = UserLibraryService(
    SupabaseClient('https://example.supabase.co', 'test-key'),
  );

  test('rejeita notas fora de 1 a 5 estrelas inteiras', () {
    for (final score in [0.0, 1.0, 9.0, 11.0]) {
      expect(
        () => service.setRating(
          userEmail: 'player@example.com',
          gameId: 1,
          userScore: score,
        ),
        throwsArgumentError,
      );
    }
  });
}
