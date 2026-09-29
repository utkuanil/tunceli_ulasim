import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/announcement.dart';
import '../../models/bus_route.dart';
import '../../models/bus_trip.dart';
import '../../models/bus_stop.dart';
import '../../services/announcement_service.dart';
import '../../services/favorite_service.dart';
import '../../services/schedule_service.dart';
import '../../services/stop_service.dart';

import '../announcements/announcement_detail_page.dart';
import '../announcements/announcements_page.dart';
import '../favorites/favorites_page.dart';
import '../map/map_page.dart';
import '../routes/route_detail_page.dart';
import '../routes/routes_page.dart';
import '../schedules/schedules_page.dart';
import '../search/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScheduleService _scheduleService = ScheduleService();
  final AnnouncementService _announcementService = AnnouncementService();
  final FavoriteService _favoriteService = FavoriteService();
  final StopService _stopService = StopService();

  _NextTripInfo? _nextTrip;
  bool _loadingNextTrip = true;

  Announcement? _latestAnnouncement;
  bool _loadingAnnouncement = true;

  int _favoriteRouteCount = 0;
  int _favoriteStopCount = 0;
  BusStop? _firstFavoriteStop;
  bool _loadingFavorites = true;

  @override
  void initState() {
    super.initState();
    _loadNextTrip();
    _loadLatestAnnouncement();
    _loadFavoriteSummary();
  }

  Future<void> _loadNextTrip() async {
    try {
      final routes = await _scheduleService.getRoutes();
      final nextTrip = _findNextTrip(routes);

      if (!mounted) return;

      setState(() {
        _nextTrip = nextTrip;
        _loadingNextTrip = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _nextTrip = null;
        _loadingNextTrip = false;
      });
    }
  }

  Future<void> _loadLatestAnnouncement() async {
    try {
      final announcements =
      await _announcementService.getAnnouncements();

      if (!mounted) return;

      setState(() {
        _latestAnnouncement =
        announcements.isNotEmpty ? announcements.first : null;

        _loadingAnnouncement = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _latestAnnouncement = null;
        _loadingAnnouncement = false;
      });
    }
  }

  Future<void> _loadFavoriteSummary() async {
    try {
      final favoriteRouteIds =
      await _favoriteService.getFavoriteRouteIds();
      final favoriteStopIds =
      await _favoriteService.getFavoriteStopIds();
      final allStops = await _stopService.getStops();

      BusStop? firstFavoriteStop;

      for (final stopId in favoriteStopIds) {
        for (final stop in allStops) {
          if (stop.id == stopId) {
            firstFavoriteStop = stop;
            break;
          }
        }

        if (firstFavoriteStop != null) {
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        _favoriteRouteCount = favoriteRouteIds.length;
        _favoriteStopCount = favoriteStopIds.length;
        _firstFavoriteStop = firstFavoriteStop;
        _loadingFavorites = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _favoriteRouteCount = 0;
        _favoriteStopCount = 0;
        _firstFavoriteStop = null;
        _loadingFavorites = false;
      });
    }
  }

  _NextTripInfo? _findNextTrip(List<BusRoute> routes) {
    final now = DateTime.now();

    final isWeekend =
        now.weekday == DateTime.saturday ||
            now.weekday == DateTime.sunday;

    final todayKey = _todayKey(now.weekday);

    _NextTripInfo? nearest;

    for (final route in routes) {
      final trips = isWeekend
          ? route.weekend
          : route.weekday;

      for (final trip in trips) {
        if (!isWeekend &&
            trip.days != null &&
            trip.days!.isNotEmpty &&
            !trip.days!.contains(todayKey)) {
          continue;
        }

        final tripDateTime = _parseTripTime(
          now,
          trip.time,
        );

        if (tripDateTime == null) {
          continue;
        }

        if (tripDateTime.isBefore(now)) {
          continue;
        }

        final candidate = _NextTripInfo(
          route: route,
          trip: trip,
          dateTime: tripDateTime,
        );

        if (nearest == null ||
            candidate.dateTime.isBefore(nearest.dateTime)) {
          nearest = candidate;
        }
      }
    }

    return nearest;
  }

  DateTime? _parseTripTime(
      DateTime date,
      String time,
      ) {
    final parts = time.trim().split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  String _todayKey(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return '';
    }
  }

  void _openAnnouncements(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AnnouncementsPage(),
      ),
    );
  }

  void _openRoutes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RoutesPage(),
      ),
    );
  }

  void _openSchedules(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SchedulesPage(),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchPage(),
      ),
    );
  }

  Future<void> _openFavorites(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FavoritesPage(),
      ),
    );

    if (!mounted) return;

    await _loadFavoriteSummary();
  }

  Future<void> _openFavoriteStop(
      BuildContext context,
      BusStop stop,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPage(
          initialStopId: stop.id,
        ),
      ),
    );

    if (!mounted) return;

    await _loadFavoriteSummary();
  }

  void _openMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPage(),
      ),
    );
  }

  void _openNearestStop(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPage(
          autoFindNearest: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HeroSection(
                onSearchTap: () => _openSearch(context),
                onNotificationTap: () => _openAnnouncements(context),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                24,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    const _SectionTitle(
                      title: 'Hızlı Erişim',
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.directions_bus_rounded,
                            title: 'Hatlar',
                            onTap: () => _openRoutes(context),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.schedule_rounded,
                            title: 'Seferler',
                            onTap: () => _openSchedules(context),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.favorite_rounded,
                            title: 'Favoriler',
                            onTap: () => _openFavorites(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _FavoritesSummaryCard(
                      loading: _loadingFavorites,
                      routeCount: _favoriteRouteCount,
                      stopCount: _favoriteStopCount,
                      favoriteStop: _firstFavoriteStop,
                      onTap: () => _openFavorites(context),
                      onStopTap: _firstFavoriteStop == null
                          ? null
                          : () => _openFavoriteStop(
                        context,
                        _firstFavoriteStop!,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _NearestStopCard(
                      onTap: () => _openNearestStop(context),
                    ),

                    const SizedBox(height: 20),

                    const _SectionTitle(
                      title: 'Sonraki Sefer',
                      subtitle: 'Bugünün en yakın hareket saati',
                    ),

                    const SizedBox(height: 10),

                    _NextTripCard(
                      tripInfo: _nextTrip,
                      loading: _loadingNextTrip,
                      onTap: _nextTrip == null
                          ? null
                          : () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RouteDetailPage(
                              route: _nextTrip!.route,
                            ),
                          ),
                        );

                        _loadNextTrip();
                      },
                    ),

                    const SizedBox(height: 18),

                    _MapCard(
                      onTap: () => _openMap(context),
                    ),

                    const SizedBox(height: 28),

                    _SectionTitle(
                      title: 'Belediye Duyuruları',
                      subtitle: 'Güncel bilgilendirmeler',
                      actionText: 'Tümünü Gör',
                      onActionTap: () => _openAnnouncements(context),
                    ),

                    const SizedBox(height: 12),

                    _LatestAnnouncementCard(
                      announcement: _latestAnnouncement,
                      loading: _loadingAnnouncement,
                      onTap: _latestAnnouncement == null
                          ? () => _openAnnouncements(context)
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AnnouncementDetailPage(
                                  announcement:
                                  _latestAnnouncement!,
                                ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    const _CityFooter(),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;

  const _HeroSection({
    required this.onSearchTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        0,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -65,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.055,
                  ),
                ),
              ),
            ),

            Positioned(
              right: 35,
              top: 90,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.035,
                  ),
                ),
              ),
            ),

            Positioned(
              left: -35,
              bottom: -55,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.04,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                14,
                18,
                18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.14,
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),

                      const SizedBox(width: 11),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TUNCELİ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ULAŞIM',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Material(
                        color: Colors.white.withValues(
                          alpha: 0.13,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          onTap: onNotificationTap,
                          borderRadius: BorderRadius.circular(13),
                          child: const SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Şehir içi ulaşım\nartık daha kolay.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Hatlara ve sefer saatlerine hızlıca ulaşın.',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.76,
                      ),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    child: InkWell(
                      onTap: onSearchTap,
                      borderRadius: BorderRadius.circular(17),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius:
                                BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                color: AppColors.primary,
                                size: 21,
                              ),
                            ),

                            const SizedBox(width: 12),

                            const Expanded(
                              child: Text(
                                'Hat veya ulaşım noktası ara',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.textSecondary,
                              size: 19,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onActionTap;

  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (actionText != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 5,
              ),
              child: Row(
                children: [
                  Text(
                    actionText!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 105,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.divider.withValues(
                alpha: 0.8,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),

              const Spacer(),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritesSummaryCard extends StatelessWidget {
  final bool loading;
  final int routeCount;
  final int stopCount;
  final BusStop? favoriteStop;
  final VoidCallback onTap;
  final VoidCallback? onStopTap;

  const _FavoritesSummaryCard({
    required this.loading,
    required this.routeCount,
    required this.stopCount,
    required this.favoriteStop,
    required this.onTap,
    required this.onStopTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.divider,
            ),
          ),
          child: loading
              ? const SizedBox(
            height: 58,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          )
              : Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.09,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Favorilerim',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$routeCount Hat • $stopCount Durak',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),
                  ),
                ],
              ),
              if (favoriteStop != null) ...[
                const SizedBox(height: 12),
                Material(
                  color: AppColors.primary.withValues(
                    alpha: 0.06,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: onStopTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hızlı Durak',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  favoriteStop!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.primary,
                            size: 17,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NearestStopCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NearestStopCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.075),
                Colors.white,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.near_me_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'En Yakın Durak',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Konumunuza en yakın durağı otomatik bulun',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextTripInfo {
  final BusRoute route;
  final BusTrip trip;
  final DateTime dateTime;

  const _NextTripInfo({
    required this.route,
    required this.trip,
    required this.dateTime,
  });
}

class _NextTripCard extends StatelessWidget {
  final _NextTripInfo? tripInfo;
  final bool loading;
  final VoidCallback? onTap;

  const _NextTripCard({
    required this.tripInfo,
    required this.loading,
    required this.onTap,
  });

  String _remainingTime(DateTime departure) {
    final now = DateTime.now();

    var minutes =
        departure.difference(now).inMinutes;

    if (minutes < 0) {
      minutes = 0;
    }

    if (minutes == 0) {
      return 'Şimdi';
    }

    if (minutes < 60) {
      return '$minutes dk';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '$hours sa';
    }

    return '$hours sa $remainingMinutes dk';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 145,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.divider,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (tripInfo == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.divider,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.nightlight_round,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bugün için başka sefer bulunmuyor.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final info = tripInfo!;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.primary.withValues(
                alpha: 0.14,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.09,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: AppColors.primary,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Text(
                      info.route.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.09,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _remainingTime(info.dateTime),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HAREKET',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info.trip.time,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'VARIŞ / GÜZERGÂH',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info.trip.destination,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 11),

              Container(
                height: 1,
                color: AppColors.divider,
              ),

              const SizedBox(height: 9),

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),

                  const SizedBox(width: 5),

                  Expanded(
                    child: Text(
                      'Kalkış: ${info.route.departurePoint}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),

                  const Text(
                    'Sefer detayı',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(width: 2),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 17,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MapCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 96,
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ulaşım Haritası',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Durakları harita üzerinde görüntüleyin',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestAnnouncementCard extends StatelessWidget {
  final Announcement? announcement;
  final bool loading;
  final VoidCallback onTap;

  const _LatestAnnouncementCard({
    required this.announcement,
    required this.loading,
    required this.onTap,
  });

  List<String> _dateParts(String date) {
    final parts = date.trim().split(
      RegExp(r'\s+'),
    );

    if (parts.length >= 3) {
      final month = parts[1];

      return [
        parts[0],
        month
            .substring(
          0,
          month.length > 3 ? 3 : month.length,
        )
            .toUpperCase(),
        parts[2],
      ];
    }

    return ['', '', ''];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 145,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.divider,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (announcement == null) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.divider,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Duyurular şu anda görüntülenemiyor.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = announcement!;
    final date = _dateParts(item.date);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.divider,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      date[0],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 21,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      date[1],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      date[2],
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: 0.07,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'BELEDİYE DUYURUSU',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if (item.summary.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.45,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Duyuruyu Gör',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityFooter extends StatelessWidget {
  const _CityFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.18,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        const SizedBox(height: 9),

        const Text(
          'TUNCELİ BELEDİYESİ',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
