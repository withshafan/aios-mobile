import 'package:shared_preferences/shared_preferences.dart';

class AccessibilitySettings {
  static const _highContrastKey = 'high_contrast';
  static const _textScaleKey = 'text_scale';
  static const _reducedMotionKey = 'reduced_motion';

  static Future<bool> getHighContrast() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_highContrastKey) ?? false;
  }

  static Future<void> setHighContrast(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
  }

  static Future<double> getTextScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_textScaleKey) ?? 1.0;
  }

  static Future<void> setTextScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, value);
  }

  static Future<bool> getReducedMotion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reducedMotionKey) ?? false;
  }

  static Future<void> setReducedMotion(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reducedMotionKey, value);
  }
}
