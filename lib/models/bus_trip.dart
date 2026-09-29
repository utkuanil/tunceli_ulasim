class BusTrip {
  final String time;
  final String destination;
  final String? note;
  final List<String>? days;

  const BusTrip({
    required this.time,
    required this.destination,
    this.note,
    this.days,
  });

  factory BusTrip.fromJson(Map<String, dynamic> json) {
    return BusTrip(
      time: json['time'] as String,
      destination: json['destination'] as String,
      note: json['note'] as String?,
      days: json['days'] != null
          ? List<String>.from(json['days'])
          : null,
    );
  }
}