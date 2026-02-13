import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'dashboard_colors.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final bool isMobile;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.statShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // زر الصفحة السابقة
          _buildPageButton(
            icon: Icons.chevron_left_rounded,
            onPressed: currentPage > 1
                ? () => onPageChanged(currentPage - 1)
                : null,
          ),

          const SizedBox(width: 4),

          // أرقام الصفحات
          if (isMobile)
            _buildMobilePageNumbers(context)
          else
            _buildDesktopPageNumbers(context),

          const SizedBox(width: 4),

          // زر الصفحة التالية
          _buildPageButton(
            icon: Icons.chevron_right_rounded,
            onPressed: currentPage < totalPages
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPageNumbers(BuildContext context) {
    List<Widget> pageButtons = [];

    if (totalPages <= 7) {
      // عرض كل الأرقام
      for (int i = 1; i <= totalPages; i++) {
        pageButtons.add(_buildPageNumber(i));
      }
    } else {
      // عرض مع علامة ...
      if (currentPage <= 4) {
        for (int i = 1; i <= 5; i++) {
          pageButtons.add(_buildPageNumber(i));
        }
        pageButtons.add(_buildDots());
        pageButtons.add(_buildPageNumber(totalPages));
      } else if (currentPage >= totalPages - 3) {
        pageButtons.add(_buildPageNumber(1));
        pageButtons.add(_buildDots());
        for (int i = totalPages - 4; i <= totalPages; i++) {
          pageButtons.add(_buildPageNumber(i));
        }
      } else {
        pageButtons.add(_buildPageNumber(1));
        pageButtons.add(_buildDots());
        pageButtons.add(_buildPageNumber(currentPage - 1));
        pageButtons.add(_buildPageNumber(currentPage));
        pageButtons.add(_buildPageNumber(currentPage + 1));
        pageButtons.add(_buildDots());
        pageButtons.add(_buildPageNumber(totalPages));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: pageButtons,
    );
  }

  Widget _buildMobilePageNumbers(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Text(
        '$currentPage / $totalPages',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPageNumber(int page) {
    final isSelected = page == currentPage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPageChanged(page),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.statBorder,
              ),
            ),
            child: Text(
              page.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: onPressed != null
                  ? AppColors.primary.withOpacity(0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: onPressed != null
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.statBorder,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: onPressed != null
                  ? AppColors.primary
                  : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}