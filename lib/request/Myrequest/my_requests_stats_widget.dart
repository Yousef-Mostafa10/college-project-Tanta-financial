// import 'package:flutter/material.dart';
// import 'my_requests_colors.dart';
//
// Widget buildStatItem(String label, int value, Color color, IconData icon, bool isMobile) {
//   return Column(
//     children: [
//       Container(
//         padding: EdgeInsets.all(isMobile ? 8 : 10),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           shape: BoxShape.circle,
//           border: Border.all(color: color.withOpacity(0.3), width: 1),
//         ),
//         child: Icon(icon, color: color, size: isMobile ? 18 : 22),
//       ),
//       SizedBox(height: isMobile ? 6 : 10),
//       Text(
//         value.toString(),
//         style: TextStyle(
//           fontSize: isMobile ? 16 : 20,
//           fontWeight: FontWeight.bold,
//           color: color,
//         ),
//       ),
//       SizedBox(height: isMobile ? 2 : 6),
//       Text(
//         label,
//         style: TextStyle(
//           fontSize: isMobile ? 10 : 13,
//           fontWeight: FontWeight.w500,
//           color: MyRequestsColors.textSecondary,
//         ),
//       ),
//     ],
//   );
// }
//
// Widget buildDesktopStatsRow(int total, int approved, int rejected, int waiting) {
//   final stats = [
//     {"label": "Total", "value": total, "color": MyRequestsColors.textPrimary, "icon": Icons.dashboard_rounded},
//     {"label": "Approved", "value": approved, "color": MyRequestsColors.statusApproved, "icon": Icons.check_circle_rounded},
//     {"label": "Rejected", "value": rejected, "color": MyRequestsColors.statusRejected, "icon": Icons.cancel_rounded},
//     {"label": "Waiting", "value": waiting, "color": MyRequestsColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
//   ];
//
//   return Container(
//     decoration: BoxDecoration(
//       color: MyRequestsColors.statBgLight,
//       borderRadius: BorderRadius.circular(16),
//       boxShadow: [
//         BoxShadow(
//           color: MyRequestsColors.statShadow,
//           blurRadius: 10,
//           offset: Offset(0, 4),
//         ),
//       ],
//       border: Border.all(color: MyRequestsColors.statBorder),
//     ),
//     child: Padding(
//       padding: EdgeInsets.all(20),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: stats.map((stat) =>
//             buildStatItem(
//                 stat["label"] as String,
//                 stat["value"] as int,
//                 stat["color"] as Color,
//                 stat["icon"] as IconData,
//                 false
//             )
//         ).toList(),
//       ),
//     ),
//   );
// }


import 'package:flutter/material.dart';
import 'my_requests_colors.dart';

Widget buildDesktopStatsRow(int total, int approved, int rejected, int waiting, int needsChange, int fulfilled) {
  final stats = [
    {"label": "Total", "value": total, "color": MyRequestsColors.textPrimary, "icon": Icons.dashboard_rounded},
    {"label": "Approved", "value": approved, "color": MyRequestsColors.statusApproved, "icon": Icons.check_circle_rounded},
    {"label": "Rejected", "value": rejected, "color": MyRequestsColors.statusRejected, "icon": Icons.cancel_rounded},
    {"label": "Waiting", "value": waiting, "color": MyRequestsColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
    {"label": "Needs Change", "value": needsChange, "color": MyRequestsColors.statusNeedsChange, "icon": Icons.edit_note_rounded},
    {"label": "Fulfilled", "value": fulfilled, "color": MyRequestsColors.statusFulfilled, "icon": Icons.task_alt_rounded},
  ];

  return Container(
    decoration: BoxDecoration(
      color: MyRequestsColors.statBgLight,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: MyRequestsColors.statShadow,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
      border: Border.all(color: MyRequestsColors.statBorder),
    ),
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((stat) => Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (stat["color"] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: (stat["color"] as Color).withOpacity(0.3), width: 1),
              ),
              child: Icon(stat["icon"] as IconData, color: stat["color"] as Color, size: 22),
            ),
            SizedBox(height: 10),
            Text(
              (stat["value"] as int).toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: stat["color"] as Color,
              ),
            ),
            SizedBox(height: 6),
            Text(
              stat["label"] as String,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: MyRequestsColors.textSecondary,
              ),
            ),
          ],
        )).toList(),
      ),
    ),
  );
}