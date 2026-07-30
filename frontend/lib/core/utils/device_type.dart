import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceType {
  static bool _isTv = false;
  static bool get isTv => _isTv;

  static Future<void> init() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      // 1. Check for official Leanback (Google TV / Android TV)
      final hasLeanback = androidInfo.systemFeatures.contains('android.software.leanback');
      
      // 2. Check for generic Television hardware flag (Some AOSP builds)
      final hasTvHardware = androidInfo.systemFeatures.contains('android.hardware.type.television');

      _isTv = hasLeanback || hasTvHardware;

      // _isTv = true;
    }
  }
}