import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/models/user_model.dart';

class UserLocalDatasource {
  Box<UserModel> get _box => Hive.box<UserModel>(HiveBoxes.users);

  Future<void> saveUser(UserModel user) async {
    await _box.put(user.id, user);
  }

  UserModel? getUserById(String id) {
    return _box.get(id);
  }

  UserModel? getUserByEmail(String email) {
    try {
      return _box.values.firstWhere((u) => u.email == email);
    } catch (_) {
      return null;
    }
  }

  List<UserModel> getAllUsers() {
    return _box.values.toList();
  }

  List<UserModel> getUsersByRole(UserRole role) {
    return _box.values.where((u) => u.role == role).toList();
  }

  Future<void> deleteUser(String id) async {
    await _box.delete(id);
  }

  Future<void> updateDeviceId(String userId, String? deviceId) async {
    final user = _box.get(userId);
    if (user != null) {
      user.deviceId = deviceId;
      await user.save();
    }
  }

  bool get isEmpty => _box.isEmpty;
}
