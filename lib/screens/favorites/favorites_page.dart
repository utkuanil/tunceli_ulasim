import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/bus_route.dart';
import '../../models/bus_stop.dart';
import '../../services/favorite_service.dart';
import '../../services/schedule_service.dart';
import '../../services/stop_service.dart';
import '../map/map_page.dart';
import '../routes/route_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => FavoritesPageState();
}

class FavoritesPageState extends State<FavoritesPage> {
  final FavoriteService _favoriteService = FavoriteService();
  final ScheduleService _scheduleService = ScheduleService();
  final StopService _stopService = StopService();

  bool _isLoading = true;
  String? _error;

  List<BusRoute> _favoriteRoutes = [];
  List<BusStop> _favoriteStops = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> refreshFavorites() async {
    await _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final favoriteRouteIds = await _favoriteService.getFavoriteRouteIds();
      final favoriteStopIds = await _favoriteService.getFavoriteStopIds();

      final allRoutes = await _scheduleService.getRoutes();
      final allStops = await _stopService.getStops();

      final favoriteRoutes = allRoutes.where((route) {
        return favoriteRouteIds.contains(route.id);
      }).toList();

      final favoriteStops = allStops.where((stop) {
        return favoriteStopIds.contains(stop.id);
      }).toList();

      if (!mounted) return;

      setState(() {
        _favoriteRoutes = favoriteRoutes;
        _favoriteStops = favoriteStops;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Favoriler yüklenemedi.';
      });
    }
  }

  Future<void> _removeRouteFavorite(BusRoute route) async {
    await _favoriteService.removeFavorite(route.id);
    if (!mounted) return;

    await _loadFavorites();
    if (!mounted) return;

    _showMessage('${route.name} favorilerden çıkarıldı.');
  }

  Future<void> _removeStopFavorite(BusStop stop) async {
    await _favoriteService.removeFavoriteStop(stop.id);
    if (!mounted) return;

    await _loadFavorites();
    if (!mounted) return;

    _showMessage('${stop.name} favorilerden çıkarıldı.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openRoute(BusRoute route) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteDetailPage(route: route),
      ),
    );

    if (!mounted) return;
    await _loadFavorites();
  }

  Future<void> _openStop(BusStop stop) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPage(initialStopId: stop.id),
      ),
    );

    if (!mounted) return;
    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Favoriler',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: [
                    Tab(text: 'Hatlarım (${_favoriteRoutes.length})'),
                    Tab(text: 'Duraklarım (${_favoriteStops.length})'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        )
            : _error != null
            ? _ErrorView(
          message: _error!,
          onRetry: _loadFavorites,
        )
            : TabBarView(
          children: [
            _buildRoutesTab(),
            _buildStopsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadFavorites,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          _FavoritesHero(
            title: 'Favori Hatlarım',
            subtitle: 'Sık kullandığınız otobüs hatlarına hızlıca ulaşın.',
            icon: Icons.directions_bus_rounded,
            countText: '${_favoriteRoutes.length} hat',
          ),
          const SizedBox(height: 20),
          if (_favoriteRoutes.isEmpty)
            const _EmptyFavoriteContent(
              icon: Icons.directions_bus_outlined,
              title: 'Henüz favori hattınız yok',
              description:
              'Bir hattın detay sayfasındaki kalp simgesine dokunarak favorilerinize ekleyebilirsiniz.',
            )
          else
            ...List.generate(
              _favoriteRoutes.length,
                  (index) {
                final route = _favoriteRoutes[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _favoriteRoutes.length - 1 ? 0 : 10,
                  ),
                  child: _FavoriteRouteCard(
                    route: route,
                    onTap: () => _openRoute(route),
                    onRemove: () => _removeRouteFavorite(route),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStopsTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadFavorites,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          _FavoritesHero(
            title: 'Favori Duraklarım',
            subtitle: 'Sık kullandığınız durakları tek ekranda toplayın.',
            icon: Icons.location_on_rounded,
            countText: '${_favoriteStops.length} durak',
          ),
          const SizedBox(height: 20),
          if (_favoriteStops.isEmpty)
            const _EmptyFavoriteContent(
              icon: Icons.location_on_outlined,
              title: 'Henüz favori durağınız yok',
              description:
              'Haritadaki bir durağın detayından kalp simgesine dokunarak favorilerinize ekleyebilirsiniz.',
            )
          else
            ...List.generate(
              _favoriteStops.length,
                  (index) {
                final stop = _favoriteStops[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _favoriteStops.length - 1 ? 0 : 10,
                  ),
                  child: _FavoriteStopCard(
                    stop: stop,
                    onTap: () => _openStop(stop),
                    onRemove: () => _removeStopFavorite(stop),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _FavoritesHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String countText;

  const _FavoritesHero({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.countText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: Colors.white, size: 25),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  countText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteRouteCard extends StatelessWidget {
  final BusRoute route;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteRouteCard({
    required this.route,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _FavoriteCardShell(
      icon: Icons.directions_bus_rounded,
      title: route.name,
      subtitle: 'Kalkış: ${route.departurePoint}',
      onTap: onTap,
      onRemove: onRemove,
    );
  }
}

class _FavoriteStopCard extends StatelessWidget {
  final BusStop stop;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteStopCard({
    required this.stop,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _FavoriteCardShell(
      icon: Icons.location_on_rounded,
      title: stop.name,
      subtitle:
      '${stop.latitude.toStringAsFixed(5)}, ${stop.longitude.toStringAsFixed(5)}',
      onTap: onTap,
      onRemove: onRemove,
    );
  }
}

class _FavoriteCardShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCardShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              IconButton(
                tooltip: 'Favorilerden çıkar',
                onPressed: onRemove,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.07),
                ),
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFavoriteContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyFavoriteContent({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_rounded, color: AppColors.primary, size: 15),
                SizedBox(width: 6),
                Text(
                  'Favoriler cihazınızda saklanır',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 31,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lütfen tekrar deneyin.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
