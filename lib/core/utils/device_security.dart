import 'package:safe_device/safe_device.dart';

/// Device security checks — root detection and mock location
class DeviceSecurity {
  const DeviceSecurity();

  /// Check if device is rooted/jailbroken
  Future<bool> isDeviceRooted() async {
    try {
      return await SafeDevice.isJailBroken;
    } catch (_) {
      // If check fails, allow — avoid blocking legitimate users
      return false;
    }
  }

  /// Check if mock location is enabled
  Future<bool> isMockLocationEnabled() async {
    try {
      return await SafeDevice.isMockLocation;
    } catch (_) {
      return false;
    }
  }

  /// Check if running on a real device (not emulator)
  Future<bool> isRealDevice() async {
    try {
      return await SafeDevice.isRealDevice;
    } catch (_) {
      return true;
    }
  }

  /// Run all security checks. Returns null if all pass, or failure description.
  Future<String?> runSecurityChecks() async {
    if (await isDeviceRooted()) {
      return 'rooted';
    }
    if (await isMockLocationEnabled()) {
      return 'mock_location';
    }
    return null;
  }
}
