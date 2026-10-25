import 'package:flutter/material.dart';

import '../models/game.dart';
import 'game_cover.dart';

/// Resultado do seletor: [game] `null` significa "remover favorito".
typedef FavoriteGameChoice = ({Game? game});

/// Abre a busca no catálogo para escolher o jogo favorito do perfil.
/// Devolve `null` se o usuário cancelar.
Future<FavoriteGameChoice?> showFavoriteGamePicker(
  BuildContext context, {
  required List<Game> games,
  String? currentName,
}) {
  return showDialog<FavoriteGameChoice>(
    context: context,
    builder: (context) =>
        _FavoriteGamePicker(games: games, currentName: currentName),
  );
}

class _FavoriteGamePicker extends StatefulWidget {
  final List<Game> games;
  final String? currentName;

  const _FavoriteGamePicker({required this.games, this.currentName});

  @override
  State<_FavoriteGamePicker> createState() => _FavoriteGamePickerState();
}

class _FavoriteGamePickerState extends State<_FavoriteGamePicker> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final current = widget.currentName?.trim().toLowerCase();
    final games = widget.games
        .where((game) => game.name.toLowerCase().contains(query))
        .toList();

    return AlertDialog(
      title: const Text('Escolha seu jogo favorito'),
      content: SizedBox(
        width: 420,
        height: 460,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Buscar no catálogo',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: games.isEmpty
                  ? const Center(child: Text('Nenhum jogo encontrado.'))
                  : ListView.builder(
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        final selected = game.name.toLowerCase() == current;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 36,
                              height: 48,
                              child: GameCover(imageUrl: game.imageUrl),
                            ),
                          ),
                          title: Text(game.name),
                          subtitle: Text(
                            game.platform,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.favorite,
                                  color: Color(0xFFFF4D6D),
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop((game: game)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.currentName != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop((game: null)),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('REMOVER FAVORITO'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
      ],
    );
  }
}
