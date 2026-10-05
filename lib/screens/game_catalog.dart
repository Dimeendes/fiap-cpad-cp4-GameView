import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/game.dart';
import '../models/library_entry.dart';
import '../services/supabase_game_service.dart';
import '../services/user_library_service.dart';
import '../navigation/app_navigator.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page_header.dart';

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
  List<LibraryEntry> _libraryEntries = [];
  final Set<int> _favoriteUpdates = {};
  String? _userEmail;
  bool _isLoading = true;
  Object? _loadError;
  Object? _libraryLoadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGames());
  }

  Future<void> _loadGames() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _libraryLoadError = null;
    });

    try {
      if (!SupabaseConfig.isConfigured) {
        throw StateError(
          'O banco de jogos não está configurado. '
          'Siga as instruções do Supabase no README.md.',
        );
      }

      final games = await SupabaseGameService(Supabase.instance.client)
          .getGames();
      String? email;
      var libraryEntries = <LibraryEntry>[];
      Object? libraryError;
      try {
        final prefs = await SharedPreferences.getInstance();
        email = prefs.getString('email')?.trim();
        if (email != null && email.isNotEmpty) {
          libraryEntries = await UserLibraryService(Supabase.instance.client)
              .getLibraryEntries(email);
        }
      } catch (error) {
        libraryError = error;
      }
      if (!mounted) return;
      setState(() {
        _games = games;
        _userEmail = email == null || email.isEmpty
            ? null
            : email.toLowerCase();
        _libraryEntries = libraryEntries;
        _libraryLoadError = libraryError;
        _isLoading = false;
      });
      if (libraryError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível carregar sua biblioteca: $libraryError',
            ),
          ),
        );
      }
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

  LibraryEntry? _entryFor(Game game) {
    for (final entry in _libraryEntries) {
      if (entry.game.id == game.id) return entry;
    }
    return null;
  }

  Future<void> _openGame(Game game) async {
    if (_userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _libraryLoadError == null
                ? 'Faça login para usar sua biblioteca.'
                : 'Não foi possível carregar seu perfil: $_libraryLoadError',
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => _GameDetailsDialog(
        game: game,
        entry: _entryFor(game),
        onAddToLibrary: () => _addToLibrary(game),
        onSaveReview: (stars, reviewText) =>
            _saveReview(game, stars, reviewText),
      ),
    );
  }

  Future<void> _addToLibrary(Game game) async {
    final gameId = game.id;
    final email = _userEmail;
    if (gameId == null || email == null) {
      throw StateError('Não foi possível identificar o jogo ou o usuário.');
    }

    final entry = await UserLibraryService(Supabase.instance.client)
        .addToLibrary(userEmail: email, gameId: gameId);
    if (!mounted) return;
    setState(() {
      _libraryLoadError = null;
      _libraryEntries = [
        for (final existing in _libraryEntries)
          if (existing.game.id != gameId) existing,
        entry,
      ];
    });
  }

  Future<void> _saveReview(Game game, int? stars, String? reviewText) async {
    final gameId = game.id;
    final email = _userEmail;
    if (gameId == null || email == null) {
      throw StateError('Não foi possível identificar o jogo ou o usuário.');
    }

    final entry = await UserLibraryService(Supabase.instance.client)
        .upsertReview(
          userEmail: email,
          gameId: gameId,
          userScore: stars == null ? null : (stars * 2).toDouble(),
          reviewText: reviewText,
        );
    if (!mounted) return;
    setState(() {
      _libraryLoadError = null;
      _libraryEntries = [
        for (final existing in _libraryEntries)
          if (existing.game.id != gameId) existing,
        entry,
      ];
    });
  }

  Future<void> _toggleFavorite(Game game) async {
    final gameId = game.id;
    final email = _userEmail;
    if (gameId == null || email == null) {
      _openGame(game);
      return;
    }
    if (_favoriteUpdates.contains(gameId)) return;

    final isFavorite = !(_entryFor(game)?.isFavorite ?? false);
    setState(() => _favoriteUpdates.add(gameId));
    try {
      final entry = await UserLibraryService(
        Supabase.instance.client,
      ).setFavorite(userEmail: email, gameId: gameId, isFavorite: isFavorite);
      if (!mounted) return;
      setState(() {
        _libraryLoadError = null;
        _libraryEntries = [
          for (final existing in _libraryEntries)
            if (existing.game.id != gameId) existing,
          entry,
        ];
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível atualizar o favorito: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _favoriteUpdates.remove(gameId));
      }
    }
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
            const Icon(Icons.cloud_off_outlined, color: Colors.white, size: 48),
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
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppPageHeader(
                            title: 'Descubra seu próximo jogo',
                            subtitle: 'Uma seleção para explorar em diferentes plataformas.',
                            onOpenProfile: () =>
                                AppNavigator.openProfile(context),
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
                              isInLibrary:
                                  _entryFor(filteredGames[index])
                                      ?.isInLibrary ??
                                  false,
                              isFavorite:
                                  _entryFor(filteredGames[index])?.isFavorite ??
                                  false,
                              isUpdatingFavorite:
                                  filteredGames[index].id != null &&
                                  _favoriteUpdates.contains(
                                    filteredGames[index].id,
                                  ),
                              onToggleFavorite: () =>
                                  _toggleFavorite(filteredGames[index]),
                              onTap: () => _openGame(filteredGames[index]),
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
          bottom: false,
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
  final bool isInLibrary;
  final bool isFavorite;
  final bool isUpdatingFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.showScore,
    required this.isInLibrary,
    required this.isFavorite,
    required this.isUpdatingFavorite,
    required this.onToggleFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
            if (isInLibrary)
              const Positioned(
                top: 8,
                left: 8,
                child: Icon(
                  Icons.check_circle,
                  color: Colors.lightGreenAccent,
                  size: 25,
                  semanticLabel: 'Na biblioteca',
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: isFavorite
                      ? 'Remover dos favoritos'
                      : 'Adicionar aos favoritos',
                  onPressed: isUpdatingFavorite ? null : onToggleFavorite,
                  icon: isUpdatingFavorite
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? const Color(0xFFFF4D6D)
                              : Colors.white,
                        ),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            const Positioned(
              left: 8,
              top: 8,
              child: Icon(
                Icons.open_in_new,
                color: Colors.white,
                size: 18,
                semanticLabel: 'Ver detalhes do jogo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameDetailsDialog extends StatefulWidget {
  final Game game;
  final LibraryEntry? entry;
  final Future<void> Function() onAddToLibrary;
  final Future<void> Function(int? stars, String? reviewText) onSaveReview;

  const _GameDetailsDialog({
    required this.game,
    required this.entry,
    required this.onAddToLibrary,
    required this.onSaveReview,
  });

  @override
  State<_GameDetailsDialog> createState() => _GameDetailsDialogState();
}

class _GameDetailsDialogState extends State<_GameDetailsDialog> {
  late final TextEditingController _reviewController;
  late int _selectedRating;
  late bool _isInLibrary;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = ((widget.entry?.userScore ?? 0) / 2).round();
    _isInLibrary = widget.entry?.isInLibrary ?? false;
    _reviewController = TextEditingController(
      text: widget.entry?.reviewText ?? '',
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _save(
    Future<void> Function() action, {
    bool closeOnSuccess = false,
  }) async {
    setState(() => _isSaving = true);
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isInLibrary = true;
      });
      if (closeOnSuccess) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.game.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.game.platform),
          const SizedBox(height: 20),
          const Text(
            'Sua avaliação',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final stars = index + 1;
              return IconButton(
                tooltip: '$stars ${stars == 1 ? 'estrela' : 'estrelas'}',
                onPressed: _isSaving
                    ? null
                    : () => setState(() => _selectedRating = stars),
                icon: Icon(
                  stars <= _selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            enabled: !_isSaving,
            maxLines: 4,
            maxLength: 1000,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Sua review',
              hintText: 'O que você achou deste jogo?',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          if (_isInLibrary)
            const Center(child: Text('Este jogo já está na sua biblioteca.')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('FECHAR'),
        ),
        if (!_isInLibrary)
          FilledButton.icon(
            onPressed: _isSaving
                ? null
                : () => _save(widget.onAddToLibrary, closeOnSuccess: true),
            icon: const Icon(Icons.library_add_outlined),
            label: const Text('ADICIONAR À BIBLIOTECA'),
          ),
        FilledButton(
          onPressed:
              _isSaving ||
                  (_selectedRating == 0 &&
                      _reviewController.text.trim().isEmpty &&
                      (widget.entry?.reviewText?.trim().isEmpty ?? true))
              ? null
              : () => _save(
                  () => widget.onSaveReview(
                    _selectedRating == 0 ? null : _selectedRating,
                    _reviewController.text.trim().isEmpty
                        ? null
                        : _reviewController.text.trim(),
                  ),
                ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('SALVAR REVIEW'),
        ),
      ],
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
