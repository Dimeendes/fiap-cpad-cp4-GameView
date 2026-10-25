import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/app_colors.dart';
import 'game_cover.dart';
import 'score_stars.dart';

/// Destaque do jogo favorito de uma conta: capa grande, nome e nota.
///
/// Com [onEdit] mostra o botão para trocar o favorito (perfil próprio).
class FavoriteGameCard extends StatelessWidget {
  final String name;
  final Game? game;
  final VoidCallback? onEdit;

  const FavoriteGameCard({
    super.key,
    required this.name,
    this.game,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final game = this.game;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 112,
            height: 150,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                GameCover(imageUrl: game?.imageUrl),
                if (game != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      color: Colors.black54,
                      child: ScoreStars(score: game.score),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 150),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE3E8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, color: Color(0xFFFF4D6D), size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Favorito',
                          style: TextStyle(
                            color: Color(0xFFB0213F),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF222222),
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (game != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      game.platform,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GameView Score: ${game.score.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (onEdit != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Trocar favorito'),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
