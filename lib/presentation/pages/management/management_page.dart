import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/core/theme/app_theme.dart';
import 'package:absensi_app/core/utils/date_formatters.dart';
import 'package:absensi_app/data/datasources/user_local_datasource.dart';
import 'package:absensi_app/data/datasources/attendance_local_datasource.dart';
import 'package:absensi_app/data/datasources/site_local_datasource.dart';
import 'package:absensi_app/data/models/user_model.dart';
import 'package:absensi_app/data/models/attendance_model.dart';
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
      _tabs.add(_TabDef('Users', Icons.people_rounded));
    }
    if (widget.user.role.canManageSites) {
      _tabs.add(_TabDef('Sites', Icons.location_on_rounded));
    }
    if (widget.user.role.canManageShifts) {
      _tabs.add(_TabDef('Shifts', Icons.schedule_rounded));
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
                    case 'Users':
                      return _UsersTab(user: widget.user);
                    case 'Sites':
                      return _SitesTab(user: widget.user);
                    case 'Shifts':
                      return _ShiftsTab(user: widget.user);
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
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final u = users[index];
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
                            tooltip: 'Unbind Device',
                          ),
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
                      value: selectedRole,
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
                        IconButton(
                          onPressed: () => context
                              .read<ManagementBloc>()
                              .add(DeleteSite(siteId: site.id)),
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppTheme.roseRed, size: 20),
                        ),
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
                        IconButton(
                          onPressed: () => context
                              .read<ManagementBloc>()
                              .add(DeleteShift(shiftId: shift.id)),
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppTheme.roseRed, size: 20),
                        ),
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

                    return Container(
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
}
