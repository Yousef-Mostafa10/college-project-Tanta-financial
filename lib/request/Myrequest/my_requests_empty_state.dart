import 'package:flutter/material.dart';
import 'my_requests_colors.dart';

Widget buildEmptyState(bool isMobile, {Function()? onResetFilters}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 60.0),
      child:SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: MyRequestsColors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              "No transactions found",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: MyRequestsColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Try adjusting your filters or check back later",
              style: TextStyle(
                fontSize: 12,
                color: MyRequestsColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            if (onResetFilters != null)
              ElevatedButton.icon(
                onPressed: onResetFilters,
                icon: Icon(Icons.refresh_rounded, size: 16),
                label: Text("Reset Filters"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyRequestsColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      )
    ),
  );
}