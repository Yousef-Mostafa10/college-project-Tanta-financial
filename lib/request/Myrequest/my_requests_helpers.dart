// import 'package:intl/intl.dart';
//
// class MyRequestsHelpers {
//   // 🔹 دالة لتحويل التاريخ
//   static String formatDate(dynamic dateValue) {
//     try {
//       if (dateValue == null || dateValue == "N/A" || dateValue.toString().isEmpty) {
//         return "N/A";
//       }
//
//       String dateString = dateValue.toString();
//       if (dateString.contains('T')) {
//         final date = DateTime.parse(dateString);
//         return DateFormat('MMM dd, yyyy - HH:mm').format(date);
//       }
//
//       return dateString;
//     } catch (e) {
//       print("❌ Error formatting date: $dateValue - $e");
//       return "N/A";
//     }
//   }
//
//   // 🔹 الحصول على لون الأولوية
//   static String getPriorityIcon(String priority) {
//     switch (priority.toLowerCase()) {
//       case 'high': return 'warning_amber_rounded';
//       case 'medium': return 'info_rounded';
//       case 'low': return 'flag_rounded';
//       default: return 'flag_rounded';
//     }
//   }
//
//   // 🔹 الحصول على أيقونة الحالة
//   static String getStatusIcon(String status) {
//     switch (status.toLowerCase()) {
//       case "approved":
//         return "check_circle_rounded";
//       case "rejected":
//         return "cancel_rounded";
//       case "waiting":
//         return "hourglass_empty_rounded";
//       default:
//         return "hourglass_empty_rounded";
//     }
//   }
//
//   // 🔹 الحصول على أيقونة فلتر الحالة
//   static String getStatusFilterIcon(String status) {
//     switch (status.toLowerCase()) {
//       case "approved":
//         return "check_circle_rounded";
//       case "rejected":
//         return "cancel_rounded";
//       case "waiting":
//         return "hourglass_empty_rounded";
//       case "all":
//         return "filter_list_rounded";
//       default:
//         return "hourglass_top_outlined";
//     }
//   }
//
//   // 🔹 الحصول على لون الحالة
//   static int getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case "approved":
//         return 0xFF27AE60;
//       case "rejected":
//         return 0xFFE74C3C;
//       case "waiting":
//         return 0xFF1E88E5;
//       default:
//         return 0xFF1E88E5;
//     }
//   }
//
//   // 🔹 الحصول على لون الأولوية
//   static int getPriorityColor(String priority) {
//     switch (priority.toLowerCase()) {
//       case 'high':
//         return 0xFFE74C3C;
//       case 'medium':
//         return 0xFFFFB74D;
//       case 'low':
//         return 0xFF27AE60;
//       default:
//         return 0xFF7F8C8D;
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
        return DateFormat('MMM dd, yyyy - HH:mm').format(date);
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
        return "edit_note_rounded";
      case "fulfilled":
        return "task_alt_rounded";
      case "all":
        return "filter_list_rounded";
      default:
        return "hourglass_top_outlined";
    }
  }

  // 🔹 الحصول على Color للحالة (تم إضافة حالتين)
  static Color getStatusColorAsColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Color(0xFF27AE60);
      case "rejected":
        return Color(0xFFE74C3C);
      case "waiting":
        return Color(0xFF1E88E5);
      case "needs change":
        return Color(0xFFFF9800);
      case "fulfilled":
        return Color(0xFF9C27B0);
      default:
        return Color(0xFF1E88E5);
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
    switch (status.toLowerCase()) {
      case "approved":
        return 0xFF27AE60;
      case "rejected":
        return 0xFFE74C3C;
      case "waiting":
        return 0xFF1E88E5;
      case "needs change":
        return 0xFFFF9800;
      case "fulfilled":
        return 0xFF9C27B0;
      default:
        return 0xFF1E88E5;
    }
  }

  static int getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 0xFFE74C3C;
      case 'medium':
        return 0xFFFFB74D;
      case 'low':
        return 0xFF27AE60;
      default:
        return 0xFF7F8C8D;
    }
  }
}