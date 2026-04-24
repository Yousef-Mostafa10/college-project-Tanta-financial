import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import '../shared/paginated_type_picker.dart';
import 'dashboard_colors.dart';
import 'dashboard_helpers.dart';

class FiltersWidget extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedPriority;
  final String selectedType;
  final String selectedStatus;
  final List<String> priorities;
  final List<String> typeNames;
  final List<String> statuses;
  final bool isMobile;
  final Function(String) onSearchChanged;
  final Function(String?) onPriorityChanged;
  final Function(String?) onTypeChanged;
  final Function(String?) onStatusChanged;
  final Future<Map<String, dynamic>> Function(int page) fetchTypePage;

  const FiltersWidget({
    super.key,
    required this.searchController,
    required this.selectedPriority,
    required this.selectedType,
    required this.selectedStatus,
    required this.priorities,
    required this.typeNames,
    required this.statuses,
    required this.isMobile,
    required this.onSearchChanged,
    required this.onPriorityChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.fetchTypePage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_alt_outlined, color: AppColors.primary,
                    size: 16),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.translate('filters_label'),
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            isMobile
                ? _buildMobileFilters(context)
                : _buildDesktopFilters(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFilters(BuildContext context) {
    return Column(
      children: [
        _buildFilterDropdown(
          context: context,
          value: selectedPriority,
          items: priorities,
          label: "Priority",
          icon: Icons.flag_outlined,
          onChanged: onPriorityChanged,
          isMobile: true,
        ),
        const SizedBox(height: 8),
        PaginatedTypePicker(
          selectedType: selectedType,
          onTypeChanged: onTypeChanged,
          fetchPage: fetchTypePage,
          isMobile: true,
          primaryColor: AppColors.primary,
          borderColor: AppColors.statBorder,
          textColor: AppColors.textPrimary,
          cardBg: AppColors.cardBg,
        ),
        const SizedBox(height: 8),
        _buildFilterDropdown(
          context: context,
          value: selectedStatus,
          items: statuses,
          label: "Status",
          icon: Icons.hourglass_top_outlined,
          onChanged: onStatusChanged,
          isMobile: true,
        ),
      ],
    );
  }

  Widget _buildDesktopFilters(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildFilterDropdown(
            context: context,
            value: selectedPriority,
            items: priorities,
            label: "Priority",
            icon: Icons.flag_outlined,
            onChanged: onPriorityChanged,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PaginatedTypePicker(
            selectedType: selectedType,
            onTypeChanged: onTypeChanged,
            fetchPage: fetchTypePage,
            isMobile: false,
            primaryColor: AppColors.primary,
            borderColor: AppColors.statBorder,
            textColor: AppColors.textPrimary,
            cardBg: AppColors.cardBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFilterDropdown(
            context: context,
            value: selectedStatus,
            items: statuses,
            label: "Status",
            icon: Icons.hourglass_top_outlined,
            onChanged: onStatusChanged,
            isMobile: false,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required BuildContext context,
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.statBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: Icon(
                Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            items: items
                .map((item) {
                  String displayText = item;
                  if (item.toLowerCase() == 'all') {
                    final labelKey = label.toLowerCase() == 'priority' ? 'priority_label' : 'status_label';
                    displayText = "${AppLocalizations.of(context)!.translate(labelKey)}: ${AppLocalizations.of(context)!.translate('all')}";
                  }
                  else if (item.toLowerCase() == 'all types') displayText = AppLocalizations.of(context)!.translate('all_types');
                  else if (item.toLowerCase() == 'high') displayText = AppLocalizations.of(context)!.translate('high');
                  else if (item.toLowerCase() == 'medium') displayText = AppLocalizations.of(context)!.translate('medium');
                  else if (item.toLowerCase() == 'low') displayText = AppLocalizations.of(context)!.translate('low');
                  else if (item.toLowerCase() == 'waiting') displayText = AppLocalizations.of(context)!.translate('waiting');
                  else if (item.toLowerCase() == 'approved') displayText = AppLocalizations.of(context)!.translate('approved');
                  else if (item.toLowerCase() == 'rejected') displayText = AppLocalizations.of(context)!.translate('rejected');
                  else if (item.toLowerCase() == 'fulfilled') displayText = AppLocalizations.of(context)!.translate('fulfilled');
                  else if (item.toLowerCase() == 'needs change') displayText = AppLocalizations.of(context)!.translate('needs_change');

                  return DropdownMenuItem(
                    value: item,
                    child: Row(
                      children: [
                        Icon(
                          label == "Status" 
                              ? _getStatusFilterIcon(item) 
                              : (label == "Priority" ? _getPriorityIcon(item) : icon),
                          size: isMobile ? 14 : 18,
                          color: label == "Status"
                              ? _getStatusColor(item)
                              : (label == "Priority" ? _getPriorityColor(item) : AppColors.primary),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            displayText,
                            style: TextStyle(
                              color: label == "Status"
                                  ? _getStatusColor(item)
                                  : (label == "Priority" 
                                      ? _getPriorityColor(item) 
                                      : (item == 'All Types' || item.toLowerCase() == 'all' || item == 'All Priorities'
                                          ? AppColors.primary
                                          : AppColors.textPrimary)),
                              fontWeight: item == 'All Types' || item.toLowerCase() == 'all' || item == 'All Priorities'
                                  ? FontWeight.w600
                                  : FontWeight.w500,
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

// دالة إرجاع لون الحالة
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return AppColors.primary; // أزرق
      case 'waiting':
        return AppColors.statusWaiting; // أصفر
      case 'approved':
        return AppColors.statusApproved; // أخضر
      case 'rejected':
        return AppColors.statusRejected; // أحمر
      case 'fulfilled':
        return AppColors.statusFulfilled; // بنفسجي
      case 'needs change':
        return AppColors.statusNeedsChange; // برتقالي
      default:
        return AppColors.textPrimary; // رمادي
    }
  }

// دالة إرجاع أيقونة الحالة
  IconData _getStatusFilterIcon(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return Icons.filter_list_rounded;
      case 'waiting':
        return Icons.hourglass_empty_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'fulfilled':
        return Icons.task_alt_rounded;
      case 'needs change':
        return Icons.edit_note_rounded;
      default:
        return Icons.hourglass_top_outlined;
    }
  }

  // دالة إرجاع لون الأولوية
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.statusError; // أحمر
      case 'medium':
        return AppColors.statusPending; // برتقالي
      case 'low':
        return AppColors.statusApproved; // أخضر
      case 'all':
        return AppColors.primary;
      default:
        return AppColors.textPrimary;
    }
  }

  // دالة إرجاع أيقونة الأولوية
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
}
