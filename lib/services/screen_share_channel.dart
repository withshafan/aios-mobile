import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ScreenShareChannel {
  static const _method = MethodChannel('aura/screen_share/method');
  static const _events = EventChannel('aura/screen_share/frames');

  static Future<bool> start() async {
    try {
      final result = await _method.invokeMethod<bool>('start');
      debugPrint('ScreenShareChannel.start() returned: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('ScreenShareChannel.start() error: $e');
      return false;
    }
  }

  static Future<void> stop() => _method.invokeMethod('stop');

  static Stream<String> get frames =>
      _events.receiveBroadcastStream().map((e) => e as String);
}
