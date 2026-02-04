import 'dart:async';

import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;
  ThemeController({required this.sharedPreferences}) {
    _syncThemeWithTime();
    _startTimeObserver();
  }

  bool _darkTheme = false;
  bool get darkTheme => _darkTheme;
  Timer? _timer;
  Timer? _themeTimer;

  void _startTimeObserver() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _syncThemeWithTime();
    });
  }

  void _syncThemeWithTime() {
    final int hour = DateTime.now().hour;
    final bool isNight = hour < 6 || hour >= 18;
    if (_darkTheme != isNight) {
      _darkTheme = isNight;
      sharedPreferences.setBool(AppConstants.theme, _darkTheme);
      update();
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _startThemeTimer() {
    _themeTimer?.cancel();
    _themeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _applyTimeBasedTheme();
    });
  }

  void _applyTimeBasedTheme({DateTime? now}) {
    final DateTime currentTime = now ?? DateTime.now();
    final bool shouldBeDark = currentTime.hour >= 18 || currentTime.hour < 6;
    if (_darkTheme != shouldBeDark) {
      _darkTheme = shouldBeDark;
      sharedPreferences.setBool(AppConstants.theme, _darkTheme);
      update();
    }
  }
}
