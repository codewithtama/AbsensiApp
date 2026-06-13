import 'package:equatable/equatable.dart';

/// Base failure class for typed error handling
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class DeviceRootedFailure extends Failure {
  const DeviceRootedFailure() : super('Perangkat terdeteksi di-root. Absensi tidak dapat dilakukan.');
}

class MockLocationFailure extends Failure {
  const MockLocationFailure() : super('Lokasi palsu (Mock GPS) terdeteksi. Absensi tidak dapat dilakukan.');
}

class OutOfGeofenceFailure extends Failure {
  OutOfGeofenceFailure({required double distance, required double radius})
      : super('Anda berada di luar area absensi. Jarak: ${distance.toStringAsFixed(0)}m, Batas: ${radius.toStringAsFixed(0)}m');
}

class BiometricFailure extends Failure {
  const BiometricFailure() : super('Autentikasi biometrik gagal.');
}

class BiometricNotAvailableFailure extends Failure {
  const BiometricNotAvailableFailure() : super('Biometrik tidak tersedia pada perangkat ini.');
}

class LocationPermissionFailure extends Failure {
  const LocationPermissionFailure() : super('Izin lokasi tidak diberikan.');
}

class LocationServiceDisabledFailure extends Failure {
  const LocationServiceDisabledFailure() : super('Layanan lokasi tidak aktif.');
}

class DeviceBindingFailure extends Failure {
  const DeviceBindingFailure() : super('Perangkat tidak sesuai. Hubungi Superuser untuk melepas tautan perangkat.');
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure([super.message = 'Email atau password salah.']);
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure() : super('Pengguna tidak ditemukan.');
}

class AlreadyClockedInFailure extends Failure {
  const AlreadyClockedInFailure() : super('Anda sudah melakukan absen masuk hari ini.');
}

class NotClockedInFailure extends Failure {
  const NotClockedInFailure() : super('Anda belum melakukan absen masuk hari ini.');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('Anda tidak memiliki akses untuk tindakan ini.');
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Gagal menyimpan data.']);
}

class NoShiftAssignedFailure extends Failure {
  const NoShiftAssignedFailure() : super('Tidak ada shift yang ditetapkan untuk hari ini.');
}
