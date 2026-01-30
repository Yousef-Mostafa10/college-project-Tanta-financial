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
    switch (status) {
      case 'approved':
        return 0xFF27AE60;
      case 'rejected':
        return 0xFFE74C3C;
      case 'needs-editing':
        return 0xFFFFB74D;
      case 'waiting':
        return 0xFF1E88E5;
      default:
        return 0xFF7F8C8D;
    }
  }

  // 🔹 الحصول على أيقونة الحالة
  static String getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return "check_circle_rounded";
      case 'rejected':
        return "cancel_rounded";
      case 'needs-editing':
        return "edit_note_rounded";
      case 'waiting':
        return "hourglass_empty_rounded";
      default:
        return "help_rounded";
    }
  }

  // 🔹 الحصول على لون الحالة كـ Color
  static Color getStatusColorAsColor(String status) {
    switch (status) {
      case 'approved':
        return Color(0xFF27AE60);
      case 'rejected':
        return Color(0xFFE74C3C);
      case 'needs-editing':
        return Color(0xFFFFB74D);
      case 'waiting':
        return Color(0xFF1E88E5);
      default:
        return Color(0xFF7F8C8D);
    }
  }

  // 🔹 الحصول على أيقونة الحالة كـ IconData
  static IconData getStatusIconAsIconData(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'needs-editing':
        return Icons.edit_note_rounded;
      case 'waiting':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}