import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/profile_photo_service.dart';
import '../services/user_identity_service.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _profileImageKey = 'profileImagePath';

  late final Future<SharedPreferences> _preferences =
      SharedPreferences.getInstance();

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
    final preferences = await _preferences;
    if (!mounted || !context.mounted) return;

    final nomeController = TextEditingController(text: nomeAtual);
    final emailController = TextEditingController(text: emailAtual);
    var photoPath = preferences.getString(_profileImageKey);

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
                    await UserIdentityService().getOrCreateAccountId(
                      legacyEmail: emailAtual,
                    );
                    await preferences.setString(
                      'nome',
                      nomeController.text.trim(),
                    );

                    await preferences.setString(
                      'email',
                      emailController.text.trim(),
                    );

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
                    final photoPath =
                        ProfilePhotoService.photoPath.value ??
                        preferences?.getString(_profileImageKey);
                    final hasPhoto =
                        photoPath != null && File(photoPath).existsSync();

                    return Container(
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
