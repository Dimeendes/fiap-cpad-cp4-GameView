import 'game.dart';

/// Entrada da biblioteca do usuário.
/// Pronta para reviews, favoritos e lista de desejo (escrita virá depois).
class LibraryEntry {
  final int? id;
  final String userEmail;
  final Game game;
  final double? userScore;
  final String? reviewText;
  final bool isFavorite;
  final bool isWishlist;

  const LibraryEntry({
    this.id,
    required this.userEmail,
    required this.game,
    this.userScore,
    this.reviewText,
    this.isFavorite = false,
    this.isWishlist = false,
  });

  bool get hasReview =>
      userScore != null || (reviewText != null && reviewText!.trim().isNotEmpty);

  LibraryEntry copyWith({
    int? id,
    String? userEmail,
    Game? game,
    double? userScore,
    String? reviewText,
    bool? isFavorite,
    bool? isWishlist,
  }) {
    return LibraryEntry(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      game: game ?? this.game,
      userScore: userScore ?? this.userScore,
      reviewText: reviewText ?? this.reviewText,
      isFavorite: isFavorite ?? this.isFavorite,
      isWishlist: isWishlist ?? this.isWishlist,
    );
  }

  factory LibraryEntry.fromMap(Map<String, dynamic> map) {
    final gameMap = map['games'];
    if (gameMap is! Map<String, dynamic>) {
      throw FormatException(
        'LibraryEntry espera o join "games" no mapa retornado.',
      );
    }

    return LibraryEntry(
      id: map['id'] as int?,
      userEmail: map['user_email'] as String,
      game: Game.fromMap(gameMap),
      userScore: (map['user_score'] as num?)?.toDouble(),
      reviewText: map['review_text'] as String?,
      isFavorite: map['is_favorite'] as bool? ?? false,
      isWishlist: map['is_wishlist'] as bool? ?? false,
    );
  }

  /// Payload para upsert futuro (review / favorito / wishlist).
  Map<String, dynamic> toUpsertMap() {
    return {
      if (id != null) 'id': id,
      'user_email': userEmail,
      'game_id': game.id,
      'user_score': userScore,
      'review_text': reviewText,
      'is_favorite': isFavorite,
      'is_wishlist': isWishlist,
    };
  }
}
