// home/header_widget.dart
import 'package:flutter/material.dart';
import 'dashboard_colors.dart';

class HeaderWidget extends StatelessWidget {
  final int itemCount;
  final bool isMobile;

  const HeaderWidget({
    super.key,
    required this.itemCount,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt_outlined, color: AppColors.primary, size: isMobile ? 14 : 18),
              const SizedBox(width: 6),
              Text(
                'TRANSACTIONS',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              '$itemCount items',
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}