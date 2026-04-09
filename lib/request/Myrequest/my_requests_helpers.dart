import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';

class MyRequestsHelpers {
  // 🔹 دالة لتحويل التاريخ
  static String formatDate(BuildContext context, dynamic dateValue) {
    try {
      if (dateValue == null || dateValue == "N/A" || dateValue.toString().isEmpty) {
        return AppLocalizations.of(context)!.translate('not_available');
      }

      String dateString = dateValue.toString();
      if (dateString.contains('T')) {
        final date = DateTime.parse(dateString);
        final locale = Localizations.localeOf(context).languageCode;
        return DateFormat('MMM dd, yyyy - HH:mm', locale).format(date);
      }

      return dateString;
    } catch (e) {
      print("❌ Error formatting date: $dateValue - $e");
      return AppLocalizations.of(context)!.translate('not_available');
    }
  }

  // 🔹 الحصول على أيقونة الحالة (تم إضافة حالتين)
  static String getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return "check_circle_rounded";
      case "rejected":
        return "cancel_rounded";
      case "waiting":
        return "hourglass_empty_rounded";
      case "needs change":
      case "needs_editing":
      case "needs-editing":
        return "edit_note_rounded";
      case "fulfilled":
        return "task_alt_rounded";
      default:
        return "hourglass_empty_rounded";
    }
  }

  // 🔹 الحصول على أيقونة فلتر الحالة (تم إضافة حالتين)
  static String getStatusFilterIcon(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return "check_circle_rounded";
      case "rejected":
        return "cancel_rounded";
      case "waiting":
        return "hourglass_empty_rounded";
      case "needs change":
      case "needs_editing":
      case "needs-editing":
        return "edit_note_rounded";
      case "fulfilled":
        return "task_alt_rounded";
      case "all":
        return "filter_list_rounded";
      default:
        return "hourglass_top_outlined";
    }
  }

  // 🔹 الحصول على Color للحالة — ديناميكي يتغير مع الثيم
  static Color getStatusColorAsColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return AppColors.statusApproved;
      case "rejected":
        return AppColors.statusRejected;
      case "waiting":
        return AppColors.statusWaiting;
      case "needs change":
      case "needs_editing":
      case "needs-editing":
        return AppColors.statusNeedsChange;
      case "fulfilled":
        return AppColors.statusFulfilled;
      default:
        return AppColors.statusWaiting;
    }
  }

  // 🔹 باقي الدوال كما هي بدون تغيير
  static String getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return 'warning_amber_rounded';
      case 'medium': return 'info_rounded';
      case 'low': return 'flag_rounded';
      default: return 'flag_rounded';
    }
  }

  static int getStatusColor(String status) {
    return getStatusColorAsColor(status).value;
  }

  static int getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':   return AppColors.accentRed.value;
      case 'medium': return AppColors.accentYellow.value;
      case 'low':    return AppColors.statusApproved.value;
      default:       return AppColors.textMuted.value;
    }
  }
}