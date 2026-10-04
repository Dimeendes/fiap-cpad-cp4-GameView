import 'package:flutter/material.dart';

import '../navigation/app_page.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import 'configs.dart';
import 'friend_list.dart';
import 'game_catalog.dart';
import 'games_library.dart';

class MainShell extends StatefulWidget {
  final AppPage initialPage;

  const MainShell({
    super.key,
    this.initialPage = AppPage.catalog,
  });

  static MainShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainShellState>();
  }

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late AppPage _currentPage;
  final GlobalKey<GamesLibraryScreenState> _libraryKey =
      GlobalKey<GamesLibraryScreenState>();

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
  }

  void goTo(AppPage page) {
    if (_currentPage == page) return;
    setState(() => _currentPage = page);
    if (page == AppPage.library) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _libraryKey.currentState?.reload();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentPage.index,
        children: [
          const GameCatalog(),
          const FriendListScreen(),
          GamesLibraryScreen(
            key: _libraryKey,
            onGoToCatalog: () => goTo(AppPage.catalog),
          ),
          const ConfigsScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentPage: _currentPage,
        onSelect: goTo,
      ),
      backgroundColor: AppColors.darkBlue,
    );
  }
}
