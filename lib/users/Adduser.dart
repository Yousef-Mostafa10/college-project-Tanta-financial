import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:college_project/l10n/app_localizations.dart';

// 🎨 COLOR PALETTE - Consistent with the whole application
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF00695C);
  static const Color primaryLight = Color(0xFF00796B);

  // Background Colors
  static const Color bodyBg = Color(0xFFF5F6FA);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textMuted = Color(0xFFB0B0B0);

  // Accent Colors
  static const Color accentRed = Color(0xFFE74C3C);
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color accentYellow = Color(0xFFFFB74D);

  // Status Colors
  static const Color statusApproved = Color(0xFF27AE60);
  static const Color statusRejected = Color(0xFFE74C3C);
  static const Color statusWaiting = Color(0xFF1E88E5);

  // Border Colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color focusBorderColor = Color(0xFF00695C);

  // Gradient Colors
  static const Color gradientStart = Color(0xFFE0F2F1);
  static const Color gradientEnd = Color(0xFFB2DFDB);

  // Selection Colors
  static const Color selectionBg = Color(0xFFE0F2F1);
  static const Color selectionBorder = Color(0xFF00695C);
}

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  String _selectedGroup = 'user'; // القيمة الافتراضية

  // ✅ الدالة المسؤولة عن إضافة مستخدم جديد
  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse("http://192.168.1.3:3000/users");

      // 🟢 استرجاع التوكن من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _showErrorMessage(AppLocalizations.of(context)!.translate('no_token_error'));
        setState(() => _isLoading = false);
        return;
      }

      // 🟢 إرسال الطلب مع التوكن في الهيدر
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": _nameController.text.trim(),
          "password": _passwordController.text.trim(),
          "group": _selectedGroup, // إضافة حقل المجموعة
        }),
      );

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 201) { // ✅ الـ API بيرجع 201 للنجاح
        final data = jsonDecode(response.body);
        if (data["status"] == "success") {
          _showSuccessMessage();
        } else {
          _showErrorMessage(data["message"] ?? "Failed to add user ❌");
        }
      } else if (response.statusCode == 409) {
        _showErrorMessage(AppLocalizations.of(context)!.translate('user_exists_error'));
      } else if (response.statusCode == 403) {
        _showErrorMessage(AppLocalizations.of(context)!.translate('permission_error'));
      } else if (response.statusCode == 401) {
        _showErrorMessage(AppLocalizations.of(context)!.translate('unauthorized_error'));
      } else {
        _showErrorMessage("Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error: $e");
      _showErrorMessage(AppLocalizations.of(context)!.translate('connection_error'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ رسائل النجاح والخطأ - بتعديل الالوان لتتوافق
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.translate('user_added_success'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.statusApproved,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.statusRejected,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final isDesktop = width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.bodyBg,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('add_new_user'),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(
            isMobile ? 20 :
            isTablet ? 24 :
            32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header Icon
                Container(
                  width: isMobile ? 100 : 120,
                  height: isMobile ? 100 : 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_add_alt_1,
                    size: isMobile ? 40 : 50,
                    color: AppColors.primary,
                  ),
                ),

                SizedBox(height: isMobile ? 24 : 32),

                // Username Field
                _inputField(
                  controller: _nameController,
                  label: AppLocalizations.of(context)!.translate('username'),
                  icon: Icons.person_outline,
                  isMobile: isMobile,
                  validator: (v) =>
                  v == null || v.isEmpty ? AppLocalizations.of(context)!.translate('please_enter_username') : null,
                ),
                SizedBox(height: isMobile ? 16 : 20),

                // Password Field
                _inputField(
                  controller: _passwordController,
                  label: AppLocalizations.of(context)!.translate('password'),
                  icon: Icons.lock_outline,
                  obscure: !_showPassword,
                  isMobile: isMobile,
                  suffix: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textSecondary,
                      size: isMobile ? 20 : 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppLocalizations.of(context)!.translate('please_enter_password');
                    if (v.length < 6) {
                      return AppLocalizations.of(context)!.translate('password_length_error');
                    }
                    return null;
                  },
                ),

                SizedBox(height: isMobile ? 16 : 20),

                // User Group Selection
                _buildUserGroupSelector(isMobile),

                SizedBox(height: isMobile ? 24 : 32),

                // Add User Button
                _buildAddButton(isMobile),

                SizedBox(height: isMobile ? 12 : 16),

                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 24 : 32,
                      vertical: isMobile ? 10 : 12,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('cancel'),
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ تصميم مودرن لاختيار نوع المستخدم
  Widget _buildUserGroupSelector(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            AppLocalizations.of(context)!.translate('user_type'),
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            child: Container(
              color: AppColors.cardBg,
              child: Row(
                children: [
                  // Admin Option
                  Expanded(
                    child: _buildGroupOption(
                      title: AppLocalizations.of(context)!.translate('administrator'),
                      subtitle: AppLocalizations.of(context)!.translate('full_access'),
                      value: 'admin',
                      icon: Icons.admin_panel_settings,
                      isSelected: _selectedGroup == 'admin',
                      isMobile: isMobile,
                    ),
                  ),
                  // User Option
                  Expanded(
                    child: _buildGroupOption(
                      title: AppLocalizations.of(context)!.translate('regular_user'),
                      subtitle: AppLocalizations.of(context)!.translate('limited_access'),
                      value: 'user',
                      icon: Icons.person,
                      isSelected: _selectedGroup == 'user',
                      isMobile: isMobile,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ تصميم كل خيار من خيارات نوع المستخدم
  Widget _buildGroupOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required bool isSelected,
    required bool isMobile,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGroup = value;
        });
      },
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectionBg : AppColors.cardBg,
          border: Border.all(
            color: isSelected ? AppColors.selectionBorder : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isMobile ? 40 : 48,
              height: isMobile ? 40 : 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.borderColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: isMobile ? 20 : 24,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 4 : 8),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: isMobile ? 18 : 20,
              ),
          ],
        ),
      ),
    );
  }

  // ✅ Widgets مع Responsive Design
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isMobile,
    Widget? suffix,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(
          fontSize: isMobile ? 14 : 16,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isMobile ? 14 : 16,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primary,
            size: isMobile ? 20 : 24,
          ),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            borderSide: const BorderSide(
              color: AppColors.focusBorderColor,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: AppColors.cardBg,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 14 : 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildAddButton(bool isMobile) {
    return Container(
      width: double.infinity,
      height: isMobile ? 50 : 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _addUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
          height: isMobile ? 18 : 20,
          width: isMobile ? 18 : 20,
          child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                Icons.person_add_alt_1,
                size: isMobile ? 20 : 22
            ),
            SizedBox(width: isMobile ? 6 : 8),
            Text(
              AppLocalizations.of(context)!.translate('add_user'),
              style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}