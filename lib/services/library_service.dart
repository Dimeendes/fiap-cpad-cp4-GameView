import '../models/library_entry.dart';

abstract interface class LibraryService {
  Future<List<LibraryEntry>> getLibraryEntries(String userEmail);

  Future<LibraryEntry> addToLibrary({
    required String userEmail,
    required int gameId,
  });

  Future<LibraryEntry> setRating({
    required String userEmail,
    required int gameId,
    required double userScore,
  });

  /// Preparado para a tela de review futura.
  Future<LibraryEntry> upsertReview({
    required String userEmail,
    required int gameId,
    double? userScore,
    String? reviewText,
  });

  /// Preparado para o botão de favorito futuro.
  Future<LibraryEntry> setFavorite({
    required String userEmail,
    required int gameId,
    required bool isFavorite,
  });

  /// Preparado para a lista de desejo futura.
  Future<LibraryEntry> setWishlist({
    required String userEmail,
    required int gameId,
    required bool isWishlist,
  });
}
