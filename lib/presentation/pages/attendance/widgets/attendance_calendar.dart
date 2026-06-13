import 'package:flutter/material.dart';
import 'package:absensi_app/core/theme/app_theme.dart';
import 'package:absensi_app/data/datasources/attendance_local_datasource.dart';
import 'package:absensi_app/data/datasources/leave_local_datasource.dart';
import 'package:absensi_app/data/datasources/shift_assignment_local_datasource.dart';
import 'package:absensi_app/data/datasources/shift_local_datasource.dart';
import 'package:absensi_app/data/datasources/site_local_datasource.dart';
import 'package:absensi_app/data/models/attendance_model.dart';
import 'package:absensi_app/data/models/leave_model.dart';
import 'package:absensi_app/data/models/shift_assignment_model.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/core/utils/date_formatters.dart';
import 'package:absensi_app/injection.dart';

class AttendanceCalendar extends StatefulWidget {
  final String userId;

  const AttendanceCalendar({super.key, required this.userId});

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  late DateTime _currentMonth;
  late Map<String, List<AttendanceModel>> _attendanceMap;
  late Map<String, ShiftAssignmentModel> _assignmentMap;
  late List<LeaveModel> _approvedLeaves;

  static const List<String> _indoMonths = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static const List<String> _weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _loadData();
  }

  void _loadData() {
    final attendanceDb = sl<AttendanceLocalDatasource>();
    final assignmentDb = sl<ShiftAssignmentLocalDatasource>();
    final leaveDb = sl<LeaveLocalDatasource>();

    final allAttendance = attendanceDb.getAttendanceByUser(widget.userId);
    final allAssignments = assignmentDb.getAssignmentsByUser(widget.userId);
    final allLeaves = leaveDb.getLeavesByUser(widget.userId);

    _attendanceMap = {};
    for (final att in allAttendance) {
      final dateKey = _getDateKey(att.timestamp);
      _attendanceMap.putIfAbsent(dateKey, () => []).add(att);
    }

    _assignmentMap = {};
    for (final assign in allAssignments) {
      final dateKey = _getDateKey(assign.date);
      _assignmentMap[dateKey] = assign;
    }

    _approvedLeaves = allLeaves.where((l) =>
        l.status == LeaveStatus.approvedFinal ||
        l.status == LeaveStatus.approvedL1 ||
        l.status == LeaveStatus.approvedL2).toList();
  }

  String _getDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  int _daysInMonth(DateTime date) {
    var firstDayThisMonth = DateTime(date.year, date.month, 1);
    var firstDayNextMonth = DateTime(date.year, date.month + 1, 1);
    return firstDayNextMonth.difference(firstDayThisMonth).inDays;
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Reload database maps to capture any new attendance logs
    _loadData();

    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final totalDays = _daysInMonth(_currentMonth);

    final firstDayOfMonth = DateTime(year, month, 1);
    // weekday is 1=Mon, ..., 7=Sun.
    // We want Mon as column 0, so offset = firstDayOfMonth.weekday - 1
    final offset = firstDayOfMonth.weekday - 1;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header navigasi bulan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_indoMonths[month - 1]} $year',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.tealAccent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.tealAccent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Header hari (Sen, Sel, Rab, ...)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: Color(0x4D0F172A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Grid tanggal
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offset + totalDays,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (index < offset) {
                return const SizedBox.shrink();
              }

              final day = index - offset + 1;
              final cellDate = DateTime(year, month, day);
              final dateKey = _getDateKey(cellDate);

              final isCellToday = cellDate.isAtSameMomentAs(today);
              final isCellFuture = cellDate.isAfter(today);

              // 1. Cek log absensi
              final attendanceLogs = _attendanceMap[dateKey] ?? [];

              // 2. Cek apakah ada cuti/izin/sakit disetujui pada tanggal ini
              final hasApprovedLeave = _approvedLeaves.any((leave) =>
                  (cellDate.isAtSameMomentAs(leave.startDate) || cellDate.isAfter(leave.startDate)) &&
                  (cellDate.isAtSameMomentAs(leave.endDate) || cellDate.isBefore(leave.endDate)));

              // 3. Cek shift kerja terjadwal
              final hasAssignedShift = _assignmentMap.containsKey(dateKey);

              // Tentukan status dan warna
              Color statusColor = Color(0x1F0F172A);
              bool hasData = false;

              if (isCellFuture) {
                statusColor = Colors.white.withValues(alpha: 0.04);
              } else if (attendanceLogs.isNotEmpty) {
                hasData = true;
                final hasClockIn = attendanceLogs.any((a) => a.status == AttendanceStatus.clockIn);
                final hasClockOut = attendanceLogs.any((a) => a.status == AttendanceStatus.clockOut);
                final anyLate = attendanceLogs.any((a) => a.isLate == true || a.isEarlyOut == true);

                if (hasClockIn && hasClockOut) {
                  if (anyLate) {
                    statusColor = AppTheme.amberAccent;
                  } else {
                    statusColor = AppTheme.emeraldGreen;
                  }
                } else {
                  statusColor = AppTheme.amberAccent;
                }
              } else if (hasApprovedLeave) {
                hasData = true;
                statusColor = AppTheme.skyBlue;
              } else if (cellDate.isBefore(today)) {
                if (hasAssignedShift) {
                  hasData = true;
                  statusColor = AppTheme.roseRed;
                } else {
                  statusColor = Colors.white.withValues(alpha: 0.08);
                }
              } else {
                // Hari ini tapi belum ada absen
                if (hasAssignedShift) {
                  statusColor = Colors.white.withValues(alpha: 0.12);
                } else {
                  statusColor = Colors.white.withValues(alpha: 0.08);
                }
              }

              return InkWell(
                onTap: () => _showDayDetail(
                  cellDate,
                  attendanceLogs,
                  _assignmentMap[dateKey],
                  hasApprovedLeave,
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCellToday
                        ? AppTheme.tealAccent.withValues(alpha: 0.15)
                        : statusColor.withValues(alpha: hasData ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCellToday
                          ? AppTheme.tealAccent
                          : statusColor.withValues(alpha: hasData ? 0.4 : 0.1),
                      width: isCellToday ? 1.5 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isCellToday
                              ? AppTheme.tealAccent
                              : isCellFuture
                                  ? Color(0x3D0F172A)
                                  : Colors.white,
                          fontSize: 13,
                          fontWeight: isCellToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (hasData)
                        Positioned(
                          bottom: 6,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Legenda kalender
          const Divider(color: Color(0x1F0F172A), height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendItem(AppTheme.emeraldGreen, 'Hadir Lengkap'),
              _buildLegendItem(AppTheme.amberAccent, 'Terlambat / Sebagian'),
              _buildLegendItem(AppTheme.skyBlue, 'Cuti / Izin / Sakit'),
              _buildLegendItem(AppTheme.roseRed, 'Absen / Alpa'),
              _buildLegendItem(Color(0x610F172A), 'Tidak Ada Jadwal / Libur'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0x8A0F172A),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _showDayDetail(
    DateTime date,
    List<AttendanceModel> attendanceLogs,
    ShiftAssignmentModel? assignment,
    bool hasApprovedLeave,
  ) {
    final shiftDatasource = sl<ShiftLocalDatasource>();
    final siteDatasource = sl<SiteLocalDatasource>();
    final shift = assignment == null
        ? null
        : shiftDatasource.getShiftById(assignment.shiftId);
    final site = assignment == null ? null : siteDatasource.getSiteById(assignment.siteId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF162233),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          DateFormatters.formatDay(date),
          style: const TextStyle(color: Color(0xFF0F172A)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine(
              Icons.schedule_rounded,
              'Jadwal',
              assignment == null
                  ? 'Tidak ada jadwal / libur'
                  : '${shift?.name ?? 'Shift tidak ditemukan'} (${shift?.startTime ?? '--:--'} - ${shift?.endTime ?? '--:--'})',
              assignment == null ? Color(0x610F172A) : AppTheme.tealAccent,
            ),
            const SizedBox(height: 10),
            _detailLine(
              Icons.location_on_rounded,
              'Lokasi',
              assignment == null
                  ? '-'
                  : site?.name ?? 'Lokasi tidak ditemukan',
              AppTheme.skyBlue,
            ),
            const SizedBox(height: 10),
            _detailLine(
              Icons.event_available_rounded,
              'Cuti/Izin',
              hasApprovedLeave ? 'Disetujui' : 'Tidak ada',
              hasApprovedLeave ? AppTheme.skyBlue : Color(0x610F172A),
            ),
            const SizedBox(height: 10),
            if (attendanceLogs.isEmpty)
              _detailLine(
                Icons.fingerprint_rounded,
                'Absensi',
                'Belum ada aktivitas absensi',
                Color(0x610F172A),
              )
            else
              ...attendanceLogs.map(
                (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _detailLine(
                    log.status == AttendanceStatus.clockIn
                        ? Icons.login_rounded
                        : Icons.logout_rounded,
                    log.status.displayName,
                    DateFormatters.formatTime(log.timestamp),
                    log.status == AttendanceStatus.clockIn
                        ? AppTheme.emeraldGreen
                        : AppTheme.roseRed,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0x610F172A), fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
