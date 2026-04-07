import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';

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
  void _openPicker() {
    showDialog(
      context: context,
      builder: (context) => _TypePickerDialog(
        fetchPage: widget.fetchPage,
        onSelected: (val) {
          widget.onTypeChanged(val);
          Navigator.pop(context);
        },
        primaryColor: widget.primaryColor,
        textColor: widget.textColor,
        cardBg: widget.cardBg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayText = widget.selectedType;
    if (displayText.toLowerCase() == 'all types') {
      displayText = AppLocalizations.of(context)!.translate('all_types');
    }

    return InkWell(
      onTap: _openPicker,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: widget.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 8 : 12),
        child: Row(
          children: [
            Icon(
              Icons.category_outlined,
              size: widget.isMobile ? 14 : 18,
              color: widget.primaryColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: widget.isMobile ? 12 : 14,
                  color: widget.selectedType.toLowerCase() == 'all types'
                      ? widget.primaryColor
                      : widget.textColor,
                  fontWeight: widget.selectedType.toLowerCase() == 'all types'
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: widget.textColor.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _TypePickerDialogState extends State<_TypePickerDialog> {
  final List<String> _types = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                AppLocalizations.of(context)!.translate('all_types'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.primaryColor,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _types.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _types.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final type = _types[index];
                  String displayText = type;
                  if (type.toLowerCase() == 'all types') {
                    displayText = AppLocalizations.of(context)!.translate('all_types');
                  }

                  return ListTile(
                    title: Text(
                      displayText,
                      style: TextStyle(
                        color: type.toLowerCase() == 'all types'
                            ? widget.primaryColor
                            : widget.textColor,
                        fontWeight: type.toLowerCase() == 'all types'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () => widget.onSelected(type),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
