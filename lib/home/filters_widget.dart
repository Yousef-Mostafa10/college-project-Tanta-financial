import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
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
        _buildFilterDropdown(
          context: context,
          value: selectedType,
          items: typeNames,
          label: "Type",
          icon: Icons.category_outlined,
          onChanged: onTypeChanged,
          isMobile: true,
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
          child: _buildFilterDropdown(
            context: context,
            value: selectedType,
            items: typeNames,
            label: "Type",
            icon: Icons.category_outlined,
            onChanged: onTypeChanged,
            isMobile: false,
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
                  if (item.toLowerCase() == 'all') displayText = AppLocalizations.of(context)!.translate('all');
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
                          label == "Status" ? _getStatusFilterIcon(item) : icon,
                          size: isMobile ? 14 : 18,
                          color: label == "Status"
                              ? _getStatusColor(item)
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            displayText,
                            style: TextStyle(
                              color: label == "Status"
                                  ? _getStatusColor(item) // حالة خاصة للحالة
                                  : (item == 'All Types' || item == 'All' ||
                                  item == 'All Priorities'
                                  ? AppColors.primary
                                  : AppColors.textPrimary),
                              fontWeight: item == 'All Types' || item == 'All' ||
                                  item == 'All Priorities'
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
}
