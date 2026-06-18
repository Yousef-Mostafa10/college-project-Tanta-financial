import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/core/app_colors.dart';
import './inbox_helpers.dart';
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
    // تحديد لون النص حسب الحالة أو الأولوية
    Color getTextColor() {
      final isStatus = label == AppLocalizations.of(context)!.translate('status');
      final isPriority = label == AppLocalizations.of(context)!.translate('priority');

      if (isStatus) {
        switch (value.toLowerCase()) {
          case 'waiting': return AppColors.statusWaiting;
          case 'approved': return AppColors.statusApproved;
          case 'rejected': return AppColors.statusRejected;
          case 'fulfilled': return AppColors.statusFulfilled;
          case 'needs change': 
          case 'needs_change': return Colors.orange;
          default: return AppColors.textPrimary;
        }
      } else if (isPriority) {
        switch (value.toLowerCase()) {
          case 'high': return AppColors.statusRejected;
          case 'medium': return AppColors.statusPending;
          case 'low': return AppColors.statusApproved;
          default: return AppColors.primary;
        }
      }
      return AppColors.textPrimary;
    }

    // تحديد أيقونة حسب الحالة أو الأولوية
    IconData getStatusIcon() {
      final isStatus = label == AppLocalizations.of(context)!.translate('status');
      final isPriority = label == AppLocalizations.of(context)!.translate('priority');

      if (isStatus) {
        switch (value.toLowerCase()) {
          case 'waiting': return Icons.hourglass_empty_rounded;
          case 'approved': return Icons.check_circle_rounded;
          case 'rejected': return Icons.cancel_rounded;
          case 'fulfilled': return Icons.task_alt_rounded;
          case 'needs change': 
          case 'needs_change': return Icons.edit_note_rounded;
          default: return icon;
        }
      } else if (isPriority) {
        switch (value.toLowerCase()) {
          case 'high': return Icons.priority_high_rounded;
          case 'medium': return Icons.low_priority_rounded;
          case 'low': return Icons.flag_rounded;
          case 'all': return Icons.filter_list_rounded;
          default: return icon;
        }
      }
      return icon;
    }

    // تحديد لون الأيقونة
    Color getIconColor() {
      final isStatus = label == AppLocalizations.of(context)!.translate('status');
      final isPriority = label == AppLocalizations.of(context)!.translate('priority');
      if (isStatus || isPriority) {
        return getTextColor();
      }
      return AppColors.primary;
    }

    final bool isActive = value != 'All' && value != 'All Types';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? getIconColor().withOpacity(0.15)
              : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
                ? getIconColor().withOpacity(0.5)
                : AppColors.primary.withOpacity(0.15),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive 
              ? [
                  BoxShadow(
                    color: getIconColor().withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getStatusIcon(),
              size: isActive ? 16 : 14,
              color: getIconColor(),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!.translate(label.toLowerCase()),
              style: TextStyle(
                fontSize: 9,
                color: isActive ? getIconColor() : AppColors.primary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (isActive)
              Text(
                AppLocalizations.of(context)!.translate(value.toLowerCase().replaceAll(' ', '_')),
                style: TextStyle(
                  fontSize: 8,
                  color: getTextColor(),
                  fontWeight: FontWeight.w700,
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.isDark
              ? Colors.white.withOpacity(0.2)
              : AppColors.borderColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // شريط البحث الدائري
          Container(
            decoration: BoxDecoration(
              color: AppColors.bodyBg,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.translate('search_requests'),
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.4), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(height: 10),

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
              const SizedBox(width: 8),
              Expanded(
                child: PaginatedTypePicker(
                  selectedType: selectedType,
                  onTypeChanged: (val) => onTypeChanged(val!),
                  fetchPage: fetchTypePage,
                  isMobile: true,
                  primaryColor: AppColors.primary,
                  borderColor: AppColors.primary.withOpacity(0.2),
                  textColor: AppColors.textPrimary,
                  cardBg: AppColors.cardBg,
                ),
              ),
              const SizedBox(width: 8),
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