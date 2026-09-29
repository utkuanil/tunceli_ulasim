import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/bus_route.dart';

class ScheduleService {
  static const String _assetPath =
      'assets/data/bus_schedules.json';

  Future<List<BusRoute>> getRoutes() async {
    final String jsonString =
    await rootBundle.loadString(_assetPath);

    final Map<String, dynamic> jsonData =
    json.decode(jsonString) as Map<String, dynamic>;

    final List<dynamic> routes =
    jsonData['routes'] as List<dynamic>;

    return routes
        .map(
          (route) => BusRoute.fromJson(
        route as Map<String, dynamic>,
      ),
    )
        .toList();
  }
}