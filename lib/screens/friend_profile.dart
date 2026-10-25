import 'package:flutter/material.dart';

import '../models/friend.dart';
import '../models/game.dart';
import '../services/friends_service.dart';
import '../theme/app_colors.dart';
import '../widgets/friend_avatar.dart';
import '../utils/date_format.dart';
import '../widgets/favorite_game_card.dart';
import '../widgets/game_cover.dart';
import '../widgets/ratings_summary.dart';

/// Perfil de uma conta: foto, jogo favorito, estatísticas, análise mais
/// recente e diário de jogos recentes.
class FriendProfileScreen extends StatefulWidget {
  final Friend friend;
  final Future<Map<String, Game>> catalogFuture;
  final Map<String, Game> initialCatalog;
  final bool initiallyFollowing;

  const FriendProfileScreen({
    super.key,
    required this.friend,
    required this.catalogFuture,
    this.initialCatalog = const {},
    this.initiallyFollowing = false,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late bool _following = widget.initiallyFollowing;

  Future<void> _toggleFollow() async {
    final next = !_following;
    await FriendsService.setFollowing(
      accountId: widget.friend.accountId,
      following: next,
    );
    if (!mounted) return;
    setState(() => _following = next);
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: FutureBuilder<Map<String, Game>>(
                future: widget.catalogFuture,
                initialData: widget.initialCatalog.isEmpty
                    ? null
                    : widget.initialCatalog,
                builder: (context, snapshot) {
                  final catalog = snapshot.data ?? const <String, Game>{};
                  final favorite = FriendsService.favoriteFor(friend, catalog);
                  final latest = friend.latestAnalysis;
                  final recent = friend.recentGames();

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
                      _FriendHeaderCard(
                        friend: friend,
                        following: _following,
                        onToggleFollow: _toggleFollow,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle('Jogo favorito'),
                      const SizedBox(height: 12),
                      if (favorite == null)
                        const _EmptyFavoriteCard()
                      else
                        FavoriteGameCard(
                          name: favorite.name,
                          game: favorite.game,
                        ),
                      const SizedBox(height: 24),
                      const _SectionTitle('Estatísticas'),
                      const SizedBox(height: 12),
                      RatingsSummary(
                        scores: [
                          for (final review in friend.reviews) review.userScore,
                        ],
                        analysisCount: friend.analysisCount,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle('Análise mais recente'),
                      const SizedBox(height: 12),
                      if (latest == null)
                        const _MessageCard(
                          icon: Icons.rate_review_outlined,
                          message: 'Essa conta ainda não publicou uma análise.',
                        )
                      else
                        _AnalysisCard(
                          review: latest,
                          ranked: FriendsService.resolveReview(latest, catalog),
                        ),
                      const SizedBox(height: 24),
                      const _SectionTitle('Jogos recentes'),
                      const SizedBox(height: 12),
                      if (recent.isEmpty)
                        const _MessageCard(
                          icon: Icons.sports_esports_outlined,
                          message: 'Ainda não há jogos avaliados nesta conta.',
                        )
                      else
                        for (final review in recent) ...[
                          _RecentGameRow(
                            review: review,
                            ranked: FriendsService.resolveReview(
                              review,
                              catalog,
                            ),
                          ),
                          const SizedBox(height: 10),
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

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _FriendHeaderCard extends StatelessWidget {
  final Friend friend;
  final bool following;
  final VoidCallback onToggleFollow;

  const _FriendHeaderCard({
    required this.friend,
    required this.following,
    required this.onToggleFollow,
  });

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
          if (friend.displayHandle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              friend.displayHandle,
              style: const TextStyle(color: Color(0xFF777777), fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onToggleFollow,
              child: Text(following ? 'Seguindo' : 'Seguir'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final GameReview review;
  final RankedGame ranked;

  const _AnalysisCard({required this.review, required this.ranked});

  @override
  Widget build(BuildContext context) {
    final game = ranked.game;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                      review.gameName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${review.userScore.toStringAsFixed(0)} / 10',
                          style: const TextStyle(
                            color: Color(0xFF222222),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            review.reviewText.trim(),
            style: const TextStyle(
              color: Color(0xFF444444),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentGameRow extends StatelessWidget {
  final GameReview review;
  final RankedGame ranked;

  const _RecentGameRow({required this.review, required this.ranked});

  @override
  Widget build(BuildContext context) {
    final game = ranked.game;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
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
                  review.gameName,
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
                if (formatLoggedDate(review.ratedAtMillis).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Jogado em ${formatLoggedDate(review.ratedAtMillis)}',
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                review.userScore.toStringAsFixed(0),
                style: const TextStyle(
                  color: Color(0xFF222222),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyFavoriteCard extends StatelessWidget {
  const _EmptyFavoriteCard();

  @override
  Widget build(BuildContext context) {
    return const _MessageCard(
      icon: Icons.sports_esports_outlined,
      message: 'Essa conta ainda não escolheu um jogo favorito.',
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MessageCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.blue, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
