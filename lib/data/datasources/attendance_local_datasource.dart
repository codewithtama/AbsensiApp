import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/models/attendance_model.dart';
import 'package:absensi_app/core/utils/date_formatters.dart';

class AttendanceLocalDatasource {
  Box<AttendanceModel> get _box =>
      Hive.box<AttendanceModel>(HiveBoxes.attendance);

  Future<void> saveAttendance(AttendanceModel attendance) async {
    await _box.put(attendance.id, attendance);
  }

  List<AttendanceModel> getAttendanceByUser(String userId) {
    return _box.values.where((a) => a.userId == userId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<AttendanceModel> getAttendanceByUserAndDate(
      String userId, DateTime date) {
    return _box.values
        .where((a) =>
            a.userId == userId && DateFormatters.isSameDay(a.timestamp, date))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<AttendanceModel> getAttendanceBySite(String siteId) {
    return _box.values.where((a) => a.siteId == siteId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<AttendanceModel> getAttendanceByDateRange(
    DateTime start,
    DateTime end, {
    String? userId,
  }) {
    return _box.values.where((a) {
      final inRange = a.timestamp.isAfter(start) && a.timestamp.isBefore(end);
      if (userId != null) {
        return inRange && a.userId == userId;
      }
      return inRange;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Check if user has already clocked in today (no clock-out yet)
  AttendanceModel? getTodayClockIn(String userId) {
    final today = DateTime.now();
    final todayRecords = getAttendanceByUserAndDate(userId, today);

    // Find a clock-in that has no matching clock-out
    final clockIns = todayRecords
        .where((a) => a.status == AttendanceStatus.clockIn)
        .toList();
    final clockOuts = todayRecords
        .where((a) => a.status == AttendanceStatus.clockOut)
        .toList();

    if (clockIns.isEmpty) return null;
    if (clockIns.length > clockOuts.length) {
      return clockIns.last;
    }
    return null;
  }

  bool hasClockInToday(String userId) {
    return getTodayClockIn(userId) != null;
  }

  List<AttendanceModel> getAllAttendance() {
    return _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
