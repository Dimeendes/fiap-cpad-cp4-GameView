import 'package:shared_preferences/shared_preferences.dart';

import 'user_identity_service.dart';

/// Jogo favorito escolhido manualmente no perfil (destaque único, como o
/// favorito das outras contas). Independe dos favoritos da biblioteca.
class FavoriteGameService {
  const FavoriteGameService._();

  static String storageKeyFor(String accountId) =>
      'profile_favorite_game_$accountId';

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    // Só leitura: sem conta criada ainda, não há favorito salvo.
    final accountId = prefs.getString(
      UserIdentityService.accountIdPreferenceKey,
    );
    if (accountId == null || accountId.isEmpty) return null;
    final name = prefs.getString(storageKeyFor(accountId))?.trim();
    return name == null || name.isEmpty ? null : name;
  }

  /// Salva o nome do jogo; `null` remove o favorito.
  static Future<void> save(String? gameName) async {
    final prefs = await SharedPreferences.getInstance();
    final accountId = await UserIdentityService().getOrCreateAccountId();
    final key = storageKeyFor(accountId);
    final name = gameName?.trim();
    if (name == null || name.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, name);
    }
  }
}
