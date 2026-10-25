class Game {
  final int? id;
  final String name;
  final String platform;
  final double score;
  final String imageUrl;
  final String description;

  const Game({
    this.id,
    required this.name,
    required this.platform,
    required this.score,
    required this.imageUrl,
    this.description = '',
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as int?,
      name: map['name'] as String,
      platform: map['platform'] as String,
      score: (map['score'] as num).toDouble(),
      imageUrl: map['image_url'] as String,
      description: map['description'] as String? ?? '',
    );
  }
}
