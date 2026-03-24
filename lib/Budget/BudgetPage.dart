import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';
import '../l10n/app_localizations.dart';
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
  Future<void> fetchAllCategories() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      _currentPage = 1;
      _hasMorePages = true;
      allCategories = [];
    });

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
          // API returned a plain list
          data = responseData;
        } else if (responseData is Map) {
          data = responseData['data'] ?? [];
          pagination = responseData['pagination'];
        } else {
          data = [];
        }

        setState(() {
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
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = AppLocalizations.of(context)!.translate('failed_load_budget');
        });
      }
      debugPrint('Error fetching budget categories: $e');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('budget_add_failed')),
            backgroundColor: BudgetColors.accentRed,
          ),
        );
      }
      debugPrint('Error adding category: $e');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('budget_rename_failed').replaceAll('{error}', e.toString())),
            backgroundColor: BudgetColors.accentRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      debugPrint('Error renaming category: $e');
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
                    child: const Icon(Icons.edit,
                        color: BudgetColors.accentBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.translate('edit_category_name'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BudgetColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate('new_name_label'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.account_balance_wallet,
                      color: BudgetColors.primary),
                ),
              ),
              const SizedBox(height: 24),
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
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('budget_delete_failed').replaceAll('{error}', e.toString())),
            backgroundColor: BudgetColors.accentRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      debugPrint('Error deleting category: $e');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('add_amount_failed').replaceAll('{error}', e.toString())),
            backgroundColor: BudgetColors.accentRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      debugPrint('Error adding entry: $e');
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: BudgetColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              // Name field (required)
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate('category_name_label'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.account_balance_wallet,
                      color: BudgetColors.primary),
                ),
              ),
              const SizedBox(height: 16),
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
                  prefixIcon: const Icon(Icons.monetization_on_outlined,
                      color: BudgetColors.accentGreen),
                  suffixText: AppLocalizations.of(context)!.translate('currency_unit'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.translate('add_auto_note'),
                style: const TextStyle(fontSize: 11, color: BudgetColors.textMuted),
              ),
              const SizedBox(height: 20),
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
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: BudgetColors.textMuted),
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
                    child: const Icon(Icons.add_card,
                        color: BudgetColors.accentGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('add_amount_title'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BudgetColors.textPrimary,
                          ),
                        ),
                        Text(
                          '"${category['name']}"',
                          style: const TextStyle(
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
              const SizedBox(height: 20),
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
                  prefixIcon: const Icon(Icons.monetization_on_outlined,
                      color: BudgetColors.accentGreen),
                  suffixText: AppLocalizations.of(context)!.translate('currency_unit'),
                ),
              ),
              const SizedBox(height: 24),
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
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side:
                            const BorderSide(color: BudgetColors.textMuted),
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
            const Icon(Icons.warning_rounded, color: BudgetColors.accentRed, size: 28),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.translate('delete_confirm_title'),
                style: const TextStyle(color: BudgetColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('delete_confirm_msg'),
              style:
                  const TextStyle(fontSize: 14, color: BudgetColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '"${category['name']}"',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BudgetColors.primary,
              ),
            ),
            const SizedBox(height: 12),
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
                  const Icon(Icons.info_outline,
                      color: BudgetColors.accentRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.translate('delete_request_confirm'),
                      style: const TextStyle(
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: BudgetColors.sidebarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
                    color: BudgetColors.statShadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate('search_budget_hint'),
                  hintStyle: const TextStyle(color: BudgetColors.textMuted),
                  prefixIcon:
                      const Icon(Icons.search, color: BudgetColors.primary),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
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
                      const Icon(Icons.account_balance_wallet,
                          size: 16, color: BudgetColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.translate('total_categories_stat').replaceAll('{count}', '$_totalCategories'),
                        style: const TextStyle(
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

          const SizedBox(height: 16),

          // 📱 Categories Grid
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: BudgetColors.primary))
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: BudgetColors.accentRed),
                            const SizedBox(height: 16),
                            Text(errorMessage!,
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: BudgetColors.textMuted)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchAllCategories,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: BudgetColors.primary),
                              child: Text(AppLocalizations.of(context)!.translate('retry_button'), style: const TextStyle(color: Colors.white)),
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
                                const SizedBox(height: 16),
                                Text(
                                  searchController.text.isEmpty
                                      ? AppLocalizations.of(context)!.translate('no_requests_found')
                                      : AppLocalizations.of(context)!.translate('no_search_results'),
                                  style: const TextStyle(
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
                              final int crossAxisCount = width > 1200
                                  ? 5
                                  : (width > 900
                                      ? 4
                                      : (width > 600 ? 3 : 2));
                              final double childAspectRatio = width > 600
                                  ? 1.1
                                  : (isSmallMobile ? 0.85 : 0.9);

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
                                    return const Center(
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
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
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
                  backgroundColor: BudgetColors.accentYellow,
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
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
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: BudgetColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: BudgetColors.primary,
                    size: isMobile ? 22 : 28,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 12),

                // Category Name
                Text(
                  category['name'] ?? AppLocalizations.of(context)!.translate('untitled'),
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.bold,
                    color: BudgetColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 6 : 8),

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
                  SizedBox(height: isMobile ? 6 : 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      backgroundColor: BudgetColors.statBgLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ratio >= 0.9
                            ? BudgetColors.accentRed
                            : BudgetColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(ratio * 100).toStringAsFixed(0)}% ' + AppLocalizations.of(context)!.translate('fulfilled_stat').toLowerCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: BudgetColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Three-dot menu
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: BudgetColors.textMuted, size: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                      const Icon(Icons.edit,
                          color: BudgetColors.accentBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.translate('edit_category_name')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'addEntry',
                  child: Row(
                    children: [
                      const Icon(Icons.add_card,
                          color: BudgetColors.accentGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.translate('add_amount_title')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'viewEntries',
                  child: Row(
                    children: [
                      const Icon(Icons.history,
                          color: BudgetColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.translate('view_entries')),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete,
                          color: BudgetColors.accentRed, size: 20),
                      const SizedBox(width: 8),
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
          const SizedBox(width: 4),
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
                fontSize: isMobile ? 10 : 12,
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
  static const Color primary = Color(0xFF00695C);
  static const Color primaryLight = Color(0xFF00796B);
  static const Color sidebarBg = Color(0xFF0E6C62);
  static const Color bodyBg = Color(0xFFF5F6FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textMuted = Color(0xFFB0B0B0);
  static const Color accentYellow = Color(0xFFFFB74D);
  static const Color accentRed = Color(0xFFE74C3C);
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color statBgLight = Color(0xFFF0F8F7);
  static const Color statBorder = Color(0xFFB2DFDB);
  static const Color statShadow = Color(0x1A00695C);
}
