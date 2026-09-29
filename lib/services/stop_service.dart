import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/bus_stop.dart';

class StopService {
  static const String _assetPath =
      'assets/data/bus_stops.json';

  Future<List<BusStop>> getStops() async {
    final jsonString =
    await rootBundle.loadString(_assetPath);

    final Map<String, dynamic> jsonData =
    json.decode(jsonString) as Map<String, dynamic>;

    final List<dynamic> stops =
    jsonData['stops'] as List<dynamic>;

    return stops
        .map(
          (stop) => BusStop.fromJson(
        stop as Map<String, dynamic>,
      ),
    )
        .toList();
  }
}