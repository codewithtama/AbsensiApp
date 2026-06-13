import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/models/user_model.dart';
import 'package:absensi_app/data/datasources/shift_assignment_local_datasource.dart';
import 'package:absensi_app/data/datasources/shift_local_datasource.dart';
import 'package:absensi_app/injection.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {}

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
      );
    } catch (e) {
      // Catch initialization errors (e.g. unsupported platforms or missing resources)
      // and allow startup to proceed.
      debugPrint('NotificationHelper init failed: $e');
    }
  }

  static Future<bool> requestPermissions() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    
    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> scheduleReminders(UserModel user) async {
    await cancelAll();

    final settingsBox = Hive.box(HiveBoxes.appSettings);
    final isEnabled = settingsBox.get('reminder_enabled', defaultValue: false) as bool;
    if (!isEnabled) return;

    final assignmentDatasource = sl<ShiftAssignmentLocalDatasource>();
    final shiftDatasource = sl<ShiftLocalDatasource>();

    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final targetDate = now.add(Duration(days: i));
      final assignment = assignmentDatasource.getAssignmentForUserOnDate(user.id, targetDate);
      if (assignment == null) continue;

      final shift = shiftDatasource.getShiftById(assignment.shiftId);
      if (shift == null) continue;

      // Clock In (15 menit sebelum masuk)
      try {
        final startParts = shift.startTime.split(':');
        final startHour = int.parse(startParts[0]);
        final startMinute = int.parse(startParts[1]);

        final clockInTime = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          startHour,
          startMinute,
        ).subtract(const Duration(minutes: 15));

        if (clockInTime.isAfter(now)) {
          final tzTime = tz.TZDateTime.from(clockInTime, tz.local);
          final id = (targetDate.day * 10000) + (startHour * 100) + startMinute;
          await _notificationsPlugin.zonedSchedule(
            id,
            'Pengingat Absen Masuk ⏰',
            'Shift ${shift.name} Anda akan dimulai pukul ${shift.startTime}. Jangan lupa melakukan absen masuk!',
            tzTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'absensi_reminders',
                'Pengingat Absen',
                channelDescription: 'Saluran untuk pengingat absensi harian',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      } catch (_) {}

      // Clock Out (15 menit sebelum pulang)
      try {
        final endParts = shift.endTime.split(':');
        final endHour = int.parse(endParts[0]);
        final endMinute = int.parse(endParts[1]);

        final clockOutTime = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          endHour,
          endMinute,
        ).subtract(const Duration(minutes: 15));

        if (clockOutTime.isAfter(now)) {
          final tzTime = tz.TZDateTime.from(clockOutTime, tz.local);
          final id = (targetDate.day * 10000) + (endHour * 100) + endMinute + 1;
          await _notificationsPlugin.zonedSchedule(
            id,
            'Pengingat Absen Keluar ⏰',
            'Shift ${shift.name} Anda akan berakhir pukul ${shift.endTime}. Jangan lupa melakukan absen keluar!',
            tzTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'absensi_reminders',
                'Pengingat Absen',
                channelDescription: 'Saluran untuk pengingat absensi harian',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      } catch (_) {}
    }
  }

  static Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'absensi_test_channel',
      'Tes Notifikasi',
      channelDescription: 'Saluran untuk uji coba notifikasi absensi',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      999,
      'Uji Coba Notifikasi Berhasil! 🎉',
      'Sistem notifikasi pengingat absen Anda berjalan dengan baik di perangkat ini.',
      platformChannelSpecifics,
    );
  }
}
