import 'package:flutter/material.dart';

class ScoreStars extends StatelessWidget {
  final double score;
  final double size;

  const ScoreStars({super.key, required this.score, this.size = 16});

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
            width: size,
            height: size,
            child: Stack(
              children: [
                Icon(Icons.star, size: size, color: Colors.white38),
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: fill,
                    child: Icon(Icons.star, size: size, color: Colors.amber),
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
