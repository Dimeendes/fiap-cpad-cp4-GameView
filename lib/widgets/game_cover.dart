import 'package:flutter/material.dart';

/// Capa de jogo com os mesmos estados de carregamento/erro do catálogo e da
/// biblioteca. Preenche o espaço que o pai der (use SizedBox/AspectRatio).
///
/// Sem [imageUrl] (jogo não encontrado no catálogo) mostra um placeholder.
class GameCover extends StatelessWidget {
  final String? imageUrl;

  const GameCover({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null) {
      return const _CoverPlaceholder(icon: Icons.sports_esports_outlined);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) {
        return const _CoverPlaceholder(icon: Icons.broken_image_outlined);
      },
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final IconData icon;

  const _CoverPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF0F3F8),
      child: Center(
        child: Icon(icon, size: 28, color: const Color(0xFFB0B0B0)),
      ),
    );
  }
}
