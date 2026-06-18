import 'dart:ui';
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
  final FocusNode? searchFocusNode;
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
    this.searchFocusNode,
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
        // ── Search bar (pill-shaped like Dashboard) ───────────────────────
        Container(
          decoration: BoxDecoration(
            color: MyRequestsColors.cardBg.withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: MyRequestsColors.primary.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: MyRequestsColors.primary.withOpacity(0.1),
            ),
          ),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!
                  .translate('search_transactions'),
              hintStyle:
                  TextStyle(color: MyRequestsColors.textMuted, fontSize: 14),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.search_rounded,
                    color: MyRequestsColors.primary),
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
                borderSide: BorderSide(
                  color: MyRequestsColors.primary.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(height: 16),

        // ── Glassmorphic filter container ─────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MyRequestsColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: MyRequestsColors.isDark
                      ? Colors.white.withOpacity(0.12)
                      : MyRequestsColors.borderColor.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: MyRequestsColors.statShadow.withOpacity(0.08),
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
                      Icon(Icons.filter_alt_outlined,
                          color: MyRequestsColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!
                            .translate('filters_label'),
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
                        child: _buildDropdown(
                          context: context,
                          value: selectedPriority,
                          items: priorities,
                          label: AppLocalizations.of(context)!
                              .translate('priority_filter'),
                          icon: Icons.flag_outlined,
                          onChanged: (v) => onPriorityChanged(v),
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
                          borderColor:
                              MyRequestsColors.primary.withOpacity(0.2),
                          textColor: MyRequestsColors.textPrimary,
                          cardBg: MyRequestsColors.cardBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          context: context,
                          value: selectedStatus,
                          items: statuses,
                          label: AppLocalizations.of(context)!
                              .translate('status_filter'),
                          icon: Icons.hourglass_top_outlined,
                          onChanged: (v) => onStatusChanged(v),
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

  Widget _buildDropdown({
    required BuildContext context,
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: MyRequestsColors.primary.withOpacity(0.05),
        border: Border.all(
            color: MyRequestsColors.primary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_rounded,
                color: MyRequestsColors.textSecondary),
            style: TextStyle(
              fontSize: 14,
              color: MyRequestsColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            items: items.map((item) {
              String displayText = item;
              if (item == 'All') {
                displayText =
                    "$label: ${AppLocalizations.of(context)!.translate('all')}";
              } else if (item == 'Waiting') {
                displayText = AppLocalizations.of(context)!
                    .translate('status_waiting');
              } else if (item == 'Approved') {
                displayText = AppLocalizations.of(context)!
                    .translate('status_approved');
              } else if (item == 'Rejected') {
                displayText = AppLocalizations.of(context)!
                    .translate('status_rejected');
              } else if (item == 'Needs Change') {
                displayText = AppLocalizations.of(context)!
                    .translate('status_needs_editing');
              } else if (item == 'Fulfilled') {
                displayText = AppLocalizations.of(context)!
                    .translate('status_fulfilled');
              } else if (item == 'High') {
                displayText = AppLocalizations.of(context)!
                    .translate('priority_high');
              } else if (item == 'Medium') {
                displayText = AppLocalizations.of(context)!
                    .translate('priority_medium');
              } else if (item == 'Low') {
                displayText = AppLocalizations.of(context)!
                    .translate('priority_low');
              }

              return DropdownMenuItem(
                value: item,
                child: Row(
                  children: [
                    Icon(
                      _getIcon(context, label, item),
                      size: 18,
                      color: _getColor(context, label, item),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          color: _getTextColor(context, label, item),
                          fontWeight:
                              _getFontWeight(label, item),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  IconData _getIcon(BuildContext context, String label, String item) {
    final statusLabel =
        AppLocalizations.of(context)!.translate('status_filter');
    final priorityLabel =
        AppLocalizations.of(context)!.translate('priority_filter');
    if (label == statusLabel) {
      switch (item.toLowerCase()) {
        case 'all': return Icons.filter_list_rounded;
        case 'approved': return Icons.check_circle_rounded;
        case 'rejected': return Icons.cancel_rounded;
        case 'waiting': return Icons.hourglass_empty_rounded;
        case 'needs change': return Icons.edit_note_rounded;
        case 'fulfilled': return Icons.task_alt_rounded;
        default: return Icons.hourglass_top_outlined;
      }
    } else if (label == priorityLabel) {
      switch (item.toLowerCase()) {
        case 'high': return Icons.priority_high_rounded;
        case 'medium': return Icons.low_priority_rounded;
        case 'low': return Icons.flag_rounded;
        case 'all': return Icons.filter_list_rounded;
        default: return Icons.flag_outlined;
      }
    }
    return Icons.category_outlined;
  }

  Color _getColor(BuildContext context, String label, String item) {
    if (item.toLowerCase() == 'all') return MyRequestsColors.primary;
    final priorityLabel =
        AppLocalizations.of(context)!.translate('priority_filter');
    if (label == priorityLabel) {
      switch (item.toLowerCase()) {
        case 'high': return MyRequestsColors.statusRejected;
        case 'medium': return MyRequestsColors.statusPending;
        case 'low': return MyRequestsColors.statusApproved;
      }
    }
    switch (item.toLowerCase()) {
      case 'approved': return MyRequestsColors.statusApproved;
      case 'rejected': return MyRequestsColors.statusRejected;
      case 'waiting': return MyRequestsColors.statusWaiting;
      case 'needs change':
      case 'needs_change': return MyRequestsColors.statusNeedsChange;
      case 'fulfilled': return MyRequestsColors.statusFulfilled;
      default: return MyRequestsColors.primary;
    }
  }

  Color _getTextColor(BuildContext context, String label, String item) {
    if (item == 'All' || item == 'All Types') {
      return MyRequestsColors.primary;
    }
    return _getColor(context, label, item);
  }

  FontWeight _getFontWeight(String label, String item) {
    if (item == 'All' || item == 'All Types') return FontWeight.w600;
    return FontWeight.w500;
  }
}