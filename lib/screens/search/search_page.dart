import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/bus_route.dart';
import '../../services/schedule_service.dart';
import '../routes/route_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ScheduleService _scheduleService = ScheduleService();

  final TextEditingController _searchController =
  TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  List<BusRoute> _allRoutes = [];
  List<BusRoute> _filteredRoutes = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadRoutes();

    // Ekran açılınca klavye otomatik açılsın.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  Future<void> _loadRoutes() async {
    try {
      final routes = await _scheduleService.getRoutes();

      if (!mounted) return;

      setState(() {
        _allRoutes = routes;
        _filteredRoutes = routes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _search(String value) {
    final query = _normalizeText(value.trim());

    setState(() {
      if (query.isEmpty) {
        _filteredRoutes = _allRoutes;
        return;
      }

      _filteredRoutes = _allRoutes.where((route) {
        final routeName = _normalizeText(route.name);

        final departurePoint =
        _normalizeText(route.departurePoint);

        final routeNote =
        _normalizeText(route.note ?? '');

        // Hat adında ara
        if (routeName.contains(query)) {
          return true;
        }

        // Kalkış noktasında ara
        if (departurePoint.contains(query)) {
          return true;
        }

        // Hat açıklamasında ara
        if (routeNote.contains(query)) {
          return true;
        }

        // Seferlerin hedef/güzergâh açıklamalarında ara.
        //
        // Örneğin "TOKİ", "Bardaktepe",
        // "Meslek Lisesi" gibi ifadeler de
        // ilgili hattı bulabilsin.
        final allTrips = [
          ...route.weekday,
          ...route.weekend,
        ];

        return allTrips.any(
              (trip) =>
              _normalizeText(trip.destination)
                  .contains(query),
        );
      }).toList();
    });
  }

  /// Türkçe karakterleri arama için sadeleştirir.
  ///
  /// Böylece:
  /// "İnönü" -> "inonu"
  /// "Üniversite" -> "universite"
  /// "Çiçekli" -> "cicekli"
  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ara',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // ARAMA ALANI
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
              16,
              6,
              16,
              16,
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Hat veya güzergâh ara',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),

                // Kullanıcı yazmaya başladığında
                // temizleme butonu göster.
                suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                  tooltip: 'Temizle',
                  onPressed: () {
                    _searchController.clear();
                    _search('');
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                  ),
                )
                    : null,
              ),
            ),
          ),

          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredRoutes.isEmpty) {
      return _buildNoResult();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        24,
      ),
      children: [
        Row(
          children: [
            Text(
              _searchController.text.trim().isEmpty
                  ? 'Tüm Hatlar'
                  : 'Arama Sonuçları',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_filteredRoutes.length} hat',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 13),

        ..._filteredRoutes.map(
              (route) => Padding(
            padding: const EdgeInsets.only(
              bottom: 11,
            ),
            child: _SearchRouteCard(
              route: route,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RouteDetailPage(
                      route: route,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Sonuç bulunamadı',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '"${_searchController.text}" için eşleşen bir hat bulunamadı.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ========================================================
// ARAMA SONUCU HAT KARTI
// ========================================================

class _SearchRouteCard extends StatelessWidget {
  final BusRoute route;
  final VoidCallback onTap;

  const _SearchRouteCard({
    required this.route,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.divider,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.primary,
                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),

                        const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            'Kalkış: ${route.departurePoint}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (route.note != null) ...[
                      const SizedBox(height: 5),

                      Text(
                        route.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 6),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}