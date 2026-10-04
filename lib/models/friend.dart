import 'package:flutter/painting.dart';

import '../theme/app_colors.dart';
import 'game.dart';

/// Amigo do usuário.
///
/// [topGames] guarda os NOMES dos jogos do top 5, na ordem do ranking
/// (índice 0 = 1º lugar). Os nomes precisam ser iguais aos da tabela `games`
/// (veja supabase/schema.sql) para a capa e a nota aparecerem.
class Friend {
  final String name;
  final List<String> topGames;

  /// Cor do avatar (iniciais). Fica dentro da paleta do app.
  final Color accent;

  const Friend({
    required this.name,
    this.topGames = const [],
    this.accent = AppColors.blue,
  });

  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }
}

/// Uma posição do ranking já cruzada com o catálogo de jogos.
class RankedGame {
  /// Posição no ranking, de 1 a 5.
  final int rank;

  /// Nome como foi digitado em `friends_data.dart`.
  final String name;

  /// `null` quando o nome não foi encontrado no catálogo
  /// (ou quando o catálogo não pôde ser carregado).
  final Game? game;

  const RankedGame({required this.rank, required this.name, this.game});
}
