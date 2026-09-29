import 'route_stop_time.dart';

class RouteStopTrip {
  final String departure;
  final String dataType;
  final String destination;
  final List<RouteStopTime> stops;

  const RouteStopTrip({
    required this.departure,
    required this.dataType,
    required this.destination,
    required this.stops,
  });

  bool get hasEstimatedTimes {
    return stops.any(
          (stop) => stop.estimated,
    );
  }

  factory RouteStopTrip.fromJson(
      Map<String, dynamic> json,
      ) {
    final stopsJson =
        json['stops'] as List<dynamic>? ?? [];

    return RouteStopTrip(
      departure: json['departure'] as String,
      dataType: json['dataType'] as String? ?? '',
      destination: json['destination'] as String,
      stops: stopsJson
          .map(
            (item) => RouteStopTime.fromJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }
}