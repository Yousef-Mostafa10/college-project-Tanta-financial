

import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart' show AppLocalizations;
import './inbox_colors.dart';

class InboxHelpers {
  // 🔹 دالة للحصول على لون الأولوية
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return InboxColors.accentRed;
      case 'medium':
        return InboxColors.accentYellow;
      case 'low':
        return InboxColors.accentGreen;
      default:
        return InboxColors.textMuted;
    }
  }

  // 🔹 دالة للحصول على أيقونة الحالة
  static IconData getStatusFilterIcon(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Icons.check_circle_rounded;
      case "rejected":
        return Icons.cancel_rounded;
      case "waiting":
      case "pending":
        return Icons.hourglass_empty_rounded;
      case "fulfilled":
        return Icons.task_alt_rounded;
      case "needs_change":
      case "needs change":
      case "needs_editing":
      case "needs-editing":
        return Icons.edit_note_rounded;
      case "not_assigned":
      case "not-assigned":
        return Icons.person_outline;
      case "all":
        return Icons.filter_list_rounded;
      default:
        return Icons.hourglass_top_outlined;
    }
  }

  // 🔹 دالة للحصول على لون الحالة
  static Color getStatusColor(String? status, bool isFulfilled) {
    if (isFulfilled) return InboxColors.statusFulfilled;

    if (status == null) return InboxColors.statusWaiting;

    switch (status.toLowerCase()) {
      case 'approved':
        return InboxColors.statusApproved;
      case 'rejected':
        return InboxColors.statusRejected;
      case 'needs_change':
      case 'needs change':
      case 'needs_editing':
      case 'needs-editing':
        return Colors.orange;
      case 'waiting':
      case 'pending':
        return InboxColors.statusWaiting;
      default:
        return InboxColors.statusWaiting;
    }
  }

  // 🔹 دالة للحصول على أيقونة الحالة
  static IconData getStatusIcon(String? status, bool isFulfilled) {
    if (isFulfilled) return Icons.check_rounded;

    if (status == null) return Icons.hourglass_empty_rounded;

    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'needs_change':
      case 'needs change':
      case 'needs_editing':
      case 'needs-editing':
        return Icons.edit_note_rounded;
      case 'waiting':
      case 'pending':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  // 🔹 دالة فلترة البيانات (محدثة)
  static List<dynamic> applyFilters({
    required List<dynamic> allRequests,
    required String selectedType,
    required String selectedPriority,
    required String selectedStatus,
    required String searchTerm,
  }) {
    List<dynamic> filtered = List.from(allRequests);

    // فلترة النوع
    if (selectedType != "All Types") {
      filtered = filtered.where((request) {
        final type = request["type"]?["name"]?.toString() ?? "";
        return type == selectedType;
      }).toList();
    }

    // فلترة الأولوية
    if (selectedPriority != "All") {
      filtered = filtered.where((request) {
        final priority = request["priority"]?.toString() ?? "";
        return priority.toLowerCase() == selectedPriority.toLowerCase();
      }).toList();
    }

    // فلترة الحالة (محدثة)
    if (selectedStatus != "All") {
      filtered = filtered.where((request) {
        final userForwardStatus = (request["yourCurrentStatus"] ??
            request["yourForwardStatus"] ?? 'not-assigned').toString();
        final fulfilled = request["fulfilled"] == true;

        switch (selectedStatus.toLowerCase()) {
          case "approved":
            return userForwardStatus == "approved";
          case "rejected":
            return userForwardStatus == "rejected";
          case "fulfilled":
            return fulfilled == true;
          case "needs change":
          case "needs_change":
            return userForwardStatus == "needs_change";
          case "waiting":
            if (fulfilled) return false;
            return !["approved", "rejected", "needs_change"].contains(userForwardStatus);
          case "not-assigned":
            return userForwardStatus == "not-assigned";
          default:
            return true;
        }
      }).toList();
    }

    // فلترة البحث
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((request) {
        final title = (request["title"]?.toString() ?? "").toLowerCase();
        final senderName = (request["lastSenderName"]?.toString() ??
            request["creator"]?["name"]?.toString() ?? "")
            .toLowerCase();
        final id = (request["id"]?.toString() ?? "").toLowerCase();

        return title.contains(searchTerm) ||
            senderName.contains(searchTerm) ||
            id.contains(searchTerm);
      }).toList();
    }

    return filtered;
  }

  // 🔹 دالة لتحويل حالة forward إلى نص مقروء (محدثة)
  static String getStatusText(BuildContext context, Map<String, dynamic> request) {
    final fulfilled = request["fulfilled"] == true;
    if (fulfilled) return AppLocalizations.of(context)!.translate("fulfilled");

    final status = (request["yourCurrentStatus"] ??
        request["yourForwardStatus"] ?? 'not-assigned').toString();

    switch (status.toLowerCase()) {
      case 'approved':
        return AppLocalizations.of(context)!.translate("approved");
      case 'rejected':
        return AppLocalizations.of(context)!.translate("rejected");
      case 'needs_change':
      case 'needs change':
      case 'needs_editing':
      case 'needs-editing':
        return AppLocalizations.of(context)!.translate("needs_change");
      case 'not-assigned':
      case 'not_assigned':
        return AppLocalizations.of(context)!.translate("not_assigned");
      case 'waiting':
      case 'pending':
        return AppLocalizations.of(context)!.translate("waiting");
      default:
        return AppLocalizations.of(context)!.translate("waiting");
    }
  }

  // 🔹 دالة للتحقق مما إذا كانت حالة pending (محدثة)
  static bool isRequestPending(Map<String, dynamic> request) {
    final fulfilled = request["fulfilled"] == true;
    if (fulfilled) return false;

    final status = (request["yourCurrentStatus"] ??
        request["yourForwardStatus"] ?? 'not-assigned').toString();

    return !["approved", "rejected", "needs_change"].contains(status);
  }

  // 🔹 دالة للتحقق مما إذا كانت حالة approved (محدثة)
  static bool isRequestApproved(Map<String, dynamic> request) {
    final status = (request["yourCurrentStatus"] ??
        request["yourForwardStatus"] ?? 'not-assigned').toString();
    return status == "approved";
  }

  // 🔹 دالة للتحقق مما إذا كانت حالة needs change (محدثة)
  static bool isRequestNeedsChange(Map<String, dynamic> request) {
    final status = (request["yourCurrentStatus"] ??
        request["yourForwardStatus"] ?? 'not-assigned').toString();
    return status == "needs_change";
  }

  // 🔹 دالة للتحقق مما إذا كانت حالة rejected (محدثة)
  static bool isRequestRejected(Map<String, dynamic> request) {
    final status = (request["yourCurrentStatus"] ??
        request["yourForwardStatus"] ?? 'not-assigned').toString();
    return status == "rejected";
  }
}