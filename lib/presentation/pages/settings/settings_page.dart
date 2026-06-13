import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/core/theme/app_theme.dart';
import 'package:absensi_app/core/utils/device_security.dart';
import 'package:absensi_app/core/utils/notification_helper.dart';
import 'package:absensi_app/data/models/user_model.dart';
import 'package:absensi_app/injection.dart';
import 'package:absensi_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:absensi_app/presentation/blocs/auth/auth_event.dart';

class SettingsPage extends StatefulWidget {
  final UserModel user;

  const SettingsPage({super.key, required this.user});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isRooted = false;
  bool _isMockLocation = false;
  bool _isBiometricSupported = false;
  bool _isLoadingChecks = true;
  bool _reminderEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _runDiagnostics();
  }

  void _loadSettings() {
    final settingsBox = Hive.box(HiveBoxes.appSettings);
    setState(() {
      _reminderEnabled = settingsBox.get('reminder_enabled', defaultValue: false) as bool;
    });
  }

  Future<void> _runDiagnostics() async {
    final security = sl<DeviceSecurity>();
    final auth = sl<LocalAuthentication>();

    try {
      final rooted = await security.isDeviceRooted();
      final mock = await security.isMockLocationEnabled();
      final canBiometric = await auth.canCheckBiometrics;
      final supported = await auth.isDeviceSupported();

      if (mounted) {
        setState(() {
          _isRooted = rooted;
          _isMockLocation = mock;
          _isBiometricSupported = canBiometric || supported;
          _isLoadingChecks = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingChecks = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar()),
            SliverToBoxAdapter(child: _buildProfileCard()),
            SliverToBoxAdapter(child: _buildSectionTitle('Keamanan Perangkat')),
            SliverToBoxAdapter(child: _buildSecurityCard()),
            SliverToBoxAdapter(child: _buildSectionTitle('Preferensi & Notifikasi')),
            SliverToBoxAdapter(child: _buildPreferencesCard()),
            SliverToBoxAdapter(child: _buildSectionTitle('Informasi Aplikasi')),
            SliverToBoxAdapter(child: _buildAppInfoCard()),
            SliverToBoxAdapter(child: _buildLogoutButton()),
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
              color: AppTheme.tealAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tune_rounded,
                color: AppTheme.tealAccent, size: 24),
          ),
          const SizedBox(width: 14),
          Text(
            'Pengaturan',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassDecoration,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      widget.user.name.isNotEmpty
                          ? widget.user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.email,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.tealAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.user.role.displayName,
                    style: const TextStyle(
                      color: AppTheme.tealAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.white12, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tautan Perangkat',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ID Terdaftar',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    final deviceId = widget.user.deviceId ?? 'Belum Terikat';
                    Clipboard.setData(ClipboardData(text: deviceId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ID Perangkat disalin ke papan klip'),
                        backgroundColor: AppTheme.emeraldGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, color: AppTheme.tealAccent, size: 20),
                  tooltip: 'Salin ID Perangkat',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white30,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: AppTheme.glassDecoration,
        child: Column(
          children: [
            _buildSecurityTile(
              icon: Icons.security_rounded,
              title: 'Proteksi Root Perangkat',
              subtitle: _isLoadingChecks
                  ? 'Memeriksa...'
                  : (_isRooted ? 'Bahaya - Perangkat Di-root' : 'Aman - Perangkat Standar'),
              isWarning: _isRooted && !_isLoadingChecks,
            ),
            const Divider(color: Colors.white12, height: 1),
            _buildSecurityTile(
              icon: Icons.location_off_rounded,
              title: 'Deteksi Lokasi Palsu',
              subtitle: _isLoadingChecks
                  ? 'Memeriksa...'
                  : (_isMockLocation ? 'Terdeteksi - Mock GPS Aktif' : 'Aman - GPS Asli'),
              isWarning: _isMockLocation && !_isLoadingChecks,
            ),
            const Divider(color: Colors.white12, height: 1),
            _buildSecurityTile(
              icon: Icons.fingerprint_rounded,
              title: 'Autentikasi Biometrik',
              subtitle: _isLoadingChecks
                  ? 'Memeriksa...'
                  : (_isBiometricSupported ? 'Didukung' : 'Tidak Didukung / Belum Diaktifkan'),
              isWarning: !_isBiometricSupported && !_isLoadingChecks,
              neutralWarning: !_isBiometricSupported && !_isLoadingChecks,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isWarning,
    bool neutralWarning = false,
  }) {
    Color statusColor = Colors.white54;
    if (!neutralWarning) {
      if (isWarning) {
        statusColor = AppTheme.roseRed;
      } else if (!_isLoadingChecks) {
        statusColor = AppTheme.emeraldGreen;
      }
    } else {
      statusColor = AppTheme.amberAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: statusColor.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: AppTheme.glassDecoration,
        padding: const EdgeInsets.all(16),
        child: const Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bahasa Aplikasi', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text('Bahasa Indonesia', style: TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Versi Aplikasi', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text('1.0.0 (Produksi)', style: TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: AppTheme.glassDecoration,
        child: Column(
          children: [
            SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.tealAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: AppTheme.tealAccent, size: 20),
              ),
              title: const Text(
                'Pengingat Absen',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Ingatkan 15 menit sebelum masuk dan keluar shift.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              value: _reminderEnabled,
              onChanged: _toggleReminder,
              activeThumbColor: AppTheme.tealAccent,
              activeTrackColor: AppTheme.tealAccent.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.white10,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_none_rounded, color: AppTheme.skyBlue, size: 20),
              ),
              title: const Text(
                'Uji Coba Notifikasi',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Kirim notifikasi tes langsung ke perangkat ini.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              onTap: _testNotification,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      final granted = await NotificationHelper.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin notifikasi ditolak. Aktifkan izin notifikasi di pengaturan sistem.'),
              backgroundColor: AppTheme.roseRed,
            ),
          );
        }
        return;
      }
    }

    final settingsBox = Hive.box(HiveBoxes.appSettings);
    await settingsBox.put('reminder_enabled', value);
    setState(() {
      _reminderEnabled = value;
    });

    if (value) {
      await NotificationHelper.scheduleReminders(widget.user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengingat absen otomatis berhasil dijadwalkan!'),
            backgroundColor: AppTheme.emeraldGreen,
          ),
        );
      }
    } else {
      await NotificationHelper.cancelAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengingat absen otomatis dinonaktifkan.'),
            backgroundColor: AppTheme.skyBlue,
          ),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    await NotificationHelper.showTestNotification();
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: SizedBox(
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _showLogoutConfirm,
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text('Keluar dari Akun'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.roseRed.withValues(alpha: 0.15),
            foregroundColor: AppTheme.roseRed,
            side: const BorderSide(color: AppTheme.roseRed, width: 1),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2D42),
        title: const Text('Keluar Akun', style: TextStyle(color: Colors.white)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun absensi Anda di perangkat ini?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
