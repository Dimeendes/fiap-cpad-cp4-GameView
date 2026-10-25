import 'package:flutter/painting.dart';

import '../theme/app_colors.dart';
import 'game.dart';

/// Avaliação feita por uma conta (nota, texto e data).
class GameReview {
  final String gameName;
  final double userScore;
  final String reviewText;
  final int ratedAtMillis;

  const GameReview({
    required this.gameName,
    required this.userScore,
    this.reviewText = '',
    required this.ratedAtMillis,
  });

  bool get hasAnalysis => reviewText.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'gameName': gameName,
      'userScore': userScore,
      'reviewText': reviewText,
      'ratedAtMillis': ratedAtMillis,
    };
  }

  factory GameReview.fromJson(Map<String, dynamic> json) {
    return GameReview(
      gameName: json['gameName'] as String? ?? '',
      userScore: (json['userScore'] as num?)?.toDouble() ?? 0,
      reviewText: json['reviewText'] as String? ?? '',
      ratedAtMillis: json['ratedAtMillis'] as int? ?? 0,
    );
  }
}

/// Conta do GameView (amiga, recomendada ou encontrada na busca).
///
/// [favoriteGame] guarda o NOME do jogo favorito escolhido manualmente pela
/// conta (é diferente dos favoritos da biblioteca). O nome precisa ser igual
/// ao da tabela `games` (veja supabase/schema.sql) para a capa e a nota
/// aparecerem.
class Friend {
  final String id;
  final String name;
  final String handle;
  final String? favoriteGame;
  final List<GameReview> reviews;
  final String? photoPath;
  final bool isCurrentUser;

  /// Cor do avatar (iniciais). Fica dentro da paleta do app.
  final Color accent;

  const Friend({
    this.id = '',
    required this.name,
    this.handle = '',
    this.favoriteGame,
    this.reviews = const [],
    this.photoPath,
    this.isCurrentUser = false,
    this.accent = AppColors.blue,
  });

  String get accountId => id.trim().isEmpty ? name.trim().toLowerCase() : id;

  String get displayHandle {
    final value = handle.trim();
    if (value.isEmpty) return '';
    return value.startsWith('@') ? value : '@$value';
  }

  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  bool get hasFavoriteGame => favoriteGame?.trim().isNotEmpty ?? false;

  /// Média das notas (0–10) das avaliações, ou `null` sem avaliações.
  double? get averageScore {
    if (reviews.isEmpty) return null;
    final total = reviews.fold<double>(0, (sum, review) => sum + review.userScore);
    return total / reviews.length;
  }

  int get analysisCount => reviews.where((review) => review.hasAnalysis).length;

  Friend copyWith({String? favoriteGame, String? photoPath}) {
    return Friend(
      id: id,
      name: name,
      handle: handle,
      favoriteGame: favoriteGame ?? this.favoriteGame,
      reviews: reviews,
      photoPath: photoPath ?? this.photoPath,
      isCurrentUser: isCurrentUser,
      accent: accent,
    );
  }

  GameReview? get latestAnalysis {
    final items = reviews.where((review) => review.hasAnalysis).toList()
      ..sort((a, b) => b.ratedAtMillis.compareTo(a.ratedAtMillis));
    return items.isEmpty ? null : items.first;
  }

  List<GameReview> recentGames({int limit = 5}) {
    final items = [...reviews]
      ..sort((a, b) => b.ratedAtMillis.compareTo(a.ratedAtMillis));
    return items.take(limit).toList();
  }

  bool matchesQuery(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return name.toLowerCase().contains(needle) ||
        handle.toLowerCase().contains(needle) ||
        accountId.toLowerCase().contains(needle);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': accountId,
      'name': name,
      'handle': handle,
      'favoriteGame': favoriteGame,
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'accent': accent.toARGB32(),
      'photoPath': photoPath,
      'isCurrentUser': isCurrentUser,
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      // Contas salvas antes da mudança guardavam um top 5: o 1º vira o favorito.
      favoriteGame:
          json['favoriteGame'] as String? ??
          (json['topGames'] as List<dynamic>?)?.firstOrNull?.toString(),
      reviews: (json['reviews'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => GameReview.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      accent: Color(json['accent'] as int? ?? AppColors.blue.toARGB32()),
      photoPath: json['photoPath'] as String?,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }
}

/// Um jogo citado por nome (favorito ou avaliação) já cruzado com o catálogo.
class RankedGame {
  /// Nome como foi digitado em `friends_data.dart`.
  final String name;

  /// `null` quando o nome não foi encontrado no catálogo
  /// (ou quando o catálogo não pôde ser carregado).
  final Game? game;

  const RankedGame({required this.name, this.game});
}
