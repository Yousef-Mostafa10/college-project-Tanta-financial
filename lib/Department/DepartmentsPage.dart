import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';
import '../l10n/app_localizations.dart';

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
  String? errorMessage;

  // Pagination
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  int _totalDepartments = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchAllDepartments();
    searchController.addListener(_searchDepartments);

    // Scroll listener للتحميل التدريجي
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMorePages &&
          searchController.text.isEmpty) {
        _loadMoreDepartments();
      }
    });
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
  Future<void> fetchAllDepartments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      _currentPage = 1;
      _hasMorePages = true;
      allDepartments = [];
    });

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
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = AppLocalizations.of(context)!.translate('failed_load_depts');
      });
      print('Error fetching departments: $e');
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

  // 🔍 Search for a specific department
  Future<void> _searchDepartments() async {
    String query = searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        filteredDepartments = allDepartments;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '/departments/$query',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        setState(() {
          Map<String, dynamic> dept = response.data;
          filteredDepartments = [{
            'name': dept['name'] ?? '',
            'managerId': dept['managerId'],
          }];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        filteredDepartments = [];
        isLoading = false;
      });
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('dept_added_success').replaceAll('{name}', name)),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('dept_add_failed')),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
      print('Error adding department: $e');
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
            _searchDepartments();
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.translate('dept_update_failed')}: ${e.toString()}'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
      print('Error updating department: $e');
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('dept_deleted_success').replaceAll('{name}', name)),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      }
    } on DioException catch (e) {
      String statusErrorMessage = AppLocalizations.of(context)!.translate('dept_delete_failed');
      
      if (e.response != null) {
        if (e.response!.statusCode == 500) {
          statusErrorMessage = AppLocalizations.of(context)!.translate('delete_associated_error');
        } else if (e.response!.statusCode == 403) {
          statusErrorMessage = AppLocalizations.of(context)!.translate('permission_error');
        } else if (e.response!.statusCode == 404) {
          statusErrorMessage = AppLocalizations.of(context)!.translate('user_not_found'); // Assuming user/dept sharing same key or just 'not found'
        } else {
          statusErrorMessage = 'Server error (${e.response!.statusCode})';
        }
      } else {
        statusErrorMessage = '${AppLocalizations.of(context)!.translate('connection_error')}: ${e.message}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statusErrorMessage),
            backgroundColor: AppColors.accentRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      print('Error deleting department: $e');
      print('Response: ${e.response?.data}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.translate('unknown_error')}: ${e.toString()}'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
      print('Error deleting department: $e');
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
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('add_new_dept'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.translate('dept_name_label'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.business, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Manager Picker Field
                    GestureDetector(
                      onTap: () async {
                        final result = await _showUserPickerDialog();
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
                          prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                          suffixIcon: selectedManagerId != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedManagerId = null;
                                      selectedManagerName = null;
                                    });
                                  },
                                )
                              : const Icon(Icons.arrow_drop_down),
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (nameController.text.isNotEmpty) {
                                addDepartment(
                                  nameController.text,
                                  selectedManagerId,
                                );
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(AppLocalizations.of(context)!.translate('add'), style: const TextStyle(color: Colors.black)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: const BorderSide(color: AppColors.textMuted),
                            ),
                            child: Text(AppLocalizations.of(context)!.translate('cancel')),
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
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('edit_dept'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.translate('dept_name_label'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.business, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Manager Picker Field
                    GestureDetector(
                      onTap: () async {
                        final result = await _showUserPickerDialog();
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
                          prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                          suffixIcon: selectedManagerId != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedManagerId = null;
                                      selectedManagerName = null;
                                    });
                                  },
                                )
                              : const Icon(Icons.arrow_drop_down),
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              updateDepartment(
                                department['name'],
                                nameController.text,
                                selectedManagerId,
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(AppLocalizations.of(context)!.translate('save_changes')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: const BorderSide(color: AppColors.textMuted),
                            ),
                            child: const Text('Cancel'),
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

  // 👤 User Picker Dialog - قائمة بسيطة لاختيار رئيس القسم
  Future<Map<String, dynamic>?> _showUserPickerDialog() async {
    List<Map<String, dynamic>> users = [];
    List<Map<String, dynamic>> filteredUsers = [];
    bool isLoadingUsers = true;
    bool isLoadingMoreUsers = false;
    bool hasMoreUsers = true;
    int usersPage = 1;
    String currentSearchQuery = '';
    TextEditingController searchCtrl = TextEditingController();

    // دالة لجلب صفحة من المستخدمين
    Future<void> fetchUsersPage(int page, void Function(void Function()) setPickerState) async {
      try {
        final headers = await _getAuthHeaders();
        final response = await _dio.get(
          '/users?page=$page&perPage=10',
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
            users.addAll(newUsers);
            usersPage = pagination?['currentPage'] ?? page;
            hasMoreUsers = pagination?['next'] != null;
            isLoadingUsers = false;
            isLoadingMoreUsers = false;
            // تطبيق الفلتر الحالي
            if (currentSearchQuery.isEmpty) {
              filteredUsers = List.from(users);
            } else {
              final q = currentSearchQuery.toLowerCase();
              filteredUsers = users.where((u) {
                return u['name'].toString().toLowerCase().contains(q) ||
                    u['id'].toString().contains(q);
              }).toList();
            }
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
            // جلب المستخدمين أول مرة
            if (isLoadingUsers && users.isEmpty) {
              fetchUsersPage(1, setPickerState);
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 400,
                height: 500,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.person_search, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context)!.translate('select_manager'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search
                    TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.translate('search_user_name_id'),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (query) {
                        setPickerState(() {
                          currentSearchQuery = query;
                          if (query.isEmpty) {
                            filteredUsers = List.from(users);
                          } else {
                            final q = query.toLowerCase();
                            filteredUsers = users.where((u) {
                              return u['name'].toString().toLowerCase().contains(q) ||
                                     u['id'].toString().contains(q);
                            }).toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // List
                    Expanded(
                      child: isLoadingUsers
                          ? const Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            )
                          : filteredUsers.isEmpty
                              ? Center(
                                  child: Text(AppLocalizations.of(context)!.translate('no_users_found'), style: const TextStyle(color: AppColors.textMuted)),
                                )
                              : NotificationListener<ScrollNotification>(
                                  onNotification: (scrollInfo) {
                                    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100 &&
                                        !isLoadingMoreUsers && hasMoreUsers && currentSearchQuery.isEmpty) {
                                      isLoadingMoreUsers = true;
                                      fetchUsersPage(usersPage + 1, setPickerState);
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                    itemCount: filteredUsers.length + (hasMoreUsers && currentSearchQuery.isEmpty ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      // عنصر تحميل المزيد
                                      if (index >= filteredUsers.length) {
                                        return Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Center(
                                            child: isLoadingMoreUsers
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      color: AppColors.primary,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : Text(
                                                    AppLocalizations.of(context)!.translate('scroll_for_more'),
                                                    style: const TextStyle(
                                                      color: AppColors.textMuted,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                          ),
                                        );
                                      }

                                      final user = filteredUsers[index];
                                      return ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.primary.withOpacity(0.1),
                                          child: Text(
                                            '${user['id']}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          user['name'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        subtitle: Text(
                                          'ID: ${user['id']}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
            Text(AppLocalizations.of(context)!.translate('confirm_delete_title'), style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('confirm_delete_dept'),
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                      style: const TextStyle(
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
    return Scaffold(
      backgroundColor: AppColors.bodyBg,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('departments_management'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.sidebarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // 👈 Back arrow
          onPressed: () {
            Navigator.pop(context); // 👈 Go back to previous page
          },
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Container(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.statShadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate('search_dept_hint'),
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textMuted),
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
                      const Icon(Icons.corporate_fare, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.translate('total_departments').replaceAll('{count}', '$_totalDepartments'),
                        style: const TextStyle(
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

          const SizedBox(height: 16),

          // 📱 Departments Grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.accentRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchAllDepartments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text(AppLocalizations.of(context)!.translate('retry')),
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
                  const SizedBox(height: 16),
                  Text(
                    searchController.text.isEmpty
                        ? AppLocalizations.of(context)!.translate('no_depts_found')
                        : AppLocalizations.of(context)!.translate('no_search_results'),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
                : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: filteredDepartments.length + (_hasMorePages && searchController.text.isEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                // عنصر اللودينج في الآخر
                if (index == filteredDepartments.length) {
                  return const Center(
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDepartmentDialog,
        backgroundColor: AppColors.accentYellow,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.statShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Department Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                // Department Name
                Text(
                  department['name'] ?? AppLocalizations.of(context)!.translate('untitled_dept'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Manager ID
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        department['managerId'] != null 
                            ? AppLocalizations.of(context)!.translate('manager_id_label').replaceAll('{id}', '${department['managerId']}')
                            : AppLocalizations.of(context)!.translate('no_manager_assigned'),
                        style: const TextStyle(
                          fontSize: 13,
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
          Positioned(
            top: 12,
            right: 12,
            child: PopupMenuButton<String>(
              icon: const Icon(
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
                      const Icon(Icons.edit, color: AppColors.accentBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.translate('edit')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: AppColors.accentRed, size: 20),
                      const SizedBox(width: 8),
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

// 🎨 Colors Class
class AppColors {
  static const Color primary = Color(0xFF00695C);
  static const Color primaryLight = Color(0xFF00796B);
  static const Color sidebarBg = Color(0xFF0E6C62);
  static const Color sidebarText = Color(0xFFFFFFFF);
  static const Color sidebarHover = Color(0xFF07584F);
  static const Color bodyBg = Color(0xFFF5F6FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textMuted = Color(0xFFB0B0B0);
  static const Color accentYellow = Color(0xFFFFB74D);
  static const Color accentRed = Color(0xFFE74C3C);
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color statusApproved = Color(0xFF27AE60);
  static const Color statusRejected = Color(0xFFE74C3C);
  static const Color statusWaiting = Color(0xFF1E88E5);
  static const Color statusNeedsChange = Color(0xFFFFB74D);
  static const Color statusFulfilled = Color(0xFF009688);
  static const Color statBgLight = Color(0xFFF0F8F7);
  static const Color statBorder = Color(0xFFB2DFDB);
  static const Color statShadow = Color(0x1A00695C);
}