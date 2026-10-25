import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';

import '../services/profile_photo_service.dart';

class AppPageHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Future<void> Function() onOpenProfile;

  const AppPageHeader({
    super.key,
    required this.title,
    required this.onOpenProfile,
    this.subtitle,
  });

  @override
  State<AppPageHeader> createState() => _AppPageHeaderState();
}

class _AppPageHeaderState extends State<AppPageHeader> {
  @override
  void initState() {
    super.initState();
    unawaited(ProfilePhotoService.load());
  }

  Future<void> _openProfile() async {
    await widget.onOpenProfile();
    if (!mounted) return;
    await ProfilePhotoService.load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sports_esports, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'GameView',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: ProfilePhotoService.photoPath,
              builder: (context, path, _) => IconButton(
                tooltip: 'Meu perfil',
                onPressed: _openProfile,
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFEAF2FF),
                  backgroundImage: path == null ? null : FileImage(File(path)),
                  child: path == null
                      ? const Icon(
                          Icons.person_outline,
                          color: Color(0xFF2457A7),
                          size: 23,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          widget.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
          ),
        ],
      ],
    );
  }
}
