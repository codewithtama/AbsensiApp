import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/core/theme/app_theme.dart';
import 'package:absensi_app/core/utils/date_formatters.dart';
import 'package:absensi_app/data/datasources/overtime_local_datasource.dart';
import 'package:absensi_app/data/datasources/site_local_datasource.dart';
import 'package:absensi_app/data/datasources/user_local_datasource.dart';
import 'package:absensi_app/data/models/overtime_model.dart';
import 'package:absensi_app/data/models/user_model.dart';
import 'package:absensi_app/injection.dart';
import 'package:absensi_app/presentation/blocs/overtime/overtime_bloc.dart';
import 'package:absensi_app/presentation/blocs/overtime/overtime_event.dart';
import 'package:absensi_app/presentation/blocs/overtime/overtime_state.dart';

class OvertimePage extends StatefulWidget {
  final UserModel user;

  const OvertimePage({super.key, required this.user});

  @override
  State<OvertimePage> createState() => _OvertimePageState();
}

class _OvertimePageState extends State<OvertimePage> {
  late final OvertimeBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = OvertimeBloc(
      overtimeDatasource: sl<OvertimeLocalDatasource>(),
      currentUserId: widget.user.id,
    )..add(LoadMyOvertimes(userId: widget.user.id));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _loadOvertimes() {
    _bloc.add(LoadMyOvertimes(userId: widget.user.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider.value(
        value: _bloc,
        child: Container(
          decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: BlocConsumer<OvertimeBloc, OvertimeState>(
                    listener: (context, state) {
                      if (state is OvertimeSubmitted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pengajuan lembur berhasil dikirim!'),
                            backgroundColor: AppTheme.emeraldGreen,
                          ),
                        );
                        _loadOvertimes();
                      } else if (state is OvertimeError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: AppTheme.roseRed,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is OvertimeLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppTheme.tealAccent),
                        );
                      }

                      List<OvertimeModel> overtimes = [];
                      if (state is OvertimesLoaded) {
                        overtimes = state.overtimes;
                      } else {
                        overtimes = sl<OvertimeLocalDatasource>().getOvertimesByUser(widget.user.id);
                      }

                      if (overtimes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 64,
                                color: Color(0xFF0F172A).withValues(alpha: 0.1),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada riwayat lembur',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Color(0x3D0F172A),
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: overtimes.length,
                        itemBuilder: (context, index) => _buildOvertimeCard(overtimes[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Lembur Saya',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Color(0xFF0F172A),
                  ),
            ),
          ),
          IconButton(
            onPressed: _showCreateOvertimeSheet,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.tealAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: AppTheme.tealAccent, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeCard(OvertimeModel overtime) {
    final statusColor = _getStatusColor(overtime.status);
    final site = sl<SiteLocalDatasource>().getSiteById(overtime.siteId);
    final boss = overtime.instructedBy != null
        ? sl<UserLocalDatasource>().getUserById(overtime.instructedBy!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color(0xFF0F172A).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF0F172A).withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  site?.name ?? 'Site Tidak Dikenal',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  overtime.status.displayName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: Color(0xFF0F172A).withValues(alpha: 0.3)),
              const SizedBox(width: 8),
              Text(
                DateFormatters.formatDate(overtime.date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Color(0x8A0F172A),
                    ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time_rounded,
                  size: 14, color: Color(0xFF0F172A).withValues(alpha: 0.3)),
              const SizedBox(width: 8),
              Text(
                '${overtime.startTime} - ${overtime.endTime}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Color(0x8A0F172A),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            overtime.reason,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Color(0xB30F172A),
                ),
          ),
          if (boss != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.assignment_ind_rounded,
                    size: 14, color: AppTheme.skyBlue.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  'Perintah dari: ${boss.name}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.skyBlue.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(OvertimeStatus status) {
    switch (status) {
      case OvertimeStatus.pending:
        return AppTheme.amberAccent;
      case OvertimeStatus.approvedL1:
        return AppTheme.skyBlue;
      case OvertimeStatus.approvedL2:
        return AppTheme.violetPurple;
      case OvertimeStatus.approvedFinal:
        return AppTheme.emeraldGreen;
      case OvertimeStatus.rejected:
        return AppTheme.roseRed;
    }
  }

  void _showCreateOvertimeSheet() {
    DateTime? selectedDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 17, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 20, minute: 0);
    final reasonController = TextEditingController();
    
    final sites = sl<SiteLocalDatasource>().getAllSites();
    String? selectedSiteId = sites.isNotEmpty ? sites.first.id : null;

    final bosses = sl<UserLocalDatasource>().getAllUsers().where((u) =>
        u.role == UserRole.leader ||
        u.role == UserRole.supervisor ||
        u.role == UserRole.manager ||
        u.role == UserRole.superuser).toList();
    String? selectedBossId = bosses.isNotEmpty ? bosses.first.id : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            String formatTimeOfDay(TimeOfDay tod) {
              final hr = tod.hour.toString().padLeft(2, '0');
              final mn = tod.minute.toString().padLeft(2, '0');
              return '$hr:$mn';
            }

            return Container(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              decoration: const BoxDecoration(
                color: Color(0xFF162233),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Color(0xFF0F172A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ajukan Lembur',
                      style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                            color: Color(0xFF0F172A),
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Site Selector
                    if (sites.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedSiteId,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi Kerja (Site)',
                          prefixIcon: Icon(Icons.business_rounded),
                        ),
                        dropdownColor: Color(0xFF1E2D42),
                        items: sites
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name, style: const TextStyle(color: Color(0xFF0F172A))),
                                ))
                            .toList(),
                        onChanged: (id) {
                          if (id != null) {
                            setSheetState(() => selectedSiteId = id);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Date
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 7)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) {
                          setSheetState(() => selectedDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF0F172A).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Color(0xFF0F172A).withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: Color(0x610F172A), size: 20),
                            const SizedBox(width: 12),
                            Text(
                              selectedDate != null
                                  ? DateFormatters.formatDate(selectedDate!)
                                  : 'Pilih Tanggal',
                              style: TextStyle(
                                color: selectedDate != null ? Colors.white : Color(0x610F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Start & End Time Row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final tod = await showTimePicker(
                                context: ctx,
                                initialTime: startTime,
                              );
                              if (tod != null) {
                                setSheetState(() => startTime = tod);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(0xFF0F172A).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Color(0xFF0F172A).withValues(alpha: 0.08)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, color: Color(0x610F172A), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatTimeOfDay(startTime),
                                    style: const TextStyle(color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final tod = await showTimePicker(
                                context: ctx,
                                initialTime: endTime,
                              );
                              if (tod != null) {
                                setSheetState(() => endTime = tod);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(0xFF0F172A).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Color(0xFF0F172A).withValues(alpha: 0.08)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, color: Color(0x610F172A), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatTimeOfDay(endTime),
                                    style: const TextStyle(color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Instructed By dropdown
                    if (bosses.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedBossId,
                        decoration: const InputDecoration(
                          labelText: 'Diperintah Oleh (Atasan)',
                          prefixIcon: Icon(Icons.assignment_ind_rounded),
                        ),
                        dropdownColor: Color(0xFF1E2D42),
                        items: bosses
                            .map((b) => DropdownMenuItem(
                                  value: b.id,
                                  child: Text('${b.name} (${b.role.displayName})',
                                      style: const TextStyle(color: Color(0xFF0F172A))),
                                ))
                            .toList(),
                        onChanged: (id) {
                          if (id != null) {
                            setSheetState(() => selectedBossId = id);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Reason
                    TextFormField(
                      controller: reasonController,
                      maxLines: 3,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        labelText: 'Alasan Lembur',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedDate == null ||
                              selectedSiteId == null ||
                              reasonController.text.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Harap lengkapi lokasi, tanggal, dan alasan.'),
                                backgroundColor: AppTheme.roseRed,
                              ),
                            );
                            return;
                          }
                          _bloc.add(SubmitOvertimeRequest(
                            date: selectedDate!,
                            startTime: formatTimeOfDay(startTime),
                            endTime: formatTimeOfDay(endTime),
                            reason: reasonController.text,
                            siteId: selectedSiteId!,
                            instructedBy: selectedBossId,
                          ));
                          Navigator.pop(ctx);
                        },
                        child: const Text('Kirim Pengajuan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
