import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:absensi_app/data/hive_registrar.dart';
import 'package:absensi_app/injection.dart';
import 'package:absensi_app/app.dart';
import 'package:absensi_app/core/utils/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F1923),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive
  try {
    await Hive.initFlutter();
    registerHiveAdapters();
    await openHiveBoxes();
  } catch (e) {
    debugPrint('Hive initialization failed, attempting recovery by deleting boxes: $e');
    try {
      await Hive.deleteFromDisk();
      await Hive.initFlutter();
      registerHiveAdapters();
      await openHiveBoxes();
    } catch (recoveryError) {
      debugPrint('Hive recovery failed: $recoveryError');
    }
  }

  // Setup DI
  try {
    setupDependencies();
  } catch (e) {
    debugPrint('Dependency injection setup failed: $e');
  }

  // Initialize Local Notifications
  try {
    await NotificationHelper.init();
  } catch (e) {
    debugPrint('Notification helper initialization failed: $e');
  }

  runApp(const AbsensiApp());
}
