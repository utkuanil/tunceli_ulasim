import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/route_geometry.dart';

class RouteGeometryService {
  static const String _assetPath =
      'assets/data/route_geometries.json';

  Future<List<RouteGeometry>> getRouteGeometries() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    final routes = decoded['routes'] as List<dynamic>? ?? [];

    return routes
        .map(
          (item) => RouteGeometry.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<RouteGeometry?> getGeometryForRoute(
      String routeId,
      ) async {
    final routes = await getRouteGeometries();

    for (final route in routes) {
      if (route.routeId == routeId) {
        return route;
      }
    }

    return null;
  }
}
