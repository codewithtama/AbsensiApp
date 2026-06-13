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
            Tab(text: 'Clock In/Out'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
    );
  }

  Widget _buildClockTab() {
    final sites = sl<SiteLocalDatasource>().getAllSites();

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
                      'Clock In berhasil — ${DateFormatters.formatTime(state.attendance.timestamp)}'),
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
              content: Text('Clock Out berhasil$durText'),
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Site selector
              if (sites.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassDecoration,
                  child: Column(
                    children: [
                      Icon(Icons.location_off_rounded,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada site. Hubungi Superuser untuk menambahkan site.',
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
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: DropdownButtonFormField<SiteModel>(
                    initialValue: _selectedSite,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      prefixIcon: Icon(Icons.location_on_rounded),
                      labelText: 'Pilih Site',
                    ),
                    dropdownColor: const Color(0xFF1E2D42),
                    items: sites
                        .map((site) => DropdownMenuItem(
                              value: site,
                              child: Text(site.name,
                                  style:
                                      const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (site) => setState(() => _selectedSite = site),
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
                                  isClockedIn ? 'Clock Out' : 'Clock In',
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
                _buildInfoRow(Icons.shield_rounded, 'Root & Mock GPS Detection',
                    AppTheme.emeraldGreen),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_rounded,
                    'Geofencing (Haversine)', AppTheme.skyBlue),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.fingerprint_rounded,
                    'Biometric Authentication', AppTheme.violetPurple),
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

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                size: 64, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat absensi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white24,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
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
      },
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
