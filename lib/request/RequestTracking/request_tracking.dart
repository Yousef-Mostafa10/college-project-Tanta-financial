import 'package:college_project/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../app_config.dart';
import 'tracking_colors.dart';
import 'tracking_api.dart';
import 'tracking_header.dart';
import 'tracking_filters.dart';
import 'tracking_stats.dart';
import 'tracking_empty_state.dart';
import 'tracking_loading_state.dart';
import 'tracking_error_state.dart';
import 'tracking_timeline.dart';

class TransactionTrackingPage extends StatefulWidget {
  final String transactionId;

  const TransactionTrackingPage({super.key, required this.transactionId});

  @override
  State<TransactionTrackingPage> createState() => _TransactionTrackingPageState();
}

class _TransactionTrackingPageState extends State<TransactionTrackingPage> {
  final String baseUrl = AppConfig.baseUrl;
  String? _userToken;
  List<dynamic> _forwards = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _transactionInfo;

  // الفلاتر
  String _selectedStatus = "All";
  final List<String> _statusFilters = ["All", "waiting", "approved", "rejected", "needs-editing"];

  late TrackingApi _api;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUserToken();
    await _fetchTransactionForwards();
  }

  Future<void> _getUserToken() async {
    _userToken = await TrackingApi.getUserToken();
  }

  Future<void> _fetchTransactionForwards() async {
    if (_userToken == null) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.translate('please_login_first');
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _api = TrackingApi(baseUrl: baseUrl, userToken: _userToken);
    final result = await _api.fetchTransactionForwards(widget.transactionId);

    setState(() {
      if (result['success'] == true) {
        _transactionInfo = result['transaction'];
        _forwards = result['forwards'];
      } else {
        _errorMessage = result['error'];
      }
      _isLoading = false;
    });
  }

  List<dynamic> get _filteredForwards {
    if (_selectedStatus == "All") return _forwards;
    return _forwards.where((forward) => forward['status'] == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final isDesktop = width >= 1024;

    return Scaffold(
      backgroundColor: TrackingColors.bodyBg,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('transaction_tracking_title'),
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: TrackingColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: isMobile ? 20 : 24),
            onPressed: _fetchTransactionForwards,
            tooltip: AppLocalizations.of(context)!.translate('refresh'),
          ),
        ],
      ),
      body: _isLoading
          ? buildLoadingState(context, isMobile)
          : _errorMessage != null
          ? buildErrorState(
        context: context,
        errorMessage: _errorMessage!,
        onRetry: _fetchTransactionForwards,
        isMobile: isMobile,
      )
          : _buildMainContent(isMobile, isTablet),
    );
  }

  Widget _buildMainContent(bool isMobile, bool isTablet) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // الهيدر مع معلومات المعاملة
          buildTransactionHeader(
            context: context,
            transactionId: widget.transactionId,
            forwards: _forwards,
            isMobile: isMobile,
            isTablet: isTablet,
          ),

          // قسم الفلاتر
          buildFilterSection(
            context: context,
            selectedStatus: _selectedStatus,
            statusFilters: _statusFilters,
            onStatusChanged: (status) {
              setState(() {
                _selectedStatus = status;
              });
            },
            isMobile: isMobile,
            isTablet: isTablet,
          ),

          // الإحصائيات
          buildStatsSection(
            context: context,
            forwards: _forwards,
            isMobile: isMobile,
            isTablet: isTablet,
          ),

          // مسار التتبع
          _forwards.isEmpty
              ? buildEmptyState(context: context, isMobile: isMobile, isTablet: isTablet)
              : buildTrackingTimeline(
            context: context,
            forwards: _filteredForwards,
            isMobile: isMobile,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }
}