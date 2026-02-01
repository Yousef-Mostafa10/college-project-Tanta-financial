import 'package:college_project/users/viewUser/users_api.dart';
import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'user_model.dart';
import 'users_colors.dart';
import 'users_helpers.dart';
import 'user_profile_dialog.dart';
import 'change_password_dialog.dart';

class UserCard extends StatelessWidget {
  final User user;
  final UsersApiService apiService;
  final bool isMobile;
  final bool isTablet;

  const UserCard({
    super.key,
    required this.user,
    required this.apiService,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
        leading: Container(
          width: isMobile ? 40 : 50,
          height: isMobile ? 40 : 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: AppColors.primary,
            size: isMobile ? 18 : 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: isMobile ? 14 : 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: isMobile ? 4 : 6),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 6 : 8,
                vertical: isMobile ? 2 : 4,
              ),
              decoration: BoxDecoration(
                color: UsersHelpers.getRoleColor(user.group).withOpacity(0.1),
                borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                border: Border.all(
                  color: UsersHelpers.getRoleColor(user.group).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                user.group == 'admin' ? AppLocalizations.of(context)!.translate('administrator') : AppLocalizations.of(context)!.translate('regular_user'),
                style: TextStyle(
                  fontSize: isMobile ? 9 : 10,
                  fontWeight: FontWeight.w600,
                  color: UsersHelpers.getRoleColor(user.group),
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          "${user.name}@company.com",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isMobile ? 12 : 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: AppColors.textSecondary,
            size: isMobile ? 18 : 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
          ),
          onSelected: (value) {
            if (value == 'view') {
              _showUserProfile(context);
            } else if (value == 'change_password') {
              _showChangePasswordDialog(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(
                    Icons.remove_red_eye_rounded,
                    color: AppColors.primary,
                    size: isMobile ? 16 : 18,
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  Text(
                    AppLocalizations.of(context)!.translate('view_profile'),
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'change_password',
              child: Row(
                children: [
                  Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.accentBlue,
                    size: isMobile ? 16 : 18,
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  Text(
                    AppLocalizations.of(context)!.translate('change_password'),
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UserProfileDialog(
        userName: user.name,
        apiService: apiService,
        isMobile: isMobile,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordDialog(
        userName: user.name,
        apiService: apiService,
        isMobile: isMobile,
      ),
    );
  }
}