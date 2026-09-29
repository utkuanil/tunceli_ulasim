import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_colors.dart';
import '../../models/bus_route.dart';
import '../../models/bus_stop.dart';
import '../../models/route_geometry.dart';
import '../../models/route_stop_time.dart';
import '../../models/route_stop_trip.dart';
import '../../services/route_geometry_service.dart';
import '../../services/route_stop_time_service.dart';
import '../../services/stop_service.dart';

class RouteStopsPage extends StatefulWidget {
  final BusRoute route;

  const RouteStopsPage({
    super.key,
    required this.route,
  });

  @override
  State<RouteStopsPage> createState() => _RouteStopsPageState();
}

class _RouteStopsPageState extends State<RouteStopsPage> {
  final RouteStopTimeService _stopTimeService =
  RouteStopTimeService();

  final RouteGeometryService _routeGeometryService =
  RouteGeometryService();

  final StopService _stopService = StopService();

  bool _loading = true;
  String? _error;

  List<RouteStopTrip> _timedTrips = [];
  int _selectedTripIndex = 0;

  RouteGeometry? _routeGeometry;
  List<BusStop> _routeStops = [];
  bool _showUniversityRouteStops = false;

  bool get _isUniversityRoute =>
      widget.route.id == 'ataturk_universite_aktuluk';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final geometry =
      await _routeGeometryService.getGeometryForRoute(
        widget.route.id,
      );

      final allStops = await _stopService.getStops();

      final routeStops = geometry == null
          ? <BusStop>[]
          : _filterStopsNearRoute(
        allStops,
        geometry,
      );

      List<RouteStopTrip> timedTrips = [];

      if (_isUniversityRoute) {
        timedTrips =
        await _stopTimeService.getTripsForRoute(
          widget.route.id,
        );
      }

      if (!mounted) return;

      setState(() {
        _routeGeometry = geometry;
        _routeStops = routeStops;
        _timedTrips = timedTrips;
        _selectedTripIndex = 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Durak bilgileri yüklenemedi.';
      });
    }
  }

  List<BusStop> _filterStopsNearRoute(
      List<BusStop> stops,
      RouteGeometry geometry, {
        double maxDistanceMeters = 90,
      }) {
    return stops.where((stop) {
      final distance =
      _distanceFromStopToGeometry(
        stop,
        geometry,
      );

      return distance <= maxDistanceMeters;
    }).toList();
  }

  double _distanceFromStopToGeometry(
      BusStop stop,
      RouteGeometry geometry,
      ) {
    double bestDistance = double.infinity;

    for (final part in geometry.parts) {
      final points = part.coordinates;

      if (points.length == 1) {
        final point = points.first;

        final distance =
        Geolocator.distanceBetween(
          stop.latitude,
          stop.longitude,
          point.latitude,
          point.longitude,
        );

        if (distance < bestDistance) {
          bestDistance = distance;
        }

        continue;
      }

      for (int i = 0; i < points.length - 1; i++) {
        final distance =
        _distancePointToSegmentMeters(
          stop.latitude,
          stop.longitude,
          points[i],
          points[i + 1],
        );

        if (distance < bestDistance) {
          bestDistance = distance;
        }
      }
    }

    return bestDistance;
  }

  double _distancePointToSegmentMeters(
      double pointLat,
      double pointLon,
      RouteGeometryPoint a,
      RouteGeometryPoint b,
      ) {
    const earthRadius = 6371000.0;

    final lat0 =
        pointLat * math.pi / 180.0;

    final cosLat = math.cos(lat0);

    final ax =
        (a.longitude - pointLon) *
            math.pi /
            180.0 *
            cosLat *
            earthRadius;

    final ay =
        (a.latitude - pointLat) *
            math.pi /
            180.0 *
            earthRadius;

    final bx =
        (b.longitude - pointLon) *
            math.pi /
            180.0 *
            cosLat *
            earthRadius;

    final by =
        (b.latitude - pointLat) *
            math.pi /
            180.0 *
            earthRadius;

    final vx = bx - ax;
    final vy = by - ay;

    final denominator =
        vx * vx + vy * vy;

    if (denominator == 0) {
      return math.sqrt(
        ax * ax + ay * ay,
      );
    }

    var t =
        -(ax * vx + ay * vy) /
            denominator;

    t = t.clamp(0.0, 1.0).toDouble();

    final closestX = ax + t * vx;
    final closestY = ay + t * vy;

    return math.sqrt(
      closestX * closestX +
          closestY * closestY,
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
          'Hat Durakları',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.4,
        ),
      )
          : _error != null
          ? _ErrorView(
        message: _error!,
        onRetry: _loadData,
      )
          : _isUniversityRoute
          ? _buildUniversityContent()
          : _routeGeometry != null
          ? _buildGeometryContent()
          : const _NoDataView(
        message:
        'Bu hat için belediyeden alınan güzergâh geometrisi bulunmuyor.',
      ),
    );
  }

  // ============================================================
  // ÜNİVERSİTE HATTI
  // ============================================================

  Widget _buildUniversityContent() {
    if (_timedTrips.isEmpty &&
        _routeStops.isEmpty) {
      return const _NoDataView();
    }

    final RouteStopTrip? selectedTrip =
    _timedTrips.isEmpty
        ? null
        : _timedTrips[_selectedTripIndex];

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          16,
          6,
          16,
          32,
        ),
        children: [
          _RouteHeader(
            route: widget.route,
            subtitle:
            '${_routeStops.length} güzergâha yakın durak • '
                '${_timedTrips.length} sefer için geçiş bilgisi',
          ),

          const SizedBox(height: 14),

          const _InfoCard(
            icon: Icons.verified_outlined,
            text:
            'Güzergâha yakın duraklar belediyeden alınan KML '
                'güzergâh çizgisi ile 81 resmî durak konumunun '
                'yakınlığına göre gösterilir. Bu liste resmî durak '
                'sırasını ifade etmez. Sefer geçiş saatleri ise '
                'ayrıca sağlanan sefer bilgilerinden alınmıştır.',
          ),

          const SizedBox(height: 18),

          _RouteStopsSummaryCard(
            stopCount: _routeStops.length,
            expanded: _showUniversityRouteStops,
            onTap: () {
              setState(() {
                _showUniversityRouteStops =
                !_showUniversityRouteStops;
              });
            },
          ),

          if (_showUniversityRouteStops &&
              _routeStops.isNotEmpty) ...[
            const SizedBox(height: 12),

            _UnorderedStopsList(
              stops: _routeStops,
            ),

            const SizedBox(height: 24),
          ] else
            const SizedBox(height: 24),

          if (_timedTrips.isNotEmpty) ...[
            const _SectionTitle(
              title: 'Sefer Geçiş Saatleri',
              subtitle:
              'Durak geçiş saatlerini görmek istediğiniz hareket saatini seçin',
            ),

            const SizedBox(height: 12),

            _TripSelector(
              trips: _timedTrips,
              selectedIndex: _selectedTripIndex,
              onSelected: (index) {
                setState(() {
                  _selectedTripIndex = index;
                });
              },
            ),

            if (selectedTrip != null) ...[
              const SizedBox(height: 20),

              _SelectedTripCard(
                trip: selectedTrip,
              ),

              const SizedBox(height: 24),

              _SectionTitle(
                title: 'Kayıtlı Geçiş Noktaları',
                subtitle:
                '${selectedTrip.stops.length} geçiş noktasında saat bilgisi bulunuyor',
              ),

              const SizedBox(height: 12),

              _TimedStopsTimeline(
                stops: selectedTrip.stops,
              ),

              if (selectedTrip.hasEstimatedTimes) ...[
                const SizedBox(height: 16),
                const _EstimatedTimeInfoCard(),
              ],
            ],
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DİĞER HATLAR
  // ============================================================

  Widget _buildGeometryContent() {
    if (_routeStops.isEmpty) {
      return const _NoDataView(
        message:
        'Bu güzergâhın yakınında eşleşen durak bulunamadı.',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          16,
          6,
          16,
          32,
        ),
        children: [
          _RouteHeader(
            route: widget.route,
            subtitle:
            '${_routeStops.length} güzergâha yakın resmî durak',
          ),

          const SizedBox(height: 14),

          const _InfoCard(
            icon: Icons.route_rounded,
            text:
            'Aşağıdaki duraklar belediyeden alınan KML güzergâh '
                'çizgisinin yaklaşık 90 metre çevresindeki resmî '
                'durak konumlarıdır. Yakınlık ilişkisi uygulama '
                'tarafında hesaplandığı için liste resmî durak '
                'sırası olarak yorumlanmamalıdır.',
          ),

          const SizedBox(height: 24),

          _SectionTitle(
            title: 'Güzergâha Yakın Duraklar',
            subtitle:
            '${_routeStops.length} resmî durak konumu',
          ),

          const SizedBox(height: 12),

          _UnorderedStopsList(
            stops: _routeStops,
          ),
        ],
      ),
    );
  }

}

// ============================================================
// ORTAK HEADER
// ============================================================

class _RouteHeader extends StatelessWidget {
  final BusRoute route;
  final String subtitle;

  const _RouteHeader({
    required this.route,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: 0.17,
            ),
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
                  color: Colors.white.withValues(
                    alpha: 0.14,
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
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HAT DURAK BİLGİLERİ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      route.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

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
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white,
                  size: 17,
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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

// ============================================================
// BİLGİ KARTLARI
// ============================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoCard({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStopsSummaryCard extends StatelessWidget {
  final int stopCount;
  final bool expanded;
  final VoidCallback onTap;

  const _RouteStopsSummaryCard({
    required this.stopCount,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: stopCount == 0 ? null : onTap,
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
                child: const Icon(
                  Icons.location_on_rounded,
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
                      'Güzergâha Yakın Duraklar',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '$stopCount resmî durak konumu',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              if (stopCount > 0)
                Row(
                  children: [
                    Text(
                      expanded
                          ? 'Gizle'
                          : 'Göster',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 20,
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

// ============================================================
// BÖLÜM BAŞLIĞI
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ÜNİVERSİTE HATTI - SEFER SEÇİCİ
// ============================================================

class _TripSelector extends StatelessWidget {
  final List<RouteStopTrip> trips;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _TripSelector({
    required this.trips,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: trips.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final trip = trips[index];
          final selected =
              index == selectedIndex;

          return Material(
            color: selected
                ? AppColors.primary
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                width: 78,
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Text(
                      trip.departure,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontSize: 16,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      trip.hasEstimatedTimes
                          ? 'TAHMİNİ'
                          : 'VERİLEN',
                      style: TextStyle(
                        color: selected
                            ? Colors.white70
                            : trip.hasEstimatedTimes
                            ? AppColors.warning
                            : AppColors.primary,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SelectedTripCard extends StatelessWidget {
  final RouteStopTrip trip;

  const _SelectedTripCard({
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.09,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.departure_board_rounded,
              color: AppColors.primary,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  trip.departure,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  trip.destination,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

// ============================================================
// ÜNİVERSİTE - SAATLİ TIMELINE
// ============================================================

class _TimedStopsTimeline extends StatelessWidget {
  final List<RouteStopTime> stops;

  const _TimedStopsTimeline({
    required this.stops,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        16,
        14,
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Column(
        children: List.generate(
          stops.length,
              (index) {
            final stop = stops[index];

            return _TimedStopRow(
              stop: stop,
              isFirst: index == 0,
              isLast: index == stops.length - 1,
            );
          },
        ),
      ),
    );
  }
}

class _TimedStopRow extends StatelessWidget {
  final RouteStopTime stop;
  final bool isFirst;
  final bool isLast;

  const _TimedStopRow({
    required this.stop,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return _TimelineBase(
      isFirst: isFirst,
      isLast: isLast,
      child: Row(
        children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: stop.estimated
                  ? AppColors.warning.withValues(
                alpha: 0.09,
              )
                  : AppColors.primary.withValues(
                alpha: 0.07,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              children: [
                Text(
                  stop.time,
                  style: TextStyle(
                    color: stop.estimated
                        ? AppColors.warning
                        : AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                if (stop.estimated) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'TAHMİNİ',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              stop.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnorderedStopsList extends StatelessWidget {
  final List<BusStop> stops;

  const _UnorderedStopsList({
    required this.stops,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        stops.length,
            (index) {
          final stop = stops[index];

          return Container(
            margin: EdgeInsets.only(
              bottom:
              index == stops.length - 1 ? 0 : 8,
            ),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                    AppColors.primary.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '${stop.latitude.toStringAsFixed(5)}, '
                            '${stop.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          color:
                          AppColors.textSecondary,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// TIMELINE ORTAK GÖVDE
// ============================================================

class _TimelineBase extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final Widget child;

  const _TimelineBase({
    required this.isFirst,
    required this.isLast,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color:
                      AppColors.primary.withValues(
                        alpha: 0.22,
                      ),
                    ),
                  )
                else
                  const Spacer(),

                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isFirst || isLast
                        ? AppColors.primary
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2.5,
                    ),
                  ),
                ),

                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color:
                      AppColors.primary.withValues(
                        alpha: 0.22,
                      ),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 7,
                bottom: isLast ? 7 : 15,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimatedTimeInfoCard extends StatelessWidget {
  const _EstimatedTimeInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.warning.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.access_time_rounded,
            color: AppColors.warning,
            size: 18,
          ),

          SizedBox(width: 9),

          Expanded(
            child: Text(
              'Tahmini geçiş saatleri, paylaşılan örnek '
                  'seferlerdeki duraklar arası süreler esas '
                  'alınarak hesaplanmıştır. Trafik ve yol '
                  'koşullarına göre farklılık gösterebilir.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOŞ / HATA
// ============================================================

class _NoDataView extends StatelessWidget {
  final String message;

  const _NoDataView({
    this.message =
    'Bu hat için durak bilgisi henüz bulunmuyor.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 32,
            horizontal: 20,
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
              const Icon(
                Icons.route_outlined,
                color: AppColors.textSecondary,
                size: 34,
              ),

              const SizedBox(height: 11),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
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
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 36,
            ),

            const SizedBox(height: 12),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 12),

            FilledButton(
              onPressed: onRetry,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
