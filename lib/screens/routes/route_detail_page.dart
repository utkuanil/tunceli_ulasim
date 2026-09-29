import 'package:flutter/material.dart';
import 'route_stops_page.dart';
import '../../core/constants/app_colors.dart';
import '../../models/bus_route.dart';
import '../../models/bus_trip.dart';
import '../../services/favorite_service.dart';
import '../schedules/schedule_detail_page.dart';
import '../map/map_page.dart';


class RouteDetailPage extends StatefulWidget {
  final BusRoute route;

  const RouteDetailPage({
    super.key,
    required this.route,
  });

  @override
  State<RouteDetailPage> createState() =>
      _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  final FavoriteService _favoriteService = FavoriteService();

  bool _isFavorite = false;
  bool _isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final favorite = await _favoriteService.isFavorite(
      widget.route.id,
    );

    if (!mounted) return;

    setState(() {
      _isFavorite = favorite;
      _isLoadingFavorite = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final newFavoriteStatus =
    await _favoriteService.toggleFavorite(
      widget.route.id,
    );

    if (!mounted) return;

    setState(() {
      _isFavorite = newFavoriteStatus;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newFavoriteStatus
              ? 'Hat favorilere eklendi.'
              : 'Hat favorilerden çıkarıldı.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<BusTrip> _getTodayTrips() {
    final now = DateTime.now();

    final isWeekend =
        now.weekday == DateTime.saturday ||
            now.weekday == DateTime.sunday;

    final trips = isWeekend
        ? widget.route.weekend
        : widget.route.weekday;

    if (isWeekend) {
      return trips;
    }

    final todayKeys = _todayKeys(now.weekday);

    return trips.where((trip) {
      if (trip.days == null || trip.days!.isEmpty) {
        return true;
      }

      return trip.days!.any(
            (day) => todayKeys.contains(
          _normalizeDay(day),
        ),
      );
    }).toList();
  }

  Set<String> _todayKeys(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return {'monday', 'pazartesi'};
      case DateTime.tuesday:
        return {'tuesday', 'sali'};
      case DateTime.wednesday:
        return {'wednesday', 'carsamba'};
      case DateTime.thursday:
        return {'thursday', 'persembe'};
      case DateTime.friday:
        return {'friday', 'cuma'};
      case DateTime.saturday:
        return {'saturday', 'cumartesi'};
      case DateTime.sunday:
        return {'sunday', 'pazar'};
      default:
        return {};
    }
  }

  String _normalizeDay(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  DateTime? _tripDateTime(String time) {
    final parts = time.trim().split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
  }

  int _findNextTripIndex(List<BusTrip> trips) {
    final now = DateTime.now();

    for (int i = 0; i < trips.length; i++) {
      final dateTime = _tripDateTime(trips[i].time);

      if (dateTime != null && !dateTime.isBefore(now)) {
        return i;
      }
    }

    return -1;
  }

  void _openSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleDetailPage(
          route: widget.route,
        ),
      ),
    );
  }

  void _openStops() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteStopsPage(
          route: widget.route,
        ),
      ),
    );
  }

  void _openRouteMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPage(
          routeId: widget.route.id,
          routeName: widget.route.name,
        ),
      ),
    );
  }

  bool get _hasRouteGeometry {
    return const {
      'ataturk_universite_aktuluk',
      'cumhuriyet_mahallesi',
      'inonu_kutudere',
      'yeni_mahalle',
      'esentepe_mahallesi',
    }.contains(widget.route.id);
  }


  @override
  Widget build(BuildContext context) {
    final todayTrips = _getTodayTrips();
    final nextTripIndex = _findNextTripIndex(todayTrips);
    final hasStopData =
        widget.route.id != 'alibaba_mahallesi';
    final hasRouteGeometry = _hasRouteGeometry;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Hat Detayı',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FavoriteButton(
              isFavorite: _isFavorite,
              loading: _isLoadingFavorite,
              onTap: _toggleFavorite,
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          6,
          16,
          30,
        ),
        children: [
          _RouteHeroCard(
            route: widget.route,
            isFavorite: _isFavorite,
          ),

          const SizedBox(height: 24),

          _SectionHeader(
            title: 'Bugünkü Seferler',
            subtitle: todayTrips.isEmpty
                ? 'Bugün için planlı sefer bulunmuyor'
                : nextTripIndex == -1
                ? 'Bugünkü seferler tamamlandı'
                : 'Sıradaki hareket: '
                '${todayTrips[nextTripIndex].time}',
            actionText: 'Tümünü Gör',
            onActionTap: _openSchedule,
          ),

          const SizedBox(height: 12),

          _TodayTripsCard(
            trips: todayTrips,
            nextTripIndex: nextTripIndex,
            onViewAll: _openSchedule,
          ),

          const SizedBox(height: 26),

          const _SectionHeader(
            title: 'Hat İşlemleri',
            subtitle: 'Hatla ilgili bilgilere hızlıca ulaşın',
          ),

          const SizedBox(height: 12),

          _ModernActionCard(
            icon: Icons.schedule_rounded,
            title: 'Sefer Saatleri',
            subtitle:
            'Hafta içi ve hafta sonu hareket saatlerini inceleyin',
            enabled: true,
            onTap: _openSchedule,
          ),

          const SizedBox(height: 10),

          _ModernActionCard(
            icon: Icons.directions_bus_filled_outlined,
            title: 'Hat Durakları',
            subtitle: hasStopData
                ? widget.route.id == 'ataturk_universite_aktuluk'
                ? 'Güzergâh duraklarını ve sefer geçiş saatlerini inceleyin'
                : 'Güzergâha yakın resmî durakları inceleyin'
                : 'Bu hat için güzergâh ve durak verisi henüz bulunmuyor',
            enabled: hasStopData,
            onTap: _openStops,
          ),

          const SizedBox(height: 10),

          _ModernActionCard(
            icon: Icons.map_outlined,
            title: 'Güzergâh Haritası',
            subtitle: hasRouteGeometry
                ? 'KML kaynaklı güzergâh çizgisini haritada görüntüleyin'
                : 'Bu hat için güzergâh geometrisi bulunmuyor',
            enabled: hasRouteGeometry,
            onTap: _openRouteMap,
          ),

          const SizedBox(height: 16),

          const _DataInfoCard(),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final bool loading;
  final VoidCallback onTap;

  const _FavoriteButton({
    required this.isFavorite,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Material(
      color: isFavorite
          ? AppColors.error.withValues(alpha: 0.08)
          : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: isFavorite
                ? AppColors.error
                : AppColors.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _RouteHeroCard extends StatelessWidget {
  final BusRoute route;
  final bool isFavorite;

  const _RouteHeroCard({
    required this.route,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.17),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -45,
              top: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.055,
                  ),
                ),
              ),
            ),

            Positioned(
              right: 45,
              bottom: -65,
              child: Container(
                width: 125,
                height: 125,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.035,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.14,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'OTOBÜS HATTI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const Spacer(),

                      if (isFavorite)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Favoride',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.13,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Text(
                          route.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  const _RouteLine(),

                  const SizedBox(height: 15),

                  const Text(
                    'KALKIŞ NOKTASI',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    route.departurePoint,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (route.note != null &&
                      route.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.11,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 16,
                          ),

                          const SizedBox(width: 7),

                          Expanded(
                            child: Text(
                              route.note!,
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: 0.88,
                                ),
                                fontSize: 10,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        Expanded(
          child: Container(
            height: 2,
            color: Colors.white.withValues(
              alpha: 0.35,
            ),
          ),
        ),

        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onActionTap;

  const _SectionHeader({
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
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),

              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
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
                      fontSize: 11,
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
            ),
          ),
      ],
    );
  }
}

class _TodayTripsCard extends StatelessWidget {
  final List<BusTrip> trips;
  final int nextTripIndex;
  final VoidCallback onViewAll;

  const _TodayTripsCard({
    required this.trips,
    required this.nextTripIndex,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.divider,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.event_busy_outlined,
              color: AppColors.textSecondary,
              size: 21,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bugün için planlı sefer bulunmuyor.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 61,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trips.length,
              separatorBuilder: (_, __) =>
              const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final trip = trips[index];

                final isNext = index == nextTripIndex;
                final isPast = nextTripIndex == -1 ||
                    index < nextTripIndex;

                return _TripTimeChip(
                  trip: trip,
                  isNext: isNext,
                  isPast: isPast,
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Container(
            height: 1,
            color: AppColors.divider,
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Icon(
                nextTripIndex >= 0
                    ? Icons.access_time_rounded
                    : Icons.check_circle_outline_rounded,
                color: nextTripIndex >= 0
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 15,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  nextTripIndex >= 0
                      ? 'Yeşil alan sıradaki seferi gösterir.'
                      : 'Bugünkü seferlerin tamamı gerçekleşti.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),

              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Detay',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 1),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripTimeChip extends StatelessWidget {
  final BusTrip trip;
  final bool isNext;
  final bool isPast;

  const _TripTimeChip({
    required this.trip,
    required this.isNext,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 78,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isNext
            ? AppColors.primary
            : isPast
            ? AppColors.background
            : AppColors.primary.withValues(
          alpha: 0.055,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isNext
              ? AppColors.primary
              : AppColors.divider,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            trip.time,
            style: TextStyle(
              color: isNext
                  ? Colors.white
                  : isPast
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            isNext
                ? 'SIRADAKİ'
                : isPast
                ? 'GEÇTİ'
                : 'SEFER',
            style: TextStyle(
              color: isNext
                  ? Colors.white70
                  : AppColors.textSecondary,
              fontSize: 7,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _ModernActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.58,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        style: const TextStyle(
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
                    color: enabled
                        ? AppColors.primary.withValues(
                      alpha: 0.07,
                    )
                        : AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    enabled
                        ? Icons.arrow_forward_rounded
                        : Icons.lock_outline_rounded,
                    color: enabled
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: enabled ? 16 : 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DataInfoCard extends StatelessWidget {
  const _DataInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.055,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 17,
          ),

          SizedBox(width: 8),

          Expanded(
            child: Text(
              'Belediyeden alınan 81 resmî durak konumu genel ulaşım '
                  'haritasında gösterilmektedir. KML dosyasındaki güzergâh '
                  'geometrileri hat haritalarında kullanılmaktadır. Güzergâha '
                  'yakın duraklar konumsal yakınlığa göre gösterildiğinden '
                  'resmî durak sırası olarak yorumlanmamalıdır.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
