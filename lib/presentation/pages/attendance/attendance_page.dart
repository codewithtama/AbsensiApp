import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/core/theme/app_theme.dart';
import 'package:absensi_app/core/utils/date_formatters.dart';
import 'package:absensi_app/core/utils/device_security.dart';
import 'package:absensi_app/core/utils/geofence_calculator.dart';
import 'package:absensi_app/data/datasources/attendance_local_datasource.dart';
import 'package:absensi_app/data/datasources/site_local_datasource.dart';
import 'package:absensi_app/data/models/site_model.dart';
import 'package:absensi_app/data/models/user_model.dart';
import 'package:absensi_app/injection.dart';
import 'package:absensi_app/presentation/blocs/attendance/attendance_bloc.dart';
import 'package:absensi_app/presentation/blocs/attendance/attendance_event.dart';
import 'package:absensi_app/data/datasources/shift_assignment_local_datasource.dart';
import 'package:absensi_app/data/datasources/shift_local_datasource.dart';
import 'package:absensi_app/presentation/pages/attendance/widgets/attendance_calendar.dart';
import 'package:absensi_app/presentation/blocs/attendance/attendance_state.dart';

class AttendancePage extends StatefulWidget {
  final UserModel user;

  const AttendancePage({super.key, required this.user});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with SingleTickerProviderStateMixin {
  late final AttendanceBloc _bloc;
  SiteModel? _selectedSite;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bloc = AttendanceBloc(
      attendanceDatasource: sl<AttendanceLocalDatasource>(),
      siteDatasource: sl<SiteLocalDatasource>(),
      deviceSecurity: sl<DeviceSecurity>(),
      geofenceCalculator: sl<GeofenceCalculator>(),
      localAuth: sl<LocalAuthentication>(),
      currentUserId: widget.user.id,
    )..add(CheckTodayStatus(userId: widget.user.id));
  }

  @override
  void dispose() {
    _bloc.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Container(
        decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildClockTab(),
                    _buildHistoryTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.fingerprint_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Text(
            'Absensi',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppTheme.tealAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppTheme.tealAccent,
          unselectedLabelColor: Colors.white38,
          dividerHeight: 0,
          tabs: const [
            Tab(text: 'Masuk / Keluar'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
    );
  }

  Widget _buildClockTab() {
    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is ClockInSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                      'Absen masuk berhasil — ${DateFormatters.formatTime(state.attendance.timestamp)}'),
                ],
              ),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
          _bloc.add(CheckTodayStatus(userId: widget.user.id));
        } else if (state is ClockOutSuccess) {
          final dur = state.workDuration;
          final durText =
              dur != null ? ' (${DateFormatters.formatDuration(dur)})' : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Absen keluar berhasil$durText'),
              backgroundColor: AppTheme.skyBlue,
            ),
          );
          _bloc.add(CheckTodayStatus(userId: widget.user.id));
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: AppTheme.roseRed,
            ),
          );
        }
      },
      builder: (context, state) {
        final isClockedIn =
            state is AttendanceStatusChecked ? state.isClockedIn : false;
        final isLoading = state is AttendanceLoading;
        final stepMessage =
            state is AttendanceLoading ? state.stepMessage : null;

        // Resolve active schedule assignment
        final assignmentDb = sl<ShiftAssignmentLocalDatasource>();
        final shiftDb = sl<ShiftLocalDatasource>();
        final siteDb = sl<SiteLocalDatasource>();

        final now = DateTime.now();
        var assignment = assignmentDb.getAssignmentForUserOnDate(widget.user.id, now);
        var shift = assignment != null ? shiftDb.getShiftById(assignment.shiftId) : null;
        var site = assignment != null ? siteDb.getSiteById(assignment.siteId) : null;

        // Overnight shift lookback
        if (shift == null || site == null) {
          final yesterday = now.subtract(const Duration(days: 1));
          final yesterdayAssignment = assignmentDb.getAssignmentForUserOnDate(widget.user.id, yesterday);
          if (yesterdayAssignment != null) {
            final yesterdayShift = shiftDb.getShiftById(yesterdayAssignment.shiftId);
            if (yesterdayShift != null) {
              final startParts = yesterdayShift.startTime.split(':');
              final startHour = int.parse(startParts[0]);
              final startMinute = int.parse(startParts[1]);

              final endParts = yesterdayShift.endTime.split(':');
              final endHour = int.parse(endParts[0]);
              final endMinute = int.parse(endParts[1]);

              final shiftStart = DateTime(yesterday.year, yesterday.month, yesterday.day, startHour, startMinute);
              var shiftEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, endHour, endMinute);

              if (shiftEnd.isBefore(shiftStart)) {
                shiftEnd = shiftEnd.add(const Duration(days: 1));
                if (now.isBefore(shiftEnd)) {
                  assignment = yesterdayAssignment;
                  shift = yesterdayShift;
                  site = siteDb.getSiteById(assignment.siteId);
                }
              }
            }
          }
        }

        final hasPlacement = site != null && shift != null;
        if (hasPlacement && _selectedSite?.id != site.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedSite = site;
              });
            }
          });
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Tampilan Info Penempatan Roster
              if (!hasPlacement)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassDecoration,
                  child: Column(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 48,
                          color: AppTheme.roseRed.withValues(alpha: 0.15)),
                      const SizedBox(height: 12),
                      const Text(
                        'Jadwal Tidak Ditemukan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Anda tidak memiliki jadwal shift aktif hari ini. Hubungi admin/superuser untuk pengaturan plotting jadwal kerja Anda.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white38,
                            ),
                      ),
                    ],
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.tealAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.tealAccent.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.tealAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.business_rounded, color: AppTheme.tealAccent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Penempatan Kerja Roster',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              site.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Shift: ${shift.name} (${shift.startTime} - ${shift.endTime})',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Clock button
                GestureDetector(
                  onTap: isLoading || _selectedSite == null
                      ? null
                      : () => _onClockAction(isClockedIn),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isLoading
                          ? LinearGradient(colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.05),
                            ])
                          : isClockedIn
                              ? const LinearGradient(colors: [
                                  Color(0xFFEF4444),
                                  Color(0xFFDC2626),
                                ])
                              : AppTheme.primaryGradient,
                      boxShadow: [
                        if (!isLoading)
                          BoxShadow(
                            color: (isClockedIn
                                    ? AppTheme.roseRed
                                    : AppTheme.tealAccent)
                                .withValues(alpha: 0.3),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white54,
                                  ),
                                ),
                                if (stepMessage != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    stepMessage,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: Colors.white38),
                                  ),
                                ],
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isClockedIn
                                      ? Icons.logout_rounded
                                      : Icons.login_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isClockedIn ? 'Absen Keluar' : 'Absen Masuk',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_selectedSite == null)
                  Text(
                    'Pilih site terlebih dahulu',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white24,
                        ),
                  ),

                const SizedBox(height: 32),

                // Anti-fraud info cards
                _buildInfoRow(Icons.shield_rounded, 'Deteksi Root & GPS Palsu',
                    AppTheme.emeraldGreen),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_rounded,
                    'Radius Absensi (Geofencing)', AppTheme.skyBlue),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.fingerprint_rounded,
                    'Autentikasi Biometrik', AppTheme.violetPurple),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.7),
                  ),
            ),
          ),
          Icon(Icons.check_circle_rounded,
              size: 16, color: color.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final records =
        sl<AttendanceLocalDatasource>().getAttendanceByUser(widget.user.id);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AttendanceCalendar(userId: widget.user.id),
        const SizedBox(height: 24),
        Text(
          'Aktivitas Absensi',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.glassDecoration,
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history_rounded,
                      size: 40, color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada aktivitas absensi',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white24,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          ...records.map((record) {
            final isClockIn = record.status == AttendanceStatus.clockIn;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (isClockIn ? AppTheme.emeraldGreen : AppTheme.roseRed)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isClockIn ? Icons.login_rounded : Icons.logout_rounded,
                      color:
                          isClockIn ? AppTheme.emeraldGreen : AppTheme.roseRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.status.displayName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormatters.formatDateTime(record.timestamp),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white38,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormatters.formatTime(record.timestamp),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _onClockAction(bool isClockedIn) {
    if (_selectedSite == null) return;
    if (isClockedIn) {
      _bloc.add(ClockOutRequested(siteId: _selectedSite!.id));
    } else {
      _bloc.add(ClockInRequested(siteId: _selectedSite!.id));
    }
  }
}
