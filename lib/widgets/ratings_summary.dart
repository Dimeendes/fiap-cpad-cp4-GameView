import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Estatísticas de uma conta no estilo Letterboxd: totais, média e o
/// histograma de notas de 1 a 5 estrelas.
///
/// [scores] são as notas na escala do app (0–10, 2 pontos por estrela).
class RatingsSummary extends StatelessWidget {
  final List<double> scores;
  final int analysisCount;
  final int? wishlistCount;

  const RatingsSummary({
    super.key,
    required this.scores,
    required this.analysisCount,
    this.wishlistCount,
  });

  /// Quantidade de notas por estrela (índice 0 = 1 estrela).
  static List<int> histogram(List<double> scores) {
    final buckets = List<int>.filled(5, 0);
    for (final score in scores) {
      final stars = (score / 2).round().clamp(1, 5);
      buckets[stars - 1]++;
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final buckets = histogram(scores);
    final highest = buckets.fold<int>(0, (max, value) => value > max ? value : max);
    final average = scores.isEmpty
        ? null
        : scores.reduce((a, b) => a + b) / scores.length / 2;

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
              _Stat(value: '${scores.length}', label: 'Jogos'),
              _Stat(value: '$analysisCount', label: 'Análises'),
              _Stat(
                value: average == null ? '–' : average.toStringAsFixed(1),
                label: 'Média ★',
              ),
              if (wishlistCount != null)
                _Stat(value: '$wishlistCount', label: 'Quero jogar'),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Distribuição das notas',
            style: TextStyle(
              color: Color(0xFF777777),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < buckets.length; i++)
                  Expanded(
                    child: Semantics(
                      label:
                          '${buckets[i]} ${buckets[i] == 1 ? 'jogo' : 'jogos'} '
                          'com ${i + 1} ${i == 0 ? 'estrela' : 'estrelas'}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${buckets[i]}',
                              style: const TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              height: highest == 0
                                  ? 4
                                  : 4 + 44 * buckets[i] / highest,
                              decoration: BoxDecoration(
                                color: buckets[i] == 0
                                    ? const Color(0xFFE3E8F0)
                                    : AppColors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Expanded(
                  child: Text(
                    '$i★',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF222222),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
