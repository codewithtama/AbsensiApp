import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/models/shift_model.dart';

class ShiftLocalDatasource {
  Box<ShiftModel> get _box => Hive.box<ShiftModel>(HiveBoxes.shifts);

  Future<void> saveShift(ShiftModel shift) async {
    await _box.put(shift.id, shift);
  }

  ShiftModel? getShiftById(String id) {
    return _box.get(id);
  }

  List<ShiftModel> getAllShifts() {
    return _box.values.toList();
  }

  Future<void> deleteShift(String id) async {
    await _box.delete(id);
  }

  bool get isEmpty => _box.isEmpty;
}
