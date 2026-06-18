import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/core/app_colors.dart';

class PaginatedTypePicker extends StatefulWidget {
  final String selectedType;
  final Function(String?) onTypeChanged;
  final Future<Map<String, dynamic>> Function(int page) fetchPage;
  final bool isMobile;
  final Color primaryColor;
  final Color borderColor;
  final Color textColor;
  final Color cardBg;

  const PaginatedTypePicker({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.fetchPage,
    required this.isMobile,
    required this.primaryColor,
    required this.borderColor,
    required this.textColor,
    required this.cardBg,
  });

  @override
  State<PaginatedTypePicker> createState() => _PaginatedTypePickerState();
}

class _PaginatedTypePickerState extends State<PaginatedTypePicker> {
  bool _isHovered = false;

  void _openPicker() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) => _TypePickerDialog(
        fetchPage: widget.fetchPage,
        onSelected: (val) {
          widget.onTypeChanged(val);
          Navigator.pop(context);
        },
        primaryColor: widget.primaryColor,
        textColor: widget.textColor,
        // Always use a solid opaque surface color for the dialog background
        cardBg: AppColors.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayText = widget.selectedType;
    if (displayText.toLowerCase() == 'all types') {
      displayText =
          "${AppLocalizations.of(context)!.translate('request_type_label')}: ${AppLocalizations.of(context)!.translate('all_types')}";
    }

    final isAllTypes = widget.selectedType.toLowerCase() == 'all types';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 48,
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.primaryColor.withOpacity(0.08)
              : widget.primaryColor.withOpacity(0.04),
          border: Border.all(
            color: _isHovered
                ? widget.primaryColor.withOpacity(0.5)
                : widget.borderColor,
            width: _isHovered ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: InkWell(
          onTap: _openPicker,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: widget.isMobile ? 10 : 14),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: widget.isMobile ? 14 : 16,
                  color: widget.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: widget.isMobile ? 12 : 13,
                      color: isAllTypes ? widget.primaryColor : widget.textColor,
                      fontWeight:
                          isAllTypes ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  turns: 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: widget.textColor.withOpacity(0.6),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _TypePickerDialog extends StatefulWidget {
  final Future<Map<String, dynamic>> Function(int page) fetchPage;
  final Function(String?) onSelected;
  final Color primaryColor;
  final Color textColor;
  final Color cardBg;

  const _TypePickerDialog({
    required this.fetchPage,
    required this.onSelected,
    required this.primaryColor,
    required this.textColor,
    required this.cardBg,
  });

  @override
  State<_TypePickerDialog> createState() => _TypePickerDialogState();
}

class _TypePickerDialogState extends State<_TypePickerDialog>
    with SingleTickerProviderStateMixin {
  final List<String> _types = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
    _loadNextPage();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadNextPage();
      }
    });
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final result = await widget.fetchPage(_currentPage);
      final List<String> newTypes = List<String>.from(result['types']);
      setState(() {
        if (_currentPage == 1) {
          _types.clear();
          _types.add('All Types');
        }
        _types.addAll(newTypes);
        _hasMore = result['hasMore'];
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 420,
                constraints: const BoxConstraints(maxHeight: 520),
                decoration: BoxDecoration(
                  // Use a guaranteed-opaque surface color
                  color: widget.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.isDark
                        ? Colors.white.withOpacity(0.10)
                        : AppColors.borderColor.withOpacity(0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 30,
                      spreadRadius: 0,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: widget.primaryColor.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.primaryColor.withOpacity(0.12),
                            widget.primaryColor.withOpacity(0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.borderColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.category_rounded,
                              color: widget.primaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate('all_types'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: widget.primaryColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: widget.textColor.withOpacity(0.5),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── List ──────────────────────────────────────────────
                    Flexible(
                      child: _types.isEmpty && _isLoading
                          ? SizedBox(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: widget.primaryColor,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _types.length + (_isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _types.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: widget.primaryColor,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final type = _types[index];
                                final isAllTypes =
                                    type.toLowerCase() == 'all types';
                                String displayText = type;
                                if (isAllTypes) {
                                  displayText = AppLocalizations.of(context)!
                                      .translate('all_types');
                                }

                                return _TypePickerItem(
                                  label: displayText,
                                  isAllTypes: isAllTypes,
                                  primaryColor: widget.primaryColor,
                                  textColor: widget.textColor,
                                  onTap: () => widget.onSelected(type),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Individual item with hover effect
// ─────────────────────────────────────────────────────────────────────────────

class _TypePickerItem extends StatefulWidget {
  final String label;
  final bool isAllTypes;
  final Color primaryColor;
  final Color textColor;
  final VoidCallback onTap;

  const _TypePickerItem({
    required this.label,
    required this.isAllTypes,
    required this.primaryColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_TypePickerItem> createState() => _TypePickerItemState();
}

class _TypePickerItemState extends State<_TypePickerItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: _hovered
              ? widget.primaryColor.withOpacity(0.10)
              : (widget.isAllTypes
                  ? widget.primaryColor.withOpacity(0.06)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered || widget.isAllTypes
                ? widget.primaryColor.withOpacity(0.15)
                : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: widget.primaryColor.withOpacity(0.12),
          highlightColor: widget.primaryColor.withOpacity(0.08),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  widget.isAllTypes
                      ? Icons.filter_list_rounded
                      : Icons.label_outline_rounded,
                  size: 16,
                  color: widget.isAllTypes
                      ? widget.primaryColor
                      : widget.textColor.withOpacity(0.5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.isAllTypes
                          ? widget.primaryColor
                          : widget.textColor,
                      fontWeight: widget.isAllTypes
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (_hovered || widget.isAllTypes)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: widget.primaryColor.withOpacity(0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
