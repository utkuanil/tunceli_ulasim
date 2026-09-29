class RouteGeometryPoint {
  final double latitude;
  final double longitude;

  const RouteGeometryPoint({
    required this.latitude,
    required this.longitude,
  });

  factory RouteGeometryPoint.fromJson(Map<String, dynamic> json) {
    return RouteGeometryPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class RouteGeometryPart {
  final int sourceSegmentIndex;
  final String sourceName;
  final double lengthKm;
  final List<RouteGeometryPoint> coordinates;

  const RouteGeometryPart({
    required this.sourceSegmentIndex,
    required this.sourceName,
    required this.lengthKm,
    required this.coordinates,
  });

  factory RouteGeometryPart.fromJson(Map<String, dynamic> json) {
    return RouteGeometryPart(
      sourceSegmentIndex: json['sourceSegmentIndex'] as int,
      sourceName: (json['sourceName'] ?? '').toString(),
      lengthKm: (json['lengthKm'] as num).toDouble(),
      coordinates: (json['coordinates'] as List<dynamic>)
          .map(
            (item) => RouteGeometryPoint.fromJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }
}

class RouteGeometry {
  final String routeId;
  final String dataType;
  final String routeIdAssignment;
  final String assignmentConfidence;
  final String assignmentBasis;
  final int segmentCount;
  final double totalLengthKm;
  final List<RouteGeometryPart> parts;

  const RouteGeometry({
    required this.routeId,
    required this.dataType,
    required this.routeIdAssignment,
    required this.assignmentConfidence,
    required this.assignmentBasis,
    required this.segmentCount,
    required this.totalLengthKm,
    required this.parts,
  });

  factory RouteGeometry.fromJson(Map<String, dynamic> json) {
    return RouteGeometry(
      routeId: json['routeId'] as String,
      dataType: (json['dataType'] ?? '').toString(),
      routeIdAssignment:
      (json['routeIdAssignment'] ?? '').toString(),
      assignmentConfidence:
      (json['assignmentConfidence'] ?? '').toString(),
      assignmentBasis:
      (json['assignmentBasis'] ?? '').toString(),
      segmentCount: (json['segmentCount'] as num).toInt(),
      totalLengthKm: (json['totalLengthKm'] as num).toDouble(),
      parts: (json['parts'] as List<dynamic>)
          .map(
            (item) => RouteGeometryPart.fromJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }
}
