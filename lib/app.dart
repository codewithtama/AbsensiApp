import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:absensi_app/core/theme/app_theme.dart';
import 'package:absensi_app/data/datasources/user_local_datasource.dart';
import 'package:absensi_app/injection.dart';
import 'package:absensi_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:absensi_app/presentation/blocs/auth/auth_event.dart';
import 'package:absensi_app/presentation/blocs/auth/auth_state.dart';
import 'package:absensi_app/presentation/pages/login/login_page.dart';
import 'package:absensi_app/presentation/pages/dashboard/dashboard_page.dart';

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(
        userDatasource: sl<UserLocalDatasource>(),
      )..add(const CheckSession()),
      child: MaterialApp(
        title: 'Absensi App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return DashboardPage(user: state.user);
            }
            return const LoginPage();
          },
        ),
      ),
    );
  }
}
