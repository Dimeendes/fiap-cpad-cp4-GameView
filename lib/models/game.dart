class Game {
  final int? id;
  final String name;
  final String platform;
  final double score;
  final String imageUrl;

  const Game({
    this.id,
    required this.name,
    required this.platform,
    required this.score,
    required this.imageUrl,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as int?,
      name: map['name'] as String,
      platform: map['platform'] as String,
      score: (map['score'] as num).toDouble(),
      imageUrl: map['image_url'] as String,
    );
  }
}
