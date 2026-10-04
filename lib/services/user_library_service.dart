import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game.dart';
import '../models/library_entry.dart';
import 'library_service.dart';
import 'supabase_game_service.dart';

/// Biblioteca por usuário.
/// Metadados (review/favorito/wishlist) ficam isolados por e-mail;
/// os dados dos jogos vêm da tabela `games` no Supabase.
class UserLibraryService implements LibraryService {
  final SupabaseClient _client;

  const UserLibraryService(this._client);

  static String storageKeyFor(String userEmail) =>
      'user_library_${userEmail.trim().toLowerCase()}';

  @override
  Future<List<LibraryEntry>> getLibraryEntries(String userEmail) async {
    final email = userEmail.trim().toLowerCase();
    final games = await SupabaseGameService(_client).getGames();
    final gamesById = <int, Game>{
      for (final game in games)
        if (game.id != null) game.id!: game,
    };

    final rawEntries = await _readRawEntries(email);
    final entries = <LibraryEntry>[];

    for (final raw in rawEntries) {
      final gameId = raw['game_id'];
      if (gameId is! int) continue;
      final game = gamesById[gameId];
      if (game == null) continue;

      entries.add(
        LibraryEntry(
          userEmail: email,
          game: game,
          userScore: (raw['user_score'] as num?)?.toDouble(),
          reviewText: raw['review_text'] as String?,
          isFavorite: raw['is_favorite'] as bool? ?? false,
          isWishlist: raw['is_wishlist'] as bool? ?? false,
        ),
      );
    }

    return entries;
  }

  @override
  Future<LibraryEntry> upsertReview({
    required String userEmail,
    required int gameId,
    double? userScore,
    String? reviewText,
  }) async {
    return _upsert(
      userEmail: userEmail,
      gameId: gameId,
      patch: {
        'user_score': userScore,
        'review_text': reviewText,
      },
    );
  }

  @override
  Future<LibraryEntry> setFavorite({
    required String userEmail,
    required int gameId,
    required bool isFavorite,
  }) async {
    return _upsert(
      userEmail: userEmail,
      gameId: gameId,
      patch: {'is_favorite': isFavorite},
    );
  }

  @override
  Future<LibraryEntry> setWishlist({
    required String userEmail,
    required int gameId,
    required bool isWishlist,
  }) async {
    return _upsert(
      userEmail: userEmail,
      gameId: gameId,
      patch: {'is_wishlist': isWishlist},
    );
  }

  Future<LibraryEntry> _upsert({
    required String userEmail,
    required int gameId,
    required Map<String, dynamic> patch,
  }) async {
    final email = userEmail.trim().toLowerCase();
    final entries = await _readRawEntries(email);
    final index = entries.indexWhere((entry) => entry['game_id'] == gameId);

    final current = index >= 0
        ? Map<String, dynamic>.from(entries[index])
        : <String, dynamic>{
            'game_id': gameId,
            'user_score': null,
            'review_text': null,
            'is_favorite': false,
            'is_wishlist': false,
          };

    current.addAll(patch);

    final hasReview = current['user_score'] != null ||
        ((current['review_text'] as String?)?.trim().isNotEmpty ?? false);
    final isFavorite = current['is_favorite'] as bool? ?? false;
    final isWishlist = current['is_wishlist'] as bool? ?? false;

    if (!hasReview && !isFavorite && !isWishlist) {
      if (index >= 0) entries.removeAt(index);
    } else if (index >= 0) {
      entries[index] = current;
    } else {
      entries.add(current);
    }

    await _writeRawEntries(email, entries);

    final games = await SupabaseGameService(_client).getGames();
    final game = games.firstWhere(
      (item) => item.id == gameId,
      orElse: () => throw StateError('Jogo $gameId não encontrado no Supabase.'),
    );

    return LibraryEntry(
      userEmail: email,
      game: game,
      userScore: (current['user_score'] as num?)?.toDouble(),
      reviewText: current['review_text'] as String?,
      isFavorite: isFavorite,
      isWishlist: isWishlist,
    );
  }

  Future<List<Map<String, dynamic>>> _readRawEntries(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyFor(email));
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _writeRawEntries(
    String email,
    List<Map<String, dynamic>> entries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKeyFor(email), jsonEncode(entries));
  }
}
