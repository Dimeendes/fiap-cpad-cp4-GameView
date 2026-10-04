import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game.dart';
import 'game_service.dart';

class SupabaseGameService implements GameService {
  final SupabaseClient _client;

  const SupabaseGameService(this._client);

  @override
  Future<List<Game>> getGames() async {
    final rows = await _client
        .from('games')
        .select('id, name, platform, score, image_url')
        .order('name');

    return rows.map((row) => Game.fromMap(row)).toList();
  }
}
