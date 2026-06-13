import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';

part 'shift_model.g.dart';

@HiveType(typeId: HiveTypeIds.shift)
class ShiftModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String startTime; // "HH:mm" format

  @HiveField(3)
  final String endTime; // "HH:mm" format

  ShiftModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  ShiftModel copyWith({
    String? name,
    String? startTime,
    String? endTime,
  }) {
    return ShiftModel(
      id: id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
