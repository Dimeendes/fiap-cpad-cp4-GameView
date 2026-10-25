import 'package:flutter/material.dart';

import '../models/friend.dart';
import '../models/game.dart';
import '../navigation/app_navigator.dart';
import '../services/friends_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page_header.dart';
import '../widgets/friend_avatar.dart';
import '../utils/date_format.dart';
import '../widgets/game_cover.dart';

enum _FriendsTab { friends, accounts }

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final _searchController = TextEditingController();
  _FriendsTab _tab = _FriendsTab.friends;
  FriendsDirectory _directory = const FriendsDirectory(
    accounts: [],
    followedIds: {},
  );
  late final Future<Map<String, Game>> _catalogFuture;

  @override
  void initState() {
    super.initState();
    _catalogFuture = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, Game>> _load() async {
    final directory = await FriendsService.loadDirectory();
    if (mounted) {
      setState(() => _directory = directory);
    } else {
      _directory = directory;
    }
    return FriendsService.loadCatalogFor(directory.accounts);
  }

  Future<void> _reloadDirectory() async {
    final directory = await FriendsService.loadDirectory();
    if (!mounted) return;
    setState(() => _directory = directory);
  }

  Future<void> _openAccount(
    Friend account,
    Map<String, Game> catalog,
  ) async {
    await AppNavigator.openFriendProfile(
      context,
      friend: account,
      catalogFuture: _catalogFuture,
      initialCatalog: catalog,
      isFollowing: _directory.followedIds.contains(account.accountId),
    );
    await _reloadDirectory();
  }

  Future<void> _toggleFollow(Friend account, {required bool follow}) async {
    await FriendsService.setFollowing(
      accountId: account.accountId,
      following: follow,
    );
    await _reloadDirectory();
  }

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
                  final query = _searchController.text;
                  final recommended = _directory.recommended;
                  final friends = _directory.searchFriends(query);
                  final activity = _directory.friendsActivity();
                  final accounts = _directory.searchAccounts(query);
                  final searching = query.trim().isNotEmpty;

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        sliver: SliverToBoxAdapter(
                          child: AppPageHeader(
                            title: 'Amigos',
                            subtitle:
                                'Encontre contas, siga recomendações e veja '
                                'o que a galera anda jogando.',
                            onOpenProfile: () =>
                                AppNavigator.openProfile(context),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                        sliver: SliverToBoxAdapter(
                          child: _SearchField(
                            controller: _searchController,
                            hintText: _tab == _FriendsTab.friends
                                ? 'Buscar amigos'
                                : 'Buscar contas',
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        sliver: SliverToBoxAdapter(
                          child: _TabBar(
                            tab: _tab,
                            onChanged: (tab) => setState(() => _tab = tab),
                          ),
                        ),
                      ),
                      if (_tab == _FriendsTab.friends && !searching) ...[
                        if (recommended.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                            sliver: SliverToBoxAdapter(
                              child: _RecommendedSection(
                                accounts: recommended,
                                catalog: catalog,
                                onFollow: (account) =>
                                    _toggleFollow(account, follow: true),
                                onOpen: (account) =>
                                    _openAccount(account, catalog),
                              ),
                            ),
                          ),
                        if (activity.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                            sliver: SliverToBoxAdapter(
                              child: _ActivitySection(
                                items: activity,
                                catalog: catalog,
                                onOpen: (account) =>
                                    _openAccount(account, catalog),
                              ),
                            ),
                          ),
                        if (friends.isEmpty)
                          const SliverToBoxAdapter(child: _EmptyFriendsCard())
                        else
                          _accountsSliver(
                            title: 'Seus amigos',
                            accounts: friends,
                            catalog: catalog,
                            followedIds: _directory.followedIds,
                          ),
                      ] else if (_tab == _FriendsTab.friends) ...[
                        if (friends.isEmpty)
                          const SliverToBoxAdapter(
                            child: _EmptySearchCard(
                              message: 'Nenhum amigo encontrado com esse nome.',
                            ),
                          )
                        else
                          _accountsSliver(
                            title: 'Amigos',
                            accounts: friends,
                            catalog: catalog,
                            followedIds: _directory.followedIds,
                          ),
                      ] else ...[
                        if (accounts.isEmpty)
                          const SliverToBoxAdapter(
                            child: _EmptySearchCard(
                              message: 'Nenhuma conta encontrada.',
                            ),
                          )
                        else
                          _accountsSliver(
                            title: searching ? 'Contas' : 'Todas as contas',
                            accounts: accounts,
                            catalog: catalog,
                            followedIds: _directory.followedIds,
                          ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
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

  Widget _accountsSliver({
    required String title,
    required List<Friend> accounts,
    required Map<String, Game> catalog,
    required Set<String> followedIds,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (final account in accounts) ...[
            _AccountRow(
              friend: account,
              catalog: catalog,
              isFollowing: followedIds.contains(account.accountId),
              onTap: () => _openAccount(account, catalog),
              onFollow: account.isCurrentUser
                  ? null
                  : () => _toggleFollow(
                      account,
                      follow: !followedIds.contains(account.accountId),
                    ),
            ),
            const SizedBox(height: 10),
          ],
        ]),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Color(0xFF222222)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF888888)),
        prefixIcon: const Icon(Icons.search, color: AppColors.blue),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final _FriendsTab tab;
  final ValueChanged<_FriendsTab> onChanged;

  const _TabBar({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabChip(
            label: 'Amigos',
            selected: tab == _FriendsTab.friends,
            onTap: () => onChanged(_FriendsTab.friends),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TabChip(
            label: 'Contas',
            selected: tab == _FriendsTab.accounts,
            onTap: () => onChanged(_FriendsTab.accounts),
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.blue : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendedSection extends StatelessWidget {
  final List<Friend> accounts;
  final Map<String, Game> catalog;
  final ValueChanged<Friend> onFollow;
  final ValueChanged<Friend> onOpen;

  const _RecommendedSection({
    required this.accounts,
    required this.catalog,
    required this.onFollow,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amigos recomendados',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        for (final account in accounts) ...[
          _RecommendedCard(
            friend: account,
            catalog: catalog,
            onFollow: () => onFollow(account),
            onOpen: () => onOpen(account),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final Friend friend;
  final Map<String, Game> catalog;
  final VoidCallback onFollow;
  final VoidCallback onOpen;

  const _RecommendedCard({
    required this.friend,
    required this.catalog,
    required this.onFollow,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final favorite = FriendsService.favoriteFor(friend, catalog);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              FriendAvatar(friend: friend, radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (friend.displayHandle.isNotEmpty)
                      Text(
                        friend.displayHandle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 12,
                        ),
                      ),
                    if (favorite != null)
                      Text(
                        'Favorito: ${favorite.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onFollow,
                child: const Text('Seguir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final Friend friend;
  final Map<String, Game> catalog;
  final bool isFollowing;
  final VoidCallback onTap;
  final VoidCallback? onFollow;

  const _AccountRow({
    required this.friend,
    required this.catalog,
    required this.isFollowing,
    required this.onTap,
    this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final favorite = FriendsService.favoriteFor(friend, catalog);

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.isCurrentUser ? '${friend.name} (você)' : friend.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (friend.displayHandle.isNotEmpty)
                      Text(
                        friend.displayHandle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 12,
                        ),
                      ),
                    if (favorite != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Favorito: ${favorite.name}',
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
              if (favorite != null) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 40,
                    height: 54,
                    child: GameCover(imageUrl: favorite.game?.imageUrl),
                  ),
                ),
              ],
              if (onFollow != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onFollow,
                  child: Text(isFollowing ? 'Seguindo' : 'Seguir'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Feed com as avaliações mais recentes de quem você segue.
class _ActivitySection extends StatelessWidget {
  final List<FriendActivity> items;
  final Map<String, Game> catalog;
  final ValueChanged<Friend> onOpen;

  const _ActivitySection({
    required this.items,
    required this.catalog,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atividade dos amigos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        for (final item in items) ...[
          _ActivityRow(
            item: item,
            game: FriendsService.resolveReview(item.review, catalog).game,
            onTap: () => onOpen(item.friend),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final FriendActivity item;
  final Game? game;
  final VoidCallback onTap;

  const _ActivityRow({required this.item, required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final review = item.review;
    final stars = (review.userScore / 2).round().clamp(0, 5);
    final date = formatLoggedDate(review.ratedAtMillis);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 60,
                  child: GameCover(imageUrl: game?.imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FriendAvatar(friend: item.friend, radius: 10),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            review.hasAnalysis
                                ? '${item.friend.name} analisou'
                                : '${item.friend.name} avaliou',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (date.isNotEmpty)
                          Text(
                            date,
                            style: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.gameName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${'★' * stars}${'☆' * (5 - stars)}',
                      semanticsLabel: '$stars de 5 estrelas',
                      style: const TextStyle(color: Colors.amber, fontSize: 14),
                    ),
                    if (review.hasAnalysis) ...[
                      const SizedBox(height: 4),
                      Text(
                        review.reviewText.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF444444),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: _MessageCard(
        icon: Icons.group_outlined,
        message: 'Você ainda não segue ninguém. Use as recomendações ou busque contas.',
      ),
    );
  }
}

class _EmptySearchCard extends StatelessWidget {
  final String message;

  const _EmptySearchCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: _MessageCard(icon: Icons.search_off, message: message),
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
