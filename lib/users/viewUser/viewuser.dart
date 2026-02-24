import 'package:flutter/material.dart';
import 'user_model.dart';
import 'users_api.dart';
import 'users_colors.dart';
import 'users_helpers.dart';
import 'users_search_filter.dart';
import 'user_card.dart';
import 'users_empty_state.dart';
import 'users_list_header.dart';
import 'package:college_project/l10n/app_localizations.dart';

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
  String _selectedFilter = 'all';

  // Pagination
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  int _totalUsers = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUsers();

    // Scroll listener للتحميل التدريجي
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoadingMore &&
          _hasMorePages &&
          _searchQuery.isEmpty &&
          _selectedFilter == 'all') {
        _loadMoreUsers();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      final result = await _apiService.fetchUsersPaginated(page: 1, perPage: 10);
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
      UsersHelpers.showErrorMessage(context, e.toString());
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _apiService.fetchUsersPaginated(page: _currentPage, perPage: 10);
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
    }
  }

  List<User> get _filteredUsers {
    List<User> filtered = _users;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedFilter != 'all') {
      filtered = filtered
          .where((u) => u.role.toLowerCase() == _selectedFilter)
          .toList();
    }

    return filtered;
  }

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
        centerTitle: true,
      ),
      body: Column(
        children: [
          UsersSearchFilter(
            searchQuery: _searchQuery,
            selectedFilter: _selectedFilter,
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            onFilterChanged: (value) => setState(() => _selectedFilter = value),
            isMobile: isMobile,
          ),
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
                : _filteredUsers.isEmpty
                ? UsersEmptyState(
              selectedFilter: _selectedFilter,
              hasUsers: _users.isNotEmpty,
              isMobile: isMobile,
            )
                : Column(
              children: [
                UsersListHeader(
                  filteredUsersCount: _searchQuery.isEmpty && _selectedFilter == 'all'
                      ? _totalUsers
                      : _filteredUsers.length,
                  selectedFilter: _selectedFilter,
                  hasMore: _hasMorePages,
                  searchQuery: _searchQuery,
                  isMobile: isMobile,
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    itemCount: _filteredUsers.length + (_hasMorePages && _searchQuery.isEmpty && _selectedFilter == 'all' ? 1 : 0),
                    itemBuilder: (context, index) {
                      // عنصر اللودينج في الآخر
                      if (index == _filteredUsers.length) {
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
                      final user = _filteredUsers[index];
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
    );
  }
}