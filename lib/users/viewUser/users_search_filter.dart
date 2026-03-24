import 'package:flutter/material.dart';
import 'users_colors.dart';
import 'users_api.dart';
import 'package:college_project/l10n/app_localizations.dart';

class UsersSearchFilter extends StatefulWidget {
  final String searchQuery;
  final String selectedRole;
  final String selectedDepartment;
  final bool? selectedActive;
  final List<String> departments;
  final UsersApiService apiService;
  final Function(String) onSearchChanged;
  final Function(String) onRoleChanged;
  final Function(String) onDepartmentChanged;
  final Function(bool?) onActiveChanged;
  final bool isMobile;

  const UsersSearchFilter({
    super.key,
    required this.searchQuery,
    required this.selectedRole,
    required this.selectedDepartment,
    required this.selectedActive,
    required this.departments,
    required this.apiService,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onDepartmentChanged,
    required this.onActiveChanged,
    required this.isMobile,
  });

  @override
  State<UsersSearchFilter> createState() => _UsersSearchFilterState();
}

class _UsersSearchFilterState extends State<UsersSearchFilter> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          TextField(
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.translate('search_users'),
              hintStyle: TextStyle(color: AppColors.textMuted),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.primary,
                size: widget.isMobile ? 20 : 24,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 16),
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 16),
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 16),
                borderSide: BorderSide(
                  color: AppColors.focusBorderColor,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppColors.bodyBg,
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 16 : 20,
                vertical: widget.isMobile ? 14 : 16,
              ),
            ),
          ),
          SizedBox(height: widget.isMobile ? 12 : 16),
          
          // Filters Label
          Row(
            children: [
              Icon(Icons.filter_list, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.translate('filters_label') ?? "FILTERS",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Filter Row (Scrollable on mobile)
          widget.isMobile 
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    SizedBox(width: 140, child: _buildRoleDropdown()),
                    SizedBox(width: 8),
                    SizedBox(width: 180, child: _buildDepartmentDropdown()),
                    SizedBox(width: 8),
                    SizedBox(width: 130, child: _buildActiveDropdown()),
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(child: _buildRoleDropdown()),
                  SizedBox(width: 12),
                  Expanded(child: _buildDepartmentDropdown()),
                  SizedBox(width: 12),
                  Expanded(child: _buildActiveDropdown()),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return _buildDropdownContainer(
      icon: Icons.flag_outlined,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selectedRole,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          items: [
            DropdownMenuItem(value: 'all', child: Text(AppLocalizations.of(context)!.translate('all'))),
            DropdownMenuItem(value: 'admin', child: Text(AppLocalizations.of(context)!.translate('administrator'))),
            DropdownMenuItem(value: 'user', child: Text(AppLocalizations.of(context)!.translate('regular_user'))),
            DropdownMenuItem(value: 'accountant', child: Text(AppLocalizations.of(context)!.translate('accountant'))),
          ],
          onChanged: (val) => widget.onRoleChanged(val!),
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return GestureDetector(
      onTap: () => _showDepartmentPicker(),
      child: _buildDropdownContainer(
        icon: Icons.business_outlined,
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.selectedDepartment == 'all'
                    ? (AppLocalizations.of(context)!.translate('all_types') ?? "All Departments")
                    : widget.selectedDepartment,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showDepartmentPicker() {
    showDialog(
      context: context,
      builder: (context) => DepartmentPickerDialog(
        apiService: widget.apiService,
        initialSelected: widget.selectedDepartment,
        onSelected: (val) => widget.onDepartmentChanged(val),
      ),
    );
  }

  Widget _buildActiveDropdown() {
    String value = widget.selectedActive == null ? 'all' : widget.selectedActive.toString();
    return _buildDropdownContainer(
      icon: Icons.filter_alt_outlined,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          items: [
            DropdownMenuItem(value: 'all', child: Text(AppLocalizations.of(context)!.translate('all'))),
            DropdownMenuItem(value: 'true', child: Text(AppLocalizations.of(context)!.translate('active') ?? "Active")),
            DropdownMenuItem(value: 'false', child: Text(AppLocalizations.of(context)!.translate('inactive') ?? "Inactive")),
          ],
          onChanged: (val) {
            if (val == 'all') widget.onActiveChanged(null);
            else widget.onActiveChanged(val == 'true');
          },
        ),
      ),
    );
  }

  Widget _buildDropdownContainer({required IconData icon, required Widget child}) {
    return Container(
      height: widget.isMobile ? 48 : 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ✅ Paginated Picker Dialog (10 by 10)
class DepartmentPickerDialog extends StatefulWidget {
  final UsersApiService apiService;
  final String initialSelected;
  final Function(String) onSelected;

  const DepartmentPickerDialog({
    super.key,
    required this.apiService,
    required this.initialSelected,
    required this.onSelected,
  });

  @override
  State<DepartmentPickerDialog> createState() => _DepartmentPickerDialogState();
}

class _DepartmentPickerDialogState extends State<DepartmentPickerDialog> {
  final List<String> _departments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
        if (!_isLoadingMore && _hasMore) {
          _loadMoreDepartments();
        }
      }
    });
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
      _departments.clear();
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final result = await widget.apiService.fetchDepartmentsPaginated(page: 1, perPage: 10);
      final List<String> fetched = result['departments'] as List<String>;
      final pagination = result['pagination'] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _departments.addAll(fetched);
          if (pagination != null && pagination['next'] != null) {
            _currentPage = pagination['next'];
            _hasMore = true;
          } else {
            _hasMore = false;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreDepartments() async {
    setState(() => _isLoadingMore = true);

    try {
      final result = await widget.apiService.fetchDepartmentsPaginated(page: _currentPage, perPage: 10);
      final List<String> fetched = result['departments'] as List<String>;
      final pagination = result['pagination'] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _departments.addAll(fetched);
          if (pagination != null && pagination['next'] != null) {
            _currentPage = pagination['next'];
            _hasMore = true;
          } else {
            _hasMore = false;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('select_department') ?? "Select Department"),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Option "All"
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('all_types') ?? "All Departments"),
              leading: Icon(Icons.all_inclusive, color: AppColors.primary),
              selected: widget.initialSelected == 'all',
              onTap: () {
                widget.onSelected('all');
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _departments.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _departments.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ));
                      }
                      final dept = _departments[index];
                      return ListTile(
                        title: Text(dept),
                        leading: const Icon(Icons.business),
                        selected: widget.initialSelected == dept,
                        onTap: () {
                          widget.onSelected(dept);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text(AppLocalizations.of(context)!.translate('cancel') ?? "Cancel")
        ),
      ],
    );
  }
}