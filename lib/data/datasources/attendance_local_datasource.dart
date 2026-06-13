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

  /// Check if user has an active clock-in (looks back 18 hours to support overnight/night shifts)
  AttendanceModel? getTodayClockIn(String userId) {
    final records = getAttendanceByUser(userId);
    if (records.isEmpty) return null;

    final latestRecord = records.first;
    if (latestRecord.status == AttendanceStatus.clockIn) {
      final hoursPassed = DateTime.now().difference(latestRecord.timestamp).inHours;
      if (hoursPassed < 18) {
        return latestRecord;
      }
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
