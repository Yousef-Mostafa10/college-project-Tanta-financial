import 'package:flutter/material.dart';
import '../../utils/app_error_handler.dart';
import 'user_model.dart';
import 'users_api.dart';
import 'users_colors.dart';
import 'users_helpers.dart';
import 'users_search_filter.dart';
import 'user_card.dart';
import 'users_empty_state.dart';
import 'users_list_header.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'dart:async';

class ViewUsersPage extends StatefulWidget {
  const ViewUsersPage({super.key});

  @override
  State<ViewUsersPage> createState() => _ViewUsersPageState();
}

class _ViewUsersPageState extends State<ViewUsersPage> {
  final UsersApiService _apiService = UsersApiService();
  final List<User> _users = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedRole = 'all';
  String _selectedDepartment = 'all';
  bool? _selectedActive;
  List<String> _departments = [];

  // Pagination
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  int _totalUsers = 0;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // Scroll listener للتحميل التدريجي
    _scrollController.addListener(() {
      if (_scrollController.offset >= 200) {
        if (!_showBackToTop) setState(() => _showBackToTop = true);
      } else {
        if (_showBackToTop) setState(() => _showBackToTop = false);
      }

      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoadingMore &&
          _hasMorePages) {
        _loadMoreUsers();
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

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadUsers(),
      _fetchDepartments(),
    ]);
  }

  Future<void> _fetchDepartments() async {
    try {
      final depts = await _apiService.fetchDepartments();
      setState(() {
        _departments = depts;
      });
    } catch (e) {
      debugPrint("Error fetching departments: $e");
      if (mounted) {
        UsersHelpers.showErrorMessage(context, AppErrorHandler.translateException(context, e));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _users.clear();
      _currentPage = 1;
      _hasMorePages = true;
    });

    try {
      final result = await _apiService.fetchUsersPaginated(
        page: 1,
        perPage: 10,
        name: _searchQuery,
        role: _selectedRole,
        department: _selectedDepartment,
        active: _selectedActive,
      );
      final List<User> fetchedUsers = result['users'] as List<User>;
      final pagination = result['pagination'] as Map<String, dynamic>?;

      setState(() {
        _users.addAll(fetchedUsers);
        _totalUsers = pagination?['total'] ?? _users.length;

        if (pagination != null && pagination['next'] != null) {
          _currentPage = pagination['next'];
          _hasMorePages = true;
        } else {
          _hasMorePages = false;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      UsersHelpers.showErrorMessage(context, AppErrorHandler.translateException(context, e));
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _apiService.fetchUsersPaginated(
        page: _currentPage,
        perPage: 10,
        name: _searchQuery,
        role: _selectedRole,
        department: _selectedDepartment,
        active: _selectedActive,
      );
      final List<User> fetchedUsers = result['users'] as List<User>;
      final pagination = result['pagination'] as Map<String, dynamic>?;

      setState(() {
        _users.addAll(fetchedUsers);
        _totalUsers = pagination?['total'] ?? _users.length;

        if (pagination != null && pagination['next'] != null) {
          _currentPage = pagination['next'];
          _hasMorePages = true;
        } else {
          _hasMorePages = false;
        }

        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) {
        UsersHelpers.showErrorMessage(context, AppErrorHandler.translateException(context, e));
      }
    }
  }

  void _onSearchQueryChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _searchQuery = query);
        _loadUsers();
      }
    });
  }

  void _onRoleChanged(String role) {
    setState(() => _selectedRole = role);
    _loadUsers();
  }

  void _onDepartmentChanged(String dept) {
    setState(() => _selectedDepartment = dept);
    _loadUsers();
  }

  void _onActiveChanged(bool? active) {
    setState(() => _selectedActive = active);
    _loadUsers();
  }

  // Row selection filters (old logic)
  void _onFilterChanged(String filter) {
     _onRoleChanged(filter);
  }


  // List<User> get _filteredUsers {
  //   List<User> filtered = _users;

  //   if (_searchQuery.isNotEmpty) {
  //     filtered = filtered
  //         .where((u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()))
  //         .toList();
  //   }

  //   if (_selectedFilter != 'all') {
  //     filtered = filtered
  //         .where((u) => u.role.toLowerCase() == _selectedFilter)
  //         .toList();
  //   }

  //   return filtered;
  // }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;

    return Scaffold(
      backgroundColor: AppColors.bodyBg,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('users_management'),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadUsers,
            tooltip: AppLocalizations.of(context)!.translate('refresh_tooltip'),
          ),
        ],
      ),
      body: Column(
        children: [
          UsersSearchFilter(
            searchQuery: _searchQuery,
            selectedRole: _selectedRole,
            selectedDepartment: _selectedDepartment,
            selectedActive: _selectedActive,
            departments: _departments,
            apiService: _apiService,
            onSearchChanged: _onSearchQueryChanged,
            onRoleChanged: _onRoleChanged,
            onDepartmentChanged: _onDepartmentChanged,
            onActiveChanged: _onActiveChanged,
            isMobile: isMobile,
          ),
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
                : _users.isEmpty
                ? UsersEmptyState(
              selectedFilter: _selectedRole,
              hasUsers: _users.isNotEmpty,
              isMobile: isMobile,
            )
                : Column(
              children: [
                UsersListHeader(
                  filteredUsersCount: _searchQuery.isEmpty && _selectedRole == 'all' && _selectedDepartment == 'all' && _selectedActive == null
                      ? _totalUsers
                      : _users.length,
                  selectedFilter: _selectedRole,
                  hasMore: _hasMorePages,
                  searchQuery: _searchQuery,
                  isMobile: isMobile,
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    itemCount: _users.length + (_hasMorePages ? 1 : 0),
                    itemBuilder: (context, index) {
                      // عنصر اللودينج في الآخر
                      if (index == _users.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        );
                      }
                      final user = _users[index];
                      return UserCard(
                        user: user,
                        apiService: _apiService,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        onUpdate: _loadUsers,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
              heroTag: 'users_scroll_top',
              mini: true,
              onPressed: _scrollToTop,
              backgroundColor: AppColors.primary.withOpacity(0.8),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }
}
