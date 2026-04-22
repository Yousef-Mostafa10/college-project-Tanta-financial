import 'package:flutter/material.dart';
import '../../utils/app_error_handler.dart';
import 'users_api.dart';
import 'users_colors.dart';
import 'users_helpers.dart';
import 'user_model.dart';
import 'package:college_project/l10n/app_localizations.dart';

class EditUserDialog extends StatefulWidget {
  final String userName;
  final int userId;
  final UsersApiService apiService;
  final bool isMobile;

  const EditUserDialog({
    super.key,
    required this.userName,
    required this.userId,
    required this.apiService,
    required this.isMobile,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'user';
  bool _isActive = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showPassword = false;

  String? _selectedDepartment;
  List<String> _departments = [];

  final String _currentPasswordPlaceholder = "********";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = await widget.apiService.getUserDetailsById(widget.userId);
      final departments = await widget.apiService.fetchDepartments();

      setState(() {
        _nameController.text = user.name;
        _passwordController.text = _currentPasswordPlaceholder;
        _selectedRole = user.role.toUpperCase();
        _isActive = user.active;
        _departments = departments;

        if (user.departmentName != null &&
            _departments.contains(user.departmentName)) {
          _selectedDepartment = user.departmentName;
        }

        _isLoading = false;
      });
    } catch (e) {
      UsersHelpers.showErrorMessage(context, AppErrorHandler.translateException(context, e));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.isMobile ? 16 : 20),
      ),
      title: Text(
        AppLocalizations.of(context)!.translate('edit_user'),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontSize: widget.isMobile ? 18 : 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(AppLocalizations.of(context)!.translate('name_label')),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(Icons.person),
                validator: (v) => (v == null || v.isEmpty) ? AppLocalizations.of(context)!.translate('required') : null,
              ),
              SizedBox(height: 12),

              _buildLabel(AppLocalizations.of(context)!.translate('department_name')),
              _departments.isEmpty
                  ? Text(
                AppLocalizations.of(context)!.translate('no_departments_found'),
                style: const TextStyle(color: Colors.red, fontSize: 12),
              )
                  : DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: _buildInputDecoration(Icons.business),
                items: _departments
                    .map((dept) => DropdownMenuItem(
                  value: dept,
                  child: Text(dept),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDepartment = v),
                hint: Text(
                  AppLocalizations.of(context)!.translate('select_department'),
                ),
              ),
              SizedBox(height: 12),

              _buildLabel(AppLocalizations.of(context)!.translate('role_label')),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: _buildInputDecoration(Icons.admin_panel_settings),
                items: [
                  DropdownMenuItem(
                    value: 'USER',
                    child: Text(AppLocalizations.of(context)!.translate('regular_user')),
                  ),
                  DropdownMenuItem(
                    value: 'ADMIN',
                    child: Text(AppLocalizations.of(context)!.translate('administrator')),
                  ),
                  DropdownMenuItem(
                    value: 'ACCOUNTANT',
                    child: Text(AppLocalizations.of(context)!.translate('accountant')),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              SizedBox(height: 12),

              _buildLabel(AppLocalizations.of(context)!.translate('password')),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: _buildInputDecoration(Icons.lock).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  hintText: AppLocalizations.of(context)!.translate('enter_password_hint'),
                ),
                validator: (v) => (v == null || v.isEmpty) 
                    ? AppLocalizations.of(context)!.translate('required') 
                    : (v.length < 6 && v != _currentPasswordPlaceholder)
                        ? AppLocalizations.of(context)!.translate('password_length_error')
                        : null,
                onTap: () {
                  if (_passwordController.text == _currentPasswordPlaceholder) {
                    _passwordController.clear();
                  }
                },
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Text(AppLocalizations.of(context)!.translate('active_status')),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.bodyBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      String? newPasswordToSend;
      if (_passwordController.text.isNotEmpty &&
          _passwordController.text != _currentPasswordPlaceholder) {
        newPasswordToSend = _passwordController.text;
      }

      await widget.apiService.updateUserById(
        widget.userId,
        newName: _nameController.text,
        newRole: _selectedRole,
        active: _isActive,
        departmentName: _selectedDepartment,
        newPassword: newPasswordToSend,
      );

      if (mounted) {
        UsersHelpers.showSuccessMessage(context, AppLocalizations.of(context)!.translate('user_updated_success'));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        UsersHelpers.showErrorMessage(context, AppErrorHandler.translateException(context, e));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
