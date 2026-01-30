// import 'package:flutter/material.dart';
// import 'my_requests_colors.dart';
//
// Widget buildDesktopFilters({
//   required String selectedPriority,
//   required String selectedType,
//   required String selectedStatus,
//   required List<String> priorities,
//   required List<String> typeNames,
//   required List<String> statuses,
//   required Function(String?) onPriorityChanged,
//   required Function(String?) onTypeChanged,
//   required Function(String?) onStatusChanged,
// }) {
//   return Card(
//     elevation: 2,
//     color: MyRequestsColors.cardBg,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(12),
//     ),
//     child: Padding(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.filter_alt_outlined, color: MyRequestsColors.primary, size: 16),
//               SizedBox(width: 6),
//               Text(
//                 'FILTERS',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: MyRequestsColors.primary,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildFilterDropdown(
//                   value: selectedPriority,
//                   items: priorities,
//                   label: "Priority",
//                   icon: Icons.flag_outlined,
//                   onChanged: onPriorityChanged,
//                 ),
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: _buildFilterDropdown(
//                   value: selectedType,
//                   items: typeNames,
//                   label: "Type",
//                   icon: Icons.category_outlined,
//                   onChanged: onTypeChanged,
//                 ),
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: _buildFilterDropdown(
//                   value: selectedStatus,
//                   items: statuses,
//                   label: "Status",
//                   icon: Icons.hourglass_top_outlined,
//                   onChanged: onStatusChanged,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     ),
//   );
// }
//
// Widget _buildFilterDropdown({
//   required String value,
//   required List<String> items,
//   required String label,
//   required IconData icon,
//   required Function(String?) onChanged,
// }) {
//   IconData _getStatusFilterIcon(String status) {
//     switch (status.toLowerCase()) {
//       case "approved":
//         return Icons.check_circle_rounded;
//       case "rejected":
//         return Icons.cancel_rounded;
//       case "waiting":
//         return Icons.hourglass_empty_rounded;
//       case "all":
//         return Icons.filter_list_rounded;
//       default:
//         return Icons.hourglass_top_outlined;
//     }
//   }
//
//   return Container(
//     decoration: BoxDecoration(
//       border: Border.all(color: MyRequestsColors.statBorder),
//       borderRadius: BorderRadius.circular(8),
//     ),
//     child: Padding(
//       padding: EdgeInsets.symmetric(horizontal: 12),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: value,
//           isExpanded: true,
//           icon: Icon(Icons.arrow_drop_down_rounded, color: MyRequestsColors.textSecondary),
//           style: TextStyle(
//             fontSize: 14,
//             color: MyRequestsColors.textPrimary,
//             fontWeight: FontWeight.w500,
//           ),
//           items: items
//               .map((item) => DropdownMenuItem(
//             value: item,
//             child: Row(
//               children: [
//                 Icon(
//                   label == "Status" ? _getStatusFilterIcon(item) : icon,
//                   size: 18,
//                   color: MyRequestsColors.primary,
//                 ),
//                 SizedBox(width: 6),
//                 Expanded(
//                   child: Text(
//                     item,
//                     style: TextStyle(
//                       color: item == 'All Types' || item == 'All'
//                           ? MyRequestsColors.primary
//                           : MyRequestsColors.textPrimary,
//                       fontWeight: item == 'All Types' || item == 'All'
//                           ? FontWeight.w600
//                           : FontWeight.w500,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ))
//               .toList(),
//           onChanged: onChanged,
//         ),
//       ),
//     ),
//   );
// }

import 'package:flutter/material.dart';
import 'my_requests_colors.dart';

class MyRequestsDesktopFilters extends StatelessWidget {
  final String selectedPriority;
  final String selectedType;
  final String selectedStatus;
  final List<String> priorities;
  final List<String> typeNames;
  final List<String> statuses;
  final TextEditingController searchController;
  final Function(String?) onPriorityChanged;
  final Function(String?) onTypeChanged;
  final Function(String?) onStatusChanged;
  final Function(String) onSearchChanged;

  const MyRequestsDesktopFilters({
    Key? key,
    required this.selectedPriority,
    required this.selectedType,
    required this.selectedStatus,
    required this.priorities,
    required this.typeNames,
    required this.statuses,
    required this.searchController,
    required this.onPriorityChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط البحث
        Container(
          decoration: BoxDecoration(
            color: MyRequestsColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: MyRequestsColors.statShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search requests...',
              hintStyle: TextStyle(color: MyRequestsColors.textMuted),
              prefixIcon: Icon(Icons.search_rounded, color: MyRequestsColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: MyRequestsColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: MyRequestsColors.bodyBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(height: 16),

        // فلاتر الديسكتوب
        Card(
          elevation: 2,
          color: MyRequestsColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, color: MyRequestsColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'FILTERS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MyRequestsColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDesktopFilterDropdown(
                        value: selectedPriority,
                        items: priorities,
                        label: "Priority",
                        icon: Icons.flag_outlined,
                        onChanged: (value) => onPriorityChanged(value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDesktopFilterDropdown(
                        value: selectedType,
                        items: typeNames,
                        label: "Type",
                        icon: Icons.category_outlined,
                        onChanged: (value) => onTypeChanged(value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDesktopFilterDropdown(
                        value: selectedStatus,
                        items: statuses,
                        label: "Status",
                        icon: Icons.hourglass_top_outlined,
                        onChanged: (value) => onStatusChanged(value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopFilterDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: MyRequestsColors.statBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_rounded, color: MyRequestsColors.textSecondary),
            style: TextStyle(
              fontSize: 14,
              color: MyRequestsColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            items: items
                .map((item) => DropdownMenuItem(
              value: item,
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(label, item),
                    size: 18,
                    color: _getStatusColor(label, item),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: _getStatusTextColor(label, item),
                        fontWeight: _getStatusFontWeight(label, item),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String label, String item) {
    if (label == "Status") {
      return _getStatusFilterIcon(item);
    } else if (label == "Priority") {
      return Icons.flag_outlined;
    } else {
      return Icons.category_outlined;
    }
  }

  IconData _getStatusFilterIcon(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return Icons.filter_list_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'waiting':
        return Icons.hourglass_empty_rounded;
      case 'needs change':
        return Icons.edit_note_rounded;
      case 'fulfilled':
        return Icons.task_alt_rounded;
      default:
        return Icons.hourglass_top_outlined;
    }
  }

  Color _getStatusColor(String label, String item) {
    if (label == "Status") {
      switch (item.toLowerCase()) {
        case 'all':
          return MyRequestsColors.primary;
        case 'approved':
          return MyRequestsColors.statusApproved;
        case 'rejected':
          return MyRequestsColors.statusRejected;
        case 'waiting':
          return MyRequestsColors.statusWaiting;
        case 'needs change':
          return MyRequestsColors.statusNeedsChange;
        case 'fulfilled':
          return MyRequestsColors.statusFulfilled;
        default:
          return MyRequestsColors.primary;
      }
    } else {
      return MyRequestsColors.primary;
    }
  }

  Color _getStatusTextColor(String label, String item) {
    if (item == 'All Types' || item == 'All' || item == 'All Priorities') {
      return MyRequestsColors.primary;
    }

    if (label == "Status") {
      switch (item.toLowerCase()) {
        case 'approved':
          return MyRequestsColors.statusApproved;
        case 'rejected':
          return MyRequestsColors.statusRejected;
        case 'waiting':
          return MyRequestsColors.statusWaiting;
        case 'needs change':
          return MyRequestsColors.statusNeedsChange;
        case 'fulfilled':
          return MyRequestsColors.statusFulfilled;
        default:
          return MyRequestsColors.textPrimary;
      }
    } else {
      return MyRequestsColors.textPrimary;
    }
  }

  FontWeight _getStatusFontWeight(String label, String item) {
    if (item == 'All Types' || item == 'All' || item == 'All Priorities') {
      return FontWeight.w600;
    }
    return FontWeight.w500;
  }
}