import 'package:flutter/material.dart';
import 'users_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';

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
                ? (selectedFilter == 'admin'
                ? AppLocalizations.of(context)!.translate('no_admins_found')
                : AppLocalizations.of(context)!.translate('no_users_found'))
                : AppLocalizations.of(context)!.translate('no_users_found'),
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: AppColors.textSecondary,
            ),
          ),
          if (selectedFilter != 'all' && hasUsers)
            Padding(
              padding: EdgeInsets.only(top: isMobile ? 8 : 12),
              child: Text(
                AppLocalizations.of(context)!.translate('try_loading_more'),
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