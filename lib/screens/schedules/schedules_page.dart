import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/bus_route.dart';
import '../../models/bus_trip.dart';
import '../../services/schedule_service.dart';
import 'schedule_detail_page.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  final ScheduleService _scheduleService = ScheduleService();

  late Future<List<BusRoute>> _routesFuture;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  void _loadRoutes() {
    _routesFuture = _scheduleService.getRoutes();
  }

  Future<void> _refreshRoutes() async {
    setState(() {
      _loadRoutes();
    });

    await _routesFuture;
  }

  void _openSchedule(BusRoute route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleDetailPage(
          route: route,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Sefer Saatleri',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: FutureBuilder<List<BusRoute>>(
        future: _routesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return _ErrorView(
              onRetry: () {
                setState(() {
                  _loadRoutes();
                });
              },
            );
          }

          final routes = snapshot.data ?? [];

          if (routes.isEmpty) {
            return const _EmptyView();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshRoutes,
            child: ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                6,
                16,
                30,
              ),
              children: [
                _SchedulesHeader(
                  routeCount: routes.length,
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Otobüs Hatları',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Sefer programını görüntülemek için bir hat seçin',
                            style: TextStyle(
                              color:
                              AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: 0.07,
                        ),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${routes.length} hat',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ...List.generate(
                  routes.length,
                      (index) {
                    final route = routes[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom:
                        index == routes.length - 1
                            ? 0
                            : 10,
                      ),
                      child: _ScheduleRouteCard(
                        route: route,
                        todayTripCount:
                        _getTodayTrips(route).length,
                        onTap: () {
                          _openSchedule(route);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<BusTrip> _getTodayTrips(BusRoute route) {
    final now = DateTime.now();

    final bool isWeekend =
        now.weekday == DateTime.saturday ||
            now.weekday == DateTime.sunday;

    final source =
    isWeekend ? route.weekend : route.weekday;

    if (isWeekend) {
      return source;
    }

    final currentDay = _getDayName(now.weekday);

    return source.where((trip) {
      if (trip.days == null || trip.days!.isEmpty) {
        return true;
      }

      return trip.days!.contains(currentDay);
    }).toList();
  }

  String _getDayName(int weekday) {
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
}

// ============================================================
// ÜST BİLGİ ALANI
// ============================================================

class _SchedulesHeader extends StatelessWidget {
  final int routeCount;

  const _SchedulesHeader({
    required this.routeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: 0.16,
            ),
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
              right: -40,
              top: -55,
              child: Container(
                width: 155,
                height: 155,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.055,
                  ),
                ),
              ),
            ),

            Positioned(
              right: 55,
              bottom: -75,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.035,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(19),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.13,
                          ),
                          borderRadius:
                          BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons
                                  .directions_bus_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$routeCount hat',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 17),

                  const Text(
                    'Sefer Saatleri',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Tunceli şehir içi otobüs hatlarının '
                        'güncel hareket saatlerini görüntüleyin.',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.82,
                      ),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(13),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Hat seçerek hafta içi ve hafta sonu '
                                'programlarını inceleyebilirsiniz.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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

// ============================================================
// HAT KARTI
// ============================================================

class _ScheduleRouteCard extends StatelessWidget {
  final BusRoute route;
  final int todayTripCount;
  final VoidCallback onTap;

  const _ScheduleRouteCard({
    required this.route,
    required this.todayTripCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasTripsToday = todayTripCount > 0;

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
            border: Border.all(
              color: AppColors.divider,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textSecondary,
                          size: 13,
                        ),

                        const SizedBox(width: 4),

                        Flexible(
                          child: Text(
                            'Kalkış: ${route.departurePoint}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color:
                              AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: hasTripsToday
                            ? AppColors.primary.withValues(
                          alpha: 0.07,
                        )
                            : AppColors.background,
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasTripsToday
                                ? Icons
                                .schedule_rounded
                                : Icons
                                .event_busy_outlined,
                            color: hasTripsToday
                                ? AppColors.primary
                                : AppColors
                                .textSecondary,
                            size: 12,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            hasTripsToday
                                ? 'Bugün $todayTripCount sefer'
                                : 'Bugün sefer yok',
                            style: TextStyle(
                              color: hasTripsToday
                                  ? AppColors.primary
                                  : AppColors
                                  .textSecondary,
                              fontSize: 8.5,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.07,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HATA
// ============================================================

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({
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
                color: AppColors.error.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 31,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Sefer bilgileri yüklenemedi',
              style: TextStyle(
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
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text(
                'Tekrar Dene',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BOŞ DURUM
// ============================================================

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_outlined,
              color: AppColors.textSecondary,
              size: 38,
            ),
            SizedBox(height: 12),
            Text(
              'Henüz sefer bilgisi bulunmuyor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}