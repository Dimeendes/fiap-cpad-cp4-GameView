import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/library_entry.dart';
import '../navigation/app_navigator.dart';
import '../services/user_library_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page_header.dart';
import '../widgets/custom_button.dart';

enum _LibraryFilter {
  alphabeticalAsc,
  alphabeticalDesc,
  scoreHighToLow,
  scoreLowToHigh,
  wishlist,
  favorites,
}

const _emptyMessages = [
  'Você pensa na grande possibilidade de jogos para se avaliar e isso te enche de determinação.',
  'É perigoso ir sozinho! Avalie esse jogo.',
  'Parece que seus jogos estão em outro castelo',
  'Temos que avaliar!',
];

class GamesLibraryScreen extends StatefulWidget {
  final VoidCallback? onGoToCatalog;

  const GamesLibraryScreen({super.key, this.onGoToCatalog});

  @override
  State<GamesLibraryScreen> createState() => GamesLibraryScreenState();
}

class GamesLibraryScreenState extends State<GamesLibraryScreen> {
  _LibraryFilter _filter = _LibraryFilter.alphabeticalAsc;
  List<LibraryEntry> _entries = [];
  bool _isLoading = true;
  Object? _loadError;
  String? _userEmail;
  late String _emptyMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLibrary());
  }

  Future<void> reload() => _loadLibrary();

  Future<void> _loadLibrary() async {
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

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email')?.trim() ?? '';
      if (email.isEmpty) {
        throw StateError(
          'Não encontramos o e-mail do perfil. Faça login novamente.',
        );
      }

      final entries = await UserLibraryService(Supabase.instance.client)
          .getLibraryEntries(email);

      if (!mounted) return;
      setState(() {
        _userEmail = email.toLowerCase();
        _entries = entries;
        if (entries.isEmpty) {
          _emptyMessage =
              _emptyMessages[Random().nextInt(_emptyMessages.length)];
        }
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

  List<LibraryEntry> get _reviewedEntries =>
      _entries.where((entry) => entry.hasReview).toList();

  List<LibraryEntry> get _visibleEntries {
    late final List<LibraryEntry> source;

    switch (_filter) {
      case _LibraryFilter.wishlist:
        source = _entries.where((entry) => entry.isWishlist).toList();
      case _LibraryFilter.favorites:
        source = _entries.where((entry) => entry.isFavorite).toList();
      case _LibraryFilter.alphabeticalAsc:
      case _LibraryFilter.alphabeticalDesc:
      case _LibraryFilter.scoreHighToLow:
      case _LibraryFilter.scoreLowToHigh:
        source = List<LibraryEntry>.from(_reviewedEntries);
    }

    source.sort((a, b) {
      switch (_filter) {
        case _LibraryFilter.alphabeticalDesc:
          return b.game.name.toLowerCase().compareTo(a.game.name.toLowerCase());
        case _LibraryFilter.scoreHighToLow:
          return _compareScore(b, a);
        case _LibraryFilter.scoreLowToHigh:
          return _compareScore(a, b);
        case _LibraryFilter.alphabeticalAsc:
        case _LibraryFilter.wishlist:
        case _LibraryFilter.favorites:
          return a.game.name.toLowerCase().compareTo(b.game.name.toLowerCase());
      }
    });

    return source;
  }

  int _compareScore(LibraryEntry a, LibraryEntry b) {
    final scoreA = a.userScore ?? -1;
    final scoreB = b.userScore ?? -1;
    final byScore = scoreA.compareTo(scoreB);
    if (byScore != 0) return byScore;
    return a.game.name.toLowerCase().compareTo(b.game.name.toLowerCase());
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
              'Não foi possível carregar a biblioteca.',
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
              onPressed: _loadLibrary,
              child: const Text('TENTAR NOVAMENTE'),
            ),
          ],
        ),
      );
    }

    final hasLibraryGames = _entries.isNotEmpty;
    final visibleEntries = _visibleEntries;

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
                            title: 'Sua biblioteca',
                            subtitle: _userEmail == null
                                ? 'Jogos avaliados, favoritos e lista de desejo.'
                                : 'Biblioteca de $_userEmail',
                            onOpenProfile: () =>
                                AppNavigator.openProfile(context),
                          ),
                          if (hasLibraryGames) ...[
                            const SizedBox(height: 22),
                            _FilterCard(
                              filter: _filter,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _filter = value);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!hasLibraryGames)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: _EmptyLibraryCard(
                          message: _emptyMessage,
                          onGoToCatalog: widget.onGoToCatalog ?? () {},
                        ),
                      ),
                    )
                  else if (visibleEntries.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 36,
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.filter_alt_off_outlined,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Nenhum jogo encontrado para este filtro.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.76,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _LibraryGameCard(
                            entry: visibleEntries[index],
                            showScore:
                                _filter == _LibraryFilter.scoreHighToLow ||
                                _filter == _LibraryFilter.scoreLowToHigh ||
                                visibleEntries[index].userScore != null,
                          ),
                          childCount: visibleEntries.length,
                        ),
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: AppPageHeader(
                  title: 'Sua biblioteca',
                  onOpenProfile: () => AppNavigator.openProfile(context),
                ),
              ),
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final _LibraryFilter filter;
  final ValueChanged<_LibraryFilter?> onChanged;

  const _FilterCard({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const Icon(Icons.tune, color: AppColors.blue, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Filtrar biblioteca',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF222222),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<_LibraryFilter>(
            initialValue: filter,
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
                value: _LibraryFilter.alphabeticalAsc,
                child: Text('Alfabética (A-Z)'),
              ),
              DropdownMenuItem(
                value: _LibraryFilter.alphabeticalDesc,
                child: Text('Alfabética (Z-A)'),
              ),
              DropdownMenuItem(
                value: _LibraryFilter.scoreHighToLow,
                child: Text('Nota (maior → menor)'),
              ),
              DropdownMenuItem(
                value: _LibraryFilter.scoreLowToHigh,
                child: Text('Nota (menor → maior)'),
              ),
              DropdownMenuItem(
                value: _LibraryFilter.wishlist,
                child: Text('Lista de desejo'),
              ),
              DropdownMenuItem(
                value: _LibraryFilter.favorites,
                child: Text('Favoritos'),
              ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _EmptyLibraryCard extends StatelessWidget {
  final String message;
  final VoidCallback onGoToCatalog;

  const _EmptyLibraryCard({required this.message, required this.onGoToCatalog});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_esports_outlined,
              color: AppColors.blue,
              size: 48,
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF222222),
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(text: 'IR AO CATÁLOGO', onPressed: onGoToCatalog),
          ],
        ),
      ),
    );
  }
}

class _LibraryGameCard extends StatelessWidget {
  final LibraryEntry entry;
  final bool showScore;

  const _LibraryGameCard({required this.entry, required this.showScore});

  @override
  Widget build(BuildContext context) {
    final score = entry.userScore ?? entry.game.score;

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
            entry.game.imageUrl,
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
          if (entry.isFavorite)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFFFF4D6D),
                  size: 16,
                ),
              ),
            ),
          if (showScore)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.black54,
                child: _UserScoreStars(score: score),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserScoreStars extends StatelessWidget {
  final double score;

  const _UserScoreStars({required this.score});

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
