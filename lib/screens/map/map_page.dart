import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../models/bus_stop.dart';
import '../../models/route_geometry.dart';
import '../../services/favorite_service.dart';
import '../../services/route_geometry_service.dart';
import '../../services/stop_service.dart';

class MapPage extends StatefulWidget {
  final bool autoFindNearest;
  final String? initialStopId;
  final String? routeId;
  final String? routeName;

  const MapPage({
    super.key,
    this.autoFindNearest = false,
    this.initialStopId,
    this.routeId,
    this.routeName,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final StopService _stopService = StopService();
  final FavoriteService _favoriteService = FavoriteService();
  final RouteGeometryService _routeGeometryService =
  RouteGeometryService();

  static const LatLng _tunceliCenter = LatLng(
    39.1079,
    39.5401,
  );

  static const double _initialZoom = 14.0;

  List<BusStop> _stops = [];
  List<BusStop> _routeStops = [];
  List<_NearbyStopInfo> _nearbyStops = [];
  Set<String> _favoriteStopIds = <String>{};
  RouteGeometry? _routeGeometry;

  bool _loading = true;
  bool _showStops = true;
  bool _isLocating = false;
  bool _autoFindTriggered = false;

  String? _error;
  String? _selectedStopId;

  Position? _userPosition;

  double _currentZoom = _initialZoom;

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  // ============================================================
  // DURAKLARI YÜKLE
  // ============================================================

  Future<void> _loadStops() async {
    try {
      final stops = await _stopService.getStops();
      final favoriteStopIds =
      await _favoriteService.getFavoriteStopIds();

      RouteGeometry? routeGeometry;

      if (widget.routeId != null) {
        routeGeometry =
        await _routeGeometryService.getGeometryForRoute(
          widget.routeId!,
        );
      }

      final routeStops = routeGeometry == null
          ? <BusStop>[]
          : _filterStopsNearRoute(
        stops,
        routeGeometry,
      );

      if (!mounted) return;

      setState(() {
        _stops = stops;
        _routeGeometry = routeGeometry;
        _routeStops = routeStops;
        _favoriteStopIds = favoriteStopIds.toSet();
        _loading = false;
        _error = null;
      });

      if (widget.initialStopId != null) {
        BusStop? targetStop;

        for (final stop in stops) {
          if (stop.id == widget.initialStopId) {
            targetStop = stop;
            break;
          }
        }

        if (targetStop != null) {
          final selected = targetStop;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _selectStop(selected);
          });

          return;
        }
      }

      if (routeGeometry != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _fitRouteGeometry();
        });
      }

      if (widget.autoFindNearest && !_autoFindTriggered) {
        _autoFindTriggered = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _findNearestStop();
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Durak veya güzergâh bilgileri yüklenemedi.';
      });
    }
  }

  List<BusStop> get _visibleStops {
    if (widget.routeId != null) {
      return _routeStops;
    }

    return _stops;
  }

  List<BusStop> _filterStopsNearRoute(
      List<BusStop> stops,
      RouteGeometry geometry, {
        double maxDistanceMeters = 90,
      }) {
    return stops.where((stop) {
      final distance =
      _distanceFromStopToGeometry(stop, geometry);

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

        final distance = Geolocator.distanceBetween(
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
        final distance = _distancePointToSegmentMeters(
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

    final lat0 = pointLat * 3.141592653589793 / 180.0;
    final cosLat = math.cos(lat0);

    final ax =
        (a.longitude - pointLon) *
            3.141592653589793 /
            180.0 *
            cosLat *
            earthRadius;

    final ay =
        (a.latitude - pointLat) *
            3.141592653589793 /
            180.0 *
            earthRadius;

    final bx =
        (b.longitude - pointLon) *
            3.141592653589793 /
            180.0 *
            cosLat *
            earthRadius;

    final by =
        (b.latitude - pointLat) *
            3.141592653589793 /
            180.0 *
            earthRadius;

    final vx = bx - ax;
    final vy = by - ay;

    final denominator = vx * vx + vy * vy;

    if (denominator == 0) {
      return math.sqrt(ax * ax + ay * ay);
    }

    var t = -(ax * vx + ay * vy) / denominator;
    t = t.clamp(0.0, 1.0).toDouble();

    final closestX = ax + t * vx;
    final closestY = ay + t * vy;

    return math.sqrt(
      closestX * closestX + closestY * closestY,
    );
  }

  void _fitRouteGeometry() {
    final geometry = _routeGeometry;

    if (geometry == null) return;

    final points = geometry.parts
        .expand((part) => part.coordinates)
        .map(
          (point) => LatLng(
        point.latitude,
        point.longitude,
      ),
    )
        .toList();

    if (points.isEmpty) return;

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(
          34,
          95,
          34,
          115,
        ),
      ),
    );
  }

  // ============================================================
  // DURAK SEÇİMİ
  // ============================================================

  void _moveToStop(BusStop stop) {
    _mapController.move(
      LatLng(
        stop.latitude,
        stop.longitude,
      ),
      17,
    );
  }

  Future<void> _selectStop(BusStop stop) async {
    setState(() {
      _selectedStopId = stop.id;
    });

    _moveToStop(stop);

    await _showStopDetails(stop);
  }

  Future<void> _showStopDetails(BusStop stop) async {
    // Her durak açılışında favorileri kalıcı hafızadan yeniden oku.
    final favoriteStopIds =
    await _favoriteService.getFavoriteStopIds();

    if (!mounted) return;

    setState(() {
      _favoriteStopIds = favoriteStopIds.toSet();
    });

    final distance = _distanceToStop(stop);

    final isFavorite =
    _favoriteStopIds.contains(stop.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _StopBottomSheet(
          stop: stop,
          distanceText: distance == null
              ? null
              : _formatDistance(distance),
          initialFavorite: isFavorite,
          onFavoriteTap: () =>
              _toggleStopFavorite(stop),
          onDirectionsTap: () {
            _openDirections(stop);
          },
        );
      },
    ).whenComplete(() {
      if (!mounted) return;

      setState(() {
        _selectedStopId = null;
      });
    });
  }
  Future<bool> _toggleStopFavorite(BusStop stop) async {
    final newStatus =
    await _favoriteService.toggleFavoriteStop(stop.id);

    if (!mounted) {
      return newStatus;
    }

    setState(() {
      if (newStatus) {
        _favoriteStopIds.add(stop.id);
      } else {
        _favoriteStopIds.remove(stop.id);
      }
    });

    _showMessage(
      newStatus
          ? '${stop.name} favori duraklara eklendi.'
          : '${stop.name} favori duraklardan çıkarıldı.',
    );

    return newStatus;
  }

  double? _distanceToStop(BusStop stop) {
    final position = _userPosition;

    if (position == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      stop.latitude,
      stop.longitude,
    );
  }

  List<_NearbyStopInfo> _calculateNearbyStops(
      Position position, {
        int limit = 5,
      }) {
    final items = _visibleStops.map((stop) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        stop.latitude,
        stop.longitude,
      );

      return _NearbyStopInfo(
        stop: stop,
        distance: distance,
      );
    }).toList()
      ..sort(
            (a, b) => a.distance.compareTo(b.distance),
      );

    if (items.length <= limit) {
      return items;
    }

    return items.take(limit).toList();
  }

  void _moveToUserLocation() {
    final position = _userPosition;

    if (position == null) {
      _showMessage(
        'Önce konumunuzu belirleyin.',
      );
      return;
    }

    _mapController.move(
      LatLng(
        position.latitude,
        position.longitude,
      ),
      17.5,
    );
  }

  void _showNearbyStops() {
    if (_nearbyStops.isEmpty) {
      _findNearestStop();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _NearbyStopsSheet(
          nearbyStops: _nearbyStops,
          favoriteStopIds: _favoriteStopIds,
          formatDistance: _formatDistance,
          onRefresh: () async {
            Navigator.pop(context);
            await _findNearestStop();
          },
          onStopTap: (stop) {
            Navigator.pop(context);

            Future.delayed(
              const Duration(milliseconds: 150),
                  () {
                if (!mounted) return;
                _selectStop(stop);
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // GOOGLE MAPS YOL TARİFİ
  // ============================================================

  Future<void> _openDirections(BusStop stop) async {
    if (Platform.isIOS) {
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(
                12,
                0,
                12,
                12,
              ),
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(
                        bottom: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const Text(
                    'Harita Uygulaması Seçin',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${stop.name} durağı için yol tarifi',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DirectionsAppTile(
                    icon: Icons.map_rounded,
                    title: 'Apple Haritalar',
                    subtitle:
                    'Apple Haritalar ile yol tarifi aç',
                    onTap: () {
                      Navigator.pop(context);
                      _openAppleMaps(stop);
                    },
                  ),
                  const SizedBox(height: 8),
                  _DirectionsAppTile(
                    icon: Icons.navigation_rounded,
                    title: 'Google Haritalar',
                    subtitle:
                    'Google Haritalar ile yol tarifi aç',
                    onTap: () {
                      Navigator.pop(context);
                      _openGoogleMaps(stop);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );

      return;
    }

    await _openGoogleMaps(stop);
  }

  Future<void> _openAppleMaps(BusStop stop) async {
    final originPart = _userPosition == null
        ? ''
        : '&saddr=${_userPosition!.latitude},'
        '${_userPosition!.longitude}';

    final uri = Uri.parse(
      'https://maps.apple.com/?'
          '$originPart'
          '&daddr=${stop.latitude},${stop.longitude}'
          '&dirflg=w',
    );

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showMessage(
        'Apple Haritalar açılamadı.',
      );
    }
  }

  Future<void> _openGoogleMaps(BusStop stop) async {
    final originPart = _userPosition == null
        ? ''
        : '&origin=${_userPosition!.latitude},'
        '${_userPosition!.longitude}';

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
          '$originPart'
          '&destination=${stop.latitude},${stop.longitude}'
          '&travelmode=walking',
    );

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showMessage(
        'Google Haritalar açılamadı.',
      );
    }
  }

  // ============================================================
  // EN YAKIN DURAK
  // ============================================================

  static const String _locationDisclosureKey =
      'location_disclosure_accepted';

  Future<bool> _showLocationDisclosureIfNeeded() async {
    final preferences = await SharedPreferences.getInstance();
    final accepted =
        preferences.getBool(_locationDisclosureKey) ?? false;

    if (accepted) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            22,
            22,
            22,
            0,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            22,
            16,
            22,
            8,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            14,
            4,
            14,
            14,
          ),
          title: Row(
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
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Konum İzni',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Konumunuz size en yakın durakları bulmak ve isteğiniz üzerine '
                'harita uygulamasında yol tarifi başlatmak için kullanılır. '
                'Konum bilgisi uygulama tarafından saklanmaz.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Vazgeç'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: const Text('Devam Et'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await preferences.setBool(
        _locationDisclosureKey,
        true,
      );
      return true;
    }

    return false;
  }

  Future<void> _findNearestStop() async {
    if (_isLocating) return;

    if (_stops.isEmpty) {
      _showMessage(
        'Durak bilgileri henüz yüklenmedi.',
      );
      return;
    }

    final disclosureAccepted =
    await _showLocationDisclosureIfNeeded();

    if (!disclosureAccepted || !mounted) {
      return;
    }

    setState(() {
      _isLocating = true;
    });

    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'En yakın durağı bulmak için telefonunuzun '
              'konum hizmetini açın.',
        );
        return;
      }

      var permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage(
          'En yakın durağı bulabilmek için '
              'konum izni gereklidir.',
        );
        return;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text(
                'Konum İzni Gerekli',
              ),
              content: const Text(
                'Konum izni kalıcı olarak kapatılmış. '
                    'En yakın durağı bulabilmek için '
                    'uygulama ayarlarından konum iznini açın.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Vazgeç',
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    await Geolocator.openAppSettings();
                  },
                  child: const Text(
                    'Ayarları Aç',
                  ),
                ),
              ],
            );
          },
        );

        return;
      }

      final position =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final nearbyStops =
      _calculateNearbyStops(position);

      if (nearbyStops.isEmpty) {
        _showMessage(
          'Yakın durak bulunamadı.',
        );
        return;
      }

      final nearestStop = nearbyStops.first;

      if (!mounted) return;

      setState(() {
        _userPosition = position;
        _nearbyStops = nearbyStops;
        _selectedStopId = nearestStop.stop.id;
        _showStops = true;
      });

      _mapController.move(
        LatLng(
          nearestStop.stop.latitude,
          nearestStop.stop.longitude,
        ),
        16.5,
      );

      _showMessage(
        'En yakın durak ${_formatDistance(nearestStop.distance)} uzaklıkta.',
      );

      Future.delayed(
        const Duration(milliseconds: 350),
            () {
          if (!mounted) return;

          _showNearbyStops();
        },
      );
    } catch (_) {
      _showMessage(
        'Konumunuz alınamadı. '
            'Lütfen tekrar deneyin.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // DURAK LİSTESİ
  // ============================================================

  void _showStopList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _StopsListSheet(
          stops: _visibleStops,
          onStopTap: (stop) {
            Navigator.pop(context);

            Future.delayed(
              const Duration(milliseconds: 150),
                  () {
                if (!mounted) return;

                _selectStop(stop);
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // EKRAN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool compactMarkers =
        _currentZoom < 15.5;
    final visibleStops = _visibleStops;
    final routeMode = widget.routeId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              routeMode
                  ? (widget.routeName ?? 'GÜZERGÂH')
                  : 'TUNCELİ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: routeMode ? 14 : 17,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: routeMode ? 0 : 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              routeMode
                  ? 'GÜZERGÂH HARİTASI'
                  : 'ULAŞIM HARİTASI',
              style: const TextStyle(
                fontSize: 9,
                height: 1,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _tunceliCenter,
              initialZoom: _initialZoom,
              minZoom: 5,
              maxZoom: 19,
              onPositionChanged:
                  (camera, hasGesture) {
                if ((_currentZoom - camera.zoom)
                    .abs() >
                    0.1) {
                  setState(() {
                    _currentZoom = camera.zoom;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/'
                    '{z}/{x}/{y}.png',
                userAgentPackageName:
                'tr.bel.tunceli.tunceli_ulasim',
              ),

              if (_routeGeometry != null)
                PolylineLayer(
                  polylines: _routeGeometry!.parts.map((part) {
                    return Polyline(
                      points: part.coordinates
                          .map(
                            (point) => LatLng(
                          point.latitude,
                          point.longitude,
                        ),
                      )
                          .toList(),
                      strokeWidth: 6,
                      color: AppColors.primary,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    );
                  }).toList(),
                ),

              // DURAKLAR
              if (_showStops)
                MarkerLayer(
                  markers: visibleStops.map((stop) {
                    final selected =
                        _selectedStopId == stop.id;

                    return Marker(
                      point: LatLng(
                        stop.latitude,
                        stop.longitude,
                      ),
                      width: selected
                          ? 50
                          : compactMarkers
                          ? 24
                          : 38,
                      height: selected
                          ? 50
                          : compactMarkers
                          ? 24
                          : 38,
                      child: GestureDetector(
                        onTap: () =>
                            _selectStop(stop),
                        child: _StopMarker(
                          compact: compactMarkers,
                          selected: selected,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // KULLANICI KONUMU
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _userPosition!.latitude,
                        _userPosition!.longitude,
                      ),
                      width: 60,
                      height: 60,
                      child: const _UserLocationMarker(),
                    ),
                  ],
                ),
            ],
          ),

          // ÜST DURAK BİLGİ KARTI
          Positioned(
            top: 14,
            left: 14,
            right: 70,
            child: _MapInfoCard(
              loading: _loading,
              error: _error,
              stopCount: visibleStops.length,
              title: routeMode
                  ? 'Güzergâh Durakları'
                  : 'Tunceli Durakları',
              subtitle: routeMode && _routeGeometry != null
                  ? '${_routeGeometry!.totalLengthKm.toStringAsFixed(2)} km • '
                  '${visibleStops.length} güzergâha yakın durak'
                  : null,
              onTap: visibleStops.isEmpty
                  ? null
                  : _showStopList,
            ),
          ),

          // TUNCELİ MERKEZE DÖN
          Positioned(
            top: 14,
            right: 14,
            child: _MapButton(
              icon:
              Icons.center_focus_strong_rounded,
              tooltip: routeMode
                  ? 'Güzergâhı ekrana sığdır'
                  : 'Tunceli merkeze dön',
              onTap: () {
                if (routeMode && _routeGeometry != null) {
                  _fitRouteGeometry();
                } else {
                  _mapController.move(
                    _tunceliCenter,
                    _initialZoom,
                  );
                }
              },
            ),
          ),

          // SAĞ ALT BUTONLAR
          Positioned(
            right: 14,
            bottom: 90,
            child: Column(
              children: [
                // DURAKLARI GİZLE / GÖSTER
                _MapButton(
                  icon: _showStops
                      ? Icons.location_on_rounded
                      : Icons.location_off_outlined,
                  tooltip: _showStops
                      ? 'Durakları gizle'
                      : 'Durakları göster',
                  active: _showStops,
                  onTap: () {
                    setState(() {
                      _showStops = !_showStops;
                    });
                  },
                ),

                const SizedBox(height: 9),

                // ZOOM +
                _MapButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Yakınlaştır',
                  onTap: () {
                    final camera = _mapController.camera;

                    final nextZoom =
                    (camera.zoom + 1).clamp(5.0, 19.0);

                    _mapController.move(
                      camera.center,
                      nextZoom,
                    );
                  },
                ),

                const SizedBox(height: 9),

                // ZOOM -
                _MapButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Uzaklaştır',
                  onTap: () {
                    final camera = _mapController.camera;

                    final nextZoom =
                    (camera.zoom - 1).clamp(5.0, 19.0);

                    _mapController.move(
                      camera.center,
                      nextZoom,
                    );
                  },
                ),
              ],
            ),
          ),

          // ALT KONUM AKSİYONLARI
          Positioned(
            left: 14,
            right: 76,
            bottom: 24,
            child: Row(
              children: [
                Expanded(
                  child: _LocationActionButton(
                    icon: Icons.near_me_rounded,
                    label: _isLocating
                        ? 'Konum aranıyor...'
                        : routeMode
                        ? 'Güzergâh Durakları (${visibleStops.length})'
                        : _userPosition == null
                        ? 'Yakındaki Duraklar'
                        : 'Yakındaki Duraklar (${_nearbyStops.length})',
                    loading: _isLocating,
                    onTap: routeMode
                        ? _showStopList
                        : _userPosition != null &&
                        _nearbyStops.isNotEmpty
                        ? _showNearbyStops
                        : _findNearestStop,
                  ),
                ),

                if (_userPosition != null) ...[
                  const SizedBox(width: 10),
                  _LocationRoundButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Konumuma dön',
                    onTap: _moveToUserLocation,
                  ),
                ],
              ],
            ),
          ),

          if (_loading)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(
                child: _LoadingPill(),
              ),
            ),

          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: _ErrorCard(
                message: _error!,
                onRetry: _loadStops,
              ),
            ),
        ],
      ),
    );
  }
}

class _DirectionsAppTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DirectionsAppTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// KULLANICI KONUM MARKER
// ============================================================

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.13),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 9,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location_rounded,
            color: Colors.white,
            size: 19,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DURAK MARKER
// ============================================================

class _StopMarker extends StatelessWidget {
  final bool compact;
  final bool selected;

  const _StopMarker({
    required this.compact,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    if (compact && !selected) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.18,
              ),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );
    }

    return AnimatedContainer(
      duration:
      const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary
            : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? Colors.white
              : AppColors.primary,
          width: selected ? 3 : 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha:
              selected ? 0.24 : 0.14,
            ),
            blurRadius:
            selected ? 11 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        Icons.directions_bus_rounded,
        color: selected
            ? Colors.white
            : AppColors.primary,
        size: selected ? 24 : 18,
      ),
    );
  }
}

// ============================================================
// HARİTA ÜST BİLGİ KARTI
// ============================================================

class _MapInfoCard extends StatelessWidget {
  final bool loading;
  final String? error;
  final int stopCount;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _MapInfoCard({
    required this.loading,
    required this.error,
    required this.stopCount,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(
        alpha: 0.96,
      ),
      elevation: 3,
      shadowColor: Colors.black.withValues(
        alpha: 0.10,
      ),
      borderRadius:
      BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(17),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                  AppColors.primary.withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color:
                        AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      loading
                          ? 'Duraklar yükleniyor...'
                          : error != null
                          ? 'Duraklar yüklenemedi'
                          : subtitle ??
                          '$stopCount durak konumu',
                      style: const TextStyle(
                        color: AppColors
                            .textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              if (!loading &&
                  error == null &&
                  stopCount > 0)
                const Icon(
                  Icons
                      .keyboard_arrow_up_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DURAK DETAYI
// ============================================================

class _StopBottomSheet extends StatefulWidget {
  final BusStop stop;
  final String? distanceText;
  final bool initialFavorite;
  final Future<bool> Function() onFavoriteTap;
  final VoidCallback onDirectionsTap;

  const _StopBottomSheet({
    required this.stop,
    required this.distanceText,
    required this.initialFavorite,
    required this.onFavoriteTap,
    required this.onDirectionsTap,
  });

  @override
  State<_StopBottomSheet> createState() =>
      _StopBottomSheetState();
}

class _StopBottomSheetState
    extends State<_StopBottomSheet> {
  late bool _isFavorite;
  bool _updatingFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialFavorite;
  }

  Future<void> _toggleFavorite() async {
    if (_updatingFavorite) return;

    setState(() {
      _updatingFavorite = true;
    });

    final newStatus = await widget.onFavoriteTap();

    if (!mounted) return;

    setState(() {
      _isFavorite = newStatus;
      _updatingFavorite = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.14,
              ),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.09,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DURAK KONUMU',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        stop.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: _isFavorite
                      ? 'Favorilerden çıkar'
                      : 'Favorilere ekle',
                  onPressed:
                  _updatingFavorite ? null : _toggleFavorite,
                  style: IconButton.styleFrom(
                    backgroundColor: _isFavorite
                        ? AppColors.error.withValues(alpha: 0.08)
                        : AppColors.primary.withValues(alpha: 0.07),
                  ),
                  icon: _updatingFavorite
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                      : Icon(
                    _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFavorite
                        ? AppColors.error
                        : AppColors.primary,
                    size: 21,
                  ),
                ),
              ],
            ),
            if (widget.distanceText != null) ...[
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.straighten_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Size uzaklık',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.distanceText!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${stop.latitude.toStringAsFixed(6)}, '
                          '${stop.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: widget.onDirectionsTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.directions_rounded,
                  size: 20,
                ),
                label: const Text(
                  'Yol Tarifi Al',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.textSecondary,
                  size: 15,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Konum, belediyeden alınan durak '
                        'verisine göre gösterilmektedir.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyStopInfo {
  final BusStop stop;
  final double distance;

  const _NearbyStopInfo({
    required this.stop,
    required this.distance,
  });
}

class _NearbyStopsSheet extends StatelessWidget {
  final List<_NearbyStopInfo> nearbyStops;
  final Set<String> favoriteStopIds;
  final String Function(double) formatDistance;
  final Future<void> Function() onRefresh;
  final ValueChanged<BusStop> onStopTap;

  const _NearbyStopsSheet({
    required this.nearbyStops,
    required this.favoriteStopIds,
    required this.formatDistance,
    required this.onRefresh,
    required this.onStopTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.near_me_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yakındaki Duraklar',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Konumunuza en yakın 5 durak',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Konumu yenile',
                  onPressed: () {
                    onRefresh();
                  },
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...List.generate(
              nearbyStops.length,
                  (index) {
                final item = nearbyStops[index];
                final favorite =
                favoriteStopIds.contains(item.stop.id);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                    index == nearbyStops.length - 1 ? 0 : 8,
                  ),
                  child: Material(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => onStopTap(item.stop),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? AppColors.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: index == 0
                                      ? Colors.white
                                      : AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.stop.name,
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color:
                                            AppColors.textPrimary,
                                            fontSize: 13,
                                            fontWeight:
                                            FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (favorite)
                                        const Padding(
                                          padding:
                                          EdgeInsets.only(left: 6),
                                          child: Icon(
                                            Icons.favorite_rounded,
                                            color: AppColors.error,
                                            size: 15,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatDistance(item.distance),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DURAK LİSTESİ
// ============================================================

class _StopsListSheet
    extends StatefulWidget {
  final List<BusStop> stops;
  final ValueChanged<BusStop> onStopTap;

  const _StopsListSheet({
    required this.stops,
    required this.onStopTap,
  });

  @override
  State<_StopsListSheet> createState() =>
      _StopsListSheetState();
}

class _StopsListSheetState
    extends State<_StopsListSheet> {
  String _query = '';

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  @override
  Widget build(BuildContext context) {
    final query =
    _normalize(_query.trim());

    final filteredStops =
    query.isEmpty
        ? widget.stops
        : widget.stops.where(
          (stop) {
        return _normalize(
          stop.name,
        ).contains(query);
      },
    ).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      builder:
          (context, scrollController) {
        return Container(
          decoration:
          const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),

              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
              ),

              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  17,
                  10,
                  10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration:
                      BoxDecoration(
                        color: AppColors.primary
                            .withValues(
                          alpha: 0.09,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          13,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .directions_bus_rounded,
                        color:
                        AppColors.primary,
                        size: 21,
                      ),
                    ),

                    const SizedBox(width: 11),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          const Text(
                            'Duraklar',
                            style: TextStyle(
                              color: AppColors
                                  .textPrimary,
                              fontSize: 18,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            '${widget.stops.length} durak konumu',
                            style:
                            const TextStyle(
                              color: AppColors
                                  .textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  12,
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                  decoration:
                  InputDecoration(
                    hintText: 'Durak ara',
                    prefixIcon:
                    const Icon(
                      Icons.search_rounded,
                    ),
                    filled: true,
                    fillColor:
                    AppColors.background,
                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 12,
                    ),
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                      borderSide:
                      BorderSide.none,
                    ),
                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                      borderSide:
                      BorderSide.none,
                    ),
                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                      borderSide:
                      const BorderSide(
                        color:
                        AppColors.primary,
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(
                height: 1,
                color: AppColors.divider,
              ),

              Expanded(
                child:
                filteredStops.isEmpty
                    ? const Center(
                  child: Text(
                    'Durak bulunamadı.',
                    style:
                    TextStyle(
                      color: AppColors
                          .textSecondary,
                      fontSize: 12,
                    ),
                  ),
                )
                    : ListView
                    .separated(
                  controller:
                  scrollController,
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    16,
                    12,
                    16,
                    24,
                  ),
                  itemCount:
                  filteredStops
                      .length,
                  separatorBuilder:
                      (_, __) =>
                  const SizedBox(
                    height: 8,
                  ),
                  itemBuilder:
                      (context,
                      index) {
                    final stop =
                    filteredStops[
                    index];

                    return Material(
                      color: AppColors
                          .background,
                      borderRadius:
                      BorderRadius
                          .circular(
                        15,
                      ),
                      child:
                      InkWell(
                        onTap: () =>
                            widget
                                .onStopTap(
                              stop,
                            ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          15,
                        ),
                        child:
                        Padding(
                          padding:
                          const EdgeInsets
                              .all(
                            12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width:
                                36,
                                height:
                                36,
                                decoration:
                                BoxDecoration(
                                  color:
                                  Colors.white,
                                  borderRadius:
                                  BorderRadius.circular(
                                    11,
                                  ),
                                ),
                                child:
                                const Icon(
                                  Icons
                                      .location_on_outlined,
                                  color:
                                  AppColors.primary,
                                  size:
                                  19,
                                ),
                              ),
                              const SizedBox(
                                width:
                                11,
                              ),
                              Expanded(
                                child:
                                Text(
                                  stop.name,
                                  style:
                                  const TextStyle(
                                    color:
                                    AppColors.textPrimary,
                                    fontSize:
                                    13,
                                    fontWeight:
                                    FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons
                                    .chevron_right_rounded,
                                color:
                                AppColors.primary,
                                size:
                                20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// KONUM AKSİYON BUTONLARI
// ============================================================

class _LocationActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _LocationActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withValues(
        alpha: 0.14,
      ),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: 21,
                ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _LocationRoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _LocationRoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      elevation: 4,
      shadowColor: Colors.black.withValues(
        alpha: 0.14,
      ),
      shape: const CircleBorder(),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 50,
            height: 50,
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HARİTA BUTONU
// ============================================================

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.primary
          : Colors.white,
      elevation: 3,
      shadowColor:
      Colors.black.withValues(
        alpha: 0.12,
      ),
      borderRadius:
      BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(14),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icon,
              color: active
                  ? Colors.white
                  : AppColors.primary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOADING
// ============================================================

class _LoadingPill
    extends StatelessWidget {
  const _LoadingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.10,
            ),
            blurRadius: 12,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          SizedBox(
            width: 15,
            height: 15,
            child:
            CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Duraklar yükleniyor',
            style: TextStyle(
              color:
              AppColors.textPrimary,
              fontSize: 10,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorCard
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(16),
      elevation: 3,
      child: Padding(
        padding:
        const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              color: AppColors.error,
              size: 19,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style:
                const TextStyle(
                  color: AppColors
                      .textPrimary,
                  fontSize: 11,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child:
              const Text(
                'Tekrar Dene',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
