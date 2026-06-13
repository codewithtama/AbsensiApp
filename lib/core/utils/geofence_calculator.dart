import 'dart:math' as math;
import 'package:absensi_app/core/constants/app_constants.dart';

/// Haversine formula to calculate great-circle distance between two GPS coordinates.
/// Returns distance in meters.
class GeofenceCalculator {
  const GeofenceCalculator();

  /// Calculate distance between two points in meters using Haversine formula
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return GeofenceConfig.earthRadiusKm * c * 1000; // Convert km to meters
  }

  /// Check if a point is within the geofence radius of a site
  bool isWithinGeofence({
    required double userLat,
    required double userLng,
    required double siteLat,
    required double siteLng,
    required double radiusMeters,
  }) {
    final distance = calculateDistance(
      lat1: userLat,
      lon1: userLng,
      lat2: siteLat,
      lon2: siteLng,
    );
    return distance <= radiusMeters;
  }

  /// Get distance and whether within geofence — useful for UI display
  ({double distance, bool isWithin}) checkGeofence({
    required double userLat,
    required double userLng,
    required double siteLat,
    required double siteLng,
    required double radiusMeters,
  }) {
    final distance = calculateDistance(
      lat1: userLat,
      lon1: userLng,
      lat2: siteLat,
      lon2: siteLng,
    );
    return (distance: distance, isWithin: distance <= radiusMeters);
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}
