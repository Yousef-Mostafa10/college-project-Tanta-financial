// // home/dashboard_helpers.dart
// import 'package:flutter/material.dart';
// import 'dashboard_colors.dart';
//
// class DashboardHelpers {
//   static Map<String, dynamic> getStatusInfo(String? status) {
//     switch (status) {
//       case "approved":
//         return {
//           'text': 'Approved',
//           'color': AppColors.statusApproved,
//           'icon': Icons.check_circle_rounded,
//         };
//       case "rejected":
//         return {
//           'text': 'Rejected',
//           'color': AppColors.statusRejected,
//           'icon': Icons.cancel_rounded,
//         };
//       case "waiting":
//         return {
//           'text': 'Waiting',
//           'color': AppColors.statusWaiting,
//           'icon': Icons.hourglass_empty_rounded,
//         };
//       default:
//         return {
//           'text': 'Pending',
//           'color': AppColors.statusPending,
//           'icon': Icons.access_time_filled_rounded,
//         };
//     }
//   }
//
//   static IconData getStatusFilterIcon(String status) {
//     switch (status.toLowerCase()) {
//       case "approved":
//         return Icons.check_circle_rounded;
//       case "rejected":
//         return Icons.cancel_rounded;
//       case "waiting":
//         return Icons.hourglass_empty_rounded;
//       case "all":
//         return Icons.filter_list_rounded;
//       default:
//         return Icons.hourglass_top_outlined;
//     }
//   }
//
//   static Color getPriorityColor(String priority) {
//     switch (priority.toLowerCase()) {
//       case 'high':
//         return AppColors.accentRed;
//       case 'medium':
//         return AppColors.accentYellow;
//       case 'low':
//         return AppColors.accentGreen;
//       default:
//         return AppColors.textMuted;
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'dashboard_colors.dart';

class DashboardHelpers {
  static Map<String, dynamic> getStatusInfo(String? status) {
    switch (status) {
      case "approved":
        return {
          'text': 'Approved',
          'color': AppColors.statusApproved,
          'icon': Icons.check_circle_rounded,
        };
      case "rejected":
        return {
          'text': 'Rejected',
          'color': AppColors.statusRejected,
          'icon': Icons.cancel_rounded,
        };
      case "waiting":
        return {
          'text': 'Waiting',
          'color': AppColors.statusWaiting,
          'icon': Icons.hourglass_empty_rounded,
        };
      case "needsChange":  // حالة جديدة
        return {
          'text': 'Needs Change',
          'color': AppColors.statusNeedsChange,
          'icon': Icons.edit_note_rounded,
        };
      case "fulfilled":  // حالة جديدة
        return {
          'text': 'Fulfilled',
          'color': AppColors.statusFulfilled,
          'icon': Icons.task_alt_rounded,
        };
      default:
        return {
          'text': 'Pending',
          'color': AppColors.statusPending,
          'icon': Icons.access_time_filled_rounded,
        };
    }
  }

  static IconData getStatusFilterIcon(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Icons.check_circle_rounded;
      case "rejected":
        return Icons.cancel_rounded;
      case "waiting":
        return Icons.hourglass_empty_rounded;
      case "needs change":  // حالة جديدة
        return Icons.edit_note_rounded;
      case "fulfilled":  // حالة جديدة
        return Icons.task_alt_rounded;
      case "all":
        return Icons.filter_list_rounded;
      default:
        return Icons.hourglass_top_outlined;
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.accentRed;
      case 'medium':
        return AppColors.accentYellow;
      case 'low':
        return AppColors.accentGreen;
      default:
        return AppColors.textMuted;
    }
  }
}