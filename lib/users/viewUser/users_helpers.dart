import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'users_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';

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
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
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

  /// 🛠️ استخراج رسالة مقروءة من أي نوع من الأخطاء
  static String _extractReadableMessage(String raw, BuildContext context) {
    // الخطوة 1: إزالة بادئات الـ Exception
    String msg = raw
        .replaceAll('Exception: ', '')
        .replaceAll('FormatException: ', '')
        .trim();

    // الخطوة 2: إزالة بادئة error_code: NNN: للوصول لجسم الخطأ
    final errorCodeRegex = RegExp(r'^error_code:\s*\d+:\s*');
    if (errorCodeRegex.hasMatch(msg)) {
      msg = msg.replaceFirst(errorCodeRegex, '').trim();
    }

    // الخطوة 3: إذا بقي نص فارغ أو قصير جداً بعد التنظيف، أرجع رسالة عامة
    if (msg.isEmpty) {
      return AppLocalizations.of(context)?.translate('unknown_error') ?? 'An error occurred';
    }

    // الخطوة 4: محاولة تحليله كـ JSON
    if (msg.contains('{') && msg.contains('}')) {
      try {
        final startIndex = msg.indexOf('{');
        final endIndex = msg.lastIndexOf('}') + 1;
        final jsonPart = msg.substring(startIndex, endIndex);
        final dynamic data = jsonDecode(jsonPart);
        final parsed = _parseApiError(data, context);
        if (parsed != null) {
          // ترجمة المفتاح إذا وجد في ملفات الترجمة
          return AppLocalizations.of(context)?.translate(parsed) ?? parsed;
        }
      } catch (_) {
        // JSON parsing failed - continue
      }
    }

    // الخطوة 5: إذا كانت الرسالة مفتاح ترجمة معروف، ترجمه
    final translated = AppLocalizations.of(context)?.translate(msg);
    if (translated != null && translated != msg) {
      return translated;
    }

    // الخطوة 6: إذا كانت الرسالة تبدو تقنية (تحتوي على {, }, :, _ بكثرة)، أرجع رسالة عامة
    final technicalPattern = RegExp(r'[{}\[\]":,_]');
    final technicalMatches = technicalPattern.allMatches(msg).length;
    if (technicalMatches > 3 || msg.length > 200) {
      return AppLocalizations.of(context)?.translate('unknown_error') ?? 'An error occurred';
    }

    return msg;
  }

  // 🛠️ Robust Error Parser - يرجع nullable String
  static String? _parseApiError(dynamic data, BuildContext context) {
    if (data == null) return null;

    try {
      if (data is Map) {
        final msg = data['message'] ?? data['error'] ?? data['errors'] ?? data['msg'];

        if (msg is String && msg.isNotEmpty) return msg;

        if (msg is List) return msg.map((e) => e.toString()).join(', ');

        if (msg is Map) {
          // هيكل {key: "ERROR_KEY", args: {...}} من الباك اند
          if (msg.containsKey('key')) return msg['key'].toString();
          // محاولة اللغة الحالية
          final locale = AppLocalizations.of(context)?.locale.languageCode ?? 'en';
          if (msg.containsKey(locale)) return msg[locale].toString();
          // أول قيمة في الـ Map
          if (msg.values.isNotEmpty) {
            final first = msg.values.first;
            if (first is List) return first.join(', ');
            return first.toString();
          }
        }

        // لو مافيش message key، حاول أول قيمة String في الـ Map
        if (msg == null) {
          final locale = AppLocalizations.of(context)?.locale.languageCode ?? 'en';
          if (data.containsKey(locale)) return data[locale]?.toString();
        }
      } else if (data is String) {
        return data;
      }
    } catch (e) {
      debugPrint('_parseApiError error: $e');
    }

    return null;
  }

  static void showSuccessMessage(BuildContext context, String message) {
    // ✅ مسح أي SnackBar موجود لإظهار الجديد فوراً
    ScaffoldMessenger.of(context).clearSnackBars();

    final localizedMessage = AppLocalizations.of(context)?.translate(message) ?? message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
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