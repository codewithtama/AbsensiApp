import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';

part 'user_model.g.dart';

@HiveType(typeId: HiveTypeIds.user)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String passwordHash;

  @HiveField(4)
  final UserRole role;

  @HiveField(5)
  String? deviceId;

  @HiveField(6)
  String? pin;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.deviceId,
    this.pin,
    required this.createdAt,
    required this.updatedAt,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? passwordHash,
    UserRole? role,
    String? deviceId,
    String? pin,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      deviceId: deviceId ?? this.deviceId,
      pin: pin ?? this.pin,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
