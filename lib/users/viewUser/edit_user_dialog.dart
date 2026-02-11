import 'package:flutter/material.dart';
import 'users_api.dart';
import 'users_colors.dart';
import 'users_helpers.dart';
import 'user_model.dart';
import 'package:college_project/l10n/app_localizations.dart';

class EditUserDialog extends StatefulWidget {
  final String userName;
  final UsersApiService apiService;
  final bool isMobile;

  const EditUserDialog({
    super.key,
    required this.userName,
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
  
  // قيمة وهمية لتمثيل كلمة المرور الحالية
  final String _currentPasswordPlaceholder = "********";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = await widget.apiService.getUserDetails(widget.userName);
      final departments = await widget.apiService.fetchDepartments();

      setState(() {
        _nameController.text = user.name;
        _passwordController.text = _currentPasswordPlaceholder;
        _selectedRole = user.role.toUpperCase(); // ضمان أنها تكون uppercase
        _isActive = user.active;
        _departments = departments;
        
        if (user.departmentName != null && _departments.contains(user.departmentName)) {
            _selectedDepartment = user.departmentName;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      UsersHelpers.showErrorMessage(context, e.toString());
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
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.isMobile ? 16 : 20),
      ),
      title: Text(
        AppLocalizations.of(context)!.translate('edit_user') ?? 'Edit User',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontSize: widget.isMobile ? 18 : 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(AppLocalizations.of(context)!.translate('name_label') ?? 'Name'),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(Icons.person),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 12),

              _buildLabel(AppLocalizations.of(context)!.translate('department') ?? 'Department'),
              _departments.isEmpty 
                ? Text('No departments found', style: TextStyle(color: Colors.red, fontSize: 12))
                : DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: _buildInputDecoration(Icons.business),
                    items: _departments.map((dept) => DropdownMenuItem(
                      value: dept,
                      child: Text(dept),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedDepartment = v),
                    hint: Text(AppLocalizations.of(context)!.translate('select_department') ?? 'Select Dept'),
                  ),
              SizedBox(height: 12),

              _buildLabel(AppLocalizations.of(context)!.translate('role_label') ?? 'Role'),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: _buildInputDecoration(Icons.admin_panel_settings),
                items: [
                  DropdownMenuItem(value: 'USER', child: Text(AppLocalizations.of(context)!.translate('regular_user'))),
                  DropdownMenuItem(value: 'ADMIN', child: Text(AppLocalizations.of(context)!.translate('administrator'))),
                ],
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              SizedBox(height: 12),

              _buildLabel(AppLocalizations.of(context)!.translate('password') ?? 'Password'),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: _buildInputDecoration(Icons.lock).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  hintText: 'Enter new password or leave as is',
                ),
                onTap: () {
                    // إذا ضغط المستخدم وكان الحقل يحتوي على النجوم فقط، نقوم بمسحه ليسهل عليه الكتابة
                    if (_passwordController.text == _currentPasswordPlaceholder) {
                        _passwordController.clear();
                    }
                },
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Text(AppLocalizations.of(context)!.translate('active_status') ?? 'Active Status'),
                  Spacer(),
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
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(AppLocalizations.of(context)!.translate('save') ?? 'Save'),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
    );
  }

  InputDecoration _buildInputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.bodyBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      // نتحقق إذا كان الباسورد قد تغير أم لا يزال يحتوي على النجوم (القيمة الوهمية)
      String? newPasswordToSend;
      if (_passwordController.text.isNotEmpty && _passwordController.text != _currentPasswordPlaceholder) {
          newPasswordToSend = _passwordController.text;
      }

      await widget.apiService.updateUser(
        widget.userName,
        newName: _nameController.text,
        newRole: _selectedRole,
        active: _isActive,
        departmentName: _selectedDepartment,
        newPassword: newPasswordToSend, // سيتم إرساله فقط إذا قام المستخدم بتعديله
      );
      
      if (mounted) {
        UsersHelpers.showSuccessMessage(context, 'User updated successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        UsersHelpers.showErrorMessage(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
