// import 'package:flutter/material.dart';
// import 'my_requests_colors.dart';
//
// Widget buildMobileFilterSection({
//   required TextEditingController searchController,
//   required String selectedPriority,
//   required String selectedType,
//   required String selectedStatus,
//   required List<String> priorities,
//   required List<String> typeNames,
//   required List<String> statuses,
//   required Function(String) onSearchChanged,
//   required Function() onPriorityTap,
//   required Function() onTypeTap,
//   required Function() onStatusTap,
// }) {
//   return Container(
//     margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//     padding: const EdgeInsets.all(12),
//     decoration: BoxDecoration(
//       color: MyRequestsColors.cardBg,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: MyRequestsColors.statShadow,
//           blurRadius: 8,
//           offset: Offset(0, 2),
//         ),
//       ],
//     ),
//     child: Column(
//       children: [
//         // شريط البحث
//         TextField(
//           controller: searchController,
//           decoration: InputDecoration(
//             hintText: 'Search transactions...',
//             hintStyle: TextStyle(color: MyRequestsColors.textMuted),
//             prefixIcon: const Icon(Icons.search_rounded, color: MyRequestsColors.primary),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: BorderSide.none,
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: BorderSide(color: MyRequestsColors.primary, width: 1.5),
//             ),
//             filled: true,
//             fillColor: MyRequestsColors.bodyBg,
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             isDense: true,
//           ),
//           onChanged: onSearchChanged,
//         ),
//         const SizedBox(height: 12),
//
//         // الفلاتر في صف واحد
//         Row(
//           children: [
//             Expanded(
//               child: _buildMobileFilterChip(
//                 label: "Priority",
//                 value: selectedPriority,
//                 icon: Icons.flag_outlined,
//                 onTap: onPriorityTap,
//               ),
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: _buildMobileFilterChip(
//                 label: "Type",
//                 value: selectedType,
//                 icon: Icons.category_outlined,
//                 onTap: onTypeTap,
//               ),
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: _buildMobileFilterChip(
//                 label: "Status",
//                 value: selectedStatus,
//                 icon: Icons.hourglass_top_outlined,
//                 onTap: onStatusTap,
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }
//
// Widget _buildMobileFilterChip({
//   required String label,
//   required String value,
//   required IconData icon,
//   required VoidCallback onTap,
// }) {
//   return GestureDetector(
//     onTap: onTap,
//     child: Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
//       decoration: BoxDecoration(
//         color: MyRequestsColors.primary.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: MyRequestsColors.primary.withOpacity(0.2)),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 14, color: MyRequestsColors.primary),
//           const SizedBox(height: 2),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 9,
//               color: MyRequestsColors.primary,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           if (value != 'All' && value != 'All Types')
//             Text(
//               value.length > 8 ? value.substring(0, 8) + '...' : value,
//               style: TextStyle(
//                 fontSize: 8,
//                 color: MyRequestsColors.textPrimary,
//                 fontWeight: FontWeight.w600,
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//         ],
//       ),
//     ),
//   );
// }


import 'package:flutter/material.dart';
import 'my_requests_colors.dart';

Widget buildMobileFilterSection({
  required TextEditingController searchController,
  required String selectedPriority,
  required String selectedType,
  required String selectedStatus,
  required List<String> priorities,
  required List<String> typeNames,
  required List<String> statuses,
  required Function(String) onSearchChanged,
  required Function() onPriorityTap,
  required Function() onTypeTap,
  required Function() onStatusTap,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: MyRequestsColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: MyRequestsColors.statShadow,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        // شريط البحث
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search transactions...',
            hintStyle: TextStyle(color: MyRequestsColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: MyRequestsColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: MyRequestsColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: MyRequestsColors.bodyBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            isDense: true,
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),

        // الفلاتر في صف واحد
        Row(
          children: [
            Expanded(
              child: _buildMobileFilterChip(
                label: "Priority",
                value: selectedPriority,
                icon: Icons.flag_outlined,
                onTap: onPriorityTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMobileFilterChip(
                label: "Type",
                value: selectedType,
                icon: Icons.category_outlined,
                onTap: onTypeTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMobileFilterChip(
                label: "Status",
                value: selectedStatus,
                icon: Icons.hourglass_top_outlined,
                onTap: onStatusTap,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildMobileFilterChip({
  required String label,
  required String value,
  required IconData icon,
  required VoidCallback onTap,
}) {
  // تحديد لون النص حسب الحالة
  Color getTextColor() {
    if (label == "Status") {
      switch (value.toLowerCase()) {
        case 'waiting':
          return MyRequestsColors.statusWaiting;
        case 'approved':
          return MyRequestsColors.statusApproved;
        case 'rejected':
          return MyRequestsColors.statusRejected;
        case 'needs change':
          return MyRequestsColors.statusNeedsChange;
        case 'fulfilled':
          return MyRequestsColors.statusFulfilled;
        default:
          return MyRequestsColors.textPrimary;
      }
    }
    return MyRequestsColors.textPrimary;
  }

  // تحديد أيقونة حسب الحالة
  IconData getStatusIcon() {
    if (label == "Status") {
      switch (value.toLowerCase()) {
        case "approved":
          return Icons.check_circle_rounded;
        case "rejected":
          return Icons.cancel_rounded;
        case "waiting":
          return Icons.hourglass_empty_rounded;
        case "needs change":
          return Icons.edit_note_rounded;
        case "fulfilled":
          return Icons.task_alt_rounded;
        case "all":
          return Icons.filter_list_rounded;
        default:
          return icon;
      }
    }
    return icon;
  }

  // تحديد لون الأيقونة
  Color getIconColor() {
    if (label == "Status") {
      return getTextColor();
    }
    return MyRequestsColors.primary;
  }

  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: MyRequestsColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MyRequestsColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            getStatusIcon(), // استخدم الأيقونة المناسبة للحالة
            size: 14,
            color: getIconColor(), // لون الأيقونة حسب الحالة
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: MyRequestsColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (value != 'All' && value != 'All Types')
            Text(
              value.length > 8 ? value.substring(0, 8) + '...' : value,
              style: TextStyle(
                fontSize: 8,
                color: getTextColor(), // لون النص حسب الحالة
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    ),
  );
}