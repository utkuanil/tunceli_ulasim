import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/route_stop_trip.dart';

class RouteStopTimeService {
  static const String _assetPath =
      'assets/data/university_stop_times.json';

  Future<List<RouteStopTrip>> getTripsForRoute(
      String routeId,
      ) async {
    final jsonString =
    await rootBundle.loadString(
      _assetPath,
    );

    final jsonData =
    json.decode(jsonString)
    as Map<String, dynamic>;

    final dataRouteId =
    jsonData['routeId'] as String?;

    if (dataRouteId != routeId) {
      return [];
    }

    final trips =
        jsonData['trips'] as List<dynamic>? ?? [];

    return trips
        .map(
          (item) => RouteStopTrip.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<bool> hasStopTimeData(
      String routeId,
      ) async {
    final trips =
    await getTripsForRoute(routeId);

    return trips.isNotEmpty;
  }
}