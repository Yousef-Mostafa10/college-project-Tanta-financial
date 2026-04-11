import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../app_config.dart';
import '../l10n/app_localizations.dart';
import '../core/app_colors.dart';


// ─────────────────────────────────────────────
// 📄 Budget Entries Page
// ─────────────────────────────────────────────
class BudgetEntriesPage extends StatefulWidget {
  final String categoryName;

  const BudgetEntriesPage({Key? key, required this.categoryName})
      : super(key: key);

  @override
  State<BudgetEntriesPage> createState() => _BudgetEntriesPageState();
}

class _BudgetEntriesPageState extends State<BudgetEntriesPage> {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    headers: {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  // Data
  List<Map<String, dynamic>> entries = [];
  bool isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;
  int _currentPage = 1;
  int _totalEntries = 0;
  String? errorMessage;

  // Scroll
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  // Filter controllers
  final TextEditingController _inputterController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  // Date filters
  DateTime? _fromDate;
  DateTime? _toDate;

  // Filter panel visibility
  bool _showFilters = false;

  // Debounce for text filters
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchEntries(reset: true);

    _scrollController.addListener(() {
      if (_scrollController.offset >= 200) {
        if (!_showBackToTop) setState(() => _showBackToTop = true);
      } else {
        if (_showBackToTop) setState(() => _showBackToTop = false);
      }

      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMorePages) {
        _fetchEntries(reset: false);
      }
    });

    // Text filter debounce
    _inputterController.addListener(_onFilterChanged);
    _minAmountController.addListener(_onFilterChanged);
    _maxAmountController.addListener(_onFilterChanged);
  }

  void _onFilterChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchEntries(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputterController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 🔐 Auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Authorization': 'Bearer $token',
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  // 🔗 Build query URL
  String _buildUrl(int page) {
    final params = <String, String>{
      'page': '$page',
      'perPage': '10',
    };

    final inputter = _inputterController.text.trim();
    if (inputter.isNotEmpty) params['inputter'] = inputter;

    final minAmount = int.tryParse(_minAmountController.text.trim());
    if (minAmount != null) params['minAmount'] = '$minAmount';

    final maxAmount = int.tryParse(_maxAmountController.text.trim());
    if (maxAmount != null) params['maxAmount'] = '$maxAmount';

    if (_fromDate != null) {
      params['from'] = DateFormat('yyyy-MM-dd').format(_fromDate!);
    }
    if (_toDate != null) {
      params['to'] = DateFormat('yyyy-MM-dd').format(_toDate!);
    }

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '/budget-categories/${Uri.encodeComponent(widget.categoryName)}/entry?$query';
  }

  // 📥 Fetch entries
  Future<void> _fetchEntries({required bool reset}) async {
    if (!reset && (_isLoadingMore || !_hasMorePages)) return;

    if (reset) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        _currentPage = 1;
        _hasMorePages = true;
        entries = [];
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        _buildUrl(_currentPage),
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

        final newEntries =
            data.map<Map<String, dynamic>>((e) => _mapEntry(e)).toList();

        setState(() {
          if (reset) {
            entries = newEntries;
          } else {
            entries.addAll(newEntries);
          }

          _totalEntries = pagination != null
              ? ((pagination['total'] as num?)?.toInt() ?? entries.length)
              : entries.length;

          if (pagination != null && pagination['next'] != null) {
            _currentPage = (pagination['next'] as num).toInt();
            _hasMorePages = true;
          } else {
            _hasMorePages = false;
          }

          isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = reset ? false : isLoading;
        _isLoadingMore = false;
        if (reset) errorMessage = AppLocalizations.of(context)!.translate('failed_load_entries');
      });
      debugPrint('Error fetching entries: $e');
    }
  }

  Map<String, dynamic> _mapEntry(dynamic e) {
    return {
      'id': e['id'],
      'inputterId': e['inputterId'],
      'inputterName': e['inputterName'] ?? e['inputter'] ?? '',
      'amount': (e['amount'] as num?)?.toInt() ?? 0,
      'budgetName': e['budgetName'] ?? '',
      'createdAt': e['createdAt'] ?? '',
    };
  }

  // 🗑️ Confirm delete entry dialog
  void _confirmDeleteEntry(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: EntryColors.accentRed, size: 28),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.translate('delete_confirm_title'), style: TextStyle(color: EntryColors.textPrimary)),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('delete_entry_confirm')
            .replaceAll('{amount}', _formatNumber(entry['amount'] ?? 0))
            .replaceAll('{currency}', AppLocalizations.of(context)!.translate('currency_unit')),
          style: TextStyle(fontSize: 14, color: EntryColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.translate('cancel_button')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEntry(entry['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: EntryColors.accentRed),
            child: Text(AppLocalizations.of(context)!.translate('delete_button'), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🗑️ Delete entry
  Future<void> _deleteEntry(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.delete(
        '/budget-categories/${Uri.encodeComponent(widget.categoryName)}/entry/$id',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          entries.removeWhere((e) => e['id'] == id);
          _totalEntries = (_totalEntries - 1).clamp(0, _totalEntries);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('delete_entry_success')),
              backgroundColor: EntryColors.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حذف السجل: ${e.toString()}'),
            backgroundColor: EntryColors.accentRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      debugPrint('Error deleting entry: $e');
    }
  }

  // 📅 Pick date
  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (_fromDate ?? DateTime(now.year, 1, 1))
        : (_toDate ?? DateTime(now.year, 12, 31));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).brightness == Brightness.dark
            ? ColorScheme.dark(
                primary: EntryColors.primary,
                onPrimary: Colors.white,
                surface: EntryColors.cardBg,
              )
            : ColorScheme.light(
                primary: EntryColors.primary,
                onPrimary: Colors.white,
              ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _fetchEntries(reset: true);
    }
  }

  void _clearFilters() {
    _inputterController.clear();
    _minAmountController.clear();
    _maxAmountController.clear();
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _fetchEntries(reset: true);
  }

  bool get _hasActiveFilters =>
      _inputterController.text.isNotEmpty ||
      _minAmountController.text.isNotEmpty ||
      _maxAmountController.text.isNotEmpty ||
      _fromDate != null ||
      _toDate != null;

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  String _formatNumber(int n) {
    return NumberFormat('#,###').format(n);
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM/yyyy  hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EntryColors.bodyBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('payment_records'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            Text(
              '"${widget.categoryName}"',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: EntryColors.sidebarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Filter toggle button
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              backgroundColor: EntryColors.accentYellow,
              child: Icon(Icons.filter_list, color: Colors.white),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: AppLocalizations.of(context)!.translate('filters_tooltip'),
          ),
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _fetchEntries(reset: true),
            tooltip: AppLocalizations.of(context)!.translate('refresh_tooltip'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── FILTER PANEL ───
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showFilters ? _buildFilterPanel() : const SizedBox.shrink(),
          ),

          // ─── STATS BAR ───
          _buildStatsBar(),

          // ─── ENTRIES LIST ───
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
              heroTag: 'entries_scroll_top',
              mini: true,
              onPressed: _scrollToTop,
              backgroundColor: EntryColors.primary.withOpacity(0.85),
              child: Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  // ─── Filter Panel ───────────────────────────
  Widget _buildFilterPanel() {
    return Container(
      color: EntryColors.cardBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Row 1: Inputter
          _buildFilterField(
            controller: _inputterController,
            label: AppLocalizations.of(context)!.translate('inputter_name_label'),
            icon: Icons.person_search,
            keyboardType: TextInputType.text,
          ),
          SizedBox(height: 12),

          // Row 2: Min / Max Amount
          Row(
            children: [
              Expanded(
                child: _buildFilterField(
                  controller: _minAmountController,
                  label: AppLocalizations.of(context)!.translate('min_amount_label'),
                  icon: Icons.arrow_downward,
                  keyboardType: TextInputType.number,
                  suffixText: AppLocalizations.of(context)!.translate('currency_unit'),
                  color: EntryColors.accentGreen,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFilterField(
                  controller: _maxAmountController,
                  label: AppLocalizations.of(context)!.translate('max_amount_label'),
                  icon: Icons.arrow_upward,
                  keyboardType: TextInputType.number,
                  suffixText: AppLocalizations.of(context)!.translate('currency_unit'),
                  color: EntryColors.accentRed,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Row 3: From / To dates
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: AppLocalizations.of(context)!.translate('from_date_label'),
                  value: _fromDate,
                  onTap: () => _pickDate(isFrom: true),
                  onClear: () {
                    setState(() => _fromDate = null);
                    _fetchEntries(reset: true);
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  label: AppLocalizations.of(context)!.translate('to_date_label'),
                  value: _toDate,
                  onTap: () => _pickDate(isFrom: false),
                  onClear: () {
                    setState(() => _toDate = null);
                    _fetchEntries(reset: true);
                  },
                ),
              ),
            ],
          ),

          // Clear filters button
          if (_hasActiveFilters) ...[
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: Icon(Icons.clear_all, size: 18),
                label: Text(AppLocalizations.of(context)!.translate('clear_filters_button')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EntryColors.accentRed,
                  side: BorderSide(color: EntryColors.accentRed),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
    Color? color,
  }) {
    final effectiveColor = color ?? EntryColors.primary;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: EntryColors.textMuted),
        prefixIcon: Icon(icon, color: effectiveColor, size: 18),
        suffixText: suffixText,
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 16),
                onPressed: () {
                  controller.clear();
                  _fetchEntries(reset: true);
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        filled: true,
        fillColor: EntryColors.bodyBg.withOpacity(0.5),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value != null
              ? EntryColors.primary.withOpacity(0.07)
              : EntryColors.bodyBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value != null
                ? EntryColors.primary.withOpacity(0.4)
                : Colors.grey.shade400,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                size: 16,
                color: value != null
                    ? EntryColors.primary
                    : EntryColors.textMuted),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                value != null
                    ? DateFormat('dd/MM/yyyy').format(value)
                    : label,
                style: TextStyle(
                  fontSize: 12,
                  color: value != null
                      ? EntryColors.textPrimary
                      : EntryColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close,
                    size: 16, color: EntryColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Stats bar ──────────────────────────────
  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: EntryColors.cardBg,
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: EntryColors.statBgLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: EntryColors.statBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long,
                    size: 14, color: EntryColors.primary),
                SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.translate('total_entries_stat').replaceAll('{count}', '$_totalEntries'),
                  style: TextStyle(
                    color: EntryColors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (_hasActiveFilters) ...[
            SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: EntryColors.accentYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: EntryColors.accentYellow.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_alt,
                      size: 14, color: EntryColors.accentYellow),
                  SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.translate('active_filter_label'),
                    style: TextStyle(
                      color: EntryColors.accentYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Main content ────────────────────────────
  Widget _buildContent() {
    if (isLoading) {
      return Center(
          child:
              CircularProgressIndicator(color: EntryColors.primary));
    }
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: EntryColors.accentRed),
            SizedBox(height: 16),
            Text(errorMessage!,
                style: TextStyle(
                    fontSize: 16, color: EntryColors.textMuted)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchEntries(reset: true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: EntryColors.primary),
              child: Text(AppLocalizations.of(context)!.translate('retry_button'),
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64,
                color: EntryColors.textMuted.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(
              _hasActiveFilters
                  ? AppLocalizations.of(context)!.translate('no_results_filters')
                  : AppLocalizations.of(context)!.translate('no_entries_category'),
              style: TextStyle(
                  fontSize: 16, color: EntryColors.textMuted),
            ),
            if (_hasActiveFilters) ...[
              SizedBox(height: 12),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: Icon(Icons.clear_all),
                label: Text(AppLocalizations.of(context)!.translate('clear_filters_button')),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: entries.length + (_hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == entries.length) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                  color: EntryColors.primary, strokeWidth: 2),
            ),
          );
        }
        return _buildEntryCard(entries[index], index);
      },
    );
  }

  // ─── Entry Card ─────────────────────────────
  Widget _buildEntryCard(Map<String, dynamic> entry, int index) {
    final int amount = (entry['amount'] as num?)?.toInt() ?? 0;
    final String createdAt = _formatDate(entry['createdAt'] ?? '');
    final int? inputterId = entry['inputterId'] as int?;
    final String inputterName = entry['inputterName'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: EntryColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: EntryColors.statShadow,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: EntryColors.accentGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    color: EntryColors.accentGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount
                  Row(
                    children: [
                      Icon(Icons.monetization_on,
                          size: 16, color: EntryColors.accentGreen),
                      SizedBox(width: 4),
                      Text(
                        '${_formatNumber(amount)} ' + AppLocalizations.of(context)!.translate('currency_unit'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: EntryColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),

                  // Inputter
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14, color: EntryColors.textMuted),
                      SizedBox(width: 4),
                      Text(
                        inputterName.isNotEmpty
                            ? inputterName
                            : inputterId != null
                                ? AppLocalizations.of(context)!.translate('inputter_label') + ' #$inputterId'
                                : AppLocalizations.of(context)!.translate('unknown'),
                        style: TextStyle(
                          fontSize: 13,
                          color: EntryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),

                  // Date
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: EntryColors.textMuted),
                      SizedBox(width: 4),
                      Text(
                        createdAt,
                        style: TextStyle(
                          fontSize: 12,
                          color: EntryColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions: Badge and Delete
            if (entry['id'] != null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: EntryColors.statBgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EntryColors.statBorder),
                    ),
                    child: Text(
                      'ID: ${entry['id']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: EntryColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () => _confirmDeleteEntry(entry),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.delete_outline,
                          color: EntryColors.accentRed, size: 20),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 🎨 Colors
// ─────────────────────────────────────────────
class EntryColors {
  static Color get primary         => AppColors.primary;
  static Color get sidebarBg       => AppColors.shade950;
  static Color get bodyBg          => AppColors.background;
  static Color get cardBg          => AppColors.surface;
  static Color get textPrimary     => AppColors.textPrimary;
  static Color get textSecondary   => AppColors.textSecondary;
  static Color get textMuted       => AppColors.textMuted;
  static Color get accentYellow    => AppColors.accentYellow;
  static Color get accentRed       => AppColors.accentRed;
  static Color get accentGreen     => AppColors.primary;
  static Color get statBgLight     => AppColors.surfaceElevated;
  static Color get statBorder      => AppColors.borderColor;
  static Color get statShadow      => AppColors.shadowColor;
}
