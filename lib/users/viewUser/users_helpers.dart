import 'dart:convert';
import '../../utils/app_error_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'users_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/utils/app_error_handler.dart';

class UsersHelpers {
  static String formatDate(String? iso, BuildContext context) {
    if (iso == null || iso.isEmpty) {
      return AppLocalizations.of(context)?.translate('unknown') ?? "Unknown";
    }
    try {
      final dt = DateTime.parse(iso);
      final locale = Localizations.localeOf(context).languageCode;
      return DateFormat('dd/MM/yyyy', locale).format(dt);
    } catch (e) {
      return iso;
    }
  }

  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.roleAdmin;
      case 'user':
        return AppColors.roleUser;
      case 'accountant':
        return AppColors.roleAccountant;
      default:
        return AppColors.textSecondary;
    }
  }

  static void showErrorMessage(BuildContext context, String message) {
    // ✅ مسح أي SnackBar موجود لإظهار الجديد فوراً
    ScaffoldMessenger.of(context).clearSnackBars();

    final cleanMessage = _extractReadableMessage(message, context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(cleanMessage)),
          ],
        ),
        backgroundColor: AppColors.statusRejected,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// 🛠️ استخراج رسالة مقروءة من أي نوع من الأخطاء — يستخدم AppErrorHandler
  static String _extractReadableMessage(String raw, BuildContext context) {
    // إزالة بادئة Exception
    final cleaned = raw
        .replaceAll('Exception: ', '')
        .replaceAll('FormatException: ', '')
        .trim();

    // إذا كان النص يبدو كـ error key مباشرة
    if (AppErrorHandler.isErrorKey(cleaned)) {
      return AppErrorHandler.translateKey(context, cleaned);
    }

    // إذا كان يحتوي على JSON و key
    final bodyStart = cleaned.indexOf('{');
    if (bodyStart != -1) {
      final jsonPart = cleaned.substring(bodyStart);
      final key = AppErrorHandler.extractErrorKey(jsonPart);
      if (key != null) return AppErrorHandler.translateKey(context, key);
    }

    // fallback: ترجمة مباشرة
    final translated = AppLocalizations.of(context)?.translate(cleaned);
    if (translated != null && translated != cleaned) return translated;

    // fallback نهائي
    if (cleaned.isEmpty || cleaned.length > 200) {
      return AppLocalizations.of(context)?.translate('unknown_error') ?? 'An error occurred';
    }
    return cleaned;
  }

  static void showSuccessMessage(BuildContext context, String message) {
    // ✅ مسح أي SnackBar موجود لإظهار الجديد فوراً
    ScaffoldMessenger.of(context).clearSnackBars();

    final localizedMessage = AppLocalizations.of(context)?.translate(message) ?? message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(localizedMessage)),
          ],
        ),
        backgroundColor: AppColors.statusApproved,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
