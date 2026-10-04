import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/game.dart';
import '../services/supabase_game_service.dart';
import '../theme/app_colors.dart';
import 'profile.dart';

enum _GameSortOrder { alphabetical, score }

void main() {
  runApp(const GameCatalog());
}

class GameCatalog extends StatefulWidget {
  const GameCatalog({super.key});

  @override
  State<GameCatalog> createState() => _GameCatalogState();
}

class _GameCatalogState extends State<GameCatalog> {
  final TextEditingController _searchController = TextEditingController();
  _GameSortOrder _sortOrder = _GameSortOrder.alphabetical;
  List<Game> _games = [];
  bool _isLoading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGames());
  }

  Future<void> _loadGames() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      if (!SupabaseConfig.isConfigured) {
        throw StateError(
          'O banco de jogos não está configurado. '
          'Siga as instruções do Supabase no README.md.',
        );
      }

      final games = await SupabaseGameService(
        Supabase.instance.client,
      ).getGames();
      if (!mounted) return;
      setState(() {
        _games = games;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  List<Game> get _filteredGames {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _games.where((game) {
      return query.isEmpty ||
          game.name.toLowerCase().contains(query) ||
          game.platform.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      if (_sortOrder == _GameSortOrder.score) {
        final scoreComparison = b.score.compareTo(a.score);
        if (scoreComparison != 0) return scoreComparison;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildStatusScreen(
        const CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_loadError != null) {
      return _buildStatusScreen(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Não foi possível carregar os jogos do Supabase.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '$_loadError',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadGames,
              child: const Text('TENTAR NOVAMENTE'),
            ),
          ],
        ),
      );
    }

    final filteredGames = _filteredGames;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.sports_esports,
                                color: Colors.white,
                                size: 30,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'GameView',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Meu perfil',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.account_circle_outlined,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Descubra seu próximo jogo',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Uma seleção para explorar em diferentes plataformas.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Pesquisar jogo ou plataforma',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Limpar pesquisa',
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.swap_vert,
                                      color: AppColors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Ordenar catálogo',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF222222),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<_GameSortOrder>(
                                  initialValue: _sortOrder,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF0F3F8),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: _GameSortOrder.alphabetical,
                                      child: Text(
                                        'Ordem alfabética',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: _GameSortOrder.score,
                                      child: Text(
                                        'GameView Score (maior primeiro)',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  onChanged: (order) {
                                    if (order == null) return;
                                    setState(() => _sortOrder = order);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        if (filteredGames.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 36),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.search_off,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Nenhum jogo encontrado',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.76,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _GameCard(
                              game: filteredGames[index],
                              showScore: _sortOrder == _GameSortOrder.score,
                            ),
                            childCount: filteredGames.length,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusScreen(Widget content) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Game game;
  final bool showScore;

  const _GameCard({required this.game, required this.showScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            game.imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(
                color: Color(0xFFF0F3F8),
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 40,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
              );
            },
          ),
          if (showScore)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.black54,
                child: _GameScoreStars(score: game.score),
              ),
            ),
        ],
      ),
    );
  }
}

class _GameScoreStars extends StatelessWidget {
  final double score;

  const _GameScoreStars({required this.score});

  @override
  Widget build(BuildContext context) {
    final rating = (score / 2).clamp(0.0, 5.0);

    return Semantics(
      label: 'Nota ${score.toStringAsFixed(1)} de 10',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final fill = (rating - index).clamp(0.0, 1.0);
          return SizedBox(
            width: 16,
            height: 16,
            child: Stack(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.white38),
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: fill,
                    child: const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
