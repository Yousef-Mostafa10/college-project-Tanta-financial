import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';
import '../l10n/app_localizations.dart';
import '../core/app_colors.dart';
import '../utils/app_error_handler.dart';
import 'BudgetEntriesPage.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({Key? key}) : super(key: key);

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    headers: {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  List<Map<String, dynamic>> allCategories = [];
  List<Map<String, dynamic>> filteredCategories = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  bool isRefreshing = false;
  String? errorMessage;

  // Pagination
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  int _totalCategories = 0;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  // Search debounce
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    fetchAllCategories();

    searchController.addListener(_onSearchChanged);

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
        _loadMoreCategories();
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
    _searchDebounce?.cancel();
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

  // 📥 Fetch all categories (page 1)
  Future<void> fetchAllCategories({bool fullLoad = true}) async {
    setState(() {
      if (fullLoad) {
        isLoading = true;
      } else {
        isRefreshing = true;
      }
      errorMessage = null;
    });

    // تأخير بسيط لإعطاء إيحاء بالتحديث البصري
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '/budget-categories?page=1&perPage=10',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        List<dynamic> data;
        Map<String, dynamic>? pagination;

        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map) {
          data = responseData['data'] ?? [];
          pagination = responseData['pagination'];
        } else {
          data = [];
        }

        if (mounted) {
          setState(() {
            _currentPage = 1;
            allCategories = data.map((c) => _mapCategory(c)).toList();
            filteredCategories = allCategories;
            _totalCategories = pagination != null
                ? ((pagination['total'] as num?)?.toInt() ?? allCategories.length)
                : allCategories.length;

            if (pagination != null && pagination['next'] != null) {
              _currentPage = (pagination['next'] as num).toInt();
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
      debugPrint('Error fetching budget categories: $e');
    } finally {
      if (mounted) {
        setState(() {
          isRefreshing = false;
          isLoading = false;
        });
      }
    }
  }

  // 📥 Load more categories (next page)
  Future<void> _loadMoreCategories() async {
    if (_isLoadingMore || !_hasMorePages) return;
    setState(() => _isLoadingMore = true);

    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '/budget-categories?page=$_currentPage&perPage=10',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        List<dynamic> data;
        Map<String, dynamic>? pagination;

        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map) {
          data = responseData['data'] ?? [];
          pagination = responseData['pagination'];
        } else {
          data = [];
        }

        setState(() {
          allCategories.addAll(data.map((c) => _mapCategory(c)).toList());
          _totalCategories = pagination != null
              ? ((pagination['total'] as num?)?.toInt() ?? allCategories.length)
              : allCategories.length;

          if (searchController.text.isEmpty) {
            filteredCategories = List.from(allCategories);
          }

          if (pagination != null && pagination['next'] != null) {
            _currentPage = (pagination['next'] as num).toInt();
            _hasMorePages = true;
          } else {
            _hasMorePages = false;
          }

          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
      debugPrint('Error loading more categories: $e');
    }
  }

  // 🗺️ Map API response to local format
  Map<String, dynamic> _mapCategory(dynamic c) {
    return {
      'name': c['name']?.toString() ?? '',
      'budget': (c['budget'] as num?)?.toInt() ?? 0,
      'allocated': (c['allocated'] as num?)?.toInt() ?? 0,
      'available': (c['available'] as num?)?.toInt() ?? 0,
    };
  }

  // 🔍 Triggered on search text change (with debounce)
  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchCategories(searchController.text.trim());
    });
  }

  // 🔍 Search categories via API
  Future<void> _searchCategories(String query) async {
    if (query.isEmpty) {
      setState(() {
        filteredCategories = allCategories;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '/budget-categories?page=1&perPage=10&name=${Uri.encodeComponent(query)}',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> data = responseData['data'] ?? [];
        setState(() {
          filteredCategories = data.map((c) => _mapCategory(c)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        filteredCategories = [];
        isLoading = false;
      });
    }
  }

  // ➕ Add new budget category
  Future<void> _addCategory(String name) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        '/budget-categories/${Uri.encodeComponent(name)}',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newCat = _mapCategory(response.data);
        setState(() {
          allCategories.add(newCat);
          if (searchController.text.isEmpty) {
            filteredCategories = List.from(allCategories);
          }
          _totalCategories++;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('budget_added_success').replaceAll('{name}', name)),
              backgroundColor: BudgetColors.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // استخراج الـ key من DioException أو Exception
        final errMsg = (e is DioException)
          ? AppErrorHandler.extractAndTranslate(
              context, _dioBodyToJson(e.response?.data),
              fallback: AppLocalizations.of(context)!.translate('budget_add_failed'),
            )
          : AppLocalizations.of(context)!.translate('budget_add_failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: BudgetColors.accentRed),
        );
      }
    }
  }

  // ✏️ Rename budget category
  Future<void> _renameCategory(String oldName, String newName) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.patch(
        '/budget-categories/${Uri.encodeComponent(oldName)}',
        data: {'name': newName},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final updated = _mapCategory(response.data);
        setState(() {
          final allIdx = allCategories.indexWhere((c) => c['name'] == oldName);
          if (allIdx != -1) allCategories[allIdx] = updated;

          final filtIdx = filteredCategories.indexWhere((c) => c['name'] == oldName);
          if (filtIdx != -1) filteredCategories[filtIdx] = updated;
        });

        fetchAllCategories(fullLoad: false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('budget_rename_success').replaceAll('{name}', newName)),
              backgroundColor: BudgetColors.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errMsg = (e is DioException)
          ? AppErrorHandler.extractAndTranslate(
              context, _dioBodyToJson(e.response?.data),
              fallback: AppLocalizations.of(context)!.translate('budget_rename_failed').replaceAll('{error}', ''),
            )
          : AppLocalizations.of(context)!.translate('budget_rename_failed').replaceAll('{error}', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: BudgetColors.accentRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ✏️ Show rename dialog
  void _showRenameCategoryDialog(Map<String, dynamic> category) {
    final nameController =
        TextEditingController(text: category['name']);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BudgetColors.accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit,
                        color: BudgetColors.accentBlue, size: 22),
                  ),
                  SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.translate('edit_category_name'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BudgetColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate('new_name_label'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.account_balance_wallet,
                      color: BudgetColors.primary),
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final newName = nameController.text.trim();
                        if (newName.isNotEmpty &&
                            newName != category['name']) {
                          _renameCategory(category['name'], newName);
                          Navigator.pop(context);
                        } else if (newName == category['name']) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BudgetColors.primary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(AppLocalizations.of(context)!.translate('save_button'),
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(
                            color: BudgetColors.textMuted),
                      ),
                      child: Text(AppLocalizations.of(context)!.translate('cancel_button')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🗑️ Delete budget category
  Future<void> _deleteCategory(String name) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.delete(
        '/budget-categories/${Uri.encodeComponent(name)}',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          allCategories.removeWhere((c) => c['name'] == name);
          filteredCategories.removeWhere((c) => c['name'] == name);
          _totalCategories = (_totalCategories - 1).clamp(0, _totalCategories);
        });

        fetchAllCategories(fullLoad: false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('budget_delete_success').replaceAll('{name}', name)),
              backgroundColor: BudgetColors.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errMsg = (e is DioException)
          ? AppErrorHandler.extractAndTranslate(
              context, _dioBodyToJson(e.response?.data),
              fallback: AppLocalizations.of(context)!.translate('budget_delete_failed').replaceAll('{error}', ''),
            )
          : AppLocalizations.of(context)!.translate('budget_delete_failed').replaceAll('{error}', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: BudgetColors.accentRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // 💰 Add budget entry (deposit amount)
  Future<void> _addEntry(String categoryName, int amount) async {
    try {
      final headers = await _getAuthHeaders();
      await _dio.post(
        '/budget-categories/${Uri.encodeComponent(categoryName)}/entry',
        data: {'amount': amount},
        options: Options(headers: headers),
      );
      // Refresh that single category to reflect new budget values
      await _refreshSingleCategory(categoryName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('amount_added_success')
              .replaceAll('{amount}', _formatNumber(amount))
              .replaceAll('{name}', categoryName)),
            backgroundColor: BudgetColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errMsg = (e is DioException)
          ? AppErrorHandler.extractAndTranslate(
              context, _dioBodyToJson(e.response?.data),
              fallback: AppLocalizations.of(context)!.translate('add_amount_failed').replaceAll('{error}', ''),
            )
          : AppLocalizations.of(context)!.translate('add_amount_failed').replaceAll('{error}', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: BudgetColors.accentRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// تحويل response body من Dio إلى JSON string لاستخدام AppErrorHandler
  String _dioBodyToJson(dynamic body) {
    if (body == null) return '';
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  // 🔄 Refresh a single category from API
  Future<void> _refreshSingleCategory(String name) async {
    try {
      final headers = await _getAuthHeaders();
      // Re-fetch list filtered by name to get updated values
      final response = await _dio.get(
        '/budget-categories?page=1&perPage=10&name=${Uri.encodeComponent(name)}',
        options: Options(headers: headers),
      );
      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> data = responseData is List
            ? responseData
            : (responseData['data'] ?? []);
        if (data.isNotEmpty) {
          final updated = _mapCategory(data.first);
          setState(() {
            final allIdx = allCategories.indexWhere((c) => c['name'] == name);
            if (allIdx != -1) allCategories[allIdx] = updated;
            final filtIdx = filteredCategories.indexWhere((c) => c['name'] == name);
            if (filtIdx != -1) filteredCategories[filtIdx] = updated;
          });
        }
      }
    } catch (e) {
      debugPrint('Error refreshing category: $e');
    }
  }

  // 🔢 Format number with commas
  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('add_new_category'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: BudgetColors.textPrimary,
                ),
              ),
              SizedBox(height: 24),
              // Name field (required)
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate('category_name_label'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.account_balance_wallet,
                      color: BudgetColors.primary),
                ),
              ),
              SizedBox(height: 16),
              // Amount field (optional)
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate('initial_amount_label'),
                  hintText: AppLocalizations.of(context)!.translate('initial_amount_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.monetization_on_outlined,
                      color: BudgetColors.accentGreen),
                  suffixText: AppLocalizations.of(context)!.translate('currency_unit'),
                ),
              ),
              SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.translate('add_auto_note'),
                style: TextStyle(fontSize: 11, color: BudgetColors.textMuted),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          Navigator.pop(context);
                          await _addCategory(name);
                          final amount =
                              int.tryParse(amountController.text.trim());
                          if (amount != null && amount > 0) {
                            await _addEntry(name, amount);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BudgetColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(AppLocalizations.of(context)!.translate('add_button'),
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(color: BudgetColors.textMuted),
                      ),
                      child: Text(AppLocalizations.of(context)!.translate('cancel_button')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 💰 Show add entry dialog (for existing category)
  void _showAddEntryDialog(Map<String, dynamic> category) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BudgetColors.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_card,
                        color: BudgetColors.accentGreen, size: 22),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('add_amount_title'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BudgetColors.textPrimary,
                          ),
                        ),
                        Text(
                          '"${category['name']}"',
                          style: TextStyle(
                            fontSize: 13,
                            color: BudgetColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate('amount_label'),
                  hintText: AppLocalizations.of(context)!.translate('initial_amount_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.monetization_on_outlined,
                      color: BudgetColors.accentGreen),
                  suffixText: AppLocalizations.of(context)!.translate('currency_unit'),
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final amount =
                            int.tryParse(amountController.text.trim());
                        if (amount != null && amount > 0) {
                          Navigator.pop(context);
                          _addEntry(category['name'], amount);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BudgetColors.accentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(AppLocalizations.of(context)!.translate('add_button'),
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side:
                            BorderSide(color: BudgetColors.textMuted),
                      ),
                      child: Text(AppLocalizations.of(context)!.translate('cancel_button')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🗑️ Confirm delete dialog
  void _confirmDelete(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: BudgetColors.accentRed, size: 28),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.translate('delete_confirm_title'),
                style: TextStyle(color: BudgetColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('delete_confirm_msg'),
              style:
                  TextStyle(fontSize: 14, color: BudgetColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              '"${category['name']}"',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BudgetColors.primary,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BudgetColors.accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: BudgetColors.accentRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: BudgetColors.accentRed, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.translate('delete_request_confirm'),
                      style: TextStyle(
                          fontSize: 12, color: BudgetColors.accentRed),
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
            child: Text(AppLocalizations.of(context)!.translate('cancel_button')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category['name']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BudgetColors.accentRed,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.translate('delete_button')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BudgetColors.bodyBg,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('budget_management'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: BudgetColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => fetchAllCategories(fullLoad: false),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: BudgetColors.statShadow,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate('search_budget_hint'),
                  hintStyle: TextStyle(color: BudgetColors.textMuted),
                  prefixIcon:
                      Icon(Icons.search, color: BudgetColors.primary),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: BudgetColors.textMuted),
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              filteredCategories = allCategories;
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: BudgetColors.statBgLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: BudgetColors.statBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          size: 16, color: BudgetColors.primary),
                      SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.translate('total_categories_stat').replaceAll('{count}', '$_totalCategories'),
                        style: TextStyle(
                          color: BudgetColors.primary,
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

          // 📱 Categories Grid
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: BudgetColors.primary))
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: BudgetColors.accentRed),
                            SizedBox(height: 16),
                            Text(errorMessage!,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: BudgetColors.textMuted)),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchAllCategories,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: BudgetColors.primary),
                              child: Text(AppLocalizations.of(context)!.translate('retry_button'), style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : filteredCategories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 64,
                                  color:
                                      BudgetColors.textMuted.withOpacity(0.5),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  searchController.text.isEmpty
                                      ? AppLocalizations.of(context)!.translate('no_requests_found')
                                      : AppLocalizations.of(context)!.translate('no_search_results'),
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: BudgetColors.textMuted),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final double width = constraints.maxWidth;
                              final bool isSmallMobile = width < 360;
                              final int crossAxisCount = width > 900
                                  ? 4
                                  : (width > 600 ? 3 : 2);
                              final double childAspectRatio = width > 600
                                  ? 1.0
                                  : (isSmallMobile ? 0.72 : 0.75);

                              return GridView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.all(
                                    isSmallMobile ? 12 : 24),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: childAspectRatio,
                                  crossAxisSpacing:
                                      isSmallMobile ? 12 : 16,
                                  mainAxisSpacing:
                                      isSmallMobile ? 12 : 16,
                                ),
                                itemCount: filteredCategories.length +
                                    (_hasMorePages &&
                                            searchController.text.isEmpty
                                        ? 1
                                        : 0),
                                itemBuilder: (context, index) {
                                  if (index == filteredCategories.length) {
                                    return Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(
                                          color: BudgetColors.primary,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }
                                  final cat = filteredCategories[index];
                                  return BudgetCategoryCard(
                                    category: cat,
                                    onEdit: () => _showRenameCategoryDialog(cat),
                                    onAddEntry: () => _showAddEntryDialog(cat),
                                    onDelete: () => _confirmDelete(cat),
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
                  heroTag: 'budget_add_btn',
                  onPressed: _showAddCategoryDialog,
                  backgroundColor: BudgetColors.primary,
                  child: Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
            if (_showBackToTop)
              Align(
                alignment: Alignment.bottomCenter,
                child: FloatingActionButton(
                  heroTag: 'budget_scroll_top',
                  mini: true,
                  onPressed: _scrollToTop,
                  backgroundColor: BudgetColors.primary.withOpacity(0.8),
                  child: Icon(Icons.arrow_upward, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 🃏 Budget Category Card Widget
// ─────────────────────────────────────────────
class BudgetCategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onEdit;
  final VoidCallback onAddEntry;
  final VoidCallback onDelete;

  const BudgetCategoryCard({
    Key? key,
    required this.category,
    required this.onEdit,
    required this.onAddEntry,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;

    final int budget = (category['budget'] as num?)?.toInt() ?? 0;
    final int allocated = (category['allocated'] as num?)?.toInt() ?? 0;
    final int available = (category['available'] as num?)?.toInt() ?? 0;

    // Progress ratio for allocated vs budget
    final double ratio =
        budget > 0 ? (allocated / budget).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: BudgetColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: BudgetColors.statShadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content — ClipRect silently clips any marginal overflow (no more exception)
          ClipRect(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(isMobile ? 7 : 10),
                    decoration: BoxDecoration(
                      color: BudgetColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: BudgetColors.primary,
                      size: isMobile ? 18 : 28,
                    ),
                  ),
                  SizedBox(height: isMobile ? 6 : 12),

                  // Category Name
                  Text(
                    category['name'] ?? AppLocalizations.of(context)!.translate('untitled'),
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 17, // زيادة الخط للديسكتوب
                      fontWeight: FontWeight.bold,
                      color: BudgetColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 4 : 8),

                  // Budget info rows
                  _InfoRow(
                    label: AppLocalizations.of(context)!.translate('total_budget'),
                    value: '$budget',
                    icon: Icons.monetization_on_outlined,
                    color: BudgetColors.primary,
                    isMobile: isMobile,
                  ),
                  _InfoRow(
                    label: AppLocalizations.of(context)!.translate('allocated_amount'),
                    value: '$allocated',
                    icon: Icons.trending_up,
                    color: BudgetColors.accentYellow,
                    isMobile: isMobile,
                  ),
                  _InfoRow(
                    label: AppLocalizations.of(context)!.translate('available_balance'),
                    value: '$available',
                    icon: Icons.check_circle_outline,
                    color: BudgetColors.accentGreen,
                    isMobile: isMobile,
                  ),

                  if (budget > 0) ...[
                    SizedBox(height: isMobile ? 4 : 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 4,
                        backgroundColor: BudgetColors.statBgLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ratio >= 0.9
                              ? BudgetColors.accentRed
                              : ratio >= 0.7
                                  ? Colors.orange
                                  : ratio >= 0.4
                                      ? BudgetColors.accentYellow
                                      : BudgetColors.accentGreen,
                        ),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${(ratio * 100).toStringAsFixed(0)}% ' +
                          AppLocalizations.of(context)!.translate('fulfilled_stat').toLowerCase(),
                      style: TextStyle(fontSize: 9, color: BudgetColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Three-dot menu
          PositionedDirectional(
            top: 8,
            end: 8,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: BudgetColors.textMuted, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.borderColor, width: 1)),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'addEntry') {
                  onAddEntry();
                } else if (value == 'viewEntries') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetEntriesPage(
                          categoryName: category['name']),
                    ),
                  );
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit,
                          color: BudgetColors.accentBlue, size: 20),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.translate('edit_category_name')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'addEntry',
                  child: Row(
                    children: [
                      Icon(Icons.add_card,
                          color: BudgetColors.accentGreen, size: 20),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.translate('add_amount_title')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'viewEntries',
                  child: Row(
                    children: [
                      Icon(Icons.history,
                          color: BudgetColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.translate('view_entries')),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete,
                          color: BudgetColors.accentRed, size: 20),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.translate('delete_button')),
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

// ─────────────────────────────────────────────
// 📝 Info Row Helper Widget
// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isMobile;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: isMobile ? 11 : 13, color: color),
          SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: BudgetColors.textMuted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 10 : 13, // زيادة طفيفة للديسكتوب
                fontWeight: FontWeight.w600,
                color: BudgetColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 🎨 Colors
// ─────────────────────────────────────────────
class BudgetColors {
  static Color get primary         => AppColors.primary;
  static Color get primaryLight    => AppColors.primaryHover;
  static Color get sidebarBg       => AppColors.shade950;
  static Color get bodyBg          => AppColors.background;
  static Color get cardBg          => AppColors.surface;
  static Color get textPrimary     => AppColors.textPrimary;
  static Color get textSecondary   => AppColors.textSecondary;
  static Color get textMuted       => AppColors.textMuted;
  static Color get accentYellow    => AppColors.accentYellow;
  static Color get accentRed       => AppColors.accentRed;
  static Color get accentGreen     => AppColors.primary;
  static Color get accentBlue      => AppColors.accentBlue;
  static Color get statBgLight     => AppColors.surfaceElevated;
  static Color get statBorder      => AppColors.borderColor;
  static Color get statShadow      => AppColors.shadowColor;
}
