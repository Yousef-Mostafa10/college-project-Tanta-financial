import 'package:flutter/material.dart';
import 'users_colors.dart';

class UsersEmptyState extends StatelessWidget {
  final String selectedFilter;
  final bool hasUsers;
  final bool isMobile;

  const UsersEmptyState({
    super.key,
    required this.selectedFilter,
    required this.hasUsers,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: isMobile ? 48 : 64,
            color: AppColors.textMuted,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            selectedFilter != 'all'
                ? 'No ${selectedFilter}s found'
                : 'No users found',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: AppColors.textSecondary,
            ),
          ),
          if (selectedFilter != 'all' && hasUsers)
            Padding(
              padding: EdgeInsets.only(top: isMobile ? 8 : 12),
              child: Text(
                'Try loading more users or change filter',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}