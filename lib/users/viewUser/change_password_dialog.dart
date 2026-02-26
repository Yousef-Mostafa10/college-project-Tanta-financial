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
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${AppLocalizations.of(context)!.translate('change_password')} - ${widget.userName}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: _buildInputDecoration(
              AppLocalizations.of(context)!.translate('new_password'),
              Icons.lock,
              suffix: IconButton(
                icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            obscureText: !_showPassword,
            decoration: _buildInputDecoration(
              AppLocalizations.of(context)!.translate('confirm_password'),
              Icons.lock_clock_outlined,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _savePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Text(AppLocalizations.of(context)!.translate('save')),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.bodyBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _savePassword() async {
    if (_passwordController.text.isEmpty) {
      UsersHelpers.showErrorMessage(context, AppLocalizations.of(context)!.translate('password_empty_error'));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      UsersHelpers.showErrorMessage(context, AppLocalizations.of(context)!.translate('passwords_dont_match'));
      return;
    }
    if (_passwordController.text.length < 6) {
      UsersHelpers.showErrorMessage(
        context,
        AppLocalizations.of(context)!.translate('password_length_error'),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.apiService.changePassword(
        widget.userName,
        _passwordController.text,
      );
      if (mounted) {
        UsersHelpers.showSuccessMessage(
          context,
          AppLocalizations.of(context)!.translate('password_changed_success'),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        UsersHelpers.showErrorMessage(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}