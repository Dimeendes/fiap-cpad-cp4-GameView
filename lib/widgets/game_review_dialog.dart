import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/library_entry.dart';
import '../services/friends_service.dart';
import '../services/library_service.dart';
import '../utils/date_format.dart';
import 'friend_avatar.dart';
import 'game_cover.dart';

/// Página do jogo (catálogo e biblioteca): descrição, favorito, "quero jogar",
/// nota + análise editáveis e o que os amigos acharam.
///
/// Cada alteração salva é repassada em [onChanged] para a tela atualizar.
class GameReviewDialog extends StatefulWidget {
  final Game game;
  final LibraryEntry? entry;
  final String userEmail;
  final LibraryService service;
  final List<FriendActivity> friendsWhoPlayed;
  final ValueChanged<LibraryEntry> onChanged;

  const GameReviewDialog({
    super.key,
    required this.game,
    required this.entry,
    required this.userEmail,
    required this.service,
    required this.onChanged,
    this.friendsWhoPlayed = const [],
  });

  @override
  State<GameReviewDialog> createState() => _GameReviewDialogState();
}

class _GameReviewDialogState extends State<GameReviewDialog> {
  late final TextEditingController _reviewController;
  late LibraryEntry? _entry = widget.entry;
  late int _selectedRating;
  bool _isSaving = false;

  int get _gameId {
    final id = widget.game.id;
    if (id == null) {
      throw StateError('Não foi possível identificar o jogo.');
    }
    return id;
  }

  bool get _hasSavedReview => _entry?.hasReview ?? false;

  @override
  void initState() {
    super.initState();
    _selectedRating = ((widget.entry?.userScore ?? 0) / 2).round();
    _reviewController = TextEditingController(
      text: widget.entry?.reviewText ?? '',
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<LibraryEntry> Function() action, {
    bool closeOnSuccess = false,
  }) async {
    setState(() => _isSaving = true);
    try {
      final entry = await action();
      widget.onChanged(entry);
      if (!mounted) return;
      setState(() {
        _entry = entry;
        _isSaving = false;
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

  void _toggleFavorite() {
    _run(
      () => widget.service.setFavorite(
        userEmail: widget.userEmail,
        gameId: _gameId,
        isFavorite: !(_entry?.isFavorite ?? false),
      ),
    );
  }

  void _toggleWishlist() {
    _run(
      () => widget.service.setWishlist(
        userEmail: widget.userEmail,
        gameId: _gameId,
        isWishlist: !(_entry?.isWishlist ?? false),
      ),
    );
  }

  void _saveReview() {
    final text = _reviewController.text.trim();
    _run(
      () => widget.service.upsertReview(
        userEmail: widget.userEmail,
        gameId: _gameId,
        userScore: _selectedRating == 0 ? null : (_selectedRating * 2).toDouble(),
        reviewText: text.isEmpty ? null : text,
      ),
      closeOnSuccess: true,
    );
  }

  Future<void> _deleteReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar avaliação?'),
        content: const Text(
          'Sua nota e sua análise deste jogo serão removidas. '
          'O jogo continua na biblioteca.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('APAGAR'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _reviewController.clear();
    setState(() => _selectedRating = 0);
    _run(
      () => widget.service.upsertReview(
        userEmail: widget.userEmail,
        gameId: _gameId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final isFavorite = entry?.isFavorite ?? false;
    final isWishlist = entry?.isWishlist ?? false;
    final loggedAt = formatLoggedDate(entry?.loggedAtMillis);
    final canSave =
        !_isSaving &&
        (_selectedRating != 0 ||
            _reviewController.text.trim().isNotEmpty ||
            _hasSavedReview);

    return AlertDialog(
      scrollable: true,
      title: Text(widget.game.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.game.platform),
                    const SizedBox(height: 8),
                    Text(
                      widget.game.description.trim().isEmpty
                          ? 'Descrição não cadastrada no banco de dados.'
                          : widget.game.description,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 112,
                  height: 168,
                  child: GameCover(imageUrl: widget.game.imageUrl),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                selected: isFavorite,
                onSelected: _isSaving ? null : (_) => _toggleFavorite(),
                avatar: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: const Color(0xFFFF4D6D),
                  size: 18,
                ),
                showCheckmark: false,
                label: Text(isFavorite ? 'Favorito' : 'Favoritar'),
              ),
              FilterChip(
                selected: isWishlist,
                onSelected: _isSaving ? null : (_) => _toggleWishlist(),
                avatar: Icon(
                  isWishlist ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.teal,
                  size: 18,
                ),
                showCheckmark: false,
                label: const Text('Quero jogar'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  _hasSavedReview ? 'Sua avaliação' : 'Avaliar',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (loggedAt.isNotEmpty && _hasSavedReview)
                Text(
                  'Registrado em $loggedAt',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
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
                    : () => setState(
                        // Tocar de novo na mesma estrela limpa a nota.
                        () => _selectedRating = _selectedRating == stars
                            ? 0
                            : stars,
                      ),
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
              labelText: 'Sua análise',
              hintText: 'O que você achou deste jogo?',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: [
              if (_hasSavedReview)
                TextButton(
                  onPressed: _isSaving ? null : _deleteReview,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('APAGAR'),
                ),
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text('FECHAR'),
              ),
              FilledButton(
                onPressed: canSave ? _saveReview : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_hasSavedReview ? 'SALVAR ANÁLISE' : 'AVALIAR'),
              ),
            ],
          ),
          if (widget.friendsWhoPlayed.isNotEmpty) ...[
            const Divider(height: 32),
            Text(
              'Amigos que jogaram',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in widget.friendsWhoPlayed)
              _FriendRatingRow(item: item),
          ],
        ],
      ),
    );
  }
}

class _FriendRatingRow extends StatelessWidget {
  final FriendActivity item;

  const _FriendRatingRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final stars = (item.review.userScore / 2).round().clamp(0, 5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FriendAvatar(friend: item.friend, radius: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.friend.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${'★' * stars}${'☆' * (5 - stars)}',
                      semanticsLabel: '$stars de 5 estrelas',
                      style: const TextStyle(color: Colors.amber),
                    ),
                  ],
                ),
                if (item.review.hasAnalysis)
                  Text(
                    item.review.reviewText.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
