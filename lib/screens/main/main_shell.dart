import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../favorites/favorites_page.dart';
import '../home/home_page.dart';
import '../map/map_page.dart';
import '../menu/menu_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final GlobalKey<FavoritesPageState> _favoritesKey =
  GlobalKey<FavoritesPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const HomePage(),
      const MapPage(),
      FavoritesPage(key: _favoritesKey),
      const MenuPage(),
    ];
  }

  void _changePage(int index) {
    if (_currentIndex == index) {
      if (index == 2) {
        _favoritesKey.currentState?.refreshFavorites();
      }
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    if (index == 2) {
      _favoritesKey.currentState?.refreshFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _ModernBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _changePage,
      ),
    );
  }
}

class _ModernBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ModernBottomNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.65),
            width: 0.7,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            12,
            7,
            12,
            6,
          ),
          child: Row(
            children: [
              Expanded(
                child: _NavigationItem(
                  index: 0,
                  currentIndex: currentIndex,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Ana Sayfa',
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _NavigationItem(
                  index: 1,
                  currentIndex: currentIndex,
                  icon: Icons.map_outlined,
                  selectedIcon: Icons.map_rounded,
                  label: 'Harita',
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _NavigationItem(
                  index: 2,
                  currentIndex: currentIndex,
                  icon: Icons.favorite_border_rounded,
                  selectedIcon: Icons.favorite_rounded,
                  label: 'Favoriler',
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _NavigationItem(
                  index: 3,
                  currentIndex: currentIndex,
                  icon: Icons.menu_rounded,
                  selectedIcon: Icons.menu_rounded,
                  label: 'Menü',
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final int index;
  final int currentIndex;

  final IconData icon;
  final IconData selectedIcon;

  final String label;

  final ValueChanged<int> onTap;

  const _NavigationItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  bool get isSelected => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 57,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isSelected ? 48 : 36,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.11)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    key: ValueKey(isSelected),
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: isSelected ? 21 : 20,
                  ),
                ),
              ),

              const SizedBox(height: 3),

              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 10,
                  height: 1,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}