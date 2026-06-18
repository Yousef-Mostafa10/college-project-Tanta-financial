import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/core/app_colors.dart';
import './inbox_helpers.dart';
import '../shared/paginated_type_picker.dart';

class InboxDesktopFilters extends StatelessWidget {
  final String selectedPriority;
  final String selectedType;
  final String selectedStatus;
  final List<String> priorities;
  final List<String> typeNames;
  final List<String> statuses;
  final TextEditingController searchController;
  final Function(String) onPriorityChanged;
  final Function(String) onTypeChanged;
  final Function(String) onStatusChanged;
  final Function(String) onSearchChanged;
  final Future<Map<String, dynamic>> Function(int page) fetchTypePage;

  const InboxDesktopFilters({
    Key? key,
    required this.selectedPriority,
    required this.selectedType,
    required this.selectedStatus,
    required this.priorities,
    required this.typeNames,
    required this.statuses,
    required this.searchController,
    required this.onPriorityChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
    required this.fetchTypePage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط البحث العصري (مثل الداشبورد)
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg.withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.translate('search_requests'),
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.search_rounded, color: AppColors.primary),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 1.5),
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(height: 16),

        // فلاتر الديسكتوب الزجاجية (مثل الداشبورد)
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.isDark
                      ? Colors.white.withOpacity(0.12)
                      : AppColors.borderColor.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.statShadow.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_alt_outlined, color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.translate('filters_label'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDesktopFilterDropdown(
                          context: context,
                          value: selectedPriority,
                          items: priorities,
                          label: AppLocalizations.of(context)!.translate('priority'),
                          icon: Icons.flag_outlined,
                          onChanged: (value) => onPriorityChanged(value!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PaginatedTypePicker(
                          selectedType: selectedType,
                          onTypeChanged: (val) => onTypeChanged(val!),
                          fetchPage: fetchTypePage,
                          isMobile: false,
                          primaryColor: AppColors.primary,
                          borderColor: AppColors.primary.withOpacity(0.2),
                          textColor: AppColors.textPrimary,
                          cardBg: AppColors.cardBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDesktopFilterDropdown(
                          context: context,
                          value: selectedStatus,
                          items: statuses,
                          label: AppLocalizations.of(context)!.translate('status'),
                          icon: Icons.hourglass_top_outlined,
                          onChanged: (value) => onStatusChanged(value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopFilterDropdown({
    required BuildContext context,
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            items: items
                .map((item) {
                  String displayText = AppLocalizations.of(context)!.translate(item.toLowerCase().replaceAll(' ', '_'));
                  if (item.toLowerCase() == 'all') {
                    displayText = "$label: ${AppLocalizations.of(context)!.translate('all')}";
                  }

                  return DropdownMenuItem(
                    value: item,
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(context, label, item),
                          size: 18,
                          color: _getStatusColor(context, label, item),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            displayText,
                            style: TextStyle(
                              color: _getStatusTextColor(context, label, item),
                              fontWeight: _getStatusFontWeight(label, item),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                })
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(BuildContext context, String label, String item) {
    if (label == AppLocalizations.of(context)!.translate('status')) {
      return _getStatusFilterIcon(item);
    } else if (label == AppLocalizations.of(context)!.translate('priority')) {
      return _getPriorityIcon(item);
    } else {
      return Icons.category_outlined;
    }
  }

  IconData _getStatusFilterIcon(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return Icons.filter_list_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'waiting':
        return Icons.hourglass_empty_rounded;
      case 'not-assigned':
        return Icons.person_outline;
      case 'needs change':
      case 'needs_change':
        return Icons.edit_note_rounded;
      case 'fulfilled':
        return Icons.task_alt_rounded;
      default:
        return Icons.hourglass_top_outlined;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high_rounded;
      case 'medium':
        return Icons.low_priority_rounded;
      case 'low':
        return Icons.flag_rounded;
      case 'all':
        return Icons.filter_list_rounded;
      default:
        return Icons.flag_outlined;
    }
  }

  Color _getStatusColor(BuildContext context, String label, String item) {
    if (item.toLowerCase() == 'all' || item.toLowerCase() == 'all types') {
      return AppColors.primary;
    }

    if (label == AppLocalizations.of(context)!.translate('priority')) {
      switch (item.toLowerCase()) {
        case 'high': return AppColors.statusRejected;
        case 'medium': return AppColors.statusPending;
        case 'low': return AppColors.statusApproved;
      }
    }

    if (label == AppLocalizations.of(context)!.translate('status')) {
      switch (item.toLowerCase()) {
        case 'approved':
          return AppColors.statusApproved;
        case 'rejected':
          return AppColors.statusRejected;
        case 'waiting':
        case 'not-assigned':
          return AppColors.statusWaiting;
        case 'needs change':
        case 'needs_change':
          return Colors.orange;
        case 'fulfilled':
          return AppColors.statusFulfilled;
        default:
          return AppColors.primary;
      }
    } else {
      return AppColors.primary;
    }
  }

  Color _getStatusTextColor(BuildContext context, String label, String item) {
    if (item == 'All Types' || item == 'All' || item == 'All Priorities') {
      return AppColors.primary;
    }

    return _getStatusColor(context, label, item);
  }

  FontWeight _getStatusFontWeight(String label, String item) {
    if (item == 'All Types' || item == 'All' || item == 'All Priorities') {
      return FontWeight.w600;
    }
    return FontWeight.w500;
  }
}