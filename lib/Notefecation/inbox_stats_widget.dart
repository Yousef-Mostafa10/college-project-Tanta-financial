// // Notefecation/inbox_stats_widget.dart
// import 'package:flutter/material.dart';
// import './inbox_colors.dart';
//
// class InboxStatsWidget extends StatelessWidget {
//   final List<dynamic> requests;
//   final bool isMobile;
//
//   const InboxStatsWidget({
//     Key? key,
//     required this.requests,
//     this.isMobile = false,
//   }) : super(key: key);
//
//   // حساب الإحصائيات
//   Map<String, int> _calculateStats() {
//     final total = requests.length;
//     final waiting = requests.where((req) {
//       final userForwardStatus = req['yourForwardStatus'];
//       final fulfilled = req["fulfilled"] == true;
//       return (userForwardStatus != "approved" &&
//           userForwardStatus != "rejected" &&
//           !fulfilled) ||
//           (userForwardStatus == null && !fulfilled);
//     }).length;
//
//     final approved = requests.where((req) => req['yourForwardStatus'] == "approved").length;
//     final rejected = requests.where((req) => req['yourForwardStatus'] == "rejected").length;
//     final fulfilled = requests.where((req) => req["fulfilled"] == true).length;
//
//     return {
//       'total': total,
//       'waiting': waiting,
//       'approved': approved,
//       'rejected': rejected,
//       'fulfilled': fulfilled,
//     };
//   }
//
//   // إحصائيات الديسكتوب
//   Widget _buildDesktopStatsRow() {
//     final stats = _calculateStats();
//
//     final statItems = [
//       {"label": "Total", "value": stats['total']!, "color": InboxColors.textPrimary, "icon": Icons.dashboard_rounded},
//       {"label": "Waiting", "value": stats['waiting']!, "color": InboxColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
//       {"label": "Approved", "value": stats['approved']!, "color": InboxColors.statusApproved, "icon": Icons.check_circle_rounded},
//       {"label": "Rejected", "value": stats['rejected']!, "color": InboxColors.statusRejected, "icon": Icons.cancel_rounded},
//       if (stats['fulfilled']! > 0) {"label": "Fulfilled", "value": stats['fulfilled']!, "color": InboxColors.statusFulfilled, "icon": Icons.check_rounded},
//     ];
//
//     return Container(
//       decoration: BoxDecoration(
//         color: InboxColors.statBgLight,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: InboxColors.statShadow,
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//         border: Border.all(color: InboxColors.statBorder),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: statItems.map((stat) =>
//               _buildStatItem(
//                 stat["label"] as String,
//                 stat["value"] as int,
//                 stat["color"] as Color,
//                 stat["icon"] as IconData,
//                 false,
//               )
//           ).toList(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatItem(String label, int value, Color color, IconData icon, bool isMobile) {
//     return Column(
//       children: [
//         Container(
//           padding: EdgeInsets.all(isMobile ? 8 : 10),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//             border: Border.all(color: color.withOpacity(0.3), width: 1),
//           ),
//           child: Icon(icon, color: color, size: isMobile ? 18 : 22),
//         ),
//         SizedBox(height: isMobile ? 6 : 10),
//         Text(
//           value.toString(),
//           style: TextStyle(
//             fontSize: isMobile ? 16 : 20,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         SizedBox(height: isMobile ? 2 : 6),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: isMobile ? 10 : 13,
//             fontWeight: FontWeight.w500,
//             color: InboxColors.textSecondary,
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return _buildDesktopStatsRow();
//   }
// }

// Notefecation/inbox_stats_widget.dart


import 'package:flutter/material.dart';
import './inbox_colors.dart';
import './inbox_helpers.dart';

class InboxStatsWidget extends StatelessWidget {
  final List<dynamic> requests;
  final bool isMobile;

  const InboxStatsWidget({
    Key? key,
    required this.requests,
    this.isMobile = false,
  }) : super(key: key);

  // حساب الإحصائيات
  Map<String, int> _calculateStats() {
    final total = requests.length;

    final waiting = requests.where((req) =>
    InboxHelpers.isRequestPending(req) &&
        req["fulfilled"] != true
    ).length;

    final approved = requests.where((req) =>
    InboxHelpers.isRequestApproved(req) &&
        req["fulfilled"] != true
    ).length;

    final rejected = requests.where((req) =>
    InboxHelpers.isRequestRejected(req) &&
        req["fulfilled"] != true
    ).length;

    final needsChange = requests.where((req) =>
    InboxHelpers.isRequestNeedsChange(req) &&
        req["fulfilled"] != true
    ).length;

    final fulfilled = requests.where((req) => req["fulfilled"] == true).length;

    return {
      'total': total,
      'waiting': waiting,
      'approved': approved,
      'rejected': rejected,
      'needs_change': needsChange,
      'fulfilled': fulfilled,
    };
  }

  // إحصائيات الديسكتوب
  Widget _buildDesktopStatsRow() {
    final stats = _calculateStats();

    final statItems = [
      {"label": "Total", "value": stats['total']!, "color": InboxColors.textPrimary, "icon": Icons.dashboard_rounded},
      {"label": "Waiting", "value": stats['waiting']!, "color": InboxColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
      {"label": "Approved", "value": stats['approved']!, "color": InboxColors.statusApproved, "icon": Icons.check_circle_rounded},
      {"label": "Rejected", "value": stats['rejected']!, "color": InboxColors.statusRejected, "icon": Icons.cancel_rounded},
      {"label": "Needs Change", "value": stats['needs_change']!, "color": Colors.orange, "icon": Icons.edit_note_rounded},
      {"label": "Fulfilled", "value": stats['fulfilled']!, "color": InboxColors.statusFulfilled, "icon": Icons.task_alt_rounded},
    ];

    return Container(
      decoration: BoxDecoration(
        color: InboxColors.statBgLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: InboxColors.statShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: InboxColors.statBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: statItems.map((stat) =>
              _buildStatItem(
                stat["label"] as String,
                stat["value"] as int,
                stat["color"] as Color,
                stat["icon"] as IconData,
                false,
              )
          ).toList(),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, IconData icon, bool isMobile) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: isMobile ? 18 : 22),
        ),
        SizedBox(height: isMobile ? 6 : 10),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: isMobile ? 16 : 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: isMobile ? 2 : 6),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 13,
            fontWeight: FontWeight.w500,
            color: InboxColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildDesktopStatsRow();
  }
}