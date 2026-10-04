import '../models/game.dart';

abstract interface class GameService {
  Future<List<Game>> getGames();
}
