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
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: AppTheme.violetPurple, size: 24),
          ),
          const SizedBox(width: 14),
          Text(
            'Kelola',
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
          isScrollable: _tabs.length > 3,
          indicator: BoxDecoration(
            color: AppTheme.tealAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppTheme.tealAccent,
          unselectedLabelColor: Colors.white38,
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
                backgroundColor: AppTheme.emeraldGreen),
          );
          setState(() {
            _currentPage = 1;
          });
          context.read<ManagementBloc>().add(const LoadUsers());
        } else if (state is ManagementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.roseRed),
          );
        }
      },
      buildWhen: (prev, curr) => curr is UsersLoaded || curr is ManagementLoading,
      builder: (context, state) {
        if (state is ManagementLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.tealAccent));
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
                    child: Text('${users.length} pengguna',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white38)),
                  ),
                  IconButton(
                    onPressed: () => _showCreateUserDialog(context),
                    icon: Container(
                       padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.tealAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppTheme.tealAccent, size: 20),
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
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: Colors.white)),
                              Text(u.email,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white38)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.tealAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(u.role.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: AppTheme.tealAccent,
                                      fontWeight: FontWeight.w600)),
                        ),
                        if (widget.user.role.canUnbindDevice &&
                            u.deviceId != null)
                          IconButton(
                            onPressed: () => context
                                .read<ManagementBloc>()
                                .add(UnbindDevice(userId: u.id)),
                            icon: const Icon(Icons.link_off_rounded,
                                color: AppTheme.amberAccent, size: 20),
                            tooltip: 'Lepas Tautan',
                          ),
                        if (widget.user.role.canManageUsers) ...[
                          IconButton(
                            onPressed: () => _showEditUserDialog(context, u),
                            icon: const Icon(Icons.edit_rounded,
                                color: AppTheme.tealAccent, size: 20),
                            tooltip: 'Ubah',
                          ),
                          IconButton(
                            onPressed: () => _showDeleteUserConfirm(context, u),
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppTheme.roseRed, size: 20),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: AppTheme.tealAccent,
                      disabledColor: Colors.white12,
                    ),
                    Text(
                      'Halaman $currentPage dari $totalPages',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    IconButton(
                      onPressed: currentPage < totalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: AppTheme.tealAccent,
                      disabledColor: Colors.white12,
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
        backgroundColor: const Color(0xFF1E2D42),
        title: const Text('Hapus Pengguna', style: TextStyle(color: Colors.white)),
        content: Text('Apakah Anda yakin ingin menghapus "${targetUser.name}"? Catatan absensi pengguna ini tidak akan terhapus namun relasinya akan hilang.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ManagementBloc>().add(DeleteUser(userId: targetUser.id));
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
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Ubah Pengguna',
                        style: Theme.of(ctx).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameC,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailC,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passC,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Password Baru (kosongkan jika tidak diubah)',
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
                      dropdownColor: const Color(0xFF1E2D42),
                      items: UserRole.values
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.displayName,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ))
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
                          context.read<ManagementBloc>().add(UpdateUser(
                                userId: targetUser.id,
                                name: nameC.text,
                                email: emailC.text,
                                password: passC.text.isEmpty ? null : passC.text,
                                role: selectedRole,
                              ));
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
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Tambah Pengguna',
                        style: Theme.of(ctx).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameC,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailC,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passC,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
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
                      dropdownColor: const Color(0xFF1E2D42),
                      items: UserRole.values
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.displayName,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ))
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
                          context.read<ManagementBloc>().add(CreateUser(
                                name: nameC.text,
                                email: emailC.text,
                                password: passC.text,
                                role: selectedRole,
                              ));
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
                backgroundColor: AppTheme.emeraldGreen),
          );
          context.read<ManagementBloc>().add(const LoadSites());
        }
      },
      buildWhen: (prev, curr) => curr is SitesLoaded || curr is ManagementLoading,
      builder: (context, state) {
        if (state is ManagementLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.tealAccent));
        }

        final sites = state is SitesLoaded ? state.sites : [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${sites.length} sites',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white38)),
                  ),
                  IconButton(
                    onPressed: () => _showCreateSiteDialog(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.tealAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppTheme.tealAccent, size: 20),
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
                            color:
                                AppTheme.skyBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.location_on_rounded,
                              color: AppTheme.skyBlue, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(site.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: Colors.white)),
                              Text(
                                '${site.latitude.toStringAsFixed(6)}, ${site.longitude.toStringAsFixed(6)} • ${site.radiusMeters.toStringAsFixed(0)}m',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.white38),
                              ),
                            ],
                          ),
                        ),
                        if (widget.user.role.canManageSites) ...[
                          IconButton(
                            onPressed: () => _showEditSiteDialog(context, site),
                            icon: const Icon(Icons.edit_rounded,
                                color: AppTheme.tealAccent, size: 20),
                            tooltip: 'Ubah',
                          ),
                          IconButton(
                            onPressed: () => _showDeleteSiteConfirm(context, site),
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppTheme.roseRed, size: 20),
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
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Tambah Site',
                    style: Theme.of(ctx).textTheme.headlineMedium
                        ?.copyWith(color: Colors.white)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameC,
                  style: const TextStyle(color: Colors.white),
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
                            decimal: true, signed: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Latitude'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: lngC,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        style: const TextStyle(color: Colors.white),
                        decoration:
                            const InputDecoration(labelText: 'Longitude'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: radiusC,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
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
                      context.read<ManagementBloc>().add(CreateSite(
                            name: nameC.text,
                            latitude: lat,
                            longitude: lng,
                            radiusMeters: radius,
                          ));
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
        backgroundColor: const Color(0xFF1E2D42),
        title: const Text('Hapus Lokasi Kerja', style: TextStyle(color: Colors.white)),
        content: Text('Apakah Anda yakin ingin menghapus "${targetSite.name}"? Karyawan yang dikaitkan dengan lokasi ini tidak akan dapat melakukan absensi sebelum jadwal lokasi mereka diubah.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ManagementBloc>().add(DeleteSite(siteId: targetSite.id));
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
    final radiusC = TextEditingController(text: targetSite.radiusMeters.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
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
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Ubah Site',
                    style: Theme.of(ctx).textTheme.headlineMedium
                        ?.copyWith(color: Colors.white)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameC,
                  style: const TextStyle(color: Colors.white),
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
                            decimal: true, signed: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Latitude'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: lngC,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        style: const TextStyle(color: Colors.white),
                        decoration:
                            const InputDecoration(labelText: 'Longitude'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: radiusC,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
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
                      context.read<ManagementBloc>().add(UpdateSite(
                            siteId: targetSite.id,
                            name: nameC.text,
                            latitude: lat,
                            longitude: lng,
                            radiusMeters: radius,
                          ));
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
                backgroundColor: AppTheme.emeraldGreen),
          );
          context.read<ManagementBloc>().add(const LoadShifts());
        }
      },
      buildWhen: (prev, curr) => curr is ShiftsLoaded || curr is ManagementLoading,
      builder: (context, state) {
        if (state is ManagementLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.tealAccent));
        }

        final shifts = state is ShiftsLoaded ? state.shifts : [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${shifts.length} shifts',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white38)),
                  ),
                  IconButton(
                    onPressed: () => _showCreateShiftDialog(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.tealAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppTheme.tealAccent, size: 20),
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
                            color: AppTheme.amberAccent
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.schedule_rounded,
                              color: AppTheme.amberAccent, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shift.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: Colors.white)),
                              Text(
                                '${shift.startTime} — ${shift.endTime}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.white38),
                              ),
                            ],
                          ),
                        ),
                        if (widget.user.role.canManageShifts) ...[
                          IconButton(
                            onPressed: () => _showEditShiftDialog(context, shift),
                            icon: const Icon(Icons.edit_rounded,
                                color: AppTheme.tealAccent, size: 20),
                            tooltip: 'Ubah',
                          ),
                          IconButton(
                            onPressed: () => _showDeleteShiftConfirm(context, shift),
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppTheme.roseRed, size: 20),
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
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Tambah Shift',
                    style: Theme.of(ctx).textTheme.headlineMedium
                        ?.copyWith(color: Colors.white)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameC,
                  style: const TextStyle(color: Colors.white),
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
                            style: const TextStyle(color: Colors.white),
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
                            style: const TextStyle(color: Colors.white),
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
                      context.read<ManagementBloc>().add(CreateShift(
                            name: nameC.text,
                            startTime: startC.text,
                            endTime: endC.text,
                          ));
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
        backgroundColor: const Color(0xFF1E2D42),
        title: const Text('Hapus Shift Kerja', style: TextStyle(color: Colors.white)),
        content: Text('Apakah Anda yakin ingin menghapus "${targetShift.name}"? Jadwal harian karyawan yang menggunakan shift ini akan perlu disesuaikan kembali.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ManagementBloc>().add(DeleteShift(shiftId: targetShift.id));
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
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Ubah Shift',
                    style: Theme.of(ctx).textTheme.headlineMedium
                        ?.copyWith(color: Colors.white)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameC,
                  style: const TextStyle(color: Colors.white),
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
                              ? TimeOfDay(hour: int.parse(initialParts[0]), minute: int.parse(initialParts[1]))
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
                            style: const TextStyle(color: Colors.white),
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
                              ? TimeOfDay(hour: int.parse(initialParts[0]), minute: int.parse(initialParts[1]))
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
                            style: const TextStyle(color: Colors.white),
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
                      context.read<ManagementBloc>().add(UpdateShift(
                            shiftId: targetShift.id,
                            name: nameC.text,
                            startTime: startC.text,
                            endTime: endC.text,
                          ));
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

    final allUsers = userDatasource.getAllUsers()
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
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
                      final records = attendanceDatasource.getAttendanceByDateRange(
                        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
                        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59),
                      );
                      
                      if (records.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tidak ada data absensi untuk diekspor pada tanggal ini.'),
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
                        final file = await generator.generateAttendanceCsv(records);
                        
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Rekap berhasil diekspor ke: ${file.path}'),
                            backgroundColor: AppTheme.emeraldGreen,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Gagal mengekspor rekap: ${e.toString()}'),
                            backgroundColor: AppTheme.roseRed,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download_rounded, color: AppTheme.tealAccent),
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
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                        ? siteDatasource.getSiteById(clockInRecord.siteId)?.name ?? 'Unknown Site'
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
                                color: AppTheme.tealAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
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
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${employee.role.displayName} • $siteName',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildStatusBadge(hasAttended, clockOutRecord != null),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimes(clockInRecord, clockOutRecord),
                                  style: const TextStyle(
                                    color: Colors.white54,
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
    final outStr = outRec != null ? DateFormatters.formatTime(outRec.timestamp) : '--:--';
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
                Text('Email: ${employee.email}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                Text('Jabatan: ${employee.role.displayName}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const Divider(height: 24),
                
                // Section Masuk
                const Text('Absen Masuk:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.tealAccent)),
                const SizedBox(height: 6),
                if (inRec == null)
                  const Text('Belum absen masuk.', style: TextStyle(color: Colors.white30, fontSize: 13))
                else ...[
                  Text('Waktu: ${DateFormatters.formatTime(inRec.timestamp)}', style: const TextStyle(fontSize: 13)),
                  Text('Lokasi: $siteName', style: const TextStyle(fontSize: 13)),
                  Text('Perangkat: ${inRec.deviceName ?? 'Tidak Diketahui'}', style: const TextStyle(fontSize: 13)),
                  Text('Sistem Operasi: ${inRec.deviceOs ?? 'Tidak Diketahui'}', style: const TextStyle(fontSize: 13)),
                  Text('Jaringan: ${inRec.networkType ?? 'Tidak Diketahui'}', style: const TextStyle(fontSize: 13)),
                  
                  // Lateness info
                  if (inRec.isLate == true)
                    Text('Status: Terlambat (${inRec.delayMinutes} menit)', style: const TextStyle(color: AppTheme.roseRed, fontSize: 13, fontWeight: FontWeight.w600))
                  else if (inRec.isLate == false)
                    const Text('Status: Tepat Waktu', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 13, fontWeight: FontWeight.w600))
                  else
                    const Text('Status: Tepat Waktu (Bypass)', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
                
                const Divider(height: 24),
                
                // Section Keluar
                const Text('Absen Keluar:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.amberAccent)),
                const SizedBox(height: 6),
                if (outRec == null)
                  const Text('Belum absen keluar.', style: TextStyle(color: Colors.white30, fontSize: 13))
                else ...[
                  Text('Waktu: ${DateFormatters.formatTime(outRec.timestamp)}', style: const TextStyle(fontSize: 13)),
                  Text('Perangkat: ${outRec.deviceName ?? 'Tidak Diketahui'}', style: const TextStyle(fontSize: 13)),
                  Text('Sistem Operasi: ${outRec.deviceOs ?? 'Tidak Diketahui'}', style: const TextStyle(fontSize: 13)),
                  Text('Jaringan: ${outRec.networkType ?? 'Tidak Diketahui'}', style: const TextStyle(fontSize: 13)),
                  
                  // Early out info
                  if (outRec.isEarlyOut == true)
                    Text('Status: Pulang Cepat (${outRec.delayMinutes} menit)', style: const TextStyle(color: AppTheme.roseRed, fontSize: 13, fontWeight: FontWeight.w600))
                  else if (outRec.isEarlyOut == false)
                    const Text('Status: Sesuai Jadwal', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 13, fontWeight: FontWeight.w600))
                  else
                    const Text('Status: Sesuai Jadwal (Bypass)', style: TextStyle(color: Colors.white38, fontSize: 13)),
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

    return BlocConsumer<ManagementBloc, ManagementState>(
      listener: (context, state) {
        if (state is ManagementSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppTheme.emeraldGreen),
          );
          setState(() => _currentPage = 1);
          context.read<ManagementBloc>().add(const LoadShiftAssignments());
        } else if (state is ManagementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppTheme.roseRed),
          );
        }
      },
      buildWhen: (prev, curr) =>
          curr is ShiftAssignmentsLoaded || curr is ManagementLoading,
      builder: (context, state) {
        if (state is ManagementLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent));
        }

        final allAssignments = state is ShiftAssignmentsLoaded ? state.assignments : <ShiftAssignmentModel>[];

        // Filter per site
        final filtered = _filterSiteId == null
            ? allAssignments
            : allAssignments.where((a) => a.siteId == _filterSiteId).toList();

        // Pagination
        final total = filtered.length;
        final totalPages = total == 0 ? 1 : (total / _pageSize).ceil();
        final page = _currentPage.clamp(1, totalPages);
        final startIdx = (page - 1) * _pageSize;
        final endIdx = (startIdx + _pageSize).clamp(0, total);
        final paginated = filtered.sublist(startIdx, endIdx);

        return Column(
          children: [
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
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _filterSiteId,
                          dropdownColor: const Color(0xFF1E2D42),
                          icon: const Icon(Icons.filter_list_rounded, color: Colors.white38, size: 18),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          hint: const Text('Semua Lokasi', style: TextStyle(color: Colors.white38, fontSize: 13)),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Semua Lokasi', style: TextStyle(color: Colors.white)),
                            ),
                            ...allSites.map((s) => DropdownMenuItem<String?>(
                                  value: s.id,
                                  child: Text(s.name, style: const TextStyle(color: Colors.white)),
                                )),
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
                  Text('${filtered.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38)),
                  // Tombol tambah
                  IconButton(
                    onPressed: () => _showAssignmentDialog(context, null),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.tealAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_rounded, color: AppTheme.tealAccent, size: 20),
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
                          Icon(Icons.calendar_month_rounded,
                              size: 48, color: Colors.white.withValues(alpha: 0.12)),
                          const SizedBox(height: 12),
                          Text(
                            _filterSiteId == null
                                ? 'Belum ada penugasan jadwal.'
                                : 'Tidak ada penugasan untuk lokasi ini.',
                            style: const TextStyle(color: Colors.white38),
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
                                  color: AppTheme.tealAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.calendar_month_rounded,
                                    color: AppTheme.tealAccent, size: 20),
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
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (employee != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.violetPurple.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              employee.role.displayName,
                                              style: const TextStyle(
                                                  color: AppTheme.violetPurple,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${shift == null ? "\u2014" : shift.name} • ${shift?.startTime ?? ""}–${shift?.endTime ?? ""}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded,
                                            size: 11, color: Colors.white38),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            site?.name ?? '—',
                                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.calendar_today_rounded,
                                            size: 11, color: Colors.white38),
                                        const SizedBox(width: 3),
                                        Text(
                                          DateFormatters.formatDate(a.date),
                                          style: const TextStyle(color: Colors.white38, fontSize: 11),
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
                                    onTap: () => _showAssignmentDialog(context, a),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(Icons.edit_rounded,
                                          color: AppTheme.skyBlue, size: 18),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _confirmDelete(context, a.id),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(Icons.delete_outline_rounded,
                                          color: AppTheme.roseRed.withValues(alpha: 0.8), size: 18),
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
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white54),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.tealAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.tealAccent.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '$page / $totalPages',
                        style: const TextStyle(
                            color: AppTheme.tealAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    IconButton(
                      onPressed: page < totalPages
                          ? () => setState(() => _currentPage = page + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String assignmentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162233),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Penugasan?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Penugasan jadwal ini akan dihapus permanen. Karyawan terkait tidak akan bisa absen pada hari tersebut.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ManagementBloc>().add(DeleteAssignment(assignmentId: assignmentId));
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  /// [existing] == null → mode Create, != null → mode Edit
  void _showAssignmentDialog(BuildContext context, ShiftAssignmentModel? existing) {
    final userDatasource = sl<UserLocalDatasource>();
    final siteDatasource = sl<SiteLocalDatasource>();
    final shiftDatasource = sl<ShiftLocalDatasource>();

    // Semua role kecuali superuser bisa di-assign
    final employees = userDatasource.getAllUsers()
        .where((u) => u.role != UserRole.superuser)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final sites = siteDatasource.getAllSites();
    final shifts = shiftDatasource.getAllShifts();

    if (employees.isEmpty || sites.isEmpty || shifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pastikan Karyawan, Lokasi, dan Shift sudah tersedia.'),
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
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isEdit ? 'Edit Penugasan Jadwal' : 'Plotting Jadwal Karyawan',
                      style: Theme.of(ctx)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 24),

                    // Karyawan Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedUserId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Karyawan / Atasan',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      dropdownColor: const Color(0xFF1E2D42),
                      items: employees
                          .map((e) => DropdownMenuItem(
                                value: e.id,
                                child: Row(
                                  children: [
                                    Text(e.name, style: const TextStyle(color: Colors.white)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '[${e.role.displayName}]',
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.35),
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ))
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
                      dropdownColor: const Color(0xFF1E2D42),
                      items: sites
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name,
                                    style: const TextStyle(color: Colors.white)),
                              ))
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
                      dropdownColor: const Color(0xFF1E2D42),
                      items: shifts
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  '${s.name} (${s.startTime} – ${s.endTime})',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ))
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
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setSS(() => selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: Colors.white38, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              DateFormatters.formatDate(selectedDate),
                              style: const TextStyle(color: Colors.white),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_calendar_rounded,
                                color: Colors.white24, size: 16),
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
                              selectedShiftId == null) { return; }

                          if (isEdit) {
                            context.read<ManagementBloc>().add(UpdateAssignment(
                                  assignmentId: existing.id,
                                  userId: selectedUserId!,
                                  shiftId: selectedShiftId!,
                                  siteId: selectedSiteId!,
                                  date: selectedDate,
                                  assignedBy: widget.user.id,
                                ));
                          } else {
                            context.read<ManagementBloc>().add(AssignShift(
                                  userId: selectedUserId!,
                                  shiftId: selectedShiftId!,
                                  siteId: selectedSiteId!,
                                  date: selectedDate,
                                  assignedBy: widget.user.id,
                                ));
                          }
                          Navigator.pop(ctx);
                        },
                        child: Text(isEdit ? 'Perbarui Penugasan' : 'Simpan Penugasan'),
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
