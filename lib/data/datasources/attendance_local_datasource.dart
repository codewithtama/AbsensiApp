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
      // Inklusif pada batas start dan end
      final ts = a.timestamp;
      final inRange = !ts.isBefore(start) && !ts.isAfter(end);
      if (userId != null) {
        return inRange && a.userId == userId;
      }
      return inRange;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // ---------------------------------------------------------------------------
  // SHIFT SESSION — window 24 jam (mendukung shift malam yang melewati tengah malam)
  // ---------------------------------------------------------------------------

  /// Mengembalikan semua record milik [userId] dalam 24 jam terakhir,
  /// diurutkan ascending (terlama → terbaru).
  List<AttendanceModel> _getRecentRecords(String userId) {
    final cutoff = DateTime.now().toLocal().subtract(const Duration(hours: 24));
    return _box.values
        .where((a) =>
            a.userId == userId && a.timestamp.toLocal().isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Mengembalikan record clock-in aktif yang belum di-clock-out dalam 24 jam terakhir.
  ///
  /// Mendukung shift reguler dan overnight. Logika: ambil seluruh record 24 jam
  /// terakhir → jika record TERAKHIR adalah clockIn, sesi masih berjalan.
  AttendanceModel? getActiveClockIn(String userId) {
    final recent = _getRecentRecords(userId);
    if (recent.isEmpty) return null;
    final last = recent.last;
    return last.status == AttendanceStatus.clockIn ? last : null;
  }

  /// Alias backward-compat — selalu gunakan [getActiveClockIn] di kode baru.
  AttendanceModel? getTodayClockIn(String userId) => getActiveClockIn(userId);

  /// True jika ada sesi clock-in aktif (belum di-clock-out) dalam 24 jam terakhir.
  bool hasActiveClockIn(String userId) => getActiveClockIn(userId) != null;

  /// Alias backward-compat.
  bool hasClockInToday(String userId) => hasActiveClockIn(userId);

  /// True jika user sudah menyelesaikan satu siklus shift penuh (clockIn → clockOut)
  /// dalam 24 jam terakhir. Mencegah absen ganda dalam satu siklus shift.
  ///
  /// Logika: pindai records ascending → cari pasangan clockIn diikuti clockOut.
  bool hasCompletedShiftRecently(String userId) {
    final recent = _getRecentRecords(userId);
    if (recent.length < 2) return false;

    bool foundClockIn = false;
    for (final record in recent) {
      if (record.status == AttendanceStatus.clockIn) {
        foundClockIn = true;
      } else if (record.status == AttendanceStatus.clockOut && foundClockIn) {
        return true; // Pasangan clockIn → clockOut lengkap ditemukan
      }
    }
    return false;
  }

  /// Alias backward-compat (nama lama berbasis kalender — kini berbasis sesi 24 jam).
  bool hasClockOutToday(String userId) => hasCompletedShiftRecently(userId);

  List<AttendanceModel> getAllAttendance() {
    return _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
