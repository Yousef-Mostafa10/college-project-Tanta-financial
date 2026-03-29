import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/login.dart';

/// مدير الجلسة - يتعامل مع انتهاء الجلسة ويوجه المستخدم لتسجيل الدخول
class SessionManager {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// يتحقق من الخطأ ويحول للـ login لو كانت الجلسة منتهية
  static Future<void> handleSessionExpired() async {
    debugPrint('⚠️ Session expired - redirecting to login...');

    // مسح بيانات الجلسة
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
    await prefs.remove('username');
    await prefs.remove('user_role');
    await prefs.remove('user_group');
    await prefs.remove('user_id');
    await prefs.remove('department_name');
    await prefs.remove('user_active');

    // التوجيه لصفحة تسجيل الدخول وإزالة كل الصفحات السابقة
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  /// يلف أي دالة API ويتعامل مع SessionExpiredException
  static Future<T> runProtected<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      if (e.toString().contains('SessionExpiredException')) {
        await handleSessionExpired();
        rethrow;
      }
      rethrow;
    }
  }
}
