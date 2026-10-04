import 'package:flutter/material.dart';

import '../data/friends_data.dart';
import '../models/friend.dart';
import '../models/game.dart';
import '../navigation/app_navigator.dart';
import '../services/friends_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page_header.dart';
import '../widgets/friend_avatar.dart';
import '../widgets/game_cover.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  // Carregado uma única vez e compartilhado com o perfil do amigo, para não
  // buscar o catálogo de novo a cada clique. Nunca lança (ver FriendsService).
  late final Future<Map<String, Game>> _catalogFuture =
      FriendsService.loadCatalogFor(kFriends);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: FutureBuilder<Map<String, Game>>(
                future: _catalogFuture,
                builder: (context, snapshot) {
                  final catalog = snapshot.data ?? const <String, Game>{};

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        sliver: SliverToBoxAdapter(
                          child: AppPageHeader(
                            title: 'Amigos',
                            subtitle:
                                'Veja o que a galera anda jogando. Toque em '
                                'um amigo para ver o top 5 dele.',
                            onOpenProfile: () =>
                                AppNavigator.openProfile(context),
                          ),
                        ),
                      ),
                      if (kFriends.isEmpty)
                        const SliverToBoxAdapter(child: _EmptyFriendsCard())
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                          sliver: SliverGrid(
                            // 1 coluna no celular, 2 em janelas largas.
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 560,
                                  mainAxisExtent: 100,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final friend = kFriends[index];
                                return _FriendCard(
                                  friend: friend,
                                  catalog: catalog,
                                  onTap: () => AppNavigator.openFriendProfile(
                                    context,
                                    friend: friend,
                                    catalogFuture: _catalogFuture,
                                    initialCatalog: catalog,
                                  ),
                                );
                              },
                              childCount: kFriends.length,
                            ),
                          ),
                        ),
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

class _FriendCard extends StatelessWidget {
  final Friend friend;
  final Map<String, Game> catalog;
  final VoidCallback onTap;

  const _FriendCard({
    required this.friend,
    required this.catalog,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ranking = FriendsService.rankFor(friend, catalog);
    final numberOne = ranking.isEmpty ? null : ranking.first;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              FriendAvatar(friend: friend, radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (numberOne == null)
                      const Text(
                        'Ainda sem top 5',
                        style: TextStyle(color: Color(0xFF777777), fontSize: 13),
                      )
                    else ...[
                      const Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 15,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Jogo Nº 1',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        numberOne.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (numberOne != null) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 46,
                    height: 62,
                    child: GameCover(imageUrl: numberOne.game?.imageUrl),
                  ),
                ),
              ],
              const Icon(Icons.chevron_right, color: Color(0xFFB0B0B0)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFriendsCard extends StatelessWidget {
  const _EmptyFriendsCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(Icons.group_outlined, color: AppColors.blue, size: 48),
            SizedBox(height: 16),
            Text(
              'Você ainda não tem amigos por aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF222222),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
