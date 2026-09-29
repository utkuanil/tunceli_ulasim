import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/bus_route.dart';
import '../../models/bus_trip.dart';

class ScheduleDetailPage extends StatefulWidget {
  final BusRoute route;

  const ScheduleDetailPage({
    super.key,
    required this.route,
  });

  @override
  State<ScheduleDetailPage> createState() =>
      _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late bool _showWeekday;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _showWeekday =
        now.weekday >= DateTime.monday &&
            now.weekday <= DateTime.friday;
  }

  @override
  Widget build(BuildContext context) {
    final trips = _getVisibleTrips();
    final nextTripIndex = _getNextTripIndex(trips);
    final selectedTabIsToday = _isSelectedTabToday();

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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              16,
              6,
              16,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _RouteScheduleHero(
                    route: widget.route,
                    tripCount: trips.length,
                  ),

                  const SizedBox(height: 14),

                  _ScheduleTabs(
                    showWeekday: _showWeekday,
                    onWeekdayTap: () {
                      setState(() {
                        _showWeekday = true;
                      });
                    },
                    onWeekendTap: () {
                      setState(() {
                        _showWeekday = false;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  _ScheduleSummary(
                    showWeekday: _showWeekday,
                    tripCount: trips.length,
                    selectedTabIsToday:
                    selectedTabIsToday,
                    nextTrip: nextTripIndex >= 0
                        ? trips[nextTripIndex]
                        : null,
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          if (trips.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                showWeekday: _showWeekday,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                30,
              ),
              sliver: SliverList.separated(
                itemCount: trips.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  final trip = trips[index];

                  return _TripCard(
                    trip: trip,
                    isNext: index == nextTripIndex,
                    isPast: _isTripPast(trip),
                    order: index + 1,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  List<BusTrip> _getVisibleTrips() {
    final now = DateTime.now();

    final List<BusTrip> source = _showWeekday
        ? widget.route.weekday
        : widget.route.weekend;

    if (!_showWeekday) {
      return source;
    }

    final bool todayIsWeekday =
        now.weekday >= DateTime.monday &&
            now.weekday <= DateTime.friday;

    // Kullanıcı hafta sonundayken manuel olarak
    // hafta içi programını görüntülüyorsa tüm hafta
    // içi kayıtlarını göster.
    if (!todayIsWeekday) {
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

  int _getNextTripIndex(List<BusTrip> trips) {
    if (!_isSelectedTabToday()) {
      return -1;
    }

    final now = DateTime.now();

    for (int i = 0; i < trips.length; i++) {
      final tripDateTime =
      _tripDateTime(trips[i], now);

      if (tripDateTime != null &&
          !tripDateTime.isBefore(now)) {
        return i;
      }
    }

    return -1;
  }

  bool _isTripPast(BusTrip trip) {
    if (!_isSelectedTabToday()) {
      return false;
    }

    final now = DateTime.now();
    final tripDateTime =
    _tripDateTime(trip, now);

    if (tripDateTime == null) {
      return false;
    }

    return tripDateTime.isBefore(now);
  }

  bool _isSelectedTabToday() {
    final now = DateTime.now();

    final todayIsWeekday =
        now.weekday >= DateTime.monday &&
            now.weekday <= DateTime.friday;

    return (_showWeekday && todayIsWeekday) ||
        (!_showWeekday && !todayIsWeekday);
  }

  DateTime? _tripDateTime(
      BusTrip trip,
      DateTime date,
      ) {
    final parts = trip.time.split(':');

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
}

// ============================================================
// HERO
// ============================================================

class _RouteScheduleHero extends StatelessWidget {
  final BusRoute route;
  final int tripCount;

  const _RouteScheduleHero({
    required this.route,
    required this.tripCount,
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
              right: 35,
              bottom: -70,
              child: Container(
                width: 135,
                height: 135,
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
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.14,
                          ),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'SEFER PROGRAMI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
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
                              Icons.schedule_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$tripCount sefer',
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

                  const SizedBox(height: 18),

                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                            fontSize: 19,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white,
                          size: 17,
                        ),

                        const SizedBox(width: 7),

                        const Text(
                          'Kalkış',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(width: 7),

                        Expanded(
                          child: Text(
                            route.departurePoint,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (route.note != null &&
                      route.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                        BorderRadius.circular(13),
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                                color:
                                Colors.white.withValues(
                                  alpha: 0.90,
                                ),
                                fontSize: 10,
                                height: 1.4,
                                fontWeight:
                                FontWeight.w500,
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

// ============================================================
// HAFTA İÇİ / HAFTA SONU
// ============================================================

class _ScheduleTabs extends StatelessWidget {
  final bool showWeekday;
  final VoidCallback onWeekdayTap;
  final VoidCallback onWeekendTap;

  const _ScheduleTabs({
    required this.showWeekday,
    required this.onWeekdayTap,
    required this.onWeekendTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DayButton(
              title: 'Hafta İçi',
              icon: Icons.business_center_outlined,
              selected: showWeekday,
              onTap: onWeekdayTap,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _DayButton(
              title: 'Hafta Sonu',
              icon: Icons.weekend_outlined,
              selected: !showWeekday,
              onTap: onWeekendTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DayButton({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ÖZET
// ============================================================

class _ScheduleSummary extends StatelessWidget {
  final bool showWeekday;
  final int tripCount;
  final bool selectedTabIsToday;
  final BusTrip? nextTrip;

  const _ScheduleSummary({
    required this.showWeekday,
    required this.tripCount,
    required this.selectedTabIsToday,
    required this.nextTrip,
  });

  @override
  Widget build(BuildContext context) {
    String subtitle;
    IconData icon;
    Color iconColor;

    if (tripCount == 0) {
      subtitle = 'Yayınlanmış sefer bulunmuyor';
      icon = Icons.event_busy_outlined;
      iconColor = AppColors.textSecondary;
    } else if (!selectedTabIsToday) {
      subtitle = '$tripCount planlı sefer';
      icon = Icons.calendar_month_outlined;
      iconColor = AppColors.primary;
    } else if (nextTrip != null) {
      subtitle = 'Sıradaki hareket ${nextTrip!.time}';
      icon = Icons.access_time_rounded;
      iconColor = AppColors.primary;
    } else {
      subtitle = 'Bugünkü seferler tamamlandı';
      icon = Icons.check_circle_outline_rounded;
      iconColor = AppColors.textSecondary;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                showWeekday
                    ? 'Hafta İçi Seferleri'
                    : 'Hafta Sonu Seferleri',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (tripCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.07,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$tripCount sefer',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// SEFER KARTI
// ============================================================

class _TripCard extends StatelessWidget {
  final BusTrip trip;
  final bool isNext;
  final bool isPast;
  final int order;

  const _TripCard({
    required this.trip,
    required this.isNext,
    required this.isPast,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(
        milliseconds: 180,
      ),
      opacity: isPast ? 0.52 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: isNext
              ? AppColors.primary.withValues(
            alpha: 0.055,
          )
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isNext
                ? AppColors.primary
                : AppColors.divider,
            width: isNext ? 1.4 : 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              if (isNext)
                Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isNext ? 11 : 15,
                    13,
                    14,
                    13,
                  ),
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isNext
                              ? AppColors.primary
                              : AppColors.primary
                              .withValues(
                            alpha: 0.08,
                          ),
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Text(
                              trip.time,
                              style: TextStyle(
                                color: isNext
                                    ? Colors.white
                                    : AppColors.primary,
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),

                            if (isNext) ...[
                              const SizedBox(height: 2),
                              const Text(
                                'SIRADAKİ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 6.5,
                                  fontWeight:
                                  FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Text(
                              trip.destination,
                              style: const TextStyle(
                                color:
                                AppColors.textPrimary,
                                fontSize: 13,
                                height: 1.35,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),

                            if (trip.note != null &&
                                trip.note!
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 7),

                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning
                                      .withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(
                                    9,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize:
                                  MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons
                                          .info_outline_rounded,
                                      color:
                                      AppColors.warning,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        trip.note!,
                                        style:
                                        const TextStyle(
                                          color: AppColors
                                              .textPrimary,
                                          fontSize: 9,
                                          fontWeight:
                                          FontWeight
                                              .w600,
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

                      const SizedBox(width: 8),

                      Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Text(
                            order.toString().padLeft(
                              2,
                              '0',
                            ),
                            style: TextStyle(
                              color: AppColors.textSecondary
                                  .withValues(
                                alpha: 0.55,
                              ),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          if (isPast) ...[
                            const SizedBox(height: 4),
                            const Icon(
                              Icons
                                  .check_circle_outline_rounded,
                              color:
                              AppColors.textSecondary,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
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
// BOŞ DURUM
// ============================================================

class _EmptyState extends StatelessWidget {
  final bool showWeekday;

  const _EmptyState({
    required this.showWeekday,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        30,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 32,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.divider,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_outlined,
                  color: AppColors.textSecondary,
                  size: 28,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                showWeekday
                    ? 'Hafta içi seferi bulunmuyor'
                    : 'Hafta sonu seferi bulunmuyor',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Bu hat için yayınlanmış sefer '
                    'bilgisi bulunmamaktadır.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}