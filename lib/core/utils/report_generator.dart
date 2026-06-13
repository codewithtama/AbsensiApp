import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:absensi_app/core/constants/app_constants.dart';
import 'package:absensi_app/data/models/attendance_model.dart';
import 'package:absensi_app/data/datasources/user_local_datasource.dart';
import 'package:absensi_app/data/datasources/site_local_datasource.dart';
import 'package:absensi_app/core/utils/date_formatters.dart';

class ReportGenerator {
  final UserLocalDatasource _userDatasource;
  final SiteLocalDatasource _siteDatasource;

  const ReportGenerator({
    required UserLocalDatasource userDatasource,
    required SiteLocalDatasource siteDatasource,
  })  : _userDatasource = userDatasource,
        _siteDatasource = siteDatasource;

  /// Generate file CSV rekap absensi untuk seluruh karyawan
  Future<File> generateAttendanceCsv(List<AttendanceModel> records) async {
    final csvRows = <List<String>>[];

    // Header tabel
    csvRows.add([
      'ID Transaksi',
      'Nama Karyawan',
      'Role',
      'Lokasi Kerja (Site)',
      'Status Absen',
      'Tanggal & Waktu',
      'Koordinat Lintang (Lat)',
      'Koordinat Bujur (Lng)'
    ]);

    // Isi data
    for (final record in records) {
      final user = _userDatasource.getUserById(record.userId);
      final site = _siteDatasource.getSiteById(record.siteId);

      csvRows.add([
        record.id,
        user?.name ?? 'Karyawan Tidak Dikenal',
        user?.role.displayName ?? '-',
        site?.name ?? 'Site Tidak Dikenal',
        record.status.displayName,
        DateFormatters.formatDateTime(record.timestamp),
        record.latitude.toString(),
        record.longitude.toString(),
      ]);
    }

    // Konversi baris ke format CSV string
    final csvContent = const ListToCsvConverter().convert(csvRows);

    // Simpan ke direktori dokumen temporer lokal
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/Rekap_Absensi_${DateTime.now().millisecondsSinceEpoch}.csv');
    
    return await file.writeAsString(csvContent, encoding: utf8);
  }
}

/// Helper converter sederhana untuk menghindari ketergantungan library luar
class ListToCsvConverter {
  const ListToCsvConverter();

  String convert(List<List<String>> rows) {
    return rows.map((row) {
      return row.map((field) {
        final sanitized = field.replaceAll('"', '""');
        return '"$sanitized"';
      }).join(',');
    }).join('\r\n');
  }
}
