import 'package:latlong2/latlong.dart';

/// Ray-casting algorithm for point-in-polygon
bool pointInPolygon(LatLng point, List<LatLng> polygon) {
  final x = point.latitude;
  final y = point.longitude;
  bool inside = false;
  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].latitude;
    final yi = polygon[i].longitude;
    final xj = polygon[j].latitude;
    final yj = polygon[j].longitude;
    final intersect =
        ((yi > y) != (yj > y)) &&
        (x < (xj - xi) * (y - yi) / (yj - yi + 0.0) + xi);
    if (intersect) inside = !inside;
    j = i;
  }
  return inside;
}
