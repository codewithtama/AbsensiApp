import 'package:hive_ce/hive.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/models/user_model.dart';
import 'package:absensi_app/data/models/site_model.dart';
import 'package:absensi_app/data/models/shift_model.dart';
import 'package:absensi_app/data/models/attendance_model.dart';
import 'package:absensi_app/data/models/leave_model.dart';
import 'package:absensi_app/data/models/shift_assignment_model.dart';
import 'package:absensi_app/hive_registrar.g.dart';

/// Register all Hive type adapters using auto-generated registrar
void registerHiveAdapters() {
  Hive.registerAdapters();
}

/// Open all Hive boxes
Future<void> openHiveBoxes() async {
  await Hive.openBox<UserModel>(HiveBoxes.users);
  await Hive.openBox<SiteModel>(HiveBoxes.sites);
  await Hive.openBox<ShiftModel>(HiveBoxes.shifts);
  await Hive.openBox<AttendanceModel>(HiveBoxes.attendance);
  await Hive.openBox<LeaveModel>(HiveBoxes.leaves);
  await Hive.openBox<ShiftAssignmentModel>(HiveBoxes.shiftAssignments);
  await Hive.openBox(HiveBoxes.appSettings);
}
