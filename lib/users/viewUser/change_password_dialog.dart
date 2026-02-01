import 'package:flutter/material.dart';
import 'users_api.dart';
import 'users_colors.dart';
import 'users_helpers.dart';
import 'package:college_project/l10n/app_localizations.dart';

class ChangePasswordDialog extends StatefulWidget {
  final String userName;
  final UsersApiService apiService;
  final bool isMobile;

  const ChangePasswordDialog({
    super.key,
    required this.userName,
    required this.apiService,
    required this.isMobile,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.isMobile ? 16 : 20),
      ),
      title: Text(
        AppLocalizations.of(context)!.translate('change_password'),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontSize: widget.isMobile ? 18 : 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppLocalizations.of(context)!.translate('change_password')} - ${widget.userName}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: widget.isMobile ? 14 : 16,
              ),
            ),
            SizedBox(height: widget.isMobile ? 16 : 20),

            // New Password Field with toggle
            TextField(
              controller: _newPasswordController,
              obscureText: !_showNewPassword,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.translate('new_password'),
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                  borderSide: BorderSide(
                    color: AppColors.focusBorderColor,
                    width: 1.5,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: widget.isMobile ? 20 : 24,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: AppColors.textSecondary,
                    size: widget.isMobile ? 18 : 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                ),
                filled: true,
                fillColor: AppColors.bodyBg,
              ),
            ),
            SizedBox(height: widget.isMobile ? 10 : 12),

            // Confirm Password Field with toggle
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.translate('confirm_password'),
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                  borderSide: BorderSide(
                    color: AppColors.focusBorderColor,
                    width: 1.5,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: widget.isMobile ? 20 : 24,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: AppColors.textSecondary,
                    size: widget.isMobile ? 18 : 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                ),
                filled: true,
                fillColor: AppColors.bodyBg,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.translate('cancel'),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: widget.isMobile ? 14 : 16,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isMobile ? 16 : 20,
              vertical: widget.isMobile ? 10 : 12,
            ),
          ),
          child: _isLoading
              ? SizedBox(
            height: widget.isMobile ? 18 : 20,
            width: widget.isMobile ? 18 : 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_reset_rounded,
                size: widget.isMobile ? 16 : 18,
              ),
              SizedBox(width: widget.isMobile ? 4 : 6),
              Text(
                AppLocalizations.of(context)!.translate('change_password'),
                style: TextStyle(fontSize: widget.isMobile ? 14 : 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.isEmpty) {
      UsersHelpers.showErrorMessage(context, AppLocalizations.of(context)!.translate('please_enter_password'));
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      // Assuming a generic error for mismatch or adding a specific key if not present
      UsersHelpers.showErrorMessage(context, "Passwords don't match"); 
      return;
    }
    if (_newPasswordController.text.length < 6) {
      UsersHelpers.showErrorMessage(context, AppLocalizations.of(context)!.translate('password_length_error'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.apiService.changePassword(
        widget.userName,
        _newPasswordController.text,
      );
      UsersHelpers.showSuccessMessage(context, "${AppLocalizations.of(context)!.translate('password_changed_success')} ${widget.userName}");
      Navigator.pop(context);
    } catch (e) {
      UsersHelpers.showErrorMessage(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }
}