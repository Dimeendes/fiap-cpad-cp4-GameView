import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/game.dart';
import '../models/library_entry.dart';
import '../services/favorite_game_service.dart';
import '../services/profile_photo_service.dart';
import '../services/supabase_game_service.dart';
import '../services/user_identity_service.dart';
import '../services/user_library_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../widgets/favorite_game_card.dart';
import '../widgets/favorite_game_picker.dart';
import '../widgets/game_cover.dart';
import '../widgets/ratings_summary.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<SharedPreferences> _preferences =
      SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    ProfilePhotoService.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<String?> _selectProfilePhoto(BuildContext dialogContext) async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Selecionar foto de perfil',
        type: FileType.image,
        compressionQuality: 85,
      );
      if (file == null) return null;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw StateError('O arquivo selecionado está vazio.');
      }

      final extension = (file.extension ?? '').toLowerCase();
      const supportedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'bmp'};
      if (!supportedExtensions.contains(extension)) {
        throw StateError('Selecione uma imagem JPG, PNG, WEBP ou BMP.');
      }

      final appDirectory = await getApplicationSupportDirectory();
      final photoDirectory = Directory(
        '${appDirectory.path}${Platform.pathSeparator}profile_photos',
      );
      await photoDirectory.create(recursive: true);
      final photoFile = File(
        '${photoDirectory.path}${Platform.pathSeparator}'
        'profile_${DateTime.now().microsecondsSinceEpoch}.$extension',
      );
      await photoFile.writeAsBytes(bytes, flush: true);
      await ProfilePhotoService.save(photoFile.path);

      if (!mounted || !dialogContext.mounted) return null;
      return photoFile.path;
    } catch (error) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text('Não foi possível alterar a foto: $error')),
        );
      }
      return null;
    }
  }

  Future<void> _editarPerfil(
    BuildContext context,
    String nomeAtual,
    String emailAtual,
  ) async {
    await ProfilePhotoService.load();
    if (!mounted || !context.mounted) return;

    final nomeController = TextEditingController(text: nomeAtual);
    final emailController = TextEditingController(text: emailAtual);
    var photoPath = ProfilePhotoService.photoPath.value;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar perfil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final selectedPath = await _selectProfilePhoto(context);
                      if (selectedPath != null) {
                        setDialogState(() => photoPath = selectedPath);
                        if (mounted) setState(() {});
                      }
                    },
                    customBorder: const CircleBorder(),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: const Color(0xFFEAF2FF),
                          backgroundImage:
                              photoPath != null && File(photoPath!).existsSync()
                              ? FileImage(File(photoPath!))
                              : null,
                          child:
                              photoPath == null ||
                                  !File(photoPath!).existsSync()
                              ? const Icon(
                                  Icons.person_outline,
                                  color: AppColors.blue,
                                  size: 44,
                                )
                              : null,
                        ),
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.blue,
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Toque na foto para alterá-la'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await UserIdentityService().updateActiveAccount(
                        name: nomeController.text.trim(),
                        email: emailController.text.trim(),
                      );
                    } on StateError catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error.message)));
                      }
                      return;
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      setState(() {});
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    nomeController.dispose();
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: FutureBuilder<SharedPreferences>(
                  future: _preferences,
                  builder: (context, snapshot) {
                    final preferences = snapshot.data;
                    final name = preferences?.getString('nome') ?? 'Usuário';
                    final email = preferences?.getString('email') ?? '';
                    final photoPath = ProfilePhotoService.photoPath.value;
                    final hasPhoto =
                        photoPath != null && File(photoPath).existsSync();

                    final card = Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            tooltip: 'Voltar ao catálogo',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppColors.blue,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: const Color(0xFFEAF2FF),
                              backgroundImage: hasPhoto
                                  ? FileImage(File(photoPath))
                                  : null,
                              child: hasPhoto
                                  ? null
                                  : const Icon(
                                      Icons.person_outline,
                                      color: AppColors.blue,
                                      size: 44,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: Text(
                              snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? 'Carregando perfil...'
                                  : name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF222222),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'E-mail',
                            style: TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email.isEmpty ? 'Nenhum e-mail cadastrado' : email,
                            style: const TextStyle(
                              color: Color(0xFF222222),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _editarPerfil(context, name, email);
                              },
                              child: const Text('Editar perfil'),
                            ),
                          ),
                        ],
                      ),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        card,
                        if (email.isNotEmpty) _ProfileActivity(email: email),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Parte "Letterboxd" do perfil: jogo favorito escolhido à mão,
/// estatísticas da biblioteca e o diário com os últimos registros.
class _ProfileActivity extends StatefulWidget {
  final String email;

  const _ProfileActivity({required this.email});

  @override
  State<_ProfileActivity> createState() => _ProfileActivityState();
}

class _ProfileActivityState extends State<_ProfileActivity> {
  List<Game> _games = [];
  List<LibraryEntry> _entries = [];
  String? _favoriteName;
  bool _isLoading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final favoriteName = await FavoriteGameService.load();
      var games = <Game>[];
      var entries = <LibraryEntry>[];
      if (SupabaseConfig.isConfigured) {
        final client = Supabase.instance.client;
        games = await SupabaseGameService(client).getGames();
        entries = await UserLibraryService(client)
            .getLibraryEntries(widget.email);
      }
      if (!mounted) return;
      setState(() {
        _favoriteName = favoriteName;
        _games = games;
        _entries = entries;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Game? get _favoriteGame {
    final name = _favoriteName?.toLowerCase();
    if (name == null) return null;
    for (final game in _games) {
      if (game.name.toLowerCase() == name) return game;
    }
    return null;
  }

  Future<void> _pickFavorite() async {
    if (_games.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O catálogo de jogos não está disponível agora.'),
        ),
      );
      return;
    }
    final choice = await showFavoriteGamePicker(
      context,
      games: _games,
      currentName: _favoriteName,
    );
    if (choice == null) return;
    final name = choice.game?.name;
    await FavoriteGameService.save(name);
    if (!mounted) return;
    setState(() => _favoriteName = name);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final reviewed = _entries
        .where((entry) => entry.userScore != null)
        .toList();
    final diary = _entries.where((entry) => entry.hasReview).toList()
      ..sort(
        (a, b) => (b.loggedAtMillis ?? 0).compareTo(a.loggedAtMillis ?? 0),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const _ProfileSectionTitle('Jogo favorito'),
        const SizedBox(height: 12),
        if (_favoriteName == null)
          _ProfileMessageCard(
            icon: Icons.favorite_border,
            message:
                'Escolha o jogo que mais representa você. Ele aparece para '
                'seus amigos no seu perfil.',
            actionLabel: 'Escolher jogo favorito',
            onAction: _pickFavorite,
          )
        else
          FavoriteGameCard(
            name: _favoriteName!,
            game: _favoriteGame,
            onEdit: _pickFavorite,
          ),
        if (_loadError != null) ...[
          const SizedBox(height: 16),
          Text(
            'Não foi possível carregar sua biblioteca: $_loadError',
            style: const TextStyle(color: Colors.white),
          ),
        ] else ...[
          const SizedBox(height: 24),
          const _ProfileSectionTitle('Estatísticas'),
          const SizedBox(height: 12),
          RatingsSummary(
            scores: [for (final entry in reviewed) entry.userScore!],
            analysisCount: _entries
                .where((entry) => entry.reviewText?.trim().isNotEmpty ?? false)
                .length,
            wishlistCount: _entries.where((entry) => entry.isWishlist).length,
          ),
          const SizedBox(height: 24),
          const _ProfileSectionTitle('Diário'),
          const SizedBox(height: 12),
          if (diary.isEmpty)
            const _ProfileMessageCard(
              icon: Icons.menu_book_outlined,
              message:
                  'Seus jogos avaliados aparecem aqui, do mais recente '
                  'ao mais antigo.',
            )
          else
            for (final entry in diary.take(5)) ...[
              _DiaryRow(entry: entry),
              const SizedBox(height: 10),
            ],
        ],
      ],
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  final String text;

  const _ProfileSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }
}

class _ProfileMessageCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ProfileMessageCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.blue, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF222222),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _DiaryRow extends StatelessWidget {
  final LibraryEntry entry;

  const _DiaryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final score = entry.userScore;
    final stars = score == null ? 0 : (score / 2).round().clamp(0, 5);
    final date = formatLoggedDate(entry.loggedAtMillis);
    final review = entry.reviewText?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 60,
              child: GameCover(imageUrl: entry.game.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.game.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF222222),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (entry.isFavorite)
                      const Icon(
                        Icons.favorite,
                        color: Color(0xFFFF4D6D),
                        size: 16,
                      ),
                  ],
                ),
                if (score != null)
                  Text(
                    '${'★' * stars}${'☆' * (5 - stars)}',
                    semanticsLabel: '$stars de 5 estrelas',
                    style: const TextStyle(color: Colors.amber, fontSize: 14),
                  ),
                if (review.isNotEmpty)
                  Text(
                    review,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF444444),
                      fontSize: 13,
                    ),
                  ),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
