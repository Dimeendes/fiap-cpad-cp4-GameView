import 'package:flutter/material.dart';

import '../navigation/app_page.dart';
import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onSelect;

  const AppBottomNav({
    super.key,
    required this.currentPage,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.sports_esports_outlined,
                selectedIcon: Icons.sports_esports,
                label: 'Catálogo',
                selected: currentPage == AppPage.catalog,
                onTap: () => onSelect(AppPage.catalog),
              ),
              _NavItem(
                icon: Icons.group_outlined,
                selectedIcon: Icons.group,
                label: 'Amigos',
                selected: currentPage == AppPage.friends,
                onTap: () => onSelect(AppPage.friends),
              ),
              _NavItem(
                icon: Icons.collections_bookmark_outlined,
                selectedIcon: Icons.collections_bookmark,
                label: 'Biblioteca',
                selected: currentPage == AppPage.library,
                onTap: () => onSelect(AppPage.library),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Configuração',
                selected: currentPage == AppPage.settings,
                onTap: () => onSelect(AppPage.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.blue : const Color(0xFF777777);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? selectedIcon : icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
