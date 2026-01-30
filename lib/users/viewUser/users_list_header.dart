import 'package:flutter/material.dart';
import 'users_colors.dart';

class UsersListHeader extends StatelessWidget {
  final int filteredUsersCount;
  final String selectedFilter;
  final bool hasMore;
  final String searchQuery;
  final bool isMobile;

  const UsersListHeader({
    super.key,
    required this.filteredUsersCount,
    required this.selectedFilter,
    required this.hasMore,
    required this.searchQuery,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 6 : 8,
        horizontal: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.bodyBg,
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $filteredUsersCount ${selectedFilter != 'all' ? selectedFilter + 's' : 'users'}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          if (hasMore && searchQuery.isEmpty && selectedFilter == 'all')
            Text(
              'Scroll to load more',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: isMobile ? 10 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}