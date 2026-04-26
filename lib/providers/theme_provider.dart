import 'package:college_project/core/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeColor _themeColor = AppThemeColor.defaultBlue;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  AppThemeColor get themeColor => _themeColor;

  ThemeProvider() {
    _loadSettings();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    AppColors.setTheme(isDark: isDark, themeColor: _themeColor);
    _saveSettings();
    notifyListeners();
  }

  void setThemeColor(AppThemeColor color) {
    _themeColor = color;
    AppColors.setTheme(isDark: isDarkMode, themeColor: _themeColor);
    _saveSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Dark Mode
    final isDark = prefs.getBool('isDark') ?? true; 
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    
    // Load Theme Color
    final colorIndex = prefs.getInt('themeColorIndex') ?? 0;
    _themeColor = AppThemeColor.values[colorIndex];
    
    debugPrint("🎨 Theme Loaded: isDark=$isDark, ColorIndex=$colorIndex");
    
    AppColors.setTheme(isDark: isDark, themeColor: _themeColor);
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDarkMode);
    await prefs.setInt('themeColorIndex', _themeColor.index);
    debugPrint("💾 Theme Saved: isDark=$isDarkMode, ColorIndex=${_themeColor.index}");
  }
}
