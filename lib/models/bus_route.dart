import 'bus_trip.dart';

class BusRoute {
  final String id;
  final String name;
  final String departurePoint;
  final String? note;
  final List<BusTrip> weekday;
  final List<BusTrip> weekend;

  const BusRoute({
    required this.id,
    required this.name,
    required this.departurePoint,
    this.note,
    required this.weekday,
    required this.weekend,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      departurePoint: json['departurePoint'] as String,
      note: json['note'] as String?,
      weekday: (json['weekday'] as List)
          .map(
            (item) => BusTrip.fromJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList(),
      weekend: (json['weekend'] as List)
          .map(
            (item) => BusTrip.fromJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }
}