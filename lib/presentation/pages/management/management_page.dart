import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/core/theme/app_theme.dart';
import 'package:absensi_app/core/utils/date_formatters.dart';
import 'package:absensi_app/data/datasources/user_local_datasource.dart';
import 'package:absensi_app/data/datasources/attendance_local_datasource.dart';
import 'package:absensi_app/data/datasources/site_local_datasource.dart';
import 'package:absensi_app/data/datasources/shift_local_datasource.dart';
import 'package:absensi_app/data/models/user_model.dart';
import 'package:absensi_app/data/models/attendance_model.dart';
import 'package:absensi_app/data/models/shift_assignment_model.dart';
import 'package:absensi_app/core/utils/report_generator.dart';
import 'package:absensi_app/injection.dart';
import 'package:absensi_app/presentation/blocs/management/management_bloc.dart';
import 'package:absensi_app/data/models/overtime_model.dart';
import 'package:absensi_app/data/datasources/overtime_local_datasource.dart';
import 'package:absensi_app/presentation/blocs/overtime/overtime_bloc.dart';
import 'package:absensi_app/presentation/blocs/overtime/overtime_event.dart';
import 'package:absensi_app/presentation/blocs/overtime/overtime_state.dart';

class ManagementPage extends StatefulWidget {
  final UserModel user;

  const ManagementPage({super.key, required this.user});

  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = <_TabDef>[];

  @override
  void initState() {
    super.initState();
    if (widget.user.role.canManageUsers) {
      _tabs.add(_TabDef('Karyawan', Icons.people_rounded));
    }
    if (widget.user.role.canManageSites) {
      _tabs.add(_TabDef('Lokasi', Icons.location_on_rounded));
    }
    if (widget.user.role.canManageShifts) {
      _tabs.add(_TabDef('Shift', Icons.schedule_rounded));
      _tabs.add(_TabDef('Jadwal', Icons.calendar_month_rounded));
    }
    if (widget.user.role.canViewTeamAttendance) {
      _tabs.add(_TabDef('Tim', Icons.groups_rounded));
      _tabs.add(_TabDef('Lembur', Icons.access_time_rounded));
    }

    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
      child: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  switch (tab.label) {
                    case 'Karyawan':
                      return _UsersTab(user: widget.user);
                    case 'Lokasi':
                      return _SitesTab(user: widget.user);
                    case 'Shift':
                      return _ShiftsTab(user: widget.user);
                    case 'Jadwal':
                      return _AssignmentsTab(user: widget.user);
                    case 'Tim':
                      return _TeamTab(user: widget.user);
                    case 'Lembur':
                      return _OvertimeTab(user: widget.user);
                    default:
                      return const SizedBox.shrink();
                  }
                }).toList(),
              ),
            ),
          ],
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
              color: AppTheme.violetPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppTheme.violetPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Kelola',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Color(0xFF0F172A)),
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
          isScrollable: _tabs.length > 3,
          indicator: BoxDecoration(
            color: AppTheme.tealAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppTheme.tealAccent,
          unselectedLabelColor: Color(0x610F172A),
          dividerHeight: 0,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
    );
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  _TabDef(this.label, this.icon);
}

// ──── Users Tab ────
class _UsersTab extends StatefulWidget {
  final UserModel user;
  const _UsersTab({required this.user});
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    context.read<ManagementBloc>().add(const LoadUsers());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManagementBloc, ManagementState>(
      listener: (context, state) {
        if (state is ManagementSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
          setState(() {
            _currentPage = 1;
          });
          context.read<ManagementBloc>().add(const LoadUsers());
        } else if (state is ManagementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.roseRed,
            ),
          );
        }
      },
      buildWhen: (prev, curr) =>
          curr is UsersLoaded || curr is ManagementLoading,
      builder: (context, state) {
        if (state is ManagementLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.tealAccent),
          );
        }

        final users = state is UsersLoaded ? state.users : <UserModel>[];
        final totalUsers = users.length;
        final totalPages = (totalUsers / _pageSize).ceil();

        int currentPage = _currentPage;
        if (currentPage > totalPages && totalPages > 0) {
          currentPage = totalPages;
        }

        final startIndex = (currentPage - 1) * _pageSize;
        final endIndex = startIndex + _pageSize;
        final paginatedUsers = users.sublist(
          startIndex.clamp(0, totalUsers),
          endIndex.clamp(0, totalUsers),
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${users.length} pengguna',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Color(0x610F172A)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showCreateUserDialog(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.tealAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppTheme.tealAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: paginatedUsers.length,
                itemBuilder: (context, index) {
                  final u = paginatedUsers[index];
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
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.name,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(color: Color(0xFF0F172A)),
                              ),
                              Text(
                                u.email,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Color(0x610F172A)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.tealAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            u.role.displayName,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.tealAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (widget.user.role.canUnbindDevice &&
                            u.deviceId != null)
                          IconButton(
                            onPressed: () => context.read<ManagementBloc>().add(
                              UnbindDevice(userId: u.id),
                            ),
                            icon: const Icon(
                              Icons.link_off_rounded,
                              color: AppTheme.amberAccent,
                              size: 20,
                            ),
                            tooltip: 'Lepas Tautan',
                          ),
                        if (widget.user.role.canManageUsers) ...[
                          IconButton(
                            onPressed: () => _showEditUserDialog(context, u),
                            icon: const Icon(
                              Icons.edit_rounded,
                              color: AppTheme.tealAccent,
                              size: 20,
                            ),
                            tooltip: 'Ubah',
                          ),
                          IconButton(
                            onPressed: () => _showDeleteUserConfirm(context, u),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.roseRed,
                              size: 20,
                            ),
                            tooltip: 'Hapus',
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: AppTheme.tealAccent,
                      disabledColor: Color(0x1F0F172A),
                    ),
                    Text(
                      'Halaman $currentPage dari $totalPages',
                      style: const TextStyle(
                        color: Color(0xB30F172A),
                        fontSize: 13,
                      ),
                    ),
                    IconButton(
                      onPressed: currentPage < totalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: AppTheme.tealAccent,
                      disabledColor: Color(0x1F0F172A),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _showDeleteUserConfirm(BuildContext context, UserModel targetUser) {
    if (targetUser.id == widget.user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak dapat menghapus akun Anda sendiri.'),
          backgroundColor: AppTheme.roseRed,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1E2D42),
        title: const Text(
          'Hapus Pengguna',
          style: TextStyle(color: Color(0xFF0F172A)),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${targetUser.name}"? Catatan absensi pengguna ini tidak akan terhapus namun relasinya akan hilang.',
          style: const TextStyle(color: Color(0xB30F172A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0x610F172A))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ManagementBloc>().add(
                DeleteUser(userId: targetUser.id),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, UserModel targetUser) {
    final nameC = TextEditingController(text: targetUser.name);
    final emailC = TextEditingController(text: targetUser.email);
    final passC = TextEditingController();
    UserRole selectedRole = targetUser.role;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSS) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
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
                      'Ubah Pengguna',
                      style: Theme.of(
                        ctx,
                      ).textTheme.headlineMedium?.copyWith(color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameC,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailC,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passC,
                      obscureText: true,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        labelText:
                            'Password Baru (kosongkan jika tidak diubah)',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      dropdownColor: Color(0xFF1E2D42),
                      items: UserRole.values
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r.displayName,
                                style: const TextStyle(color: Color(0xFF0F172A)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (r) {
                        if (r != null) setSS(() => selectedRole = r);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameC.text.isEmpty || emailC.text.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Nama dan Email wajib diisi.'),
                                backgroundColor: AppTheme.roseRed,
                              ),
                            );
                            return;
                          }
                          context.read<ManagementBloc>().add(
                            UpdateUser(
                              userId: targetUser.id,
                              name: nameC.text,
                              email: emailC.text,
                              password: passC.text.isEmpty ? null : passC.text,
                              role: selectedRole,
                            ),
                          );
                          Navigator.pop(ctx);
                        },
                        child: const Text('Simpan Perubahan'),
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

  void _showCreateUserDialog(BuildContext context) {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();
    UserRole selectedRole = UserRole.karyawan;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSS) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
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
                      'Tambah Pengguna',
                      style: Theme.of(
                        ctx,
                      ).textTheme.headlineMedium?.copyWith(color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameC,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailC,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passC,
                      obscureText: true,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      dropdownColor: Color(0xFF1E2D42),
                      items: UserRole.values
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r.displayName,
                                style: const TextStyle(color: Color(0xFF0F172A)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (r) {
                        if (r != null) setSS(() => selectedRole = r);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameC.text.isEmpty ||
                              emailC.text.isEmpty ||
                              passC.text.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Semua field wajib diisi.'),
                                backgroundColor: AppTheme.roseRed,
                              ),
                            );
                            return;
                          }
                          context.read<ManagementBloc>().add(
                            CreateUser(
                              name: nameC.text,
                              email: emailC.text,
                              password: passC.text,
                              role: selectedRole,
                            ),
                          );
                          Navigator.pop(ctx);
                        },
                        child: const Text('Simpan'),
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

// ──── Sites Tab ────
class _SitesTab extends StatefulWidget {
  final UserModel user;
  const _SitesTab({required this.user});
  @override
  State<_SitesTab> createState() => _SitesTabState();
}

class _SitesTabState extends State<_SitesTab> {
  @override
  void initState() {
    super.initState();
    context.read<ManagementBloc>().add(const LoadSites());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManagementBloc, ManagementState>(
      listener: (context, state) {
        if (state is ManagementSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
          context.read<ManagementBloc>().add(const LoadSites());
        }
      },
      buildWhen: (prev, curr) =>
          curr is SitesLoaded || curr is ManagementLoading,
      builder: (context, state) {
        if (state is ManagementLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.tealAccent),
          );
        }

        final sites = state is SitesLoaded ? state.sites : [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${sites.length} sites',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Color(0x610F172A)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showCreateSiteDialog(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.tealAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppTheme.tealAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: sites.length,
                itemBuilder: (context, index) {
                  final site = sites[index];
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
                            color: AppTheme.skyBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.skyBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                site.name,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(color: Color(0xFF0F172A)),
                              ),
                              Text(
                                '${site.latitude.toStringAsFixed(6)}, ${site.longitude.toStringAsFixed(6)} • ${site.radiusMeters.toStringAsFixed(0)}m',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Color(0x610F172A)),
                              ),
                            ],
                          ),
                        ),
                        if (widget.user.role.canManageSites) ...[
                          IconButton(
                            onPressed: () => _showEditSiteDialog(context, site),
                            icon: const Icon(
                              Icons.edit_rounded,
                              color: AppTheme.tealAccent,
                              size: 20,
                            ),
                            tooltip: 'Ubah',
                          ),
                          IconButton(
                            onPressed: () =>
                                _showDeleteSiteConfirm(context, site),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.roseRed,
                              size: 20,
                            ),
                            tooltip: 'Hapus',
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateSiteDialog(BuildContext context) {
    final nameC = TextEditingController();
    final latC = TextEditingController();
    final lngC = TextEditingController();
    final radiusC = TextEditingController(text: '100');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                  'Tambah Site',
                  style: Theme.of(
                    ctx,
                  ).textTheme.headlineMedium?.copyWith(color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameC,
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    labelText: 'Nama Site',
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: latC,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: lngC,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: radiusC,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    labelText: 'Radius (meter)',
                    prefixIcon: Icon(Icons.radar_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      final lat = double.tryParse(latC.text);
                      final lng = double.tryParse(lngC.text);
                      final radius = double.tryParse(radiusC.text);
                      if (nameC.text.isEmpty ||
                          lat == null ||
                          lng == null ||
                          radius == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Data tidak valid.'),
                            backgroundColor: AppTheme.roseRed,
                          ),
                        );
                        return;
                      }
                      context.read<ManagementBloc>().add(
                        CreateSite(
                          name: nameC.text,
                          latitude: lat,
                          longitude: lng,
                          radiusMeters: radius,
                        ),
                      );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteSiteConfirm(BuildContext context, dynamic targetSite) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1E2D42),
        title: const Text(
          'Hapus Lokasi Kerja',
          style: TextStyle(color: Color(0xFF0F172A)),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${targetSite.name}"? Karyawan yang dikaitkan dengan lokasi ini tidak akan dapat melakukan absensi sebelum jadwal lokasi mereka diubah.',
          style: const TextStyle(color: Color(0xB30F172A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0x610F172A))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ManagementBloc>().add(
                DeleteSite(siteId: targetSite.id),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showEditSiteDialog(BuildContext context, dynamic targetSite) {
    final nameC = TextEditingController(text: targetSite.name);
    final latC = TextEditingController(text: targetSite.latitude.toString());
    final lngC = TextEditingController(text: targetSite.longitude.toString());
    final radiusC = TextEditingController(
      text: targetSite.radiusMeters.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                  'Ubah Site',
                  style: Theme.of(
                    ctx,
                  ).textTheme.headlineMedium?.copyWith(color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameC,
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    labelText: 'Nama Site',
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: latC,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: lngC,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: radiusC,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    labelText: 'Radius (meter)',
                    prefixIcon: Icon(Icons.radar_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      final lat = double.tryParse(latC.text);
                      final lng = double.tryParse(lngC.text);
                      final radius = double.tryParse(radiusC.text);
                      if (nameC.text.isEmpty ||
                          lat == null ||
                          lng == null ||
                          radius == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Data tidak valid.'),
                            backgroundColor: AppTheme.roseRed,
                          ),
                        );
                        return;
                      }
                      context.read<ManagementBloc>().add(
                        UpdateSite(
                          siteId: targetSite.id,
                          name: nameC.text,
                          latitude: lat,
                          longitude: lng,
                          radiusMeters: radius,
                        ),
                      );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Simpan Perubahan'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──── Shifts Tab ────
class _ShiftsTab extends StatefulWidget {
  final UserModel user;
  const _ShiftsTab({required this.user});
  @override
  State<_ShiftsTab> createState() => _ShiftsTabState();
}

class _ShiftsTabState extends State<_ShiftsTab> {
  @override
  void initState() {
    super.initState();
    context.read<ManagementBloc>().add(const LoadShifts());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManagementBloc, ManagementState>(
      listener: (context, state) {
        if (state is ManagementSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
          context.read<ManagementBloc>().add(const LoadShifts());
        }
      },
      buildWhen: (prev, curr) =>
          curr is ShiftsLoaded || curr is ManagementLoading,
      builder: (context, state) {
        if (state is ManagementLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.tealAccent),
          );
        }

        final shifts = state is ShiftsLoaded ? state.shifts : [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${shifts.length} shifts',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Color(0x610F172A)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showCreateShiftDialog(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.tealAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppTheme.tealAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: shifts.length,
                itemBuilder: (context, index) {
                  final shift = shifts[index];
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
                            color: AppTheme.amberAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: AppTheme.amberAccent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shift.name,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(color: Color(0xFF0F172A)),
                              ),
                              Text(
                                '${shift.startTime} — ${shift.endTime}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Color(0x610F172A)),
                              ),
                            ],
                          ),
                        ),
                        if (widget.user.role.canManageShifts) ...[
                          IconButton(
                            onPressed: () =>
                                _showEditShiftDialog(context, shift),
                            icon: const Icon(
                              Icons.edit_rounded,
                              color: AppTheme.tealAccent,
                              size: 20,
                            ),
                            tooltip: 'Ubah',
                          ),
                          IconButton(
                            onPressed: () =>
                                _showDeleteShiftConfirm(context, shift),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.roseRed,
                              size: 20,
                            ),
                            tooltip: 'Hapus',
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateShiftDialog(BuildContext context) {
    final nameC = TextEditingController();
    final startC = TextEditingController();
    final endC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                  'Tambah Shift',
                  style: Theme.of(
                    ctx,
                  ).textTheme.headlineMedium?.copyWith(color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameC,
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    labelText: 'Nama Shift',
                    hintText: 'contoh: Shift Pagi',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: const TimeOfDay(hour: 8, minute: 0),
                          );
                          if (time != null) {
                            startC.text =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: startC,
                            style: const TextStyle(color: Color(0xFF0F172A)),
                            decoration: const InputDecoration(
                              labelText: 'Jam Masuk',
                              prefixIcon: Icon(Icons.access_time_rounded),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: const TimeOfDay(hour: 17, minute: 0),
                          );
                          if (time != null) {
                            endC.text =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: endC,
                            style: const TextStyle(color: Color(0xFF0F172A)),
                            decoration: const InputDecoration(
                              labelText: 'Jam Keluar',
                              prefixIcon: Icon(Icons.access_time_rounded),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameC.text.isEmpty ||
                          startC.text.isEmpty ||
                          endC.text.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Semua field wajib diisi.'),
                            backgroundColor: AppTheme.roseRed,
                          ),
                        );
                        return;
                      }
                      context.read<ManagementBloc>().add(
                        CreateShift(
                          name: nameC.text,
                          startTime: startC.text,
                          endTime: endC.text,
                        ),
                      );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteShiftConfirm(BuildContext context, dynamic targetShift) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1E2D42),
        title: const Text(
          'Hapus Shift Kerja',
          style: TextStyle(color: Color(0xFF0F172A)),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${targetShift.name}"? Jadwal harian karyawan yang menggunakan shift ini akan perlu disesuaikan kembali.',
          style: const TextStyle(color: Color(0xB30F172A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0x610F172A))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ManagementBloc>().add(
                DeleteShift(shiftId: targetShift.id),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showEditShiftDialog(BuildContext context, dynamic targetShift) {
    final nameC = TextEditingController(text: targetShift.name);
    final startC = TextEditingController(text: targetShift.startTime);
    final endC = TextEditingController(text: targetShift.endTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                  'Ubah Shift',
                  style: Theme.of(
                    ctx,
                  ).textTheme.headlineMedium?.copyWith(color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameC,
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    labelText: 'Nama Shift',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final initialParts = startC.text.split(':');
                          final initialTime = initialParts.length == 2
                              ? TimeOfDay(
                                  hour: int.parse(initialParts[0]),
                                  minute: int.parse(initialParts[1]),
                                )
                              : const TimeOfDay(hour: 8, minute: 0);
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: initialTime,
                          );
                          if (time != null) {
                            startC.text =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: startC,
                            style: const TextStyle(color: Color(0xFF0F172A)),
                            decoration: const InputDecoration(
                              labelText: 'Jam Masuk',
                              prefixIcon: Icon(Icons.access_time_rounded),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final initialParts = endC.text.split(':');
                          final initialTime = initialParts.length == 2
                              ? TimeOfDay(
                                  hour: int.parse(initialParts[0]),
                                  minute: int.parse(initialParts[1]),
                                )
                              : const TimeOfDay(hour: 17, minute: 0);
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: initialTime,
                          );
                          if (time != null) {
                            endC.text =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: endC,
                            style: const TextStyle(color: Color(0xFF0F172A)),
                            decoration: const InputDecoration(
                              labelText: 'Jam Keluar',
                              prefixIcon: Icon(Icons.access_time_rounded),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameC.text.isEmpty ||
                          startC.text.isEmpty ||
                          endC.text.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Semua field wajib diisi.'),
                            backgroundColor: AppTheme.roseRed,
                          ),
                        );
                        return;
                      }
                      context.read<ManagementBloc>().add(
                        UpdateShift(
                          shiftId: targetShift.id,
                          name: nameC.text,
                          startTime: startC.text,
                          endTime: endC.text,
                        ),
                      );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Simpan Perubahan'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──── Team Tab ────
class _TeamTab extends StatefulWidget {
  final UserModel user;
  const _TeamTab({required this.user});

  @override
  State<_TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<_TeamTab> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final userDatasource = sl<UserLocalDatasource>();
    final attendanceDatasource = sl<AttendanceLocalDatasource>();
    final siteDatasource = sl<SiteLocalDatasource>();

    final allUsers = userDatasource
        .getAllUsers()
        .where((u) => u.role != UserRole.superuser)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kehadiran Tim',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Color(0xFF0F172A)),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 90),
                        ),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(DateFormatters.formatDate(_selectedDate)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final records = attendanceDatasource
                          .getAttendanceByDateRange(
                            DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                            ),
                            DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              23,
                              59,
                              59,
                            ),
                          );

                      if (records.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tidak ada data absensi untuk diekspor pada tanggal ini.',
                            ),
                            backgroundColor: AppTheme.roseRed,
                          ),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final generator = ReportGenerator(
                          userDatasource: userDatasource,
                          siteDatasource: siteDatasource,
                        );
                        final file = await generator.generateAttendanceCsv(
                          records,
                        );

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Rekap berhasil diekspor ke: ${file.path}',
                            ),
                            backgroundColor: AppTheme.emeraldGreen,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Gagal mengekspor rekap: ${e.toString()}',
                            ),
                            backgroundColor: AppTheme.roseRed,
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.download_rounded,
                      color: AppTheme.tealAccent,
                    ),
                    tooltip: 'Ekspor Rekap Harian (CSV)',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: allUsers.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada anggota tim terdaftar.',
                    style: TextStyle(color: Color(0x610F172A)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  itemCount: allUsers.length,
                  itemBuilder: (context, index) {
                    final employee = allUsers[index];
                    final dailyRecords = attendanceDatasource
                        .getAttendanceByUserAndDate(employee.id, _selectedDate);

                    AttendanceModel? clockInRecord;
                    AttendanceModel? clockOutRecord;

                    for (final record in dailyRecords) {
                      if (record.status == AttendanceStatus.clockIn) {
                        clockInRecord = record;
                      } else if (record.status == AttendanceStatus.clockOut) {
                        clockOutRecord = record;
                      }
                    }

                    final hasAttended = clockInRecord != null;
                    final siteName = clockInRecord != null
                        ? siteDatasource
                                  .getSiteById(clockInRecord.siteId)
                                  ?.name ??
                              'Unknown Site'
                        : 'Belum absen';

                    return GestureDetector(
                      onTap: () => _showRecordDetails(
                        context,
                        employee,
                        clockInRecord,
                        clockOutRecord,
                        siteName,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.glassDecoration,
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.tealAccent.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  employee.name.isNotEmpty
                                      ? employee.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppTheme.tealAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    employee.name,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${employee.role.displayName} • $siteName',
                                    style: const TextStyle(
                                      color: Color(0x610F172A),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildStatusBadge(
                                  hasAttended,
                                  clockOutRecord != null,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimes(clockInRecord, clockOutRecord),
                                  style: const TextStyle(
                                    color: Color(0x8A0F172A),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool hasClockedIn, bool hasClockedOut) {
    Color color = AppTheme.roseRed;
    String label = 'Mangkir';
    if (hasClockedIn) {
      if (hasClockedOut) {
        color = AppTheme.skyBlue;
        label = 'Selesai';
      } else {
        color = AppTheme.emeraldGreen;
        label = 'Aktif';
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatTimes(AttendanceModel? inRec, AttendanceModel? outRec) {
    if (inRec == null) return '--:--';
    final inStr = DateFormatters.formatTime(inRec.timestamp);
    final outStr = outRec != null
        ? DateFormatters.formatTime(outRec.timestamp)
        : '--:--';
    return '$inStr - $outStr';
  }

  void _showRecordDetails(
    BuildContext context,
    UserModel employee,
    AttendanceModel? inRec,
    AttendanceModel? outRec,
    String siteName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(employee.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email: ${employee.email}',
                  style: const TextStyle(fontSize: 13, color: Color(0xB30F172A)),
                ),
                Text(
                  'Jabatan: ${employee.role.displayName}',
                  style: const TextStyle(fontSize: 13, color: Color(0xB30F172A)),
                ),
                const Divider(height: 24),

                // Section Masuk
                const Text(
                  'Absen Masuk:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.tealAccent,
                  ),
                ),
                const SizedBox(height: 6),
                if (inRec == null)
                  const Text(
                    'Belum absen masuk.',
                    style: TextStyle(color: Color(0x4D0F172A), fontSize: 13),
                  )
                else ...[
                  Text(
                    'Waktu: ${DateFormatters.formatTime(inRec.timestamp)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Lokasi: $siteName',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Perangkat: ${inRec.deviceName ?? 'Tidak Diketahui'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Sistem Operasi: ${inRec.deviceOs ?? 'Tidak Diketahui'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Jaringan: ${inRec.networkType ?? 'Tidak Diketahui'}',
                    style: const TextStyle(fontSize: 13),
                  ),

                  // Lateness info
                  if (inRec.isLate == true)
                    Text(
                      'Status: Terlambat (${inRec.delayMinutes} menit)',
                      style: const TextStyle(
                        color: AppTheme.roseRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (inRec.isLate == false)
                    const Text(
                      'Status: Tepat Waktu',
                      style: TextStyle(
                        color: AppTheme.emeraldGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const Text(
                      'Status: Tepat Waktu (Bypass)',
                      style: TextStyle(color: Color(0x610F172A), fontSize: 13),
                    ),
                ],

                const Divider(height: 24),

                // Section Keluar
                const Text(
                  'Absen Keluar:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.amberAccent,
                  ),
                ),
                const SizedBox(height: 6),
                if (outRec == null)
                  const Text(
                    'Belum absen keluar.',
                    style: TextStyle(color: Color(0x4D0F172A), fontSize: 13),
                  )
                else ...[
                  Text(
                    'Waktu: ${DateFormatters.formatTime(outRec.timestamp)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Perangkat: ${outRec.deviceName ?? 'Tidak Diketahui'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Sistem Operasi: ${outRec.deviceOs ?? 'Tidak Diketahui'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Jaringan: ${outRec.networkType ?? 'Tidak Diketahui'}',
                    style: const TextStyle(fontSize: 13),
                  ),

                  // Early out info
                  if (outRec.isEarlyOut == true)
                    Text(
                      'Status: Pulang Cepat (${outRec.delayMinutes} menit)',
                      style: const TextStyle(
                        color: AppTheme.roseRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (outRec.isEarlyOut == false)
                    const Text(
                      'Status: Sesuai Jadwal',
                      style: TextStyle(
                        color: AppTheme.emeraldGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const Text(
                      'Status: Sesuai Jadwal (Bypass)',
                      style: TextStyle(color: Color(0x610F172A), fontSize: 13),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}

// ──── Assignments Tab ────
class _AssignmentsTab extends StatefulWidget {
  final UserModel user;
  const _AssignmentsTab({required this.user});
  @override
  State<_AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends State<_AssignmentsTab> {
  int _currentPage = 1;
  static const int _pageSize = 10;
  String? _filterSiteId; // null = semua site
  String? _filterUserId;
  UserRole? _filterRole;
  String? _filterShiftId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    context.read<ManagementBloc>().add(const LoadShiftAssignments());
  }

  @override
  Widget build(BuildContext context) {
    final siteDatasource = sl<SiteLocalDatasource>();
    final userDatasource = sl<UserLocalDatasource>();
    final shiftDatasource = sl<ShiftLocalDatasource>();
    final allSites = siteDatasource.getAllSites();
    final allEmployees =
        userDatasource
            .getAllUsers()
            .where((u) => u.role != UserRole.superuser)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final allShifts = shiftDatasource.getAllShifts();
    final allRoles = UserRole.values
        .where((role) => role != UserRole.superuser)
        .where((role) => allEmployees.any((u) => u.role == role))
        .toList();

    return BlocConsumer<ManagementBloc, ManagementState>(
      listener: (context, state) {
        if (state is ManagementSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
          setState(() => _currentPage = 1);
          context.read<ManagementBloc>().add(const LoadShiftAssignments());
        } else if (state is ManagementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.roseRed,
            ),
          );
        }
      },
      buildWhen: (prev, curr) =>
          curr is ShiftAssignmentsLoaded || curr is ManagementLoading,
      builder: (context, state) {
        if (state is ManagementLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.tealAccent),
          );
        }

        final allAssignments = state is ShiftAssignmentsLoaded
            ? state.assignments
            : <ShiftAssignmentModel>[];

        final filtered = allAssignments.where((assignment) {
          final employee = userDatasource.getUserById(assignment.userId);
          final assignmentDate = DateFormatters.startOfDay(assignment.date);
          final startDate = _filterStartDate == null
              ? null
              : DateFormatters.startOfDay(_filterStartDate!);
          final endDate = _filterEndDate == null
              ? null
              : DateFormatters.startOfDay(_filterEndDate!);

          if (_filterSiteId != null && assignment.siteId != _filterSiteId) {
            return false;
          }
          if (_filterUserId != null && assignment.userId != _filterUserId) {
            return false;
          }
          if (_filterRole != null && employee?.role != _filterRole) {
            return false;
          }
          if (_filterShiftId != null && assignment.shiftId != _filterShiftId) {
            return false;
          }
          if (startDate != null && assignmentDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && assignmentDate.isAfter(endDate)) {
            return false;
          }
          return true;
        }).toList();

        // Pagination
        final total = filtered.length;
        final totalPages = total == 0 ? 1 : (total / _pageSize).ceil();
        final page = _currentPage.clamp(1, totalPages);
        final startIdx = (page - 1) * _pageSize;
        final endIdx = (startIdx + _pageSize).clamp(0, total);
        final paginated = filtered.sublist(startIdx, endIdx);

        return Column(
          children: [
            // ── Filters Panel ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown<String>(
                          value: _filterUserId,
                          hint: 'Semua User',
                          items: allEmployees
                              .map(
                                (u) => DropdownMenuItem<String>(
                                  value: u.id,
                                  child: Text(u.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() {
                            _filterUserId = value;
                            _currentPage = 1;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterDropdown<UserRole>(
                          value: _filterRole,
                          hint: 'Semua Role',
                          items: allRoles
                              .map(
                                (role) => DropdownMenuItem<UserRole>(
                                  value: role,
                                  child: Text(role.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() {
                            _filterRole = value;
                            _currentPage = 1;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown<String>(
                          value: _filterShiftId,
                          hint: 'Semua Shift',
                          items: allShifts
                              .map(
                                (shift) => DropdownMenuItem<String>(
                                  value: shift.id,
                                  child: Text(shift.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() {
                            _filterShiftId = value;
                            _currentPage = 1;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CompactDateFilter(
                          label: 'Mulai',
                          date: _filterStartDate,
                          onTap: () => _pickFilterDate(isStart: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactDateFilter(
                          label: 'Selesai',
                          date: _filterEndDate,
                          onTap: () => _pickFilterDate(isStart: false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.filter_alt_off_rounded),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Toolbar: filter + tambah ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Row(
                children: [
                  // Dropdown filter site
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Color(0xFF0F172A).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Color(0xFF0F172A).withValues(alpha: 0.08),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _filterSiteId,
                          dropdownColor: Color(0xFF1E2D42),
                          icon: const Icon(
                            Icons.filter_list_rounded,
                            color: Color(0x610F172A),
                            size: 18,
                          ),
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                          ),
                          hint: const Text(
                            'Semua Lokasi',
                            style: TextStyle(
                              color: Color(0x610F172A),
                              fontSize: 13,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'Semua Lokasi',
                                style: TextStyle(color: Color(0xFF0F172A)),
                              ),
                            ),
                            ...allSites.map(
                              (s) => DropdownMenuItem<String?>(
                                value: s.id,
                                child: Text(
                                  s.name,
                                  style: const TextStyle(color: Color(0xFF0F172A)),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _filterSiteId = v;
                            _currentPage = 1;
                          }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Jumlah record
                  Text(
                    '${filtered.length}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Color(0x610F172A)),
                  ),
                  _ScheduleActionButton(
                    tooltip: 'Salin jadwal',
                    icon: Icons.copy_rounded,
                    color: AppTheme.violetPurple,
                    onPressed: () => _showCopyScheduleDialog(context),
                  ),
                  _ScheduleActionButton(
                    tooltip: 'Hapus jadwal massal',
                    icon: Icons.delete_sweep_rounded,
                    color: AppTheme.roseRed,
                    onPressed: () => _showBulkDeleteDialog(context),
                  ),
                  _ScheduleActionButton(
                    tooltip: 'Tukar shift',
                    icon: Icons.swap_horiz_rounded,
                    color: AppTheme.amberAccent,
                    onPressed: () => _showSwapShiftDialog(context),
                  ),
                  IconButton(
                    tooltip: 'Plotting massal',
                    onPressed: () => _showBulkAssignmentDialog(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.skyBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.date_range_rounded,
                        color: AppTheme.skyBlue,
                        size: 20,
                      ),
                    ),
                  ),
                  // Tombol tambah
                  IconButton(
                    onPressed: () => _showAssignmentDialog(context, null),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.tealAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppTheme.tealAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── List ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 48,
                            color: Color(0xFF0F172A).withValues(alpha: 0.12),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filterSiteId == null
                                ? 'Belum ada penugasan jadwal.'
                                : 'Tidak ada penugasan untuk lokasi ini.',
                            style: const TextStyle(color: Color(0x610F172A)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      itemCount: paginated.length,
                      itemBuilder: (context, index) {
                        final a = paginated[index];
                        final employee = userDatasource.getUserById(a.userId);
                        final site = siteDatasource.getSiteById(a.siteId);
                        final shift = shiftDatasource.getShiftById(a.shiftId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: AppTheme.glassDecoration,
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.tealAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.calendar_month_rounded,
                                  color: AppTheme.tealAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            employee?.name ?? '—',
                                            style: const TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (employee != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.violetPurple
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              employee.role.displayName,
                                              style: const TextStyle(
                                                color: AppTheme.violetPurple,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${shift == null ? "\u2014" : shift.name} • ${shift?.startTime ?? ""}–${shift?.endTime ?? ""}',
                                      style: const TextStyle(
                                        color: Color(0xB30F172A),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          size: 11,
                                          color: Color(0x610F172A),
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            site?.name ?? '—',
                                            style: const TextStyle(
                                              color: Color(0x610F172A),
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 11,
                                          color: Color(0x610F172A),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          DateFormatters.formatDate(a.date),
                                          style: const TextStyle(
                                            color: Color(0x610F172A),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Actions
                              Column(
                                children: [
                                  InkWell(
                                    onTap: () =>
                                        _showAssignmentDialog(context, a),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        color: AppTheme.skyBlue,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _confirmDelete(context, a.id),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppTheme.roseRed.withValues(
                                          alpha: 0.8,
                                        ),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // ── Pagination ──
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: page > 1
                          ? () => setState(() => _currentPage = page - 1)
                          : null,
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0x8A0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.tealAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.tealAccent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '$page / $totalPages',
                        style: const TextStyle(
                          color: AppTheme.tealAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: page < totalPages
                          ? () => setState(() => _currentPage = page + 1)
                          : null,
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0x8A0F172A),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _showBulkAssignmentDialog(BuildContext context) {
    final userDatasource = sl<UserLocalDatasource>();
    final siteDatasource = sl<SiteLocalDatasource>();
    final shiftDatasource = sl<ShiftLocalDatasource>();

    final employees =
        userDatasource
            .getAllUsers()
            .where((u) => u.role != UserRole.superuser)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final sites = siteDatasource.getAllSites();
    final shifts = shiftDatasource.getAllShifts();

    if (employees.isEmpty || sites.isEmpty || shifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap pastikan Karyawan, Lokasi, dan Shift sudah tersedia.',
          ),
          backgroundColor: AppTheme.roseRed,
        ),
      );
      return;
    }

    final roles = UserRole.values
        .where((role) => role != UserRole.superuser)
        .where((role) => employees.any((u) => u.role == role))
        .toList();

    var targetMode = 'user';
    String? selectedUserId = employees.first.id;
    UserRole? selectedRole = roles.isNotEmpty ? roles.first : null;
    String? selectedSiteId = sites.first.id;
    String? selectedShiftId = shifts.first.id;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();

    Future<void> pickDate({
      required BuildContext pickerContext,
      required DateTime initialDate,
      required ValueChanged<DateTime> onPicked,
    }) async {
      final date = await showDatePicker(
        context: pickerContext,
        initialDate: initialDate,
        firstDate: DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (date != null) {
        onPicked(date);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSS) {
            final selectedCount = targetMode == 'role'
                ? employees.where((u) => u.role == selectedRole).length
                : 1;
            final dayCount = endDate.isBefore(startDate)
                ? 0
                : endDate.difference(startDate).inDays + 1;

            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
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
                      'Plotting Jadwal Massal',
                      style: Theme.of(
                        ctx,
                      ).textTheme.headlineMedium?.copyWith(color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'user',
                          label: Text('Per User'),
                          icon: Icon(Icons.person_outline),
                        ),
                        ButtonSegment(
                          value: 'role',
                          label: Text('Per Role'),
                          icon: Icon(Icons.groups_outlined),
                        ),
                      ],
                      selected: {targetMode},
                      onSelectionChanged: (value) {
                        setSS(() => targetMode = value.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (targetMode == 'user')
                      DropdownButtonFormField<String>(
                        initialValue: selectedUserId,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Karyawan / Atasan',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        dropdownColor: Color(0xFF1E2D42),
                        items: employees
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(
                                  '${e.name} [${e.role.displayName}]',
                                  style: const TextStyle(color: Color(0xFF0F172A)),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (id) => setSS(() => selectedUserId = id),
                      )
                    else
                      DropdownButtonFormField<UserRole>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Role',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                        dropdownColor: Color(0xFF1E2D42),
                        items: roles
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(
                                  role.displayName,
                                  style: const TextStyle(color: Color(0xFF0F172A)),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (role) => setSS(() => selectedRole = role),
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSiteId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Lokasi Kerja',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      dropdownColor: Color(0xFF1E2D42),
                      items: sites
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                s.name,
                                style: const TextStyle(color: Color(0xFF0F172A)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setSS(() => selectedSiteId = id),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedShiftId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Shift',
                        prefixIcon: Icon(Icons.schedule_outlined),
                      ),
                      dropdownColor: Color(0xFF1E2D42),
                      items: shifts
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                '${s.name} (${s.startTime} - ${s.endTime})',
                                style: const TextStyle(color: Color(0xFF0F172A)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setSS(() => selectedShiftId = id),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DateRangeField(
                            label: 'Dari Tanggal',
                            date: startDate,
                            onTap: () => pickDate(
                              pickerContext: ctx,
                              initialDate: startDate,
                              onPicked: (date) {
                                setSS(() {
                                  startDate = date;
                                  if (endDate.isBefore(startDate)) {
                                    endDate = startDate;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DateRangeField(
                            label: 'Sampai Tanggal',
                            date: endDate,
                            onTap: () => pickDate(
                              pickerContext: ctx,
                              initialDate: endDate,
                              onPicked: (date) => setSS(() => endDate = date),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$selectedCount orang x $dayCount hari = ${selectedCount * dayCount} jadwal',
                      style: const TextStyle(
                        color: Color(0x8A0F172A),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedSiteId == null ||
                              selectedShiftId == null ||
                              endDate.isBefore(startDate)) {
                            return;
                          }

                          final userIds = targetMode == 'role'
                              ? employees
                                    .where((u) => u.role == selectedRole)
                                    .map((u) => u.id)
                                    .toList()
                              : [if (selectedUserId != null) selectedUserId!];

                          if (userIds.isEmpty) {
                            return;
                          }

                          context.read<ManagementBloc>().add(
                            AssignShiftRange(
                              userIds: userIds,
                              shiftId: selectedShiftId!,
                              siteId: selectedSiteId!,
                              startDate: startDate,
                              endDate: endDate,
                              assignedBy: widget.user.id,
                            ),
                          );
                          Navigator.pop(ctx);
                        },
                        child: const Text('Simpan Jadwal Massal'),
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

  void _confirmDelete(BuildContext context, String assignmentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF162233),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Penugasan?',
          style: TextStyle(color: Color(0xFF0F172A)),
        ),
        content: const Text(
          'Penugasan jadwal ini akan dihapus permanen. Karyawan terkait tidak akan bisa absen pada hari tersebut.',
          style: TextStyle(color: Color(0x8A0F172A), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0x610F172A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ManagementBloc>().add(
                DeleteAssignment(assignmentId: assignmentId),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  /// [existing] == null → mode Create, != null → mode Edit
  void _showAssignmentDialog(
    BuildContext context,
    ShiftAssignmentModel? existing,
  ) {
    final userDatasource = sl<UserLocalDatasource>();
    final siteDatasource = sl<SiteLocalDatasource>();
    final shiftDatasource = sl<ShiftLocalDatasource>();

    // Semua role kecuali superuser bisa di-assign
    final employees =
        userDatasource
            .getAllUsers()
            .where((u) => u.role != UserRole.superuser)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final sites = siteDatasource.getAllSites();
    final shifts = shiftDatasource.getAllShifts();

    if (employees.isEmpty || sites.isEmpty || shifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap pastikan Karyawan, Lokasi, dan Shift sudah tersedia.',
          ),
          backgroundColor: AppTheme.roseRed,
        ),
      );
      return;
    }

    // Pre-fill dari existing jika edit mode
    String? selectedUserId = existing?.userId ?? employees.first.id;
    String? selectedSiteId = existing?.siteId ?? sites.first.id;
    String? selectedShiftId = existing?.shiftId ?? shifts.first.id;
    DateTime selectedDate = existing?.date.toLocal() ?? DateTime.now();
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSS) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
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
                      isEdit
                          ? 'Edit Penugasan Jadwal'
                          : 'Plotting Jadwal Karyawan',
                      style: Theme.of(
                        ctx,
                      ).textTheme.headlineMedium?.copyWith(color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 24),

                    // Karyawan Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedUserId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Karyawan / Atasan',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      dropdownColor: Color(0xFF1E2D42),
                      items: employees
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Row(
                                children: [
                                  Text(
                                    e.name,
                                    style: const TextStyle(color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '[${e.role.displayName}]',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A).withValues(
                                        alpha: 0.35,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setSS(() => selectedUserId = id),
                    ),
                    const SizedBox(height: 12),

                    // Lokasi Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedSiteId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Lokasi Kerja',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      dropdownColor: Color(0xFF1E2D42),
                      items: sites
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                s.name,
                                style: const TextStyle(color: Color(0xFF0F172A)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setSS(() => selectedSiteId = id),
                    ),
                    const SizedBox(height: 12),

                    // Shift Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedShiftId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Shift',
                        prefixIcon: Icon(Icons.schedule_outlined),
                      ),
                      dropdownColor: Color(0xFF1E2D42),
                      items: shifts
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                '${s.name} (${s.startTime} – ${s.endTime})',
                                style: const TextStyle(color: Color(0xFF0F172A)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setSS(() => selectedShiftId = id),
                    ),
                    const SizedBox(height: 12),

                    // Tanggal
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 30),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) setSS(() => selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF0F172A).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Color(0xFF0F172A).withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: Color(0x610F172A),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormatters.formatDate(selectedDate),
                              style: const TextStyle(color: Color(0xFF0F172A)),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit_calendar_rounded,
                              color: Color(0x3D0F172A),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedUserId == null ||
                              selectedSiteId == null ||
                              selectedShiftId == null) {
                            return;
                          }

                          if (isEdit) {
                            context.read<ManagementBloc>().add(
                              UpdateAssignment(
                                assignmentId: existing.id,
                                userId: selectedUserId!,
                                shiftId: selectedShiftId!,
                                siteId: selectedSiteId!,
                                date: selectedDate,
                                assignedBy: widget.user.id,
                              ),
                            );
                          } else {
                            context.read<ManagementBloc>().add(
                              AssignShift(
                                userId: selectedUserId!,
                                shiftId: selectedShiftId!,
                                siteId: selectedSiteId!,
                                date: selectedDate,
                                assignedBy: widget.user.id,
                              ),
                            );
                          }
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          isEdit ? 'Perbarui Penugasan' : 'Simpan Penugasan',
                        ),
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

  Future<void> _pickFilterDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _filterStartDate : _filterEndDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _filterStartDate = picked;
        } else {
          _filterEndDate = picked;
        }
        _currentPage = 1;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _filterUserId = null;
      _filterRole = null;
      _filterShiftId = null;
      _filterStartDate = null;
      _filterEndDate = null;
      _filterSiteId = null;
      _currentPage = 1;
    });
  }

  void _showCopyScheduleDialog(BuildContext context) {
    DateTime sourceStartDate = DateTime.now();
    DateTime sourceEndDate = DateTime.now();
    DateTime targetStartDate = DateTime.now().add(const Duration(days: 7));

    Future<void> pickDate({
      required BuildContext pickerContext,
      required DateTime initialDate,
      required ValueChanged<DateTime> onPicked,
    }) async {
      final date = await showDatePicker(
        context: pickerContext,
        initialDate: initialDate,
        firstDate: DateTime.now().subtract(const Duration(days: 90)),
        lastDate: DateTime.now().add(const Duration(days: 180)),
      );
      if (date != null) {
        onPicked(date);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSS) {
            final dayCount = sourceEndDate.isBefore(sourceStartDate)
                ? 0
                : sourceEndDate.difference(sourceStartDate).inDays + 1;

            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
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
                      'Salin Jadwal Karyawan',
                      style: Theme.of(
                        ctx,
                      ).textTheme.headlineMedium?.copyWith(color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Salin seluruh penugasan jadwal dari rentang tanggal sumber ke rentang tanggal target yang baru.',
                      style: TextStyle(color: Color(0x8A0F172A), fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Rentang Tanggal Sumber (Source)',
                      style: TextStyle(
                        color: AppTheme.tealAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _DateRangeField(
                            label: 'Mulai',
                            date: sourceStartDate,
                            onTap: () => pickDate(
                              pickerContext: ctx,
                              initialDate: sourceStartDate,
                              onPicked: (date) {
                                setSS(() {
                                  sourceStartDate = date;
                                  if (sourceEndDate.isBefore(sourceStartDate)) {
                                    sourceEndDate = sourceStartDate;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DateRangeField(
                            label: 'Selesai',
                            date: sourceEndDate,
                            onTap: () => pickDate(
                              pickerContext: ctx,
                              initialDate: sourceEndDate,
                              onPicked: (date) => setSS(() => sourceEndDate = date),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tanggal Mulai Target (Target)',
                      style: TextStyle(
                        color: AppTheme.violetPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DateRangeField(
                      label: 'Mulai Di Tanggal',
                      date: targetStartDate,
                      onTap: () => pickDate(
                        pickerContext: ctx,
                        initialDate: targetStartDate,
                        onPicked: (date) => setSS(() => targetStartDate = date),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Jumlah hari yang akan disalin: $dayCount hari',
                      style: const TextStyle(
                        color: Color(0x8A0F172A),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (sourceEndDate.isBefore(sourceStartDate)) {
                            return;
                          }
                          context.read<ManagementBloc>().add(
                                CopyAssignmentsRange(
                                  sourceStartDate: sourceStartDate,
                                  sourceEndDate: sourceEndDate,
                                  targetStartDate: targetStartDate,
                                  assignedBy: widget.user.id,
                                ),
                              );
                          Navigator.pop(ctx);
                        },
                        child: const Text('Salin Jadwal'),
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

  void _showBulkDeleteDialog(BuildContext context) {
    final userDatasource = sl<UserLocalDatasource>();
    final employees = userDatasource
        .getAllUsers()
        .where((u) => u.role != UserRole.superuser)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada karyawan untuk dihapus.'),
          backgroundColor: AppTheme.roseRed,
        ),
      );
      return;
    }

    final List<String> selectedUserIds = [];
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();

    Future<void> pickDate({
      required BuildContext pickerContext,
      required DateTime initialDate,
      required ValueChanged<DateTime> onPicked,
    }) async {
      final date = await showDatePicker(
        context: pickerContext,
        initialDate: initialDate,
        firstDate: DateTime.now().subtract(const Duration(days: 90)),
        lastDate: DateTime.now().add(const Duration(days: 180)),
      );
      if (date != null) {
        onPicked(date);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSS) {
            final isAllSelected = selectedUserIds.length == employees.length;

            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
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
                      'Hapus Jadwal Massal',
                      style: Theme.of(
                        ctx,
                      ).textTheme.headlineMedium?.copyWith(color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hapus penugasan jadwal untuk karyawan terpilih dalam rentang tanggal tertentu.',
                      style: TextStyle(color: Color(0x8A0F172A), fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Rentang Tanggal Penghapusan',
                      style: TextStyle(
                        color: AppTheme.roseRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _DateRangeField(
                            label: 'Mulai',
                            date: startDate,
                            onTap: () => pickDate(
                              pickerContext: ctx,
                              initialDate: startDate,
                              onPicked: (date) {
                                setSS(() {
                                  startDate = date;
                                  if (endDate.isBefore(startDate)) {
                                    endDate = startDate;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DateRangeField(
                            label: 'Selesai',
                            date: endDate,
                            onTap: () => pickDate(
                              pickerContext: ctx,
                              initialDate: endDate,
                              onPicked: (date) => setSS(() => endDate = date),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pilih Karyawan',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSS(() {
                              if (isAllSelected) {
                                selectedUserIds.clear();
                              } else {
                                selectedUserIds.clear();
                                selectedUserIds.addAll(employees.map((e) => e.id));
                              }
                            });
                          },
                          child: Text(
                            isAllSelected ? 'Batal Semua' : 'Pilih Semua',
                            style: const TextStyle(color: AppTheme.tealAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Color(0xFF0F172A).withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF0F172A).withValues(alpha: 0.05)),
                      ),
                      child: ListView.builder(
                        itemCount: employees.length,
                        itemBuilder: (c, idx) {
                          final e = employees[idx];
                          final isSelected = selectedUserIds.contains(e.id);
                          return CheckboxListTile(
                            title: Text(
                              e.name,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                            ),
                            subtitle: Text(
                              e.role.displayName,
                              style: const TextStyle(color: Color(0x610F172A), fontSize: 11),
                            ),
                            value: isSelected,
                            activeColor: AppTheme.roseRed,
                            checkColor: Colors.white,
                            onChanged: (val) {
                              setSS(() {
                                if (val == true) {
                                  selectedUserIds.add(e.id);
                                } else {
                                  selectedUserIds.remove(e.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Terpilih: ${selectedUserIds.length} karyawan',
                      style: const TextStyle(
                        color: Color(0x8A0F172A),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.roseRed,
                        ),
                        onPressed: () {
                          if (selectedUserIds.isEmpty || endDate.isBefore(startDate)) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Pilih minimal satu karyawan.'),
                                backgroundColor: AppTheme.roseRed,
                              ),
                            );
                            return;
                          }
                          context.read<ManagementBloc>().add(
                                DeleteAssignmentsRange(
                                  userIds: selectedUserIds,
                                  startDate: startDate,
                                  endDate: endDate,
                                ),
                              );
                          Navigator.pop(ctx);
                        },
                        child: const Text('Hapus Jadwal Massal'),
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

  void _showSwapShiftDialog(BuildContext context) {
    final userDatasource = sl<UserLocalDatasource>();
    final employees = userDatasource
        .getAllUsers()
        .where((u) => u.role != UserRole.superuser)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (employees.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Butuh minimal 2 karyawan untuk melakukan pertukaran.'),
          backgroundColor: AppTheme.roseRed,
        ),
      );
      return;
    }

    String? firstUserId = employees[0].id;
    String? secondUserId = employees[1].id;
    DateTime swapDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSS) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
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
                      'Tukar Shift Karyawan',
                      style: Theme.of(
                        ctx,
                      ).textTheme.headlineMedium?.copyWith(color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tukarkan penugasan jadwal antara dua karyawan pada tanggal yang sama. Kedua karyawan harus memiliki penugasan aktif pada tanggal tersebut.',
                      style: TextStyle(color: Color(0x8A0F172A), fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: firstUserId,
                      decoration: const InputDecoration(
                        labelText: 'Karyawan Pertama',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      dropdownColor: Color(0xFF1E2D42),
                      items: employees
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(
                                e.name,
                                style: const TextStyle(color: Color(0xFF0F172A)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        if (id != null) {
                          setSS(() {
                            firstUserId = id;
                            if (secondUserId == firstUserId) {
                              secondUserId = employees.firstWhere((e) => e.id != firstUserId).id;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: secondUserId,
                      decoration: const InputDecoration(
                        labelText: 'Karyawan Kedua',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      dropdownColor: Color(0xFF1E2D42),
                      items: employees
                          .where((e) => e.id != firstUserId)
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(
                                e.name,
                                style: const TextStyle(color: Color(0xFF0F172A)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setSS(() => secondUserId = id),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: swapDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 90)),
                          lastDate: DateTime.now().add(const Duration(days: 180)),
                        );
                        if (date != null) {
                          setSS(() => swapDate = date);
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
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: Color(0x610F172A),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormatters.formatDate(swapDate),
                              style: const TextStyle(color: Color(0xFF0F172A)),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit_calendar_rounded,
                              color: Color(0x3D0F172A),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.amberAccent,
                        ),
                        onPressed: () {
                          if (firstUserId == null || secondUserId == null) {
                            return;
                          }
                          context.read<ManagementBloc>().add(
                                SwapAssignments(
                                  firstUserId: firstUserId!,
                                  secondUserId: secondUserId!,
                                  date: swapDate,
                                  assignedBy: widget.user.id,
                                ),
                              );
                          Navigator.pop(ctx);
                        },
                        child: const Text('Tukar Shift'),
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

class _FilterDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Color(0xFF0F172A).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF0F172A).withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          dropdownColor: Color(0xFF1E2D42),
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: Color(0x610F172A),
            size: 20,
          ),
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
          hint: Text(
            hint,
            style: const TextStyle(color: Color(0x610F172A), fontSize: 13),
          ),
          items: [
            DropdownMenuItem<T?>(
              value: null,
              child: Text(
                hint,
                style: const TextStyle(color: Color(0xB30F172A)),
              ),
            ),
            ...items.map((item) => DropdownMenuItem<T?>(
                  value: item.value,
                  enabled: item.enabled,
                  onTap: item.onTap,
                  child: item.child,
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CompactDateFilter extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _CompactDateFilter({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xFF0F172A).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(0xFF0F172A).withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: Color(0x610F172A),
              size: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date == null ? label : DateFormatters.formatDate(date!),
                style: TextStyle(
                  color: date == null ? Color(0x610F172A) : Colors.white,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ScheduleActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }
}

class _DateRangeField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateRangeField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(0xFF0F172A).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Color(0xFF0F172A).withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0x610F172A), fontSize: 11),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0x610F172A),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormatters.formatDate(date),
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──── Overtime Tab ────
class _OvertimeTab extends StatefulWidget {
  final UserModel user;
  const _OvertimeTab({required this.user});
  @override
  State<_OvertimeTab> createState() => _OvertimeTabState();
}

class _OvertimeTabState extends State<_OvertimeTab> with SingleTickerProviderStateMixin {
  late final OvertimeBloc _bloc;
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _bloc = OvertimeBloc(
      overtimeDatasource: sl<OvertimeLocalDatasource>(),
      currentUserId: widget.user.id,
    )..add(const LoadAllOvertimes());
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _bloc.close();
    _subTabController.dispose();
    super.dispose();
  }

  void _refresh() {
    _bloc.add(const LoadAllOvertimes());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF0F172A).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      controller: _subTabController,
                      indicator: BoxDecoration(
                        color: AppTheme.tealAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: AppTheme.tealAccent,
                      unselectedLabelColor: Color(0x610F172A),
                      dividerHeight: 0,
                      tabs: const [
                        Tab(text: 'Persetujuan'),
                        Tab(text: 'Semua Lembur'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _showCreateMandateDialog(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.tealAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_task_rounded,
                      color: AppTheme.tealAccent,
                      size: 20,
                    ),
                  ),
                  tooltip: 'Beri Perintah Lembur',
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<OvertimeBloc, OvertimeState>(
              listener: (context, state) {
                if (state is OvertimeSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppTheme.emeraldGreen,
                    ),
                  );
                  _refresh();
                } else if (state is OvertimeApproved) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lembur disetujui!'),
                      backgroundColor: AppTheme.emeraldGreen,
                    ),
                  );
                  _refresh();
                } else if (state is OvertimeRejected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lembur ditolak.'),
                      backgroundColor: AppTheme.roseRed,
                    ),
                  );
                  _refresh();
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

                return TabBarView(
                  controller: _subTabController,
                  children: [
                    _buildPendingApprovalsView(),
                    _buildAllOvertimesView(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalsView() {
    final pending = sl<OvertimeLocalDatasource>().getPendingOvertimesForApproval(widget.user.role);

    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 48, color: Color(0xFF0F172A).withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada pengajuan lembur pending',
              style: TextStyle(color: Color(0x3D0F172A), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: pending.length,
      itemBuilder: (context, index) => _buildOvertimeCard(pending[index], isApproval: true),
    );
  }

  Widget _buildAllOvertimesView() {
    final all = sl<OvertimeLocalDatasource>().getAllOvertimes();

    if (all.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_rounded,
                size: 48, color: Color(0xFF0F172A).withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            const Text(
              'Belum ada riwayat lembur karyawan',
              style: TextStyle(color: Color(0x3D0F172A), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: all.length,
      itemBuilder: (context, index) => _buildOvertimeCard(all[index], isApproval: false),
    );
  }

  Widget _buildOvertimeCard(OvertimeModel overtime, {required bool isApproval}) {
    final employee = sl<UserLocalDatasource>().getUserById(overtime.userId);
    final site = sl<SiteLocalDatasource>().getSiteById(overtime.siteId);
    final statusColor = _getStatusColor(overtime.status);

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
                  employee?.name ?? 'Karyawan Tidak Dikenal',
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
          const SizedBox(height: 4),
          Text(
            'Site: ${site?.name ?? "-"}',
            style: const TextStyle(color: Color(0x610F172A), fontSize: 12),
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
          if (isApproval && !overtime.status.isTerminal) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _bloc.add(RejectOvertime(
                      overtimeId: overtime.id,
                      rejectedBy: widget.user.id,
                    )),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.roseRed,
                      side: const BorderSide(color: AppTheme.roseRed),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _bloc.add(ApproveOvertime(
                      overtimeId: overtime.id,
                      approverRole: widget.user.role,
                      approverId: widget.user.id,
                    )),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Setujui'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
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

  void _showCreateMandateDialog(BuildContext context) {
    DateTime? selectedDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 17, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 20, minute: 0);
    final reasonController = TextEditingController();

    final employees = sl<UserLocalDatasource>().getAllUsers().where((u) => u.role == UserRole.karyawan || u.role == UserRole.leader).toList();
    String? selectedEmpId = employees.isNotEmpty ? employees.first.id : null;

    final sites = sl<SiteLocalDatasource>().getAllSites();
    String? selectedSiteId = sites.isNotEmpty ? sites.first.id : null;

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
                      'Beri Perintah Lembur',
                      style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                            color: Color(0xFF0F172A),
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Employee selection
                    if (employees.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedEmpId,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Karyawan',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        dropdownColor: Color(0xFF1E2D42),
                        items: employees
                            .map((e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(e.name, style: const TextStyle(color: Color(0xFF0F172A))),
                                ))
                            .toList(),
                        onChanged: (id) {
                          if (id != null) {
                            setSheetState(() => selectedEmpId = id);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
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
                    // Reason
                    TextFormField(
                      controller: reasonController,
                      maxLines: 3,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        labelText: 'Tugas / Keperluan Lembur',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedDate == null ||
                              selectedEmpId == null ||
                              selectedSiteId == null ||
                              reasonController.text.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Harap lengkapi semua field.'),
                                backgroundColor: AppTheme.roseRed,
                              ),
                            );
                            return;
                          }
                          _bloc.add(CreateOvertimeMandate(
                            userId: selectedEmpId!,
                            date: selectedDate!,
                            startTime: formatTimeOfDay(startTime),
                            endTime: formatTimeOfDay(endTime),
                            reason: reasonController.text,
                            siteId: selectedSiteId!,
                            instructedBy: widget.user.id,
                          ));
                          Navigator.pop(ctx);
                        },
                        child: const Text('Kirim Perintah Lembur'),
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
