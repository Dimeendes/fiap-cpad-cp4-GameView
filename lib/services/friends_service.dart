import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/friend.dart';
import '../models/game.dart';
import 'supabase_game_service.dart';

/// Cruza o top 5 dos amigos (nomes em `friends_data.dart`) com o catálogo
/// de jogos do Supabase, reaproveitando capa, plataforma e nota.
class FriendsService {
  const FriendsService._();

  static const int maxTopGames = 5;

  static String _key(String name) => name.trim().toLowerCase();

  /// Carrega o catálogo indexado pelo nome do jogo (minúsculo).
  ///
  /// Nunca lança: se o Supabase não estiver configurado ou falhar, devolve um
  /// mapa vazio e a interface mostra só os nomes, sem capas.
  static Future<Map<String, Game>> loadCatalogFor(
    List<Friend> friends,
  ) async {
    if (!SupabaseConfig.isConfigured) return const <String, Game>{};

    try {
      final games = await SupabaseGameService(
        Supabase.instance.client,
      ).getGames();
      final catalog = {for (final game in games) _key(game.name): game};
      _warnAboutUnknownGames(friends, catalog);
      return catalog;
    } catch (error) {
      debugPrint('GameView: catálogo indisponível na tela de Amigos: $error');
      return const <String, Game>{};
    }
  }

  /// Monta o ranking de um amigo (até 5 posições), na ordem informada.
  static List<RankedGame> rankFor(Friend friend, Map<String, Game> catalog) {
    final names = friend.topGames.take(maxTopGames).toList();
    return [
      for (var i = 0; i < names.length; i++)
        RankedGame(rank: i + 1, name: names[i], game: catalog[_key(names[i])]),
    ];
  }

  static void _warnAboutUnknownGames(
    List<Friend> friends,
    Map<String, Game> catalog,
  ) {
    for (final friend in friends) {
      if (friend.topGames.length > maxTopGames) {
        debugPrint(
          'GameView: ${friend.name} tem ${friend.topGames.length} jogos no '
          'top; só os $maxTopGames primeiros serão exibidos.',
        );
      }
      for (final name in friend.topGames.take(maxTopGames)) {
        if (!catalog.containsKey(_key(name))) {
          debugPrint(
            'GameView: "$name" (top de ${friend.name}) não existe no '
            'catálogo. Confira a grafia em lib/data/friends_data.dart.',
          );
        }
      }
    }
  }
}
