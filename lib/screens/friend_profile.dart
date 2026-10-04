import 'package:flutter/material.dart';

import '../models/friend.dart';
import '../models/game.dart';
import '../services/friends_service.dart';
import '../theme/app_colors.dart';
import '../widgets/friend_avatar.dart';
import '../widgets/game_cover.dart';
import '../widgets/score_stars.dart';

/// Perfil de um amigo: o Nº 1 em destaque e, logo abaixo, do 2º ao 5º lugar.
class FriendProfileScreen extends StatelessWidget {
  final Friend friend;

  /// Mesmo future carregado pela tela de Amigos (não busca o catálogo de novo).
  final Future<Map<String, Game>> catalogFuture;

  /// Catálogo já disponível no momento do clique (evita piscar sem capas).
  final Map<String, Game> initialCatalog;

  const FriendProfileScreen({
    super.key,
    required this.friend,
    required this.catalogFuture,
    this.initialCatalog = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: FutureBuilder<Map<String, Game>>(
                future: catalogFuture,
                initialData: initialCatalog.isEmpty ? null : initialCatalog,
                builder: (context, snapshot) {
                  final catalog = snapshot.data ?? const <String, Game>{};
                  final ranking = FriendsService.rankFor(friend, catalog);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Voltar para amigos',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _FriendHeaderCard(friend: friend),
                      const SizedBox(height: 20),
                      if (ranking.isEmpty)
                        const _EmptyTopCard()
                      else ...[
                        _NumberOneCard(item: ranking.first),
                        if (ranking.length > 1) ...[
                          const SizedBox(height: 24),
                          Text(
                            ranking.length == 2
                                ? 'Em 2º lugar'
                                : 'Do 2º ao ${ranking.length}º lugar',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          for (final item in ranking.skip(1)) ...[
                            _RankRow(item: item),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendHeaderCard extends StatelessWidget {
  final Friend friend;

  const _FriendHeaderCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          FriendAvatar(friend: friend, radius: 42),
          const SizedBox(height: 18),
          Text(
            friend.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF222222),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Top 5 jogos favoritos',
            style: TextStyle(color: Color(0xFF777777), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _NumberOneCard extends StatelessWidget {
  final RankedGame item;

  const _NumberOneCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final game = item.game;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mesmo tratamento do catálogo: capa com a nota em estrelas embaixo.
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
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Nº 1',
                          style: TextStyle(
                            color: Color(0xFF8A6100),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.name,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final RankedGame item;

  const _RankRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final game = item.game;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '${item.rank}º',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 70,
              child: GameCover(imageUrl: game?.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (game != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    game.platform,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (game != null) ...[
            const SizedBox(width: 8),
            Semantics(
              label: 'Nota ${game.score.toStringAsFixed(1)} de 10',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    game.score.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFF222222),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _EmptyTopCard extends StatelessWidget {
  const _EmptyTopCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.sports_esports_outlined, color: AppColors.blue, size: 48),
          SizedBox(height: 16),
          Text(
            'Esse amigo ainda não escolheu os jogos do top 5.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF222222),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
