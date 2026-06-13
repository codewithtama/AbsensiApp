import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:absensi_app/core/theme/app_theme.dart';
import 'package:absensi_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:absensi_app/presentation/blocs/auth/auth_event.dart';
import 'package:absensi_app/presentation/blocs/auth/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFF0F172A), size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 48),
                        _buildLoginCard(),
                        const SizedBox(height: 24),
                        _buildDemoLoginPanel(),
                        const SizedBox(height: 24),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.tealAccent.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.fingerprint_rounded,
            size: 44,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Absensi',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sistem Kehadiran Karyawan',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Color(0x610F172A),
              ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      decoration: AppTheme.glassDecoration,
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Masuk',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Color(0xFF0F172A),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan kredensial Anda untuk melanjutkan',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Color(0x610F172A),
                  ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Color(0xFF0F172A)),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Email wajib diisi';
                if (!val.contains('@')) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Color(0x610F172A),
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Password wajib diisi';
                return null;
              },
            ),
            const SizedBox(height: 32),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onLogin,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF0F172A),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login_rounded, size: 20),
                              SizedBox(width: 10),
                              Text('Masuk'),
                            ],
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.amberAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.amberAccent.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline,
                  size: 16, color: AppTheme.amberAccent.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(
                'Default: admin@absensi.app / admin123',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.amberAccent.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'v1.0.0 • Offline Mode',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Color(0x3D0F172A),
              ),
        ),
      ],
    );
  }

  Widget _buildDemoLoginPanel() {
    final demoUsers = [
      {'label': 'Admin', 'email': 'admin@absensi.app', 'pass': 'admin123', 'color': AppTheme.roseRed},
      {'label': 'Manager', 'email': 'manager@absensi.app', 'pass': 'manager123', 'color': AppTheme.skyBlue},
      {'label': 'SPV', 'email': 'supervisor@absensi.app', 'pass': 'spv123', 'color': AppTheme.violetPurple},
      {'label': 'Leader', 'email': 'leader@absensi.app', 'pass': 'leader123', 'color': AppTheme.amberAccent},
      {'label': 'Staff', 'email': 'karyawan@absensi.app', 'pass': 'karyawan123', 'color': AppTheme.emeraldGreen},
    ];

    return Container(
      decoration: AppTheme.glassDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: AppTheme.tealAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Masuk Cepat (Demo)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Color(0xB30F172A),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: demoUsers.map((user) {
              final color = user['color'] as Color;
              return InkWell(
                onTap: () {
                  context.read<AuthBloc>().add(
                        LoginRequested(
                          email: user['email'] as String,
                          password: user['pass'] as String,
                        ),
                      );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    user['label'] as String,
                    style: TextStyle(
                      color: const Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<AuthBloc>().add(
          LoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }
}
