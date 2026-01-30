import 'package:flutter/material.dart';
import 'users_api.dart';
import 'users_colors.dart';
import 'users_helpers.dart';

class UserProfileDialog extends StatefulWidget {
  final String userName;
  final UsersApiService apiService;
  final bool isMobile;

  const UserProfileDialog({
    super.key,
    required this.userName,
    required this.apiService,
    required this.isMobile,
  });

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await widget.apiService.getUserDetails(widget.userName);
      if (response["status"] == "success") {
        setState(() {
          _userData = response["user"];
          _isLoading = false;
        });
      }
    } catch (e) {
      UsersHelpers.showErrorMessage(context, e.toString());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.isMobile ? 16 : 20),
      ),
      content: _isLoading
          ? SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      )
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: widget.isMobile ? 60 : 70,
            height: widget.isMobile ? 60 : 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: widget.isMobile ? 30 : 36,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: widget.isMobile ? 12 : 16),
          Text(
            _userData!["name"] ?? "",
            style: TextStyle(
              fontSize: widget.isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: widget.isMobile ? 8 : 12),
          _buildProfileDetail(
            "Group",
            _userData!["group"] ?? "Unknown",
            Icons.group_rounded,
          ),
          _buildProfileDetail(
            "Created At",
            UsersHelpers.formatDate(_userData!["createdAt"]),
            Icons.calendar_today_rounded,
          ),
          _buildProfileDetail(
            "Updated At",
            UsersHelpers.formatDate(_userData!["updatedAt"] ?? _userData!["createdAt"]),
            Icons.update_rounded,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Close",
            style: TextStyle(
              color: AppColors.primary,
              fontSize: widget.isMobile ? 14 : 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetail(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.isMobile ? 8 : 10),
      padding: EdgeInsets.all(widget.isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: AppColors.bodyBg,
        borderRadius: BorderRadius.circular(widget.isMobile ? 6 : 8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: widget.isMobile ? 16 : 18,
          ),
          SizedBox(width: widget.isMobile ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: widget.isMobile ? 11 : 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: widget.isMobile ? 12 : 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}