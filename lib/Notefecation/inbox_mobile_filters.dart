

import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import './inbox_colors.dart';
import '../shared/paginated_type_picker.dart';

class InboxMobileFilters extends StatelessWidget {
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
  final Function(String, List<String>, String, Function(String))? onShowMobileFilterDialog;
  final Future<Map<String, dynamic>> Function(int page) fetchTypePage;

  const InboxMobileFilters({
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
    this.onShowMobileFilterDialog,
    required this.fetchTypePage,
  }) : super(key: key);

  Widget _buildMobileFilterChip({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    // تحديد لون النص حسب الحالة
    Color getTextColor() {
      if (label == AppLocalizations.of(context)!.translate('status')) {
        switch (value.toLowerCase()) {
          case 'waiting':
            return InboxColors.statusWaiting;
          case 'approved':
            return InboxColors.statusApproved;
          case 'rejected':
            return InboxColors.statusRejected;
          case 'fulfilled': // حالة جديدة - الفيل فيلد
            return InboxColors.statusFulfilled;
          case 'needs change': // حالة جديدة - النيد اشانج
            return InboxColors.statusPending;
          default:
            return InboxColors.textPrimary;
        }
      }
      return InboxColors.textPrimary;
    }

    // تحديد أيقونة حسب الحالة
    IconData getStatusIcon() {
      if (label == AppLocalizations.of(context)!.translate('status')) {
        switch (value.toLowerCase()) {
          case 'waiting':
            return Icons.hourglass_empty_rounded;
          case 'approved':
            return Icons.check_circle_rounded;
          case 'rejected':
            return Icons.cancel_rounded;
          case 'fulfilled': // حالة جديدة - الفيل فيلد
            return Icons.task_alt_rounded;
          case 'needs change': // حالة جديدة - النيد اشانج
            return Icons.edit_note_rounded;
          default:
            return icon;
        }
      }
      return icon;
    }

    // تحديد لون الأيقونة
    Color getIconColor() {
      if (label == AppLocalizations.of(context)!.translate('status')) {
        return getTextColor();
      }
      return InboxColors.primary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: InboxColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: InboxColors.primary.withOpacity(0.2)),
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
              AppLocalizations.of(context)!.translate(label.toLowerCase()),
              style: TextStyle(
                fontSize: 9,
                color: InboxColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (value != 'All' && value != 'All Types')
              Text(
                AppLocalizations.of(context)!.translate(value.toLowerCase().replaceAll(' ', '_')),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: InboxColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: InboxColors.statShadow,
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
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.translate('search_requests'),
              hintStyle: TextStyle(color: InboxColors.textMuted),
              prefixIcon: Icon(Icons.search_rounded, color: InboxColors.primary),
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
                borderSide: BorderSide(color: InboxColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: InboxColors.bodyBg,
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
                  label: AppLocalizations.of(context)!.translate('priority'),
                  value: selectedPriority,
                  icon: Icons.flag_outlined,
                  onTap: () {
                    if (onShowMobileFilterDialog != null) {
                      onShowMobileFilterDialog!(
                        AppLocalizations.of(context)!.translate("select_priority"),
                        priorities,
                        selectedPriority,
                        onPriorityChanged,
                      );
                    }
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: PaginatedTypePicker(
                  selectedType: selectedType,
                  onTypeChanged: (val) => onTypeChanged(val!),
                  fetchPage: fetchTypePage,
                  isMobile: true,
                  primaryColor: InboxColors.primary,
                  borderColor: InboxColors.primary.withOpacity(0.2),
                  textColor: InboxColors.textPrimary,
                  cardBg: InboxColors.cardBg,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildMobileFilterChip(
                  context: context,
                  label: AppLocalizations.of(context)!.translate('status'),
                  value: selectedStatus,
                  icon: Icons.hourglass_top_outlined,
                  onTap: () {
                    if (onShowMobileFilterDialog != null) {
                      onShowMobileFilterDialog!(
                        AppLocalizations.of(context)!.translate("select_status"),
                        statuses,
                        selectedStatus,
                        onStatusChanged,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}