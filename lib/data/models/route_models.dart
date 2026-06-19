class RouteStop {
  final String childId;
  final String childName;
  final String riskBand;
  final double distanceKm;
  final double? latitude;
  final double? longitude;
  final String? currentLocation;
  final int order;

  const RouteStop({
    required this.childId,
    required this.childName,
    required this.riskBand,
    required this.distanceKm,
    this.latitude,
    this.longitude,
    this.currentLocation,
    required this.order,
  });

  factory RouteStop.fromJson(Map<String, dynamic> j) => RouteStop(
        childId: j['childId'] as String? ?? '',
        childName: j['childName'] as String? ?? '',
        riskBand: j['riskBand'] as String? ?? 'Low',
        distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        currentLocation: j['currentLocation'] as String?,
        order: (j['order'] as num?)?.toInt() ?? 0,
      );
}

class OptimizedRoute {
  final List<RouteStop> stops;
  final double totalKm;
  final int estMinutes;

  const OptimizedRoute({
    required this.stops,
    required this.totalKm,
    required this.estMinutes,
  });

  factory OptimizedRoute.fromJson(Map<String, dynamic> j) => OptimizedRoute(
        stops: (j['stops'] as List?)
                ?.map((e) => RouteStop.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        totalKm: (j['totalKm'] as num?)?.toDouble() ?? 0,
        estMinutes: (j['estMinutes'] as num?)?.toInt() ?? 0,
      );
}
