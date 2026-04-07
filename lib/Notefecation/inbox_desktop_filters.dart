

import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import './inbox_colors.dart';
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
        // شريط البحث
        Container(
          decoration: BoxDecoration(
            color: InboxColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: InboxColors.statShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.translate('search_requests'),
              hintStyle: TextStyle(color: InboxColors.textMuted),
              prefixIcon: Icon(Icons.search_rounded, color: InboxColors.primary),
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
                borderSide: BorderSide(color: InboxColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: InboxColors.bodyBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(height: 16),

        // فلاتر الديسكتوب
        Card(
          elevation: 2,
          color: InboxColors.cardBg,
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
                    Icon(Icons.filter_alt_outlined, color: InboxColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.translate('filters_label'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: InboxColors.primary,
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
                        primaryColor: InboxColors.primary,
                        borderColor: InboxColors.statBorder,
                        textColor: InboxColors.textPrimary,
                        cardBg: InboxColors.cardBg,
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
        border: Border.all(color: InboxColors.statBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_rounded, color: InboxColors.textSecondary),
            style: TextStyle(
              fontSize: 14,
              color: InboxColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            items: items
                .map((item) => DropdownMenuItem(
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
                      AppLocalizations.of(context)!.translate(item.toLowerCase().replaceAll(' ', '_')),
                      style: TextStyle(
                        color: _getStatusTextColor(context, label, item),
                        fontWeight: _getStatusFontWeight(label, item),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ))
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
      return Icons.flag_outlined;
    } else {
      return Icons.category_outlined;
    }
  }

  IconData _getStatusFilterIcon(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return Icons.filter_list;
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

  Color _getStatusColor(BuildContext context, String label, String item) {
    if (label == AppLocalizations.of(context)!.translate('status')) {
      switch (item.toLowerCase()) {
        case 'all':
          return InboxColors.primary;
        case 'approved':
          return InboxColors.statusApproved;
        case 'rejected':
          return InboxColors.statusRejected;
        case 'waiting':
        case 'not-assigned':
          return InboxColors.statusWaiting;
        case 'needs change':
        case 'needs_change':
          return Colors.orange;
        case 'fulfilled':
          return InboxColors.statusFulfilled;
        default:
          return InboxColors.primary;
      }
    } else {
      return InboxColors.primary;
    }
  }

  Color _getStatusTextColor(BuildContext context, String label, String item) {
    if (item == 'All Types' || item == 'All' || item == 'All Priorities') {
      return InboxColors.primary;
    }

    if (label == AppLocalizations.of(context)!.translate('status')) {
      switch (item.toLowerCase()) {
        case 'approved':
          return InboxColors.statusApproved;
        case 'rejected':
          return InboxColors.statusRejected;
        case 'waiting':
        case 'not-assigned':
          return InboxColors.statusWaiting;
        case 'needs change':
        case 'needs_change':
          return Colors.orange;
        case 'fulfilled':
          return InboxColors.statusFulfilled;
        default:
          return InboxColors.textPrimary;
      }
    } else {
      return InboxColors.textPrimary;
    }
  }

  FontWeight _getStatusFontWeight(String label, String item) {
    if (item == 'All Types' || item == 'All' || item == 'All Priorities') {
      return FontWeight.w600;
    }
    return FontWeight.w500;
  }
}