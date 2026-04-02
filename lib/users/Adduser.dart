import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/core/app_colors.dart';
import '../app_config.dart';


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
  String _selectedRole = 'USER'; // القيمة الافتراضية
  String? _selectedDepartment; // القسم المختار
  List<String> _departments = []; // قائمة الأقسام فقط
  int _departmentPage = 1;
  bool _hasMoreDepartments = true;
  bool _isLoadingMoreDepartments = false;
  final ScrollController _departmentScrollController = ScrollController();
  final TextEditingController _departmentSearchController = TextEditingController();
  Timer? _departmentSearchDebounce;
  String _currentDepartmentSearchQuery = '';

  final String _apiUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    // تحميل الأقسام فقط عند بداية الصفحة
    _fetchDepartments();
  }

  // ✅ دالة لتحميل الأقسام من الـ API مع Pagination ودعم البحث
  Future<void> _fetchDepartments({bool loadMore = false, String searchQuery = ''}) async {
    // نمنع الطلبات المتكررة فقط في حالة الـ loadMore لضمان عدم تداخل البحث
    if (loadMore && _isLoadingMoreDepartments) return;
    if (loadMore && !_hasMoreDepartments) return;

    if (!loadMore) {
      _departmentPage = 1;
      _departments = [];
      _hasMoreDepartments = true;
      _currentDepartmentSearchQuery = searchQuery;
    }

    setState(() => _isLoadingMoreDepartments = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        setState(() => _isLoadingMoreDepartments = false);
        return;
      }

      // ✅ بناء الرابط - مطابقة تماماً لما هو موجود في DepartmentsPage
      String url = '$_apiUrl/departments?page=$_departmentPage&perPage=10';
      if (_currentDepartmentSearchQuery.isNotEmpty) {
        if (RegExp(r'^\d+$').hasMatch(_currentDepartmentSearchQuery)) {
          // إذا كان البحث رقماً، نستخدم managerId
          url += '&managerId=$_currentDepartmentSearchQuery';
        } else {
          // إذا كان نصاً، نستخدم name
          url += '&name=${Uri.encodeComponent(_currentDepartmentSearchQuery)}';
        }
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "accept": "application/json",
        },
      );

      debugPrint("Departments Search URL: $url");
      debugPrint("Departments Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> departmentsList = [];

        if (data is Map) {
          departmentsList = data['data'] ?? [];
        } else if (data is List) {
          departmentsList = data;
        }

        // قراءة بيانات الـ pagination
        final pagination = data is Map ? data['pagination'] : null;

        setState(() {
          final newDepts = departmentsList.map((dept) => dept['name'].toString()).toList();
          if (loadMore) {
            _departments.addAll(newDepts);
          } else {
            _departments = newDepts;
          }

          if (pagination != null && pagination['next'] != null) {
            _departmentPage = pagination['next'];
            _hasMoreDepartments = true;
          } else {
            _hasMoreDepartments = false;
          }

          // اختيار أول قسم كقيمة افتراضية (فقط عند التحميل الأول وبدون بحث)
          if (_departments.isNotEmpty && _selectedDepartment == null && _currentDepartmentSearchQuery.isEmpty) {
            _selectedDepartment = _departments.first;
          }
          _isLoadingMoreDepartments = false;
        });
      } else {
        setState(() => _isLoadingMoreDepartments = false);
      }
    } catch (e) {
      debugPrint("Error fetching departments: $e");
      setState(() => _isLoadingMoreDepartments = false);
    }
  }

  // ✅ الدالة المسؤولة عن إضافة مستخدم جديد
  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 🟢 استرجاع التوكن من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _showErrorMessage(AppLocalizations.of(context)!.translate('no_token_error'));
        setState(() => _isLoading = false);
        return;
      }

      // 🟢 تحضير البيانات حسب الهيكل المطلوب
      Map<String, dynamic> userData = {
        "name": _nameController.text.trim(),
        "password": _passwordController.text.trim(),
        "role": _selectedRole, // USER أو ADMIN
      };

      // إضافة القسم إذا تم اختياره
      if (_selectedDepartment != null && _selectedDepartment!.isNotEmpty) {
        userData["departmentName"] = _selectedDepartment;
      }

      debugPrint("User Data to send: $userData");

      // 🟢 إرسال الطلب مع التوكن في الهيدر
      final response = await http.post(
        Uri.parse('$_apiUrl/users'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "accept": "application/json",
        },
        body: jsonEncode(userData),
      );

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessMessage();
      } else {
        // ✅ محاولة استخراج رسالة الخطأ من السيرفر
        String errorMessage = AppLocalizations.of(context)!.translate('unknown_error') ?? "Error: ${response.statusCode}";
        errorMessage = _parseApiError(response.body, errorMessage);
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      debugPrint("Error: $e");
      _showErrorMessage("${AppLocalizations.of(context)!.translate('connection_error')}: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🛠️ Robust Error Parser for http response (Modified for AddUser)
  String _parseApiError(String responseBody, String defaultMessage) {
    if (responseBody.isEmpty) return defaultMessage;
    
    try {
      final dynamic data = jsonDecode(responseBody);
      
      if (data is Map) {
        // 1. Try common top-level error keys
        var msg = data['message'] ?? data['error'] ?? data['errors'] ?? data['msg'];
        
        if (msg == null && data.isNotEmpty) {
          // If no common keys, but the map has something, maybe it's localized?
          final locale = AppLocalizations.of(context)!.locale.languageCode;
          if (data.containsKey(locale)) return data[locale].toString();
        }

        if (msg != null) {
          if (msg is String) return msg;
          if (msg is List) return msg.map((e) => e.toString()).join(', ');
          if (msg is Map) {
            // Nested localized search or validation errors
            final locale = AppLocalizations.of(context)!.locale.languageCode;
            if (msg.containsKey(locale)) return msg[locale].toString();
            if (msg.values.isNotEmpty) {
              final firstVal = msg.values.first;
              if (firstVal is List) return firstVal.join(', ');
              return firstVal.toString();
            }
            return msg.toString();
          }
          return msg.toString();
        }
      } else if (data is String) {
        return data;
      }
    } catch (e) {
      debugPrint("Error parsing API error response: $e");
      // JSON parsing failed, return body if it's a simple string
      if (responseBody.length < 100) return responseBody;
    }
    
    return defaultMessage;
  }

  // ✅ رسائل النجاح والخطأ
  void _showSuccessMessage() {
    // ✅ مسح أي SnackBar موجود لإظهار الجديد فوراً
    ScaffoldMessenger.of(context).clearSnackBars();
    
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
    // ✅ مسح أي SnackBar موجود لإظهار الجديد فوراً
    ScaffoldMessenger.of(context).clearSnackBars();

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
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppLocalizations.of(context)!.translate('please_enter_username');
                    }
                    // ✅ إزالة التحقق من وجود المستخدم - الباك اند هو المسؤول
                    return null;
                  },
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

                // User Role Selection
                _buildUserRoleSelector(isMobile),

                SizedBox(height: isMobile ? 16 : 20),

                // Department Selection
                _buildDepartmentSelector(isMobile),

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

  // ✅ فتح Bottom Sheet لاختيار القسم مع دعم البحث والتحميل التدريجي
  void _showDepartmentBottomSheet(bool isMobile) {
    // تصفير البحث عند الفتح لضمان عرض القائمة كاملة
    _departmentSearchController.clear();
    _currentDepartmentSearchQuery = '';
    
    // إذا كانت القائمة فارغة، قم بتحميلها
    if (_departments.isEmpty) {
      _fetchDepartments(searchQuery: '');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.cardBg,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // العنوان
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.translate('select_department') ?? 'Select Department',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _departmentSearchDebounce?.cancel();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 16),

                  // شريط البحث
                  TextField(
                    controller: _departmentSearchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.translate('search_departments') ?? 'Search departments...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _departmentSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _departmentSearchController.clear();
                                _departmentSearchDebounce?.cancel();
                                setStateSheet(() {
                                  _isLoadingMoreDepartments = true;
                                });
                                _fetchDepartments(searchQuery: '').then((_) {
                                  if (context.mounted) setStateSheet(() {});
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      _departmentSearchDebounce?.cancel();
                      _departmentSearchDebounce = Timer(const Duration(milliseconds: 500), () {
                        setStateSheet(() {
                          _isLoadingMoreDepartments = true;
                        });
                        _fetchDepartments(searchQuery: value.trim()).then((_) {
                          if (context.mounted) setStateSheet(() {});
                        });
                      });
                      setStateSheet(() {}); // لتحديث أيقونة المسح
                    },
                  ),
                  const SizedBox(height: 16),

                  // قائمة الأقسام مع Scroll Listener
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels >=
                                scrollInfo.metrics.maxScrollExtent - 100 &&
                            !_isLoadingMoreDepartments &&
                            _hasMoreDepartments) {
                          _fetchDepartments(loadMore: true).then((_) {
                            if (context.mounted) setStateSheet(() {});
                          });
                        }
                        return false;
                      },
                      child: _departments.isEmpty && _isLoadingMoreDepartments
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : _departments.isEmpty
                              ? Center(
                                  child: Text(
                                    AppLocalizations.of(context)!.translate('no_departments_found') ?? 'No departments found',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _departmentScrollController,
                                  itemCount: _departments.length + (_hasMoreDepartments ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    // عنصر اللودينج في الآخر
                                    if (index == _departments.length) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    final dept = _departments[index];
                                    final isSelected = dept == _selectedDepartment;

                                    return ListTile(
                                      leading: Icon(
                                        Icons.business,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        size: isMobile ? 20 : 24,
                                      ),
                                      title: Text(
                                        dept,
                                        style: TextStyle(
                                          fontSize: isMobile ? 14 : 16,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? Icon(
                                              Icons.check_circle,
                                              color: AppColors.primary,
                                              size: isMobile ? 20 : 24,
                                            )
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _selectedDepartment = dept;
                                        });
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ✅ تصميم حقل اختيار القسم
  Widget _buildDepartmentSelector(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            AppLocalizations.of(context)!.translate('department') ?? 'Department',
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _showDepartmentBottomSheet(isMobile),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 14 : 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              border: Border.all(color: AppColors.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.business,
                  color: AppColors.primary,
                  size: isMobile ? 20 : 24,
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Text(
                    _selectedDepartment ??
                        (AppLocalizations.of(context)!.translate('select_department') ?? 'Select Department'),
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: _selectedDepartment != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: isMobile ? 22 : 26,
                ),
              ],
            ),
          ),
        ),
        if (_departments.isEmpty && !_isLoadingMoreDepartments)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              AppLocalizations.of(context)!.translate('no_departments_found') ?? 'No departments found',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  // ✅ تصميم مودرن لاختيار نوع المستخدم (Role)
  Widget _buildUserRoleSelector(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            AppLocalizations.of(context)!.translate('user_role'),
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            child: Container(
              color: AppColors.cardBg,
              child: isMobile
                  ? Column(
                      children: [
                        _buildRoleOption(
                          title: AppLocalizations.of(context)!.translate('administrator') ?? 'Administrator',
                          subtitle: AppLocalizations.of(context)!.translate('full_access') ?? 'Full system access',
                          value: 'ADMIN',
                          icon: Icons.admin_panel_settings_rounded,
                          isSelected: _selectedRole == 'ADMIN',
                          isMobile: isMobile,
                        ),
                        // Divider(height: 1, color: AppColors.borderColor.withOpacity(0.3)),
                        _buildRoleOption(
                          title: AppLocalizations.of(context)!.translate('regular_user') ?? 'Regular User',
                          subtitle: AppLocalizations.of(context)!.translate('limited_access') ?? 'Basic permissions',
                          value: 'USER',
                          icon: Icons.person_rounded,
                          isSelected: _selectedRole == 'USER',
                          isMobile: isMobile,
                        ),
                        // Divider(height: 1, color: AppColors.borderColor.withOpacity(0.3)),
                        _buildRoleOption(
                          title: AppLocalizations.of(context)!.translate('accountant') ?? 'Accountant',
                          subtitle: AppLocalizations.of(context)!.translate('accounting_access') ?? 'Accounting permissions',
                          value: 'ACCOUNTANT',
                          icon: Icons.account_balance_wallet_rounded,
                          isSelected: _selectedRole == 'ACCOUNTANT',
                          isMobile: isMobile,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildRoleOption(
                            title: AppLocalizations.of(context)!.translate('administrator') ?? 'Admin',
                            subtitle: AppLocalizations.of(context)!.translate('full_access') ?? 'Full Access',
                            value: 'ADMIN',
                            icon: Icons.admin_panel_settings_rounded,
                            isSelected: _selectedRole == 'ADMIN',
                            isMobile: isMobile,
                          ),
                        ),
                        Expanded(
                          child: _buildRoleOption(
                            title: AppLocalizations.of(context)!.translate('regular_user') ?? 'User',
                            subtitle: AppLocalizations.of(context)!.translate('limited_access') ?? 'Limited',
                            value: 'USER',
                            icon: Icons.person_rounded,
                            isSelected: _selectedRole == 'USER',
                            isMobile: isMobile,
                          ),
                        ),
                        Expanded(
                          child: _buildRoleOption(
                            title: AppLocalizations.of(context)!.translate('accountant') ?? 'Finance',
                            subtitle: AppLocalizations.of(context)!.translate('accounting_access') ?? 'Accounting',
                            value: 'ACCOUNTANT',
                            icon: Icons.account_balance_wallet_rounded,
                            isSelected: _selectedRole == 'ACCOUNTANT',
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

  // ✅ تصميم كل خيار من خيارات الـ Role
  Widget _buildRoleOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required bool isSelected,
    required bool isMobile,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: isMobile ? 12 : 20,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          border: isMobile 
            ? Border(
                bottom: BorderSide(
                  color: isSelected ? AppColors.primary.withOpacity(0.3) : AppColors.borderColor.withOpacity(0.5),
                  width: 1,
                ),
                left: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 4,
                ),
              )
            : Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderColor.withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
        ),
        child: isMobile 
          ? Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.bodyBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? AppColors.primary.withOpacity(0.7) : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 22,
                  ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.bodyBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? AppColors.primary.withOpacity(0.7) : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
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
    _departmentScrollController.dispose();
    super.dispose();
  }
}