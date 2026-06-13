import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';

part 'site_model.g.dart';

@HiveType(typeId: HiveTypeIds.site)
class SiteModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final double radiusMeters;

  SiteModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = GeofenceConfig.defaultRadiusMeters,
  });

  SiteModel copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
  }) {
    return SiteModel(
      id: id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }
}
