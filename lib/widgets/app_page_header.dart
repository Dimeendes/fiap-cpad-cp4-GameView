import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late Future<String?> _profilePhoto;

  @override
  void initState() {
    super.initState();
    _profilePhoto = _loadProfilePhoto();
  }

  Future<String?> _loadProfilePhoto() async {
    final preferences = await SharedPreferences.getInstance();
    final path = preferences.getString('profileImagePath');
    if (path == null || !File(path).existsSync()) return null;
    return path;
  }

  Future<void> _openProfile() async {
    await widget.onOpenProfile();
    if (!mounted) return;
    setState(() => _profilePhoto = _loadProfilePhoto());
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
            FutureBuilder<String?>(
              future: _profilePhoto,
              builder: (context, snapshot) {
                final path = snapshot.data;
                return IconButton(
                  tooltip: 'Meu perfil',
                  onPressed: _openProfile,
                  icon: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFEAF2FF),
                    backgroundImage: path == null
                        ? null
                        : FileImage(File(path)),
                    child: path == null
                        ? const Icon(
                            Icons.person_outline,
                            color: Color(0xFF2457A7),
                            size: 23,
                          )
                        : null,
                  ),
                );
              },
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
