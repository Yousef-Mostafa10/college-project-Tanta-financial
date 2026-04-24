import 'package:flutter/material.dart';
import 'my_requests_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';
import '../../shared/paginated_type_picker.dart';

class MyRequestsDesktopFilters extends StatelessWidget {
  final String selectedPriority;
  final String selectedType;
  final String selectedStatus;
  final List<String> priorities;
  final List<String> typeNames;
  final List<String> statuses;
  final TextEditingController searchController;
  final FocusNode? searchFocusNode; // ✅ إضافة الـ FocusNode
  final Function(String?) onPriorityChanged;
  final Function(String?) onTypeChanged;
  final Function(String?) onStatusChanged;
  final Function(String) onSearchChanged;
  final Future<Map<String, dynamic>> Function(int page) fetchTypePage;

  const MyRequestsDesktopFilters({
    Key? key,
    required this.selectedPriority,
    required this.selectedType,
    required this.selectedStatus,
    required this.priorities,
    required this.typeNames,
    required this.statuses,
    required this.searchController,
    this.searchFocusNode, // ✅ إضافة الـ FocusNode
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
        // شريط البحث
        Container(
          decoration: BoxDecoration(
            color: MyRequestsColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: MyRequestsColors.statShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode, // ✅ ربط الـ FocusNode
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.translate('search_transactions'),
              hintStyle: TextStyle(color: MyRequestsColors.textMuted),
              prefixIcon: Icon(Icons.search_rounded, color: MyRequestsColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: MyRequestsColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: MyRequestsColors.bodyBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(height: 16),

        // فلاتر الديسكتوب
        Card(
          elevation: 2,
          color: MyRequestsColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, color: MyRequestsColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.translate('filters_label').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MyRequestsColors.primary,
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
                        label: AppLocalizations.of(context)!.translate('priority_filter'),
                        icon: Icons.flag_outlined,
                        onChanged: (value) => onPriorityChanged(value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PaginatedTypePicker(
                        selectedType: selectedType,
                        onTypeChanged: onTypeChanged,
                        fetchPage: fetchTypePage,
                        isMobile: false,
                        primaryColor: MyRequestsColors.primary,
                        borderColor: MyRequestsColors.statBorder,
                        textColor: MyRequestsColors.textPrimary,
                        cardBg: MyRequestsColors.cardBg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDesktopFilterDropdown(
                        context: context,
                        value: selectedStatus,
                        items: statuses,
                        label: AppLocalizations.of(context)!.translate('status_filter'),
                        icon: Icons.hourglass_top_outlined,
                        onChanged: (value) => onStatusChanged(value),
                      ),
                    ),
                  ],
                ),
              ],
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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: MyRequestsColors.statBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_rounded, color: MyRequestsColors.textSecondary),
            style: TextStyle(
              fontSize: 14,
              color: MyRequestsColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            items: items
                .map((item) {
                  String displayText = item;
                  if (item == 'All') {
                    displayText = "$label: ${AppLocalizations.of(context)!.translate('all_filter')}";
                  }
                  else if (item == 'All Types') displayText = AppLocalizations.of(context)!.translate('all_types_filter');
                  else if (item == 'Waiting') displayText = AppLocalizations.of(context)!.translate('status_waiting');
                  else if (item == 'Approved') displayText = AppLocalizations.of(context)!.translate('status_approved');
                  else if (item == 'Rejected') displayText = AppLocalizations.of(context)!.translate('status_rejected');
                  else if (item == 'Needs Change') displayText = AppLocalizations.of(context)!.translate('status_needs_editing');
                  else if (item == 'Fulfilled') displayText = AppLocalizations.of(context)!.translate('status_fulfilled');
                  else if (item == 'High') displayText = AppLocalizations.of(context)!.translate('priority_high');
                  else if (item == 'Medium') displayText = AppLocalizations.of(context)!.translate('priority_medium');
                  else if (item == 'Low') displayText = AppLocalizations.of(context)!.translate('priority_low');

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
    if (label == AppLocalizations.of(context)!.translate('status_filter')) {
      return _getStatusFilterIcon(item);
    } else if (label == AppLocalizations.of(context)!.translate('priority_filter')) {
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
      case 'needs change':
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
      return MyRequestsColors.primary;
    }
    
    // Priority colors
    if (label == AppLocalizations.of(context)!.translate('priority_filter')) {
        switch (item.toLowerCase()) {
          case 'high': return MyRequestsColors.statusRejected; // Red
          case 'medium': return MyRequestsColors.statusPending; // Amber/Orange
          case 'low': return MyRequestsColors.statusApproved; // Green
        }
    }

    switch (item.toLowerCase()) {
      case 'approved':
        return MyRequestsColors.statusApproved;
      case 'rejected':
        return MyRequestsColors.statusRejected;
      case 'waiting':
        return MyRequestsColors.statusWaiting;
      case 'needs_change':
      case 'needs change':
        return MyRequestsColors.statusNeedsChange;
      case 'fulfilled':
        return MyRequestsColors.statusFulfilled;
      default:
        return MyRequestsColors.primary;
    }
  }

  Color _getStatusTextColor(BuildContext context, String label, String item) {
    if (item == 'All Types' || item == 'All' || item == 'All Priorities') {
      return MyRequestsColors.primary;
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