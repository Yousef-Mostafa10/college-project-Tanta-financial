import 'package:college_project/users/viewUser/users_api.dart';
import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'user_model.dart';
import 'users_colors.dart';
import 'users_helpers.dart';
import 'user_profile_dialog.dart';
import 'change_password_dialog.dart';

import 'edit_user_dialog.dart';

class UserCard extends StatelessWidget {
  final User user;
  final UsersApiService apiService;
  final bool isMobile;
  final bool isTablet;
  final VoidCallback? onUpdate;

  const UserCard({
    super.key,
    required this.user,
    required this.apiService,
    required this.isMobile,
    required this.isTablet,
    this.onUpdate,
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
                color: UsersHelpers.getRoleColor(user.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                border: Border.all(
                  color: UsersHelpers.getRoleColor(user.role).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                user.role == 'admin' ? AppLocalizations.of(context)!.translate('administrator') : AppLocalizations.of(context)!.translate('regular_user'),
                style: TextStyle(
                  fontSize: isMobile ? 9 : 10,
                  fontWeight: FontWeight.w600,
                  color: UsersHelpers.getRoleColor(user.role),
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
            } else if (value == 'edit') {
              _showEditUserDialog(context);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: _buildPopupItem(Icons.remove_red_eye_rounded, AppLocalizations.of(context)!.translate('view_profile'), AppColors.primary),
            ),
            PopupMenuItem(
              value: 'edit',
              child: _buildPopupItem(Icons.edit_rounded, AppLocalizations.of(context)!.translate('edit_user') ?? 'Edit Profile', AppColors.accentBlue),
            ),
            PopupMenuItem(
              value: 'delete',
              child: _buildPopupItem(Icons.delete_outline_rounded, AppLocalizations.of(context)!.translate('delete') ?? 'Delete User', AppColors.accentRed),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.translate('delete_user') ?? 'Delete User',
          style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "${AppLocalizations.of(context)!.translate('delete_confirmation') ?? 'Are you sure you want to delete'} ${user.name}?",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await apiService.deleteUser(user.name);
                if (onUpdate != null) onUpdate!();
                UsersHelpers.showSuccessMessage(context, 'User deleted successfully');
              } catch (e) {
                UsersHelpers.showErrorMessage(context, e.toString());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.translate('delete')),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupItem(IconData icon, String label, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: isMobile ? 16 : 18),
        SizedBox(width: isMobile ? 6 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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

  void _showEditUserDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => EditUserDialog(
        userName: user.name,
        apiService: apiService,
        isMobile: isMobile,
      ),
    ).then((updated) {
      if (updated == true && onUpdate != null) {
        onUpdate!();
      }
    });
  }
}
