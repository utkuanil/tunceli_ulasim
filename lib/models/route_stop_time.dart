class RouteStopTime {
  final String name;
  final String time;
  final bool estimated;

  const RouteStopTime({
    required this.name,
    required this.time,
    required this.estimated,
  });

  factory RouteStopTime.fromJson(
      Map<String, dynamic> json,
      ) {
    return RouteStopTime(
      name: json['name'] as String,
      time: json['time'] as String,
      estimated: json['estimated'] as bool? ?? false,
    );
  }
}