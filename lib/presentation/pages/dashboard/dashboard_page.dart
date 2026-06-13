import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/core/theme/app_theme.dart';
import 'package:absensi_app/core/utils/date_formatters.dart';
import 'package:absensi_app/data/models/user_model.dart';
import 'package:absensi_app/injection.dart';
import 'package:absensi_app/data/datasources/user_local_datasource.dart';
import 'package:absensi_app/data/datasources/attendance_local_datasource.dart';
import 'package:absensi_app/data/datasources/leave_local_datasource.dart';
import 'package:absensi_app/data/datasources/site_local_datasource.dart';
import 'package:absensi_app/data/datasources/shift_local_datasource.dart';
import 'package:absensi_app/data/datasources/shift_assignment_local_datasource.dart';
import 'package:absensi_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:absensi_app/presentation/blocs/auth/auth_event.dart';
import 'package:absensi_app/presentation/blocs/management/management_bloc.dart';
import 'package:absensi_app/presentation/pages/attendance/attendance_page.dart';
import 'package:absensi_app/presentation/pages/leave/leave_page.dart';
import 'package:absensi_app/presentation/pages/management/management_page.dart';

class DashboardPage extends StatefulWidget {
  final UserModel user;

  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ManagementBloc(
        userDatasource: sl<UserLocalDatasource>(),
        siteDatasource: sl<SiteLocalDatasource>(),
        shiftDatasource: sl<ShiftLocalDatasource>(),
        assignmentDatasource: sl<ShiftAssignmentLocalDatasource>(),
      ),
      child: Scaffold(
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return AttendancePage(user: widget.user);
      case 2:
        return LeavePage(user: widget.user);
      case 3:
        return ManagementPage(user: widget.user);
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    final attendanceDatasource = sl<AttendanceLocalDatasource>();
    final leaveDatasource = sl<LeaveLocalDatasource>();
    final todayClockIn = attendanceDatasource.getTodayClockIn(widget.user.id);
    final isClockedIn = todayClockIn != null;
    final todayRecords =
        attendanceDatasource.getAttendanceByUserAndDate(widget.user.id, DateTime.now());
    final pendingLeaves = leaveDatasource.getLeavesByUser(widget.user.id)
        .where((l) => !l.status.isTerminal)
        .length;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildStatusCard(isClockedIn, todayClockIn)),
            SliverToBoxAdapter(child: _buildQuickStats(todayRecords.length, pendingLeaves)),
            SliverToBoxAdapter(child: _buildRecentActivity()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white38,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.name,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.tealAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.user.role.displayName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.tealAccent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showLogoutDialog,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  widget.user.name.isNotEmpty
                      ? widget.user.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isClockedIn, dynamic todayClockIn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: isClockedIn
              ? LinearGradient(
                  colors: [
                    AppTheme.emeraldGreen.withValues(alpha: 0.15),
                    AppTheme.tealAccent.withValues(alpha: 0.08),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isClockedIn
                ? AppTheme.emeraldGreen.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isClockedIn ? AppTheme.emeraldGreen : Colors.white24,
                    boxShadow: isClockedIn
                        ? [
                            BoxShadow(
                              color: AppTheme.emeraldGreen.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isClockedIn ? 'Sedang Bekerja' : 'Belum Clock In',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isClockedIn ? AppTheme.emeraldGreen : Colors.white38,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              DateFormatters.formatDay(DateTime.now()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white54,
                  ),
            ),
            if (isClockedIn && todayClockIn != null) ...[
              const SizedBox(height: 8),
              Text(
                'Clock In: ${DateFormatters.formatTime(todayClockIn.timestamp)}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(int todayRecords, int pendingLeaves) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.access_time_rounded,
              label: 'Absensi Hari Ini',
              value: '$todayRecords',
              color: AppTheme.skyBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.event_note_rounded,
              label: 'Cuti Pending',
              value: '$pendingLeaves',
              color: AppTheme.amberAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final records =
        sl<AttendanceLocalDatasource>().getAttendanceByUser(widget.user.id);
    final recent = records.take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivitas Terbaru',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassDecoration,
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 40, color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada aktivitas',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white24,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recent.map((record) {
              final isClockIn = record.status == AttendanceStatus.clockIn;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: AppTheme.glassDecoration,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (isClockIn ? AppTheme.emeraldGreen : AppTheme.roseRed)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isClockIn
                            ? Icons.login_rounded
                            : Icons.logout_rounded,
                        color: isClockIn ? AppTheme.emeraldGreen : AppTheme.roseRed,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.status.displayName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          Text(
                            DateFormatters.formatDateTime(record.timestamp),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white38,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_rounded),
        label: 'Beranda',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.fingerprint_rounded),
        label: 'Absensi',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.event_note_rounded),
        label: 'Cuti',
      ),
    ];

    // Management tab for Supervisor+ and Superuser
    if (widget.user.role.canManageShifts ||
        widget.user.role.canManageUsers ||
        widget.user.role.canViewTeamAttendance) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.settings_rounded),
        label: 'Kelola',
      ));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: items,
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi 👋';
    if (hour < 17) return 'Selamat Siang 👋';
    return 'Selamat Malam 👋';
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.roseRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white38,
                ),
          ),
        ],
      ),
    );
  }
}
