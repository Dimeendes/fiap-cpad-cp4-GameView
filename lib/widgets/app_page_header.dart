import 'package:flutter/material.dart';

class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onOpenProfile;

  const AppPageHeader({
    super.key,
    required this.title,
    required this.onOpenProfile,
    this.subtitle,
  });

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
            IconButton(
              tooltip: 'Meu perfil',
              onPressed: onOpenProfile,
              icon: const Icon(
                Icons.account_circle_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
          ),
        ],
      ],
    );
  }
}
