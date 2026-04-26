import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';
import '../l10n/app_localizations.dart';
import '../core/app_colors.dart';
import '../utils/app_error_handler.dart';
import 'package:provider/provider.dart';
import 'package:college_project/providers/theme_provider.dart';

class DepartmentsPage extends StatefulWidget {
  const DepartmentsPage({Key? key}) : super(key: key);

  @override
  State<DepartmentsPage> createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    headers: {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  List<Map<String, dynamic>> allDepartments = [];
  List<Map<String, dynamic>> filteredDepartments = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  bool isRefreshing = false;
  String? errorMessage;

  // Pagination
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  int _totalDepartments = 0;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    fetchAllDepartments();

    // Scroll listener للتحميل التدريجي
    _scrollController.addListener(() {
      if (_scrollController.offset >= 200) {
        if (!_showBackToTop) setState(() => _showBackToTop = true);
      } else {
        if (_showBackToTop) setState(() => _showBackToTop = false);
      }

      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMorePages &&
          searchController.text.isEmpty) {
        _loadMoreDepartments();
      }
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🔐 Get headers with authentication token
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    return {
      'Authorization': 'Bearer $token',
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  // 📥 Fetch departments with pagination
  Future<void> fetchAllDepartments({bool fullLoad = true}) async {
    setState(() {
      if (fullLoad) {
        isLoading = true;
      } else {
        isRefreshing = true;
      }
      errorMessage = null;
    });

    // تأخير بسيط لمنح المستخدم إيحاء ببدء العملية خاصة عند تكرار "إعادة المحاولة"
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '/departments?page=1&perPage=10',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> data = responseData['data'] ?? [];
        final pagination = responseData['pagination'];

        if (mounted) {
          setState(() {
            _currentPage = 1;
            allDepartments = data.map((dept) => {
              'name': dept['name'] ?? '',
              'managerId': dept['managerId'],
            }).toList();
            filteredDepartments = allDepartments;
            _totalDepartments = pagination?['total'] ?? allDepartments.length;

            if (pagination != null && pagination['next'] != null) {
              _currentPage = pagination['next'];
              _hasMorePages = true;
            } else {
              _hasMorePages = false;
            }

            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
          errorMessage = AppErrorHandler.translateException(context, e);
        });
      }
      print('Error fetching departments: $e');
    } finally {
      if (mounted) {
        setState(() {
          isRefreshing = false;
          isLoading = false;
        });
      }
    }
  }

  // 📥 Load more departments (الصفحة التالية)
  Future<void> _loadMoreDepartments() async {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() => _isLoadingMore = true);

    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '/departments?page=$_currentPage&perPage=10',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> data = responseData['data'] ?? [];
        final pagination = responseData['pagination'];

        setState(() {
          final newDepartments = data.map((dept) => {
            'name': dept['name'] ?? '',
            'managerId': dept['managerId'],
          }).toList();
          allDepartments.addAll(newDepartments);
          _totalDepartments = pagination?['total'] ?? allDepartments.length;

          // لو مفيش بحث، حدّث القائمة المفلترة كلها
          if (searchController.text.isEmpty) {
            filteredDepartments = List.from(allDepartments);
          }

          if (pagination != null && pagination['next'] != null) {
            _currentPage = pagination['next'];
            _hasMorePages = true;
          } else {
            _hasMorePages = false;
          }

          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
      print('Error loading more departments: $e');
    }
  }

  Timer? _searchDebounce;

  // ✅ معالجة البحث مع Debounce لتحسين الأداء
  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchDepartments();
    });
  }

  // 🔍 البحث عن الأقسام (باستخدام الاسم أو ID المدير)
  Future<void> _searchDepartments() async {
    String query = searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        filteredDepartments = allDepartments;
      });
      return;
    }

    setState(() {
      isRefreshing = true;
    });

    try {
      final headers = await _getAuthHeaders();
      
      // ✅ التحقق إذا كان البحث برقم (Manager ID) أو نص (Department Name)
      String urlParams = 'page=1&perPage=20'; 
      if (RegExp(r'^\d+$').hasMatch(query)) {
        // إذا كان رقم، نبحث بـ managerId
        urlParams += '&managerId=$query';
      } else {
        // إذا كان نص، نبحث بـ name
        urlParams += '&name=${Uri.encodeComponent(query)}';
      }

      final response = await _dio.get(
        '/departments?$urlParams',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> data = responseData['data'] ?? [];
        
        setState(() {
          filteredDepartments = data.map((dept) => {
            'name': dept['name'] ?? '',
            'managerId': dept['managerId'],
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        filteredDepartments = [];
        isLoading = false;
        errorMessage = AppErrorHandler.translateException(context, e);
      });
      print('Search error: $e');
    }
  }

  // ➕ Add new department
  Future<void> addDepartment(String name, int? managerId) async {
    try {
      final Map<String, dynamic> data = {'name': name};
      if (managerId != null) {
        data['managerId'] = managerId;
      }
      
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        '/departments',
        data: data,
        options: Options(headers: headers),
      );

      if (response.statusCode == 201) {
        setState(() {
          allDepartments.add({
            'name': response.data['name'],
            'managerId': response.data['managerId'],
          });
          filteredDepartments = allDepartments;
        });
        
        fetchAllDepartments(fullLoad: false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('dept_added_success').replaceAll('{name}', name)),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      }
    } on DioException catch (e) {
      // استخراج الـ key من الـ response وترجمتها
      final body = e.response?.data;
      final rawBody = body is Map ? _dioBodyToJson(body) : body?.toString() ?? '';
      final errorMsg = AppErrorHandler.extractAndTranslate(
        context, rawBody,
        fallback: AppLocalizations.of(context)!.translate('dept_add_failed'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.accentRed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.translateException(context, e)),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  /// تحويل Map من Dio إلى JSON string لاستخدام AppErrorHandler
  String _dioBodyToJson(dynamic body) {
    if (body == null) return '';
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  // ✏️ Update department
  Future<void> updateDepartment(String oldName, String newName, int? managerId) async {
    try {
      final Map<String, dynamic> data = {};

      // إرسال الاسم بس لو اتغير
      if (newName != oldName) {
        data['name'] = newName;
      }
      
      // إضافة managerId (حتى لو null علشان يشيل الـ manager)
      if (managerId != null) {
        data['managerId'] = managerId;
      }

      if (data.isEmpty) {
        return; // مفيش تغييرات
      }
      
      final headers = await _getAuthHeaders();
      final response = await _dio.patch(
        '/departments/$oldName',
        data: data,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        setState(() {
          int index = allDepartments.indexWhere((dept) => dept['name'] == oldName);
          if (index != -1) {
            allDepartments[index] = {
              'name': response.data['name'],
              'managerId': response.data['managerId'],
            };
          }

          if (searchController.text.isEmpty) {
            filteredDepartments = List.from(allDepartments);
          } else {
            fetchAllDepartments(fullLoad: false);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('dept_updated_success')),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      }
    } on DioException catch (e) {
      final errorMsg = AppErrorHandler.extractAndTranslate(
        context, _dioBodyToJson(e.response?.data),
        fallback: AppLocalizations.of(context)!.translate('dept_update_failed'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.accentRed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('dept_update_failed')),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  // 🗑️ Delete department
  Future<void> deleteDepartment(String name) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.delete(
        '/departments/$name',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        setState(() {
          allDepartments.removeWhere((dept) => dept['name'] == name);
          filteredDepartments.removeWhere((dept) => dept['name'] == name);
        });

        fetchAllDepartments(fullLoad: false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('dept_deleted_success').replaceAll('{name}', name)),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      }
    } on DioException catch (e) {
      // استخراج الـ key الحقيقية من الباك أند
      // مثل: DEPARTMENT_HAS_MEMBERS, MISSING_ROLE, DEPARTMENT_NOT_FOUND
      final errorMsg = AppErrorHandler.extractAndTranslate(
        context, _dioBodyToJson(e.response?.data),
        fallback: AppLocalizations.of(context)!.translate('dept_delete_failed'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.accentRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('unknown_error')),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  // 🎨 Show add department dialog
  void _showAddDepartmentDialog() {
    TextEditingController nameController = TextEditingController();
    int? selectedManagerId;
    String? selectedManagerName;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('add_new_dept'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.translate('dept_name_label'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.business, color: AppColors.primary),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Manager Picker Field
                    GestureDetector(
                      onTap: () async {
                        final result = await _showUserPickerDialog(departmentName: nameController.text);
                        if (result != null) {
                          setDialogState(() {
                            selectedManagerId = result['id'];
                            selectedManagerName = result['name'];
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.translate('manager_optional'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.person, color: AppColors.primary),
                          suffixIcon: selectedManagerId != null
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedManagerId = null;
                                      selectedManagerName = null;
                                    });
                                  },
                                )
                              : Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          selectedManagerId != null
                              ? '$selectedManagerName  (ID: $selectedManagerId)'
                              : AppLocalizations.of(context)!.translate('tap_to_select_manager'),
                          style: TextStyle(
                            color: selectedManagerId != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (nameController.text.isNotEmpty) {
                                addDepartment(
                                  nameController.text,
                                  selectedManagerId,
                                );
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            label: Text(
                              AppLocalizations.of(context)!.translate('add'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: AppColors.primary, width: 1.5),
                              foregroundColor: AppColors.primary,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.translate('cancel'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🎨 Show edit department dialog
  void _showEditDepartmentDialog(Map<String, dynamic> department) {
    TextEditingController nameController = TextEditingController(text: department['name']);
    int? selectedManagerId = department['managerId'];
    String? selectedManagerName;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('edit_dept'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.translate('dept_name_label'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.business, color: AppColors.primary),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Manager Picker Field
                    GestureDetector(
                      onTap: () async {
                        final result = await _showUserPickerDialog(departmentName: nameController.text);
                        if (result != null) {
                          setDialogState(() {
                            selectedManagerId = result['id'];
                            selectedManagerName = result['name'];
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.translate('manager_optional'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.person, color: AppColors.primary),
                          suffixIcon: selectedManagerId != null
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedManagerId = null;
                                      selectedManagerName = null;
                                    });
                                  },
                                )
                              : Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          selectedManagerId != null
                              ? '${selectedManagerName ?? 'User'}  (ID: $selectedManagerId)'
                              : AppLocalizations.of(context)!.translate('tap_to_select_manager'),
                          style: TextStyle(
                            color: selectedManagerId != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              updateDepartment(
                                department['name'],
                                nameController.text,
                                selectedManagerId,
                              );
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            label: Text(
                              AppLocalizations.of(context)!.translate('save_changes'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: AppColors.primary, width: 1.5),
                              foregroundColor: AppColors.primary,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.locale.languageCode == 'ar' ? 'إلغاء' : 'Cancel',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 👤 User Picker Dialog - بحث حقيقي عبر الـ API
  Future<Map<String, dynamic>?> _showUserPickerDialog({String? departmentName}) async {
    List<Map<String, dynamic>> users = [];
    bool isLoadingUsers = true;
    bool isLoadingMoreUsers = false;
    bool hasMoreUsers = true;
    int usersPage = 1;
    String currentSearchQuery = '';
    TextEditingController searchCtrl = TextEditingController();
    Timer? _searchDebounce;

    bool initialLoadCalled = false;

    // ✅ جلب صفحة من المستخدمين (مع دعم البحث بالـ name)
    Future<void> fetchUsersPage(
      int page,
      void Function(void Function()) setPickerState, {
      String searchQuery = '',
      bool reset = false,
    }) async {
      try {
        final headers = await _getAuthHeaders();

        // ✅ استخدام الـ endpoint المخصص للبحث بالاسم
        String endpoint = '/users?page=$page&perPage=10';
        if (searchQuery.isNotEmpty) {
          endpoint += '&name=${Uri.encodeComponent(searchQuery)}';
        }
        if (departmentName != null && departmentName.isNotEmpty) {
          endpoint += '&department=${Uri.encodeComponent(departmentName)}';
        }

        final response = await _dio.get(
          endpoint,
          options: Options(headers: headers),
        );

        if (response.statusCode == 200) {
          final responseData = response.data;
          List<dynamic> data = [];
          Map<String, dynamic>? pagination;

          if (responseData is Map) {
            data = responseData['data'] ?? [];
            pagination = responseData['pagination'];
          } else if (responseData is List) {
            data = responseData;
          }

          final newUsers = data.map<Map<String, dynamic>>((u) => {
            'id': u['id'],
            'name': u['name'] ?? 'Unknown',
          }).toList();

          setPickerState(() {
            if (reset) {
              users = newUsers; // امسح القديم لو بحث جديد
            } else {
              users.addAll(newUsers); // أضف للقائمة (infinite scroll)
            }
            usersPage = pagination?['currentPage'] ?? page;
            hasMoreUsers = pagination?['next'] != null;
            isLoadingUsers = false;
            isLoadingMoreUsers = false;
          });
        } else {
          setPickerState(() {
            isLoadingUsers = false;
            isLoadingMoreUsers = false;
            hasMoreUsers = false;
          });
        }
      } catch (e) {
        setPickerState(() {
          isLoadingUsers = false;
          isLoadingMoreUsers = false;
          hasMoreUsers = false;
        });
      }
    }

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            // جلب المستخدمين أول مرة فقط
            if (!initialLoadCalled) {
              initialLoadCalled = true;
              fetchUsersPage(1, setPickerState, reset: true);
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.person_search, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context)!.translate('select_manager'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // ✅ Search bar — بيعمل API call بالـ name
                    TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.translate('search_user_name_id'),
                        prefixIcon: Icon(Icons.search, size: 20),
                        suffixIcon: isLoadingUsers && users.isNotEmpty
                            ? Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (query) {
                        // debounce 400ms عشان ما نضغطش على السيرفر
                        _searchDebounce?.cancel();
                        _searchDebounce =
                            Timer(const Duration(milliseconds: 400), () {
                          currentSearchQuery = query.trim();
                          setPickerState(() {
                            isLoadingUsers = true;
                            // users = []; // لا نمسح القائمة هنا لتجنب القفز في الـ UI، الـ reset في fetch سيقوم بالمهمة
                            hasMoreUsers = false;
                          });
                          // ✅ API call بالـ name parameter
                          fetchUsersPage(
                            1,
                            setPickerState,
                            searchQuery: currentSearchQuery,
                            reset: true,
                          );
                        });
                      },
                    ),
                    SizedBox(height: 12),

                    // List
                    Expanded(
                      child: isLoadingUsers && users.isEmpty
                          ? Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            )
                          : users.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: Text(
                                          (departmentName != null && departmentName.isNotEmpty)
                                              ? (AppLocalizations.of(context)!.locale.languageCode == 'ar'
                                                  ? "لم يتم العثور على مستخدمين لهذا القسم، يرجى إضافة مستخدمين للقسم أولاً"
                                                  : "No users found for this department, please add users to the department first")
                                              : AppLocalizations.of(context)!.translate('no_users_found'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    )
                              : NotificationListener<ScrollNotification>(
                                  onNotification: (scrollInfo) {
                                    // Infinite scroll (يعمل في البحث والعادي)
                                    if (scrollInfo.metrics.pixels >=
                                            scrollInfo.metrics.maxScrollExtent - 100 &&
                                        !isLoadingMoreUsers &&
                                        hasMoreUsers) {
                                      setPickerState(() => isLoadingMoreUsers = true);
                                      fetchUsersPage(
                                        usersPage + 1,
                                        setPickerState,
                                        searchQuery: currentSearchQuery,
                                        reset: false,
                                      );
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                    itemCount: users.length +
                                        (hasMoreUsers && currentSearchQuery.isEmpty ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      // Loading indicator في الأسفل
                                      if (index >= users.length) {
                                        return Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Center(
                                            child: isLoadingMoreUsers
                                                ? SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      color: AppColors.primary,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : Text(
                                                    AppLocalizations.of(context)!
                                                        .translate('scroll_for_more'),
                                                    style: TextStyle(
                                                      color: AppColors.textMuted,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                          ),
                                        );
                                      }

                                      final user = users[index];
                                      return ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              AppColors.primary.withOpacity(0.1),
                                          child: Text(
                                            user['name'].toString().isNotEmpty
                                                ? user['name'].toString()[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          user['name'],
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        subtitle: Text(
                                          'ID: ${user['id']}',
                                          style: TextStyle(
                                              fontSize: 11, color: AppColors.textMuted),
                                        ),
                                        onTap: () => Navigator.pop(context, user),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  // 🎨 Confirm delete
  void _confirmDelete(Map<String, dynamic> department) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.accentRed, size: 28),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.translate('confirm_delete_title'), style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('confirm_delete_dept'),
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              '"${department['name']}"',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.accentRed, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.translate('delete_note_users'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accentRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteDepartment(department['name']);
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.bodyBg,
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)!.translate('departments_management'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.isDark
                      ? [AppColors.headerGradientStart, AppColors.headerGradientEnd]
                      : [AppColors.primary, AppColors.primaryHover],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: () => fetchAllDepartments(fullLoad: false),
                tooltip: AppLocalizations.of(context)!.translate('refresh'),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
              // 🔍 Search Bar
              Container(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.statShadow,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.translate('search_dept_hint'),
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textMuted),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            filteredDepartments = allDepartments;
                          });
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
    
              // 📊 Stats Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.statBgLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.statBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.corporate_fare, size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.translate('total_departments').replaceAll('{count}', '$_totalDepartments'),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    
              SizedBox(height: 16),
    
              // 📱 Departments Grid
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : errorMessage != null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.accentRed,
                      ),
                      SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: fetchAllDepartments,
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        label: Text(
                          AppLocalizations.of(context)!.translate('retry'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    : filteredDepartments.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_center,
                        size: 64,
                        color: AppColors.textMuted.withOpacity(0.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        searchController.text.isEmpty
                            ? AppLocalizations.of(context)!.translate('no_depts_found')
                            : AppLocalizations.of(context)!.translate('no_search_results'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: fetchAllDepartments,
                        icon: const Icon(Icons.sync, color: Colors.white, size: 20),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: Text(
                          AppLocalizations.of(context)!.locale.languageCode == 'ar' ? 'إعادة تحميل' : 'Reload',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          double width = constraints.maxWidth;
                          bool isSmallMobile = width < 360;
                          int crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);
                          
                          // Calculate aspect ratio based on width to ensure content fits
                          double childAspectRatio = width > 600 ? 1.1 : (isSmallMobile ? 0.72 : 0.85);
    
                          return GridView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(isSmallMobile ? 12 : 24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: childAspectRatio,
                              crossAxisSpacing: isSmallMobile ? 12 : 16,
                              mainAxisSpacing: isSmallMobile ? 12 : 16,
                            ),
                            itemCount: filteredDepartments.length + (_hasMorePages && searchController.text.isEmpty ? 1 : 0),
                            itemBuilder: (context, index) {
                              // عنصر اللودينج في الآخر
                              if (index == filteredDepartments.length) {
                                return Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              final dept = filteredDepartments[index];
                              return DepartmentCard(
                                department: dept,
                                onEdit: () => _showEditDepartmentDialog(dept),
                                onDelete: () => _confirmDelete(dept),
                              );
                            },
                          );
                        },
                      ),
                ),
              ],
            ),
            if (isRefreshing)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: FloatingActionButton(
                      heroTag: 'dept_add_btn',
                      onPressed: _showAddDepartmentDialog,
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                if (_showBackToTop)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FloatingActionButton(
                      heroTag: 'dept_scroll_top',
                      mini: true,
                      onPressed: _scrollToTop,
                      backgroundColor: AppColors.primary.withOpacity(0.8),
                      child: Icon(Icons.arrow_upward, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 🃏 Department Card Widget
class DepartmentCard extends StatelessWidget {
  final Map<String, dynamic> department;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DepartmentCard({
    Key? key,
    required this.department,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.statShadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: EdgeInsets.all(isMobile ? 10 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Department Icon
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.business,
                    color: AppColors.primary,
                    size: isMobile ? 24 : 32,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 16),
                // Department Name
                Text(
                  department['name'] ?? AppLocalizations.of(context)!.translate('untitled_dept'),
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 18, // زيادة الخط للديسكتوب
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 4 : 8),
                // Manager ID
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: isMobile ? 12 : 14,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        department['managerId'] != null 
                            ? AppLocalizations.of(context)!.translate('manager_id_label').replaceAll('{id}', '${department['managerId']}')
                            : AppLocalizations.of(context)!.translate('no_manager_assigned'),
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Three dots menu
          PositionedDirectional(
            top: 12,
            end: 12,
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: AppColors.textMuted,
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppColors.accentBlue, size: 20),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.translate('edit')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppColors.accentRed, size: 20),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.translate('delete')),
                    ],
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