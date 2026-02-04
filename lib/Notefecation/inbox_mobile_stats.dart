// // Notefecation/inbox_mobile_stats.dart
// import 'package:flutter/material.dart';
// import './inbox_colors.dart';
//
// class InboxMobileStats extends StatelessWidget {
//   final int total;
//   final int waiting;
//   final int approved;
//   final int rejected;
//   final int fulfilled;
//
//   const InboxMobileStats({
//     Key? key,
//     required this.total,
//     required this.waiting,
//     required this.approved,
//     required this.rejected,
//     required this.fulfilled,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final statItems = [
//       {"label": "Total", "value": total, "color": InboxColors.textPrimary, "icon": Icons.dashboard_rounded},
//       {"label": "Waiting", "value": waiting, "color": InboxColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
//       {"label": "Approved", "value": approved, "color": InboxColors.statusApproved, "icon": Icons.check_circle_rounded},
//       {"label": "Rejected", "value": rejected, "color": InboxColors.statusRejected, "icon": Icons.cancel_rounded},
//       if (fulfilled > 0) {"label": "Fulfilled", "value": fulfilled, "color": InboxColors.statusFulfilled, "icon": Icons.check_rounded},
//     ];
//
//     return Container(
//       margin: const EdgeInsets.all(12),
//       padding: const EdgeInsets.all(16),
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
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: statItems.map((stat) => _buildMobileStatItem(
//           label: stat["label"] as String,
//           value: stat["value"] as int,
//           color: stat["color"] as Color,
//           icon: stat["icon"] as IconData,
//         )).toList(),
//       ),
//     );
//   }
//
//   Widget _buildMobileStatItem({required String label, required int value, required Color color, required IconData icon}) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//             border: Border.all(color: color.withOpacity(0.3), width: 1),
//           ),
//           child: Icon(icon, color: color, size: 18),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           value.toString(),
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 2),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 10,
//             fontWeight: FontWeight.w500,
//             color: InboxColors.textSecondary,
//           ),
//         ),
//       ],
//     );
//   }
// }


// Notefecation/inbox_mobile_stats.dart


import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import './inbox_colors.dart';

class InboxMobileStats extends StatelessWidget {
  final int total;
  final int waiting;
  final int approved;
  final int rejected;
  final int fulfilled;
  final int needsChange; // إضافة هذا الحقل

  const InboxMobileStats({
    Key? key,
    required this.total,
    required this.waiting,
    required this.approved,
    required this.rejected,
    required this.fulfilled,
    required this.needsChange, // إضافة هذا
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statItems = [
      {"label": AppLocalizations.of(context)!.translate('total_stat'), "value": total, "color": InboxColors.textPrimary, "icon": Icons.dashboard_rounded},
      {"label": AppLocalizations.of(context)!.translate('waiting'), "value": waiting, "color": InboxColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
      {"label": AppLocalizations.of(context)!.translate('approved'), "value": approved, "color": InboxColors.statusApproved, "icon": Icons.check_circle_rounded},
      {"label": AppLocalizations.of(context)!.translate('rejected'), "value": rejected, "color": InboxColors.statusRejected, "icon": Icons.cancel_rounded},
      {"label": AppLocalizations.of(context)!.translate('needs_change'), "value": needsChange, "color": Colors.orange, "icon": Icons.edit_note_rounded}, // إضافة هذا الصف
      {"label": AppLocalizations.of(context)!.translate('fulfilled'), "value": fulfilled, "color": InboxColors.statusFulfilled, "icon": Icons.task_alt_rounded},
    ];

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisSize: MainAxisSize.min, // تغيير السطر ده
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: statItems.map((stat) => _buildMobileStatItem(
          label: stat["label"] as String,
          value: stat["value"] as int,
          color: stat["color"] as Color,
          icon: stat["icon"] as IconData,
        )).toList(),
      ),
    );
  }

  Widget _buildMobileStatItem({required String label, required int value, required Color color, required IconData icon}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: InboxColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
