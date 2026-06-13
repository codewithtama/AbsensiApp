import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/models/overtime_model.dart';
import 'package:absensi_app/core/utils/date_formatters.dart';

class OvertimeLocalDatasource {
  Box<OvertimeModel> get _box => Hive.box<OvertimeModel>(HiveBoxes.overtime);

  Future<void> saveOvertime(OvertimeModel overtime) async {
    await _box.put(overtime.id, overtime);
  }

  OvertimeModel? getOvertimeById(String id) {
    return _box.get(id);
  }

  Future<void> deleteOvertime(String id) async {
    await _box.delete(id);
  }

  List<OvertimeModel> getOvertimesByUser(String userId) {
    return _box.values.where((o) => o.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<OvertimeModel> getOvertimesByUserAndDate(String userId, DateTime date) {
    return _box.values
        .where((o) => o.userId == userId && DateFormatters.isSameDay(o.date, date))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<OvertimeModel> getApprovedOvertimesForUserOnDate(String userId, DateTime date) {
    return _box.values
        .where((o) =>
            o.userId == userId &&
            o.status == OvertimeStatus.approvedFinal &&
            DateFormatters.isSameDay(o.date, date))
        .toList();
  }

  List<OvertimeModel> getPendingOvertimesForApproval(UserRole approverRole) {
    switch (approverRole) {
      case UserRole.leader:
        return _box.values
            .where((o) => o.status == OvertimeStatus.pending)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      case UserRole.supervisor:
        return _box.values
            .where((o) =>
                o.status == OvertimeStatus.pending ||
                o.status == OvertimeStatus.approvedL1)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      case UserRole.manager:
        return _box.values
            .where((o) =>
                o.status == OvertimeStatus.pending ||
                o.status == OvertimeStatus.approvedL1 ||
                o.status == OvertimeStatus.approvedL2)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      case UserRole.superuser:
        return _box.values
            .where((o) => !o.status.isTerminal)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      default:
        return [];
    }
  }

  Future<void> updateOvertimeStatus(
    String overtimeId,
    OvertimeStatus status, {
    String? approvedBy,
  }) async {
    final overtime = _box.get(overtimeId);
    if (overtime == null) return;

    final updated = overtime.copyWith(
      status: status,
      approvedBy: approvedBy ?? overtime.approvedBy,
    );

    await _box.put(overtimeId, updated);
  }

  List<OvertimeModel> getAllOvertimes() {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
