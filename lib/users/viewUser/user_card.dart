import 'package:college_project/users/viewUser/users_api.dart';
import '../../utils/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'user_model.dart';
import 'users_colors.dart';
import 'users_helpers.dart';
import 'user_profile_dialog.dart';
import 'edit_user_dialog.dart';
import 'user_files_dialog.dart';

class UserCard extends StatefulWidget {
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
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isMobile = widget.isMobile;

    final statusColor = !user.active
        ? AppColors.statusRejected
        : (user.presence?.toUpperCase() == 'ONLINE'
            ? AppColors.statusApproved
            : Colors.grey);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
        transform: _isPressed ? (Matrix4.identity()..scale(0.98)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: statusColor,
                  width: 4,
                ),
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(isMobile ? 12 : 16),

              // ✅ أيقونة مع علامة الحالة
              leading: Stack(
                children: [
                  Container(
                    width: isMobile ? 50 : 60,
                    height: isMobile ? 50 : 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.isDark
                            ? [AppColors.gradientStart, AppColors.gradientEnd]
                            : [AppColors.primary.withValues(alpha: 0.7), AppColors.primary],
                      ),
                      shape: BoxShape.circle,
                      border: AppColors.isDark
                          ? null
                          : Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: isMobile ? 24 : 28,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: isMobile ? 14 : 16,
                      height: isMobile ? 14 : 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              // ✅ المحتوى الرئيسي
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: isMobile ? 15 : 17,
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
                          color: UsersHelpers.getRoleColor(user.role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                          border: Border.all(
                            color: UsersHelpers.getRoleColor(user.role).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          user.role.toLowerCase() == 'admin'
                              ? AppLocalizations.of(context)!.translate('administrator')
                              : user.role.toLowerCase() == 'accountant'
                                  ? AppLocalizations.of(context)!.translate('accountant')
                                  : AppLocalizations.of(context)!.translate('regular_user'),
                          style: TextStyle(
                            fontSize: isMobile ? 8 : 10,
                            fontWeight: FontWeight.bold,
                            color: UsersHelpers.getRoleColor(user.role),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 4 : 6),

                  // ✅ القسم
                  if (user.departmentName != null && user.departmentName!.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 10,
                        vertical: isMobile ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business_center,
                            size: isMobile ? 10 : 12,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            user.departmentName!,
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // ✅ subtitle بقيمة من API
              subtitle: Padding(
                padding: EdgeInsets.only(top: isMobile ? 6 : 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: isMobile ? 12 : 14,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.translate('last_login_label')
                          .replaceAll('{date}', UsersHelpers.formatDate(user.lastLogin, context)),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: isMobile ? 11 : 12,
                      ),
                    ),
                  ],
                ),
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
                  } else if (value == 'files') {
                    _showUserFilesDialog(context);
                  } else if (value == 'edit') {
                    _showEditUserDialog(context);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: _buildPopupItem(
                        Icons.remove_red_eye_rounded,
                        AppLocalizations.of(context)!.translate('view_profile'),
                        AppColors.primary
                    ),
                  ),
                  PopupMenuItem(
                    value: 'files',
                    child: _buildPopupItem(
                        Icons.folder_shared_rounded,
                        AppLocalizations.of(context)!.translate('view_files'),
                        AppColors.accentBlue
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: _buildPopupItem(
                        Icons.edit_rounded,
                        AppLocalizations.of(context)!.translate('edit_user'),
                        AppColors.accentBlue
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: _buildPopupItem(
                        Icons.delete_outline_rounded,
                        AppLocalizations.of(context)!.translate('delete'),
                        AppColors.accentRed
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(dialogContext)!.translate('delete_user'),
          style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "${AppLocalizations.of(dialogContext)!.translate('delete_confirmation')} ${widget.user.name}?",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(dialogContext)!.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await widget.apiService.deleteUserById(widget.user.id!);
                if (widget.onUpdate != null) {
                  widget.onUpdate!();
                }
                if (scaffoldContext.mounted) {
                  UsersHelpers.showSuccessMessage(
                    scaffoldContext,
                    AppLocalizations.of(scaffoldContext)!.translate('user_deleted_success'),
                  );
                }
              } catch (e) {
                if (scaffoldContext.mounted) {
                  UsersHelpers.showErrorMessage(scaffoldContext, AppErrorHandler.translateException(scaffoldContext, e));
                }
                debugPrint("Delete user error: $e");
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
        Icon(icon, color: iconColor, size: widget.isMobile ? 16 : 18),
        SizedBox(width: widget.isMobile ? 6 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: widget.isMobile ? 13 : 14,
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
        userName: widget.user.name,
        userId: widget.user.id!,
        apiService: widget.apiService,
        isMobile: widget.isMobile,
      ),
    );
  }

  void _showUserFilesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UserFilesDialog(
        userName: widget.user.name,
        userId: widget.user.id!,
        apiService: widget.apiService,
        isMobile: widget.isMobile,
      ),
    );
  }

  void _showEditUserDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => EditUserDialog(
        userName: widget.user.name,
        userId: widget.user.id!,
        apiService: widget.apiService,
        isMobile: widget.isMobile,
      ),
    ).then((updated) {
      if (updated == true && widget.onUpdate != null) {
        widget.onUpdate!();
      }
    });
  }
}
