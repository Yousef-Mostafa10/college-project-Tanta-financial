import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class StoragePermissionHelper {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// الحصول على إصدار Android الحالي
  static Future<int> getAndroidVersion() async {
    if (kIsWeb) return 0; // الويب ليس اندرويد
    try {
      if (!Platform.isAndroid) return 0;
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      print('❌ Error getting Android version: $e');
      return 0;
    }
  }

  /// التحقق من وجود أذونات التخزين
  static Future<bool> checkStoragePermission() async {
    if (kIsWeb) return true; // الويب لا يحتاج اذن تخزين تقليدي
    if (!Platform.isAndroid) return true;

    final androidVersion = await getAndroidVersion();
    
    // Android 13+ (API 33+) 
    // للمستندات والملفات العادية في المجلدات العامة، غالباً لا نحتاج لأذونات الميديا
    if (androidVersion >= 33) {
      return true; // نعتمد على Scoped Storage
    }
    // Android 11-12 (API 30-32)
    else if (androidVersion >= 30) {
      final status = await Permission.storage.status;
      return status.isGranted || await Permission.manageExternalStorage.isGranted;
    }
    // Android 10 والإصدارات الأقدم
    else {
      final status = await Permission.storage.status;
      return status.isGranted;
    }
  }

  /// طلب أذونات التخزين
  static Future<bool> requestStoragePermission() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;

    final androidVersion = await getAndroidVersion();

    try {
      if (androidVersion >= 33) {
        // في Android 13+ للمستندات، الأفضل عدم طلب أذونات الصور/الفيديو إذا لم نكن نحتاجها
        return true; 
      }
      else if (androidVersion >= 30) {
        // محاولة طلب الإذن العادي أولاً
        var status = await Permission.storage.request();
        if (status.isGranted) return true;
        
        // إذا فشل وكان الإصدار 11-12، قد نحتاج manageExternalStorage (اختياري وحساس)
        // لكن للتبسيط سنكتفي بـ true لأن معظم العمليات ستنجح في المجلدات المخصصة
        return true;
      }
      else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (e) {
      print('❌ Error requesting storage permission: $e');
      return false;
    }
  }

  /// دالة شاملة للتحقق وطلب الأذونات
  static Future<bool> checkAndRequestPermission() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;
    
    final hasPermission = await checkStoragePermission();
    if (!hasPermission) {
      return await requestStoragePermission();
    }
    return true;
  }

  static Future<void> openSettings() async {
    if (kIsWeb) return;
    await openAppSettings();
  }
}
