import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:process_run/shell.dart';

class AndroidService {
  final Shell _shell = Shell();

  /// Checks if adb is available and a device is connected
  Future<bool> isDeviceConnected() async {
    try {
      final result = await _shell.run('adb devices');
      final output = result.outText;
      // If there is a device listed besides the header
      return output.contains('\tdevice');
    } catch (e) {
      return false;
    }
  }

  /// Opens an app by package name (e.g., com.whatsapp)
  Future<String> openApp(String packageName) async {
    await _shell.run('adb shell monkey -p $packageName 1');
    return 'App $packageName opened.';
  }

  /// Takes a screenshot and saves to /sdcard/
  Future<String> takeScreenshot({String fileName = 'aios_screenshot.png'}) async {
    await _shell.run('adb shell screencap -p /sdcard/$fileName');
    return 'Screenshot saved as /sdcard/$fileName';
  }

  /// Gets battery info
  Future<String> getBatteryInfo() async {
    final result = await _shell.run('adb shell dumpsys battery');
    final lines = result.outLines;
    String level = '?';
    String status = '?';
    for (var line in lines) {
      if (line.contains('level:')) {
        level = line.split(':')[1].trim();
      } else if (line.contains('status:')) {
        status = line.split(':')[1].trim();
      }
    }
    return 'Battery level: $level%, status: $status';
  }

  /// Get device info (model, Android version)
  Future<String> getDeviceInfo() async {
    final model = await _shell.run('adb shell getprop ro.product.model');
    final android = await _shell.run('adb shell getprop ro.build.version.release');
    return 'Device: ${model.outText.trim()}, Android: ${android.outText.trim()}';
  }

  /// Execute a custom ADB shell command (approved by user)
  Future<String> executeCustomCommand(String command) async {
    final result = await _shell.run('adb shell $command');
    return result.outText;
  }
}
