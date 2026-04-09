import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';

class TrackingHelpers {
  // 🔹 دالة لتحويل التاريخ
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // 🔹 الحصول على لون الحالة — ديناميكي يتغير مع الثيم
  static int getStatusColor(String status) {
    return getStatusColorAsColor(status).value;
  }

  // 🔹 الحصول على أيقونة الحالة
  static String getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return "check_circle_rounded";
      case 'REJECTED':
        return "cancel_rounded";
      case 'NEEDS-EDITING':
      case 'NEEDS_EDITING':
      case 'NEEDS CHANGE':
        return "edit_note_rounded";
      case 'WAITING':
        return "hourglass_empty_rounded";
      default:
        return "help_rounded";
    }
  }

  // 🔹 الحصول على لون الحالة كـ Color — مرتبط بـ AppColors
  static Color getStatusColorAsColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return AppColors.statusApproved;
      case 'REJECTED':
        return AppColors.statusRejected;
      case 'NEEDS-EDITING':
      case 'NEEDS_EDITING':
      case 'NEEDS CHANGE':
        return AppColors.statusNeedsChange;
      case 'WAITING':
        return AppColors.statusWaiting;
      default:
        return AppColors.textMuted;
    }
  }

  // 🔹 الحصول على أيقونة الحالة كـ IconData
  static IconData getStatusIconAsIconData(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Icons.check_circle_rounded;
      case 'REJECTED':
        return Icons.cancel_rounded;
      case 'NEEDS-EDITING':
      case 'NEEDS_EDITING':
      case 'NEEDS CHANGE':
        return Icons.edit_note_rounded;
      case 'WAITING':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}