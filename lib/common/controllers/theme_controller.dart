import 'dart:async';

import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;
  ThemeController({required this.sharedPreferences}) {
    _loadCurrentTheme();
    _startThemeTimer();
  }

  bool _darkTheme = false;
  bool get darkTheme => _darkTheme;
  Timer? _themeTimer;

  void toggleTheme() {
    _darkTheme = !_darkTheme;
    sharedPreferences.setBool(AppConstants.theme, _darkTheme);
    update();
  }

  @override
  void onClose() {
    _themeTimer?.cancel();
    super.onClose();
  }

  void _loadCurrentTheme() async {
    _darkTheme = sharedPreferences.getBool(AppConstants.theme) ?? false;
    _applyTimeBasedTheme();
    update();
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
