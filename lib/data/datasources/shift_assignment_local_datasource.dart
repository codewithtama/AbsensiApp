import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/models/shift_assignment_model.dart';
import 'package:absensi_app/core/utils/date_formatters.dart';

class ShiftAssignmentLocalDatasource {
  Box<ShiftAssignmentModel> get _box =>
      Hive.box<ShiftAssignmentModel>(HiveBoxes.shiftAssignments);

  Future<void> saveAssignment(ShiftAssignmentModel assignment) async {
    await _box.put(assignment.id, assignment);
  }

  ShiftAssignmentModel? getAssignmentForUserOnDate(
      String userId, DateTime date) {
    try {
      return _box.values.firstWhere(
        (a) => a.userId == userId && DateFormatters.isSameDay(a.date, date),
      );
    } catch (_) {
      return null;
    }
  }

  List<ShiftAssignmentModel> getAssignmentsByUser(String userId) {
    return _box.values.where((a) => a.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<ShiftAssignmentModel> getAssignmentsBySite(String siteId) {
    return _box.values.where((a) => a.siteId == siteId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<ShiftAssignmentModel> getAssignmentsByDate(DateTime date) {
    return _box.values
        .where((a) => DateFormatters.isSameDay(a.date, date))
        .toList();
  }

  Future<void> deleteAssignment(String id) async {
    await _box.delete(id);
  }

  List<ShiftAssignmentModel> getAllAssignments() {
    return _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }
}
