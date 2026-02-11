import 'package:flutter/material.dart';
import 'users_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';

class UsersSearchFilter extends StatefulWidget {
  final String searchQuery;
  final String selectedFilter;
  final Function(String) onSearchChanged;
  final Function(String) onFilterChanged;
  final bool isMobile;

  const UsersSearchFilter({
    super.key,
    required this.searchQuery,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.isMobile,
  });

  @override
  State<UsersSearchFilter> createState() => _UsersSearchFilterState();
}

class _UsersSearchFilterState extends State<UsersSearchFilter> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.translate('search_users'),
              hintStyle: TextStyle(color: AppColors.textMuted),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.primary,
                size: widget.isMobile ? 20 : 24,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 16),
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 16),
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 16),
                borderSide: BorderSide(
                  color: AppColors.focusBorderColor,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppColors.bodyBg,
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 16 : 20,
                vertical: widget.isMobile ? 14 : 16,
              ),
            ),
          ),
          SizedBox(height: widget.isMobile ? 8 : 12),
          _buildFilterRow(),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            AppLocalizations.of(context)!.translate('all'),
            'all',
          ),
          _buildFilterChip(
            AppLocalizations.of(context)!.translate('administrator'),
            'admin',
          ),
          _buildFilterChip(
            AppLocalizations.of(context)!.translate('regular_user'),
            'user',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = widget.selectedFilter == value;
    return Container(
      margin: EdgeInsets.only(right: widget.isMobile ? 6 : 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: widget.isMobile ? 12 : 14,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          widget.onFilterChanged(selected ? value : 'all');
        },
        backgroundColor: AppColors.cardBg,
        selectedColor: AppColors.filterSelectedBg,
        labelStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        checkmarkColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
          side: BorderSide(
            color: isSelected ? AppColors.filterSelectedBorder : AppColors.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
      ),
    );
  }
}