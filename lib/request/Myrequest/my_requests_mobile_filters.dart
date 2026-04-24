import 'package:flutter/material.dart';
import 'my_requests_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';
import '../../shared/paginated_type_picker.dart';

Widget buildMobileFilterSection({
  required BuildContext context,
  required TextEditingController searchController,
  FocusNode? searchFocusNode, // ✅ إضافة الـ FocusNode
  required String selectedPriority,
  required String selectedType,
  required String selectedStatus,
  required List<String> priorities,
  required List<String> typeNames,
  required List<String> statuses,
  required Function(String) onSearchChanged,
  required Function() onPriorityTap,
  required Function() onTypeTap,
  required Function() onStatusTap,
  required Future<Map<String, dynamic>> Function(int page) fetchTypePage,
  required Function(String?) onTypeChanged,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: MyRequestsColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: MyRequestsColors.statShadow,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        // شريط البحث
        TextField(
          controller: searchController,
          focusNode: searchFocusNode, // ✅ ربط الـ FocusNode
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.translate('search_transactions'),
            hintStyle: TextStyle(color: MyRequestsColors.textMuted),
            prefixIcon: Icon(Icons.search_rounded, color: MyRequestsColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: MyRequestsColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: MyRequestsColors.bodyBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            isDense: true,
          ),
          onChanged: onSearchChanged,
        ),
        SizedBox(height: 12),

        // الفلاتر في صف واحد
        Row(
          children: [
            Expanded(
              child: _buildMobileFilterChip(
                context: context,
                label: AppLocalizations.of(context)!.translate('priority_filter'),
                value: selectedPriority,
                icon: Icons.flag_outlined,
                onTap: onPriorityTap,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: PaginatedTypePicker(
                selectedType: selectedType,
                onTypeChanged: onTypeChanged,
                fetchPage: fetchTypePage,
                isMobile: true,
                primaryColor: MyRequestsColors.primary,
                borderColor: MyRequestsColors.primary.withOpacity(0.2),
                textColor: MyRequestsColors.textPrimary,
                cardBg: MyRequestsColors.cardBg,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildMobileFilterChip(
                context: context,
                label: AppLocalizations.of(context)!.translate('status_filter'),
                value: selectedStatus,
                icon: Icons.hourglass_top_outlined,
                onTap: onStatusTap,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildMobileFilterChip({
  required BuildContext context,
  required String label,
  required String value,
  required IconData icon,
  required VoidCallback onTap,
}) {
  // تحديد لون النص حسب الحالة أو الأولوية
  Color getTextColor() {
    final isStatus = label == AppLocalizations.of(context)!.translate('status_filter');
    final isPriority = label == AppLocalizations.of(context)!.translate('priority_filter');

    if (value == 'All' || value == 'All Types') return MyRequestsColors.primary;

    if (isStatus) {
      switch (value.toLowerCase()) {
        case 'waiting': return MyRequestsColors.statusWaiting;
        case 'approved': return MyRequestsColors.statusApproved;
        case 'rejected': return MyRequestsColors.statusRejected;
        case 'needs change': return MyRequestsColors.statusNeedsChange;
        case 'fulfilled': return MyRequestsColors.statusFulfilled;
        default: return MyRequestsColors.textPrimary;
      }
    } else if (isPriority) {
      switch (value.toLowerCase()) {
        case 'high': return MyRequestsColors.statusRejected;
        case 'medium': return MyRequestsColors.statusPending;
        case 'low': return MyRequestsColors.statusApproved;
        default: return MyRequestsColors.primary;
      }
    }
    return MyRequestsColors.textPrimary;
  }

  // تحديد لون الخلفية
  Color getBgColor() {
    if (value == 'All' || value == 'All Types') {
      return MyRequestsColors.primary.withOpacity(0.05);
    }
    return getTextColor().withOpacity(0.12);
  }

  // تحديد لون الحدود
  Color getBorderColor() {
    if (value == 'All' || value == 'All Types') {
      return MyRequestsColors.primary.withOpacity(0.2);
    }
    return getTextColor().withOpacity(0.4);
  }

  // تحديد أيقونة حسب الحالة أو الأولوية
  IconData getStatusIcon() {
    final isStatus = label == AppLocalizations.of(context)!.translate('status_filter');
    final isPriority = label == AppLocalizations.of(context)!.translate('priority_filter');

    if (isStatus) {
      switch (value.toLowerCase()) {
        case "approved": return Icons.check_circle_rounded;
        case "rejected": return Icons.cancel_rounded;
        case "waiting": return Icons.hourglass_empty_rounded;
        case "needs change": return Icons.edit_note_rounded;
        case "fulfilled": return Icons.task_alt_rounded;
        case "all": return Icons.filter_list_rounded;
        default: return icon;
      }
    } else if (isPriority) {
      switch (value.toLowerCase()) {
        case "high": return Icons.priority_high_rounded;
        case "medium": return Icons.low_priority_rounded;
        case "low": return Icons.flag_rounded;
        case "all": return Icons.filter_list_rounded;
        default: return icon;
      }
    }
    return icon;
  }

  // تحديد لون الأيقونة
  Color getIconColor() {
    final isStatus = label == AppLocalizations.of(context)!.translate('status_filter');
    final isPriority = label == AppLocalizations.of(context)!.translate('priority_filter');
    if (isStatus || isPriority) {
      return getTextColor();
    }
    return MyRequestsColors.primary;
  }

  String displayValue = value;
  if (value == 'All') displayValue = AppLocalizations.of(context)!.translate('all_filter');
  if (value == 'All Types') displayValue = AppLocalizations.of(context)!.translate('all_types_filter');
  if (value == 'Waiting') displayValue = AppLocalizations.of(context)!.translate('status_waiting');
  if (value == 'Approved') displayValue = AppLocalizations.of(context)!.translate('status_approved');
  if (value == 'Rejected') displayValue = AppLocalizations.of(context)!.translate('status_rejected');
  if (value == 'Needs Change') displayValue = AppLocalizations.of(context)!.translate('status_needs_editing');
  if (value == 'Fulfilled') displayValue = AppLocalizations.of(context)!.translate('status_fulfilled');
  if (value == 'High') displayValue = AppLocalizations.of(context)!.translate('priority_high');
  if (value == 'Medium') displayValue = AppLocalizations.of(context)!.translate('priority_medium');
  if (value == 'Low') displayValue = AppLocalizations.of(context)!.translate('priority_low');

  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: getBgColor(),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: getBorderColor()),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            getStatusIcon(), // استخدم الأيقونة المناسبة للحالة
            size: 14,
            color: getIconColor(), // لون الأيقونة حسب الحالة
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: MyRequestsColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (value != 'All' && value != 'All Types')
            Text(
              displayValue.length > 8 ? displayValue.substring(0, 8) + '...' : displayValue,
              style: TextStyle(
                fontSize: 8,
                color: getTextColor(), // لون النص حسب الحالة
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    ),
  );
}