import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/core/theme/app_theme.dart';
import 'package:absensi_app/core/utils/date_formatters.dart';
import 'package:absensi_app/data/datasources/leave_local_datasource.dart';
import 'package:absensi_app/data/datasources/user_local_datasource.dart';
import 'package:absensi_app/data/models/leave_model.dart';
import 'package:absensi_app/data/models/user_model.dart';
import 'package:absensi_app/injection.dart';
import 'package:absensi_app/presentation/blocs/leave/leave_bloc.dart';
import 'package:absensi_app/presentation/blocs/leave/leave_event.dart';
import 'package:absensi_app/presentation/blocs/leave/leave_state.dart';

class LeavePage extends StatefulWidget {
  final UserModel user;

  const LeavePage({super.key, required this.user});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage>
    with SingleTickerProviderStateMixin {
  late final LeaveBloc _bloc;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _bloc = LeaveBloc(
      leaveDatasource: sl<LeaveLocalDatasource>(),
      currentUserId: widget.user.id,
    );

    final hasApprovalAccess = widget.user.role.canApproveLeave;
    _tabController = TabController(
      length: hasApprovalAccess ? 2 : 1,
      vsync: this,
    );

    _loadLeaves();
  }

  void _loadLeaves() {
    _bloc.add(LoadMyLeaves(userId: widget.user.id));
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
                child: BlocConsumer<LeaveBloc, LeaveState>(
                  listener: (context, state) {
                    if (state is LeaveSubmitted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pengajuan cuti berhasil!'),
                          backgroundColor: AppTheme.emeraldGreen,
                        ),
                      );
                      _loadLeaves();
                    } else if (state is LeaveApproved) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cuti disetujui!'),
                          backgroundColor: AppTheme.emeraldGreen,
                        ),
                      );
                      _loadLeaves();
                    } else if (state is LeaveRejected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cuti ditolak.'),
                          backgroundColor: AppTheme.roseRed,
                        ),
                      );
                      _loadLeaves();
                    } else if (state is LeaveError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppTheme.roseRed,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMyLeavesTab(state),
                        if (widget.user.role.canApproveLeave)
                          _buildApprovalsTab(),
                      ],
                    );
                  },
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
              color: AppTheme.amberAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.event_note_rounded, color: AppTheme.amberAccent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Pengajuan Cuti',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Color(0xFF0F172A),
                  ),
            ),
          ),
          IconButton(
            onPressed: _showCreateLeaveSheet,
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

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF0F172A).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppTheme.tealAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: const Color(0xFF0F172A),
          unselectedLabelColor: Color(0x610F172A),
          dividerHeight: 0,
          tabs: [
            const Tab(text: 'Cuti Saya'),
            if (widget.user.role.canApproveLeave) const Tab(text: 'Persetujuan'),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLeavesTab(LeaveState state) {
    if (state is LeaveLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.tealAccent),
      );
    }

    List<LeaveModel> leaves;
    if (state is LeavesLoaded) {
      leaves = state.leaves;
    } else {
      leaves = sl<LeaveLocalDatasource>().getLeavesByUser(widget.user.id);
    }

    if (leaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_rounded,
                size: 64, color: Color(0xFF0F172A).withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              'Belum ada pengajuan cuti',
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
      itemCount: leaves.length,
      itemBuilder: (context, index) => _buildLeaveCard(leaves[index]),
    );
  }

  Widget _buildApprovalsTab() {
    final leaves = sl<LeaveLocalDatasource>()
        .getPendingLeavesForApproval(widget.user.role);

    if (leaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 64, color: Color(0xFF0F172A).withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              'Tidak ada cuti menunggu persetujuan',
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
      itemCount: leaves.length,
      itemBuilder: (context, index) =>
          _buildLeaveCard(leaves[index], showActions: true),
    );
  }

  Widget _buildLeaveCard(LeaveModel leave, {bool showActions = false}) {
    final statusColor = _getStatusColor(leave.status);
    final userName =
        sl<UserLocalDatasource>().getUserById(leave.userId)?.name ?? 'Unknown';

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
                  showActions ? userName : leave.type,
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
                  leave.status.displayName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 4),
            Text(
              'Jenis: ${leave.type}',
              style: const TextStyle(
                color: Color(0x8A0F172A),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: Color(0xFF0F172A).withValues(alpha: 0.3)),
              const SizedBox(width: 8),
              Text(
                '${DateFormatters.formatDate(leave.startDate)} — ${DateFormatters.formatDate(leave.endDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Color(0x8A0F172A),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            leave.reason,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Color(0xB30F172A),
                ),
          ),
          if (leave.documentPath != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_file_rounded,
                    size: 14, color: AppTheme.skyBlue.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  'Dokumen terlampir',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.skyBlue.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ],
          if (showActions && !leave.status.isTerminal) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _bloc.add(RejectLeave(
                      leaveId: leave.id,
                      rejectedBy: widget.user.id,
                    )),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.roseRed,
                      side: const BorderSide(color: AppTheme.roseRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (widget.user.role == UserRole.superuser) {
                        _showSuperuserApprovalDialog(context, leave);
                      } else {
                        _bloc.add(ApproveLeave(
                          leaveId: leave.id,
                          approverRole: widget.user.role,
                          approverId: widget.user.id,
                        ));
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Setujui'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return AppTheme.amberAccent;
      case LeaveStatus.approvedL1:
        return AppTheme.skyBlue;
      case LeaveStatus.approvedL2:
        return AppTheme.violetPurple;
      case LeaveStatus.approvedFinal:
        return AppTheme.emeraldGreen;
      case LeaveStatus.rejected:
        return AppTheme.roseRed;
    }
  }

  void _showCreateLeaveSheet() {
    DateTime? startDate;
    DateTime? endDate;
    final reasonController = TextEditingController();
    String? docPath;
    String selectedType = 'Cuti';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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
                      'Ajukan Cuti / Sakit / Izin',
                      style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                            color: Color(0xFF0F172A),
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Type selector
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Pengajuan',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      dropdownColor: Color(0xFF1E2D42),
                      items: ['Cuti', 'Sakit', 'Izin']
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t, style: const TextStyle(color: Color(0xFF0F172A))),
                              ))
                          .toList(),
                      onChanged: (t) {
                        if (t != null) {
                          setSheetState(() => selectedType = t);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Start date
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setSheetState(() => startDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF0F172A).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Color(0xFF0F172A).withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: Color(0x610F172A), size: 20),
                            const SizedBox(width: 12),
                            Text(
                              startDate != null
                                  ? DateFormatters.formatDate(startDate!)
                                  : 'Tanggal Mulai',
                              style: TextStyle(
                                color: startDate != null ? const Color(0xFF0F172A) : const Color(0x610F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // End date
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate:
                              startDate ?? DateTime.now(),
                          firstDate:
                              startDate ?? DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setSheetState(() => endDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF0F172A).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Color(0xFF0F172A).withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: Color(0x610F172A), size: 20),
                            const SizedBox(width: 12),
                            Text(
                              endDate != null
                                  ? DateFormatters.formatDate(endDate!)
                                  : 'Tanggal Selesai',
                              style: TextStyle(
                                color: endDate != null ? const Color(0xFF0F172A) : const Color(0x610F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Reason
                    TextFormField(
                      controller: reasonController,
                      maxLines: 3,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        labelText: 'Alasan / Keterangan',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Document
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles();
                        if (result != null) {
                          setSheetState(
                              () => docPath = result.files.single.path);
                        }
                      },
                      icon: const Icon(Icons.attach_file_rounded, size: 18),
                      label: Text(docPath != null
                          ? 'Dokumen terlampir ✓'
                          : 'Lampirkan Dokumen (opsional)'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (startDate == null ||
                              endDate == null ||
                              reasonController.text.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Harap lengkapi semua field wajib.'),
                                backgroundColor: AppTheme.roseRed,
                              ),
                            );
                            return;
                          }
                          _bloc.add(SubmitLeave(
                            startDate: startDate!,
                            endDate: endDate!,
                            reason: reasonController.text,
                            documentPath: docPath,
                            type: selectedType,
                          ));
                          Navigator.pop(ctx);
                        },
                        child: Text('Ajukan $selectedType'),
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

  void _showSuperuserApprovalDialog(BuildContext context, LeaveModel leave) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1E2D42),
        title: const Text(
          'Persetujuan Superuser',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Pilih level persetujuan (approve sebagai role apa):',
          style: TextStyle(color: Color(0xB30F172A)),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsOverflowButtonSpacing: 8,
        actions: [
          if (leave.status == LeaveStatus.pending)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _bloc.add(ApproveLeave(
                  leaveId: leave.id,
                  approverRole: UserRole.leader,
                  approverId: widget.user.id,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF0F172A),
              ),
              child: const Text('Leader (L1)'),
            ),
          if (leave.status == LeaveStatus.pending || leave.status == LeaveStatus.approvedL1)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _bloc.add(ApproveLeave(
                  leaveId: leave.id,
                  approverRole: UserRole.supervisor,
                  approverId: widget.user.id,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF0F172A),
              ),
              child: const Text('Supervisor (L2)'),
            ),
          if (leave.status == LeaveStatus.pending ||
              leave.status == LeaveStatus.approvedL1 ||
              leave.status == LeaveStatus.approvedL2)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _bloc.add(ApproveLeave(
                  leaveId: leave.id,
                  approverRole: UserRole.manager,
                  approverId: widget.user.id,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF0F172A),
              ),
              child: const Text('Manajer (Final)'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0x610F172A))),
          ),
        ],
      ),
    );
  }
}
