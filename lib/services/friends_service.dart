import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../data/friends_data.dart';
import '../models/friend.dart';
import '../models/game.dart';
import 'favorite_game_service.dart';
import 'profile_photo_service.dart';
import 'supabase_game_service.dart';

class FriendsDirectory {
  final List<Friend> accounts;
  final Set<String> followedIds;
  final Friend? currentUser;

  const FriendsDirectory({
    required this.accounts,
    required this.followedIds,
    this.currentUser,
  });

  List<Friend> get followableAccounts =>
      accounts.where((account) => !account.isCurrentUser).toList();

  List<Friend> get friends => followableAccounts
      .where((account) => followedIds.contains(account.accountId))
      .toList();

  List<Friend> get recommended {
    return followableAccounts
        .where((account) => !followedIds.contains(account.accountId))
        .take(FriendsService.recommendLimit)
        .toList();
  }

  List<Friend> searchFriends(String query) {
    return friends.where((account) => account.matchesQuery(query)).toList();
  }

  List<Friend> searchAccounts(String query) {
    return accounts.where((account) => account.matchesQuery(query)).toList();
  }

  /// Avaliações recentes de quem você segue, mais novas primeiro
  /// (o feed de atividade, como no Letterboxd).
  List<FriendActivity> friendsActivity({int limit = 6}) {
    final items = [
      for (final friend in friends)
        for (final review in friend.reviews)
          FriendActivity(friend: friend, review: review),
    ]..sort((a, b) => b.review.ratedAtMillis.compareTo(a.review.ratedAtMillis));
    return items.take(limit).toList();
  }

  /// O que as contas que você segue acharam de um jogo.
  List<FriendActivity> friendsWhoPlayed(String gameName) {
    final needle = gameName.trim().toLowerCase();
    return [
      for (final friend in friends)
        for (final review in friend.reviews)
          if (review.gameName.trim().toLowerCase() == needle)
            FriendActivity(friend: friend, review: review),
    ];
  }
}

/// Uma avaliação feita por uma conta, para feeds e "amigos que jogaram".
class FriendActivity {
  final Friend friend;
  final GameReview review;

  const FriendActivity({required this.friend, required this.review});
}

/// Cruza o favorito das contas com o catálogo e gerencia seguir/buscar.
class FriendsService {
  const FriendsService._();

  static const int recommendLimit = 3;
  static const currentUserId = 'current_user';
  static const directoryKey = 'social_accounts_directory';
  static const followedIdsKey = 'followed_account_ids';

  static String _key(String name) => name.trim().toLowerCase();

  /// Garante que os perfis de demonstração existam no armazenamento local,
  /// como contas reais do sistema.
  static Future<List<Friend>> ensureSeededAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      directoryKey,
      jsonEncode(kFriends.map((account) => account.toJson()).toList()),
    );
    return List<Friend>.from(kFriends);
  }

  static Future<FriendsDirectory> loadDirectory() async {
    final seeded = await ensureSeededAccounts();
    final followed = await followedIds();
    final currentUser = await currentUserAccount();
    final accounts = [...seeded];
    if (currentUser != null) {
      accounts.add(currentUser);
    }
    return FriendsDirectory(
      accounts: accounts,
      followedIds: followed,
      currentUser: currentUser,
    );
  }

  static Future<Friend?> currentUserAccount() async {
    await ProfilePhotoService.load();
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('nome')?.trim() ?? '';
    final email = prefs.getString('email')?.trim() ?? '';
    if (name.isEmpty && email.isEmpty) return null;

    return Friend(
      id: currentUserId,
      name: name.isEmpty ? 'Você' : name,
      handle: email,
      favoriteGame: await FavoriteGameService.load(),
      photoPath: ProfilePhotoService.photoPath.value,
      isCurrentUser: true,
    );
  }

  static Future<Set<String>> followedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(followedIdsKey)?.toSet() ?? <String>{};
  }

  static Future<void> follow(String accountId) async {
    final id = accountId.trim();
    if (id.isEmpty || id == currentUserId) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(followedIdsKey) ?? <String>[];
    if (!ids.contains(id)) {
      ids.add(id);
      await prefs.setStringList(followedIdsKey, ids);
    }
  }

  static Future<void> unfollow(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(followedIdsKey) ?? <String>[];
    ids.remove(accountId);
    await prefs.setStringList(followedIdsKey, ids);
  }

  static Future<void> setFollowing({
    required String accountId,
    required bool following,
  }) {
    return following ? follow(accountId) : unfollow(accountId);
  }

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

  /// Cruza o jogo favorito da conta com o catálogo (`null` se não escolheu).
  static RankedGame? favoriteFor(Friend friend, Map<String, Game> catalog) {
    if (!friend.hasFavoriteGame) return null;
    final name = friend.favoriteGame!.trim();
    return RankedGame(name: name, game: catalog[_key(name)]);
  }

  static RankedGame resolveReview(GameReview review, Map<String, Game> catalog) {
    return RankedGame(
      name: review.gameName,
      game: catalog[_key(review.gameName)],
    );
  }

  static void _warnAboutUnknownGames(
    List<Friend> friends,
    Map<String, Game> catalog,
  ) {
    for (final friend in friends) {
      final names = {
        if (friend.hasFavoriteGame) friend.favoriteGame!,
        ...friend.reviews.map((review) => review.gameName),
      };
      for (final name in names) {
        if (!catalog.containsKey(_key(name))) {
          debugPrint(
            'GameView: "$name" (conta ${friend.name}) não existe no '
            'catálogo. Confira a grafia em lib/data/friends_data.dart.',
          );
        }
      }
    }
  }
}
