import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  // 🔹 الحصول على لون الحالة
  static int getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 0xFF27AE60;
      case 'REJECTED':
        return 0xFFE74C3C;
      case 'NEEDS-EDITING':
        return 0xFFFFB74D;
      case 'WAITING':
        return 0xFF1E88E5;
      default:
        return 0xFF7F8C8D;
    }
  }

  // 🔹 الحصول على أيقونة الحالة
  static String getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return "check_circle_rounded";
      case 'REJECTED':
        return "cancel_rounded";
      case 'NEEDS-EDITING':
        return "edit_note_rounded";
      case 'WAITING':
        return "hourglass_empty_rounded";
      default:
        return "help_rounded";
    }
  }

  // 🔹 الحصول على لون الحالة كـ Color
  static Color getStatusColorAsColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Color(0xFF27AE60);
      case 'REJECTED':
        return Color(0xFFE74C3C);
      case 'NEEDS-EDITING':
        return Color(0xFFFFB74D);
      case 'WAITING':
        return Color(0xFF1E88E5);
      default:
        return Color(0xFF7F8C8D);
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
        return Icons.edit_note_rounded;
      case 'WAITING':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}