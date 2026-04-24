import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/app_colors.dart';

/// =====================================================================
/// AppErrorHandler — معالج أخطاء مركزي للتطبيق
/// يستخرج الـ key من response الباك أند ويترجمها باستخدام app_localizations
/// =====================================================================
///
/// شكل الـ response المتوقع من الباك أند:
/// {
///   "statusCode": 403,
///   "message": { "key": "MISSING_ROLE", "args": { "required": "ADMIN" } },
///   "error": "Forbidden"
/// }
class AppErrorHandler {
  /// استخراج الـ error key من response body الخام
  /// يدعم أشكال متعددة من الـ response
  static String? extractErrorKey(String responseBody) {
    if (responseBody.isEmpty) return null;

    try {
      final dynamic data = jsonDecode(responseBody);

      if (data is Map) {
        // الشكل المتوقع من الباك أند الجديد: { "message": { "key": "..." } }
        final message = data['message'];
        if (message is Map) {
          final key = message['key'];
          if (key is String && key.isNotEmpty) return key;
        }

        // fallback: message قد يكون String مباشرة وهو الـ key
        if (message is String && message.isNotEmpty) {
          // إذا كانت الرسالة تبدو كـ error key (كلها uppercase مع underscores)
          if (isErrorKey(message)) return message;
        }

        // fallback آخر: بعض السيرفرات تضع الـ key في 'error'
        final error = data['error'];
        if (error is String && isErrorKey(error)) return error;
      }
    } catch (_) {}

    return null;
  }

  /// ترجمة الـ error key إلى رسالة مقروءة للمستخدم
  static String translateKey(BuildContext context, String key) {
    final translated = AppLocalizations.of(context)?.translate(key);
    // إذا لم يوجد ترجمة (رجع نفس الـ key)، نُشكّل الرسالة بشكل أفضل
    if (translated == null || translated == key) {
      return _formatRawKey(key);
    }
    return translated;
  }

  /// استخرج الرسالة الكاملة من response body وترجمها
  /// هذه هي الدالة الرئيسية التي يجب استخدامها في كل مكان
  static String extractAndTranslate(
    BuildContext context,
    String responseBody, {
    String fallback = '',
  }) {
    final key = extractErrorKey(responseBody);
    if (key != null) {
      return translateKey(context, key);
    }

    // fallback: محاولة استخراج أي رسالة نصية
    return _extractRawMessage(responseBody, fallback);
  }

  /// نسخة بدون BuildContext — تستخدم في API classes خارج الـ UI
  /// ترجع الـ key فقط (ليتم ترجمتها لاحقاً في الـ UI)
  static String extractKeyOrFallback(String responseBody, int statusCode) {
    final key = extractErrorKey(responseBody);
    if (key != null) return key;

    // fallback بناءً على statusCode
    switch (statusCode) {
      case 401:
        return 'INVALID_CREDENTIALS';
      case 403:
        return 'MISSING_ROLE';
      case 404:
        return 'not_found';
      case 409:
        return 'conflict_error';
      default:
        return 'unknown_error';
    }
  }

  /// هل النص يبدو كـ error key (مثل MISSING_ROLE, USER_NOT_FOUND)
  /// Public — يمكن استخدامه من أي مكان
  static bool isErrorKey(String text) {
    return RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(text);
  }

  /// تحويل الـ key إلى نص مقروء في حالة عدم وجود ترجمة
  /// مثال: MISSING_ROLE → Missing Role
  static String _formatRawKey(String key) {
    return key
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// استخراج أي رسالة نصية من الـ response
  static String _extractRawMessage(String responseBody, String fallback) {
    if (responseBody.isEmpty) return fallback;
    try {
      final dynamic data = jsonDecode(responseBody);
      if (data is Map) {
        final message = data['message'] ?? data['error'] ?? data['msg'];
        if (message is String && message.isNotEmpty) return message;
        if (message is List && message.isNotEmpty) {
          return message.map((e) => e.toString()).join(', ');
        }
        if (message is Map) {
          final firstVal = message.values.firstOrNull;
          if (firstVal is String && firstVal.isNotEmpty) return firstVal;
        }
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    } catch (_) {
      if (responseBody.length < 200) return responseBody;
    }
    return fallback;
  }

  /// عرض Snackbar بخطأ مترجم
  static void showErrorSnackbar(
    BuildContext context,
    String responseBody, {
    int statusCode = 400,
    String? fallbackMessage,
    Color? backgroundColor,
  }) {
    if (!context.mounted) return;

    final message = extractAndTranslate(
      context,
      responseBody,
      fallback: fallbackMessage ??
          AppLocalizations.of(context)?.translate('unknown_error') ??
          'Unknown error',
    );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.borderColor, width: 1)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// ترجمة Exception message (الـ key المُخزّن في Exception أو خطأ تقني)
  /// للاستخدام في الـ UI عند catch Exception
  static String translateException(BuildContext context, dynamic error) {
    if (error == null) return translateKey(context, 'unknown_error');

    final errorStr = error.toString();
    final lowerError = errorStr.toLowerCase();

    // 1. اكتشاف أخطاء الشبكة والإنترنت (Low-level errors)
    bool isNetworkError = lowerError.contains('socketexception') || 
        lowerError.contains('network is unreachable') ||
        lowerError.contains('connection failed') ||
        lowerError.contains('clientexception') ||
        lowerError.contains('errno = 7') || // No route to host
        lowerError.contains('errno = 101') || // Network is unreachable
        lowerError.contains('failed host lookup');

    if (isNetworkError) {
      return translateKey(context, 'no_internet_error');
    }

    if (lowerError.contains('timeout') || lowerError.contains('deadline exceeded') || lowerError.contains('os error: 10060')) {
      return translateKey(context, 'connection_timeout');
    }

    if (lowerError.contains('handshake') || lowerError.contains('certificate')) {
      return translateKey(context, 'network_error'); 
    }

    // 2. استخراج الـ key إذا كان خطأ من النوع Exception("KEY")
    // إزالة "Exception: " prefix
    String key = errorStr.replaceFirst('Exception: ', '').trim();

    // 3. إذا كان يحتوي على "error_code: " نستخرج الـ key من الـ body
    if (key.startsWith('error_code:')) {
      final bodyStart = key.indexOf('{');
      if (bodyStart != -1) {
        final body = key.substring(bodyStart);
        final extracted = extractErrorKey(body);
        if (extracted != null) key = extracted;
      }
    }

    // 4. إذا كان النص لا يزال يحتوي على مسافات أو رموز غرية، فهو ليس key
    if (key.contains(' ') || key.contains(':')) {
      return translateKey(context, 'network_error');
    }

    return translateKey(context, key);
  }
}
