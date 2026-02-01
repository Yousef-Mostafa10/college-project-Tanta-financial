// // Notefecation/inbox_mobile_card.dart
// import 'package:flutter/material.dart';
// import './inbox_colors.dart';
// import './inbox_helpers.dart';
// import './inbox_formatters.dart';
//
// class InboxMobileCard extends StatelessWidget {
//   final Map<String, dynamic> request;
//   final VoidCallback onViewDetails;
//   final VoidCallback onApprove;
//   final VoidCallback onReject;
//   final VoidCallback onForward;
//   final VoidCallback onCancelForward;
//   final bool hasForwarded;
//
//   const InboxMobileCard({
//     Key? key,
//     required this.request,
//     required this.onViewDetails,
//     required this.onApprove,
//     required this.onReject,
//     required this.onForward,
//     required this.onCancelForward,
//     required this.hasForwarded,
//   }) : super(key: key);
//
//   Widget _buildMobileChip(String text, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 10, color: color),
//           const SizedBox(width: 2),
//           Text(
//             text.length > 8 ? text.substring(0, 8) + '...' : text,
//             style: TextStyle(
//               fontSize: 9,
//               color: color,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final id = request["id"].toString();
//     final title = request["title"] ?? "No Title";
//     final type = request["type"]?["name"] ?? "N/A";
//     final priority = request["priority"] ?? "N/A";
//     final senderName = request["lastSenderName"] ?? request["creator"]?["name"] ?? "Unknown";
//     final createdAt = request["createdAt"];
//     final formattedDate = InboxFormatters.formatDate(createdAt);
//     final forwardStatus = (request['yourForwardStatus'] ?? 'not-assigned').toString();
//     final isPending = forwardStatus == 'waiting' || forwardStatus == 'not-assigned';
//     final isApproved = forwardStatus == 'approved';
//     final isRejected = forwardStatus == 'rejected';
//     final fulfilled = request["fulfilled"] == true;
//     final statusLabel = fulfilled
//         ? "Fulfilled"
//         : (isApproved ? "Approved" : (isPending ? "Waiting" : "Rejected"));
//     final statusColor = fulfilled
//         ? InboxColors.statusFulfilled
//         : (isApproved
//         ? InboxColors.statusApproved
//         : (isPending ? InboxColors.statusWaiting : InboxColors.statusRejected));
//     final lastForwardSentTo = request['lastForwardSentTo'];
//
//     IconData getStatusIcon() {
//       if (fulfilled) return Icons.check_rounded;
//       if (isApproved) return Icons.check_circle_rounded;
//       if (isRejected) return Icons.cancel_rounded;
//       return Icons.hourglass_empty_rounded;
//     }
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Card(
//         elevation: 1,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: InboxColors.cardBg,
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // الصف العلوي: العنوان والحالة
//               Row(
//                 children: [
//                   Container(
//                     width: 32,
//                     height: 32,
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       shape: BoxShape.circle,
//                       border: Border.all(color: statusColor.withOpacity(0.3)),
//                     ),
//                     child: Icon(getStatusIcon(), color: statusColor, size: 16),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: InboxColors.textPrimary,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: statusColor.withOpacity(0.3)),
//                     ),
//                     child: Text(
//                       statusLabel,
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                         color: statusColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//
//               // المرسل
//               Row(
//                 children: [
//                   Icon(Icons.person_rounded, size: 12, color: InboxColors.textSecondary),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       "From: $senderName",
//                       style: TextStyle(fontSize: 11, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//
//               // التاريخ
//               Row(
//                 children: [
//                   Icon(Icons.calendar_today_rounded, size: 12, color: InboxColors.textSecondary),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       formattedDate.length > 16 ? formattedDate.substring(0, 16) : formattedDate,
//                       style: TextStyle(fontSize: 11, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//
//               // النوع والأولوية
//               Row(
//                 children: [
//                   _buildMobileChip(type, Icons.category_outlined, InboxColors.primary),
//                   const SizedBox(width: 6),
//                   _buildMobileChip(priority, Icons.flag_outlined, InboxHelpers.getPriorityColor(priority)),
//                 ],
//               ),
//               const SizedBox(height: 8),
//
//               // أزرار الإجراءات
//               if (isPending) ...[
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.primary,
//                           side: BorderSide(color: InboxColors.primary),
//                           padding: const EdgeInsets.symmetric(vertical: 4),
//                         ),
//                         child: const Text('View', style: TextStyle(fontSize: 12)),
//                       ),
//                     ),
//                     const SizedBox(width: 6),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: onApprove,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: InboxColors.accentGreen,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 4),
//                         ),
//                         child: const Text('Approve', style: TextStyle(fontSize: 12)),
//                       ),
//                     ),
//                     const SizedBox(width: 6),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: onReject,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: InboxColors.accentRed,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 4),
//                         ),
//                         child: const Text('Reject', style: TextStyle(fontSize: 12)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (isApproved && !hasForwarded) ...[
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: onForward,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: InboxColors.primary,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 8),
//                     ),
//                     child: const Text('Forward'),
//                   ),
//                 ),
//               ] else if (hasForwarded) ...[
//                 Column(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: InboxColors.bodyBg,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: InboxColors.statBorder),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.send_rounded, size: 14, color: InboxColors.primary),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: Text(
//                               "Forwarded to ${lastForwardSentTo['receiverName']}",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                                 color: InboxColors.textPrimary,
//                               ),
//                             ),
//                           ),
//                           PopupMenuButton<String>(
//                             icon: Icon(Icons.more_vert_rounded, size: 16, color: InboxColors.textSecondary),
//                             itemBuilder: (context) => [
//                               const PopupMenuItem(
//                                 value: 'cancel',
//                                 child: Text('Cancel Forward'),
//                               ),
//                             ],
//                             onSelected: (value) {
//                               if (value == 'cancel') onCancelForward();
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.primary,
//                           side: BorderSide(color: InboxColors.primary),
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                         ),
//                         child: const Text('View Details'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (isRejected || fulfilled) ...[
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton(
//                     onPressed: onViewDetails,
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: InboxColors.primary,
//                       side: BorderSide(color: InboxColors.primary),
//                       padding: const EdgeInsets.symmetric(vertical: 8),
//                     ),
//                     child: const Text('View Details'),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import './inbox_colors.dart';
// import './inbox_helpers.dart';
// import './inbox_formatters.dart';
//
// class InboxMobileCard extends StatelessWidget {
//   final Map<String, dynamic> request;
//   final VoidCallback onViewDetails;
//   final VoidCallback onApprove;
//   final VoidCallback onReject;
//   final VoidCallback onForward;
//   final VoidCallback onCancelForward;
//   final VoidCallback onNeedChange;
//   final VoidCallback onEditRequest;
//   final bool hasForwarded;
//
//   const InboxMobileCard({
//     Key? key,
//     required this.request,
//     required this.onViewDetails,
//     required this.onApprove,
//     required this.onReject,
//     required this.onForward,
//     required this.onCancelForward,
//     required this.hasForwarded,
//     required this.onNeedChange,
//     required this.onEditRequest,
//   }) : super(key: key);
//
//   Widget _buildMobileChip(String text, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 10, color: color),
//           const SizedBox(width: 2),
//           Text(
//             text.length > 8 ? text.substring(0, 8) + '...' : text,
//             style: TextStyle(
//               fontSize: 9,
//               color: color,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final id = request["id"].toString();
//     final title = request["title"] ?? "No Title";
//     final type = request["type"]?["name"] ?? "N/A";
//     final priority = request["priority"] ?? "N/A";
//     final senderName = request["lastSenderName"] ?? request["creator"]?["name"] ?? "Unknown";
//     final createdAt = request["createdAt"];
//     final formattedDate = InboxFormatters.formatDate(createdAt);
//     final forwardStatus = (request['yourForwardStatus'] ?? 'not-assigned').toString();
//     final isPending = forwardStatus == 'waiting' || forwardStatus == 'not-assigned';
//     final isApproved = forwardStatus == 'approved';
//     final isRejected = forwardStatus == 'rejected';
//     final needsChange = forwardStatus == 'needs_change';
//     final fulfilled = request["fulfilled"] == true;
//     final statusLabel = fulfilled
//         ? "Fulfilled"
//         : (isApproved ? "Approved" : (needsChange ? "Needs Change" : (isPending ? "Waiting" : "Rejected")));
//     final statusColor = fulfilled
//         ? InboxColors.statusFulfilled
//         : (isApproved
//         ? InboxColors.statusApproved
//         : (needsChange ? Colors.orange : (isPending ? InboxColors.statusWaiting : InboxColors.statusRejected)));
//     final lastForwardSentTo = request['lastForwardSentTo'];
//
//     IconData getStatusIcon() {
//       if (fulfilled) return Icons.check_rounded;
//       if (isApproved) return Icons.check_circle_rounded;
//       if (isRejected) return Icons.cancel_rounded;
//       if (needsChange) return Icons.edit_note_rounded;
//       return Icons.hourglass_empty_rounded;
//     }
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Card(
//         elevation: 1,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: InboxColors.cardBg,
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // الصف العلوي: العنوان والحالة
//               Row(
//                 children: [
//                   Container(
//                     width: 32,
//                     height: 32,
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       shape: BoxShape.circle,
//                       border: Border.all(color: statusColor.withOpacity(0.3)),
//                     ),
//                     child: Icon(getStatusIcon(), color: statusColor, size: 16),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: InboxColors.textPrimary,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: statusColor.withOpacity(0.3)),
//                     ),
//                     child: Text(
//                       statusLabel,
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                         color: statusColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//
//               // المرسل
//               Row(
//                 children: [
//                   Icon(Icons.person_rounded, size: 12, color: InboxColors.textSecondary),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       "From: $senderName",
//                       style: TextStyle(fontSize: 11, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//
//               // التاريخ
//               Row(
//                 children: [
//                   Icon(Icons.calendar_today_rounded, size: 12, color: InboxColors.textSecondary),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       formattedDate.length > 16 ? formattedDate.substring(0, 16) : formattedDate,
//                       style: TextStyle(fontSize: 11, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//
//               // النوع والأولوية
//               Row(
//                 children: [
//                   _buildMobileChip(type, Icons.category_outlined, InboxColors.primary),
//                   const SizedBox(width: 6),
//                   _buildMobileChip(priority, Icons.flag_outlined, InboxHelpers.getPriorityColor(priority)),
//                 ],
//               ),
//               const SizedBox(height: 8),
//
//               // أزرار الإجراءات
//               if (isPending) ...[
//                 Column(
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: onViewDetails,
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: InboxColors.primary,
//                               side: BorderSide(color: InboxColors.primary),
//                               padding: const EdgeInsets.symmetric(vertical: 4),
//                             ),
//                             child: const Text('View', style: TextStyle(fontSize: 12)),
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: onApprove,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: InboxColors.accentGreen,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 4),
//                             ),
//                             child: const Text('Approve', style: TextStyle(fontSize: 12)),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: onNeedChange,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.orange,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 4),
//                             ),
//                             child: const Text('Need Change', style: TextStyle(fontSize: 12)),
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: onReject,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: InboxColors.accentRed,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 4),
//                             ),
//                             child: const Text('Reject', style: TextStyle(fontSize: 12)),
//                           ),
//                         ),
//                       ],
//                     ),
//                     // ⛔ تم حذف زر Forward من حالة isPending
//                   ],
//                 ),
//               ] else if (hasForwarded) ...[
//                 Column(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: InboxColors.bodyBg,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: InboxColors.statBorder),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.send_rounded, size: 14, color: InboxColors.primary),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: Text(
//                               "Forwarded to ${lastForwardSentTo['receiverName']}",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                                 color: InboxColors.textPrimary,
//                               ),
//                             ),
//                           ),
//                           PopupMenuButton<String>(
//                             icon: Icon(Icons.more_vert_rounded, size: 16, color: InboxColors.textSecondary),
//                             itemBuilder: (context) => [
//                               const PopupMenuItem(
//                                 value: 'cancel',
//                                 child: Text('Cancel Forward'),
//                               ),
//                             ],
//                             onSelected: (value) {
//                               if (value == 'cancel') onCancelForward();
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     // فقط أزرار Edit و View بدون Forward
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: onEditRequest,
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: Colors.blue,
//                               side: BorderSide(color: Colors.blue),
//                               padding: const EdgeInsets.symmetric(vertical: 6),
//                             ),
//                             child: const Text('Edit', style: TextStyle(fontSize: 12)),
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: onViewDetails,
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: InboxColors.primary,
//                               side: BorderSide(color: InboxColors.primary),
//                               padding: const EdgeInsets.symmetric(vertical: 6),
//                             ),
//                             child: const Text('View', style: TextStyle(fontSize: 12)),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ] else if (isApproved && !hasForwarded) ...[
//                 Column(
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: onEditRequest,
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: Colors.blue,
//                               side: BorderSide(color: Colors.blue),
//                               padding: const EdgeInsets.symmetric(vertical: 6),
//                             ),
//                             child: const Text('Edit', style: TextStyle(fontSize: 12)),
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: onForward, // ✅ زر Forward يظهر هنا (بعد الموافقة)
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: InboxColors.primary,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 6),
//                             ),
//                             child: const Text('Forward', style: TextStyle(fontSize: 12)),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.primary,
//                           side: BorderSide(color: InboxColors.primary),
//                           padding: const EdgeInsets.symmetric(vertical: 6),
//                         ),
//                         child: const Text('View Details'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (isRejected) ...[
//                 Column(
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: onEditRequest,
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: Colors.blue,
//                               side: BorderSide(color: Colors.blue),
//                               padding: const EdgeInsets.symmetric(vertical: 6),
//                             ),
//                             child: const Text('Edit', style: TextStyle(fontSize: 12)),
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: onForward, // ✅ زر Forward يظهر هنا (بعد الرفض)
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: InboxColors.primary,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 6),
//                             ),
//                             child: const Text('Forward', style: TextStyle(fontSize: 12)),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.accentRed,
//                           side: BorderSide(color: InboxColors.accentRed),
//                           padding: const EdgeInsets.symmetric(vertical: 6),
//                         ),
//                         child: const Text('View Details'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (needsChange) ...[
//                 Column(
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: onEditRequest,
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: Colors.blue,
//                               side: BorderSide(color: Colors.blue),
//                               padding: const EdgeInsets.symmetric(vertical: 6),
//                             ),
//                             child: const Text('Edit', style: TextStyle(fontSize: 12)),
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: onForward, // ✅ زر Forward يظهر هنا (بعد طلب التعديل)
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: InboxColors.primary,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 6),
//                             ),
//                             child: const Text('Forward', style: TextStyle(fontSize: 12)),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: Colors.orange,
//                           side: BorderSide(color: Colors.orange),
//                           padding: const EdgeInsets.symmetric(vertical: 6),
//                         ),
//                         child: const Text('View Details'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (fulfilled) ...[
//                 Column(
//                   children: [
//                     // زر Edit Request فقط (بدون Forward)
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onEditRequest,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: Colors.blue,
//                           side: BorderSide(color: Colors.blue),
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                         ),
//                         child: const Text('Edit Request'),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     // زر View Details فقط
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.statusFulfilled,
//                           side: BorderSide(color: InboxColors.statusFulfilled),
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                         ),
//                         child: const Text('View Details'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


//
//
// import 'package:flutter/material.dart';
// import './inbox_colors.dart';
// import './inbox_helpers.dart';
// import './inbox_formatters.dart';
//
// class InboxMobileCard extends StatelessWidget {
//   final Map<String, dynamic> request;
//   final VoidCallback onViewDetails;
//   final VoidCallback onApprove;
//   final VoidCallback onReject;
//   final VoidCallback onForward;
//   final VoidCallback onCancelForward;
//   final VoidCallback onNeedChange;
//   final VoidCallback onEditRequest;
//   final bool hasForwarded;
//
//   const InboxMobileCard({
//     Key? key,
//     required this.request,
//     required this.onViewDetails,
//     required this.onApprove,
//     required this.onReject,
//     required this.onForward,
//     required this.onCancelForward,
//     required this.hasForwarded,
//     required this.onNeedChange,
//     required this.onEditRequest,
//   }) : super(key: key);
//
//   Widget _buildMobileChip(String text, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 10, color: color),
//           const SizedBox(width: 2),
//           Text(
//             text.length > 8 ? text.substring(0, 8) + '...' : text,
//             style: TextStyle(
//               fontSize: 9,
//               color: color,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMobileActionButton({
//     required String text,
//     required VoidCallback onPressed,
//     required Color color,
//     bool isOutlined = false,
//     bool isLoading = false,
//   }) {
//     if (isLoading) {
//       return Expanded(
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           alignment: Alignment.center,
//           child: SizedBox(
//             width: 12,
//             height: 12,
//             child: CircularProgressIndicator(
//               strokeWidth: 1.5,
//               valueColor: AlwaysStoppedAnimation<Color>(color),
//             ),
//           ),
//         ),
//       );
//     }
//
//     if (isOutlined) {
//       return Expanded(
//         child: OutlinedButton(
//           onPressed: onPressed,
//           style: OutlinedButton.styleFrom(
//             foregroundColor: color,
//             side: BorderSide(color: color),
//             padding: const EdgeInsets.symmetric(vertical: 4),
//             minimumSize: const Size(0, 30),
//           ),
//           child: Text(text, style: const TextStyle(fontSize: 11)),
//         ),
//       );
//     }
//
//     return Expanded(
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           minimumSize: const Size(0, 30),
//         ),
//         child: Text(text, style: const TextStyle(fontSize: 11)),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final id = request["id"].toString();
//     final title = request["title"] ?? "No Title";
//     final type = request["type"]?["name"] ?? "N/A";
//     final priority = request["priority"] ?? "N/A";
//     final senderName = request["lastSenderName"] ?? request["creator"]?["name"] ?? "Unknown";
//     final createdAt = request["createdAt"];
//     final formattedDate = InboxFormatters.formatDate(createdAt);
//     final forwardStatus = (request['yourCurrentStatus'] ?? 'not-assigned').toString();
//     final isPending = forwardStatus == 'waiting' || forwardStatus == 'not-assigned';
//     final isApproved = forwardStatus == 'approved';
//     final isRejected = forwardStatus == 'rejected';
//     final needsChange = forwardStatus == 'needs_change';
//     final fulfilled = request["fulfilled"] == true;
//     final isUpdating = request['isUpdating'] == true;
//     final statusLabel = fulfilled
//         ? "Fulfilled"
//         : (isApproved ? "Approved" : (needsChange ? "Needs Change" : (isPending ? "Waiting" : "Rejected")));
//     final statusColor = fulfilled
//         ? InboxColors.statusFulfilled
//         : (isApproved
//         ? InboxColors.statusApproved
//         : (needsChange ? Colors.orange : (isPending ? InboxColors.statusWaiting : InboxColors.statusRejected)));
//     final lastForwardSentTo = request['lastForwardSentTo'];
//
//     IconData getStatusIcon() {
//       if (fulfilled) return Icons.check_rounded;
//       if (isApproved) return Icons.check_circle_rounded;
//       if (isRejected) return Icons.cancel_rounded;
//       if (needsChange) return Icons.edit_note_rounded;
//       return Icons.hourglass_empty_rounded;
//     }
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Card(
//         elevation: 1,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: InboxColors.cardBg,
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // الصف العلوي: العنوان والحالة
//               Row(
//                 children: [
//                   Stack(
//                     children: [
//                       Container(
//                         width: 32,
//                         height: 32,
//                         decoration: BoxDecoration(
//                           color: statusColor.withOpacity(0.1),
//                           shape: BoxShape.circle,
//                           border: Border.all(color: statusColor.withOpacity(0.3)),
//                         ),
//                         child: Icon(getStatusIcon(), color: statusColor, size: 16),
//                       ),
//                       if (isUpdating)
//                         Positioned(
//                           right: 0,
//                           bottom: 0,
//                           child: Container(
//                             width: 12,
//                             height: 12,
//                             decoration: BoxDecoration(
//                               color: Colors.blue,
//                               shape: BoxShape.circle,
//                               border: Border.all(color: Colors.white, width: 1.5),
//                             ),
//                             child: const Center(
//                               child: SizedBox(
//                                 width: 6,
//                                 height: 6,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 1,
//                                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           title,
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: InboxColors.textPrimary,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         if (isUpdating)
//                           Text(
//                             'Updating...',
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.blue,
//                               fontStyle: FontStyle.italic,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: statusColor.withOpacity(0.3)),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         if (isUpdating)
//                           SizedBox(
//                             width: 10,
//                             height: 10,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 1,
//                               valueColor: AlwaysStoppedAnimation<Color>(statusColor),
//                             ),
//                           ),
//                         if (isUpdating) const SizedBox(width: 4),
//                         Text(
//                           statusLabel,
//                           style: TextStyle(
//                             fontSize: 10,
//                             fontWeight: FontWeight.w600,
//                             color: statusColor,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//
//               // المرسل
//               Row(
//                 children: [
//                   Icon(Icons.person_rounded, size: 12, color: InboxColors.textSecondary),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       "From: $senderName",
//                       style: TextStyle(fontSize: 11, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//
//               // التاريخ
//               Row(
//                 children: [
//                   Icon(Icons.calendar_today_rounded, size: 12, color: InboxColors.textSecondary),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       formattedDate.length > 16 ? formattedDate.substring(0, 16) : formattedDate,
//                       style: TextStyle(fontSize: 11, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//
//               // النوع والأولوية
//               Row(
//                 children: [
//                   _buildMobileChip(type, Icons.category_outlined, InboxColors.primary),
//                   const SizedBox(width: 6),
//                   _buildMobileChip(priority, Icons.flag_outlined, InboxHelpers.getPriorityColor(priority)),
//                 ],
//               ),
//               const SizedBox(height: 8),
//
//               // أزرار الإجراءات
//               if (isUpdating) ...[
//                 Center(
//                   child: Column(
//                     children: [
//                       SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Updating...',
//                         style: TextStyle(
//                           color: InboxColors.textSecondary,
//                           fontSize: 11,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ] else if (isPending) ...[
//                 Column(
//                   children: [
//                     Row(
//                       children: [
//                         _buildMobileActionButton(
//                           text: 'View',
//                           onPressed: onViewDetails,
//                           color: InboxColors.primary,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 6),
//                         _buildMobileActionButton(
//                           text: 'Approve',
//                           onPressed: onApprove,
//                           color: InboxColors.accentGreen,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     Row(
//                       children: [
//                         _buildMobileActionButton(
//                           text: 'Need Change',
//                           onPressed: onNeedChange,
//                           color: Colors.orange,
//                         ),
//                         const SizedBox(width: 6),
//                         _buildMobileActionButton(
//                           text: 'Reject',
//                           onPressed: onReject,
//                           color: InboxColors.accentRed,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ] else if (hasForwarded) ...[
//                 Column(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: InboxColors.bodyBg,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: InboxColors.statBorder),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.send_rounded, size: 14, color: InboxColors.primary),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: Text(
//                               "Forwarded to ${lastForwardSentTo['receiverName']}",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                                 color: InboxColors.textPrimary,
//                               ),
//                             ),
//                           ),
//                           PopupMenuButton<String>(
//                             icon: Icon(Icons.more_vert_rounded, size: 16, color: InboxColors.textSecondary),
//                             itemBuilder: (context) => [
//                               const PopupMenuItem(
//                                 value: 'cancel',
//                                 child: Text('Cancel Forward'),
//                               ),
//                             ],
//                             onSelected: (value) {
//                               if (value == 'cancel') onCancelForward();
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     // فقط أزرار Edit و View بدون Forward
//                     Row(
//                       children: [
//                         _buildMobileActionButton(
//                           text: 'Edit',
//                           onPressed: onEditRequest,
//                           color: Colors.blue,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 6),
//                         _buildMobileActionButton(
//                           text: 'View',
//                           onPressed: onViewDetails,
//                           color: InboxColors.primary,
//                           isOutlined: true,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ] else if (isApproved && !hasForwarded) ...[
//                 Column(
//                   children: [
//                     Row(
//                       children: [
//                         _buildMobileActionButton(
//                           text: 'Edit',
//                           onPressed: onEditRequest,
//                           color: Colors.blue,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 6),
//                         _buildMobileActionButton(
//                           text: 'Forward',
//                           onPressed: onForward,
//                           color: InboxColors.primary,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.primary,
//                           side: BorderSide(color: InboxColors.primary),
//                           padding: const EdgeInsets.symmetric(vertical: 6),
//                           minimumSize: const Size(0, 30),
//                         ),
//                         child: const Text('View Details', style: TextStyle(fontSize: 11)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (isRejected) ...[
//                 Column(
//                   children: [
//                     Row(
//                       children: [
//                         _buildMobileActionButton(
//                           text: 'Edit',
//                           onPressed: onEditRequest,
//                           color: Colors.blue,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 6),
//                         _buildMobileActionButton(
//                           text: 'Forward',
//                           onPressed: onForward,
//                           color: InboxColors.primary,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.accentRed,
//                           side: BorderSide(color: InboxColors.accentRed),
//                           padding: const EdgeInsets.symmetric(vertical: 6),
//                           minimumSize: const Size(0, 30),
//                         ),
//                         child: const Text('View Details', style: TextStyle(fontSize: 11)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (needsChange) ...[
//                 Column(
//                   children: [
//                     Row(
//                       children: [
//                         _buildMobileActionButton(
//                           text: 'Edit',
//                           onPressed: onEditRequest,
//                           color: Colors.blue,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 6),
//                         _buildMobileActionButton(
//                           text: 'Forward',
//                           onPressed: onForward,
//                           color: InboxColors.primary,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: Colors.orange,
//                           side: BorderSide(color: Colors.orange),
//                           padding: const EdgeInsets.symmetric(vertical: 6),
//                           minimumSize: const Size(0, 30),
//                         ),
//                         child: const Text('View Details', style: TextStyle(fontSize: 11)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (fulfilled) ...[
//                 Column(
//                   children: [
//                     // زر Edit Request فقط (بدون Forward)
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onEditRequest,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: Colors.blue,
//                           side: BorderSide(color: Colors.blue),
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           minimumSize: const Size(0, 30),
//                         ),
//                         child: const Text('Edit Request', style: TextStyle(fontSize: 11)),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     // زر View Details فقط
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.statusFulfilled,
//                           side: BorderSide(color: InboxColors.statusFulfilled),
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           minimumSize: const Size(0, 30),
//                         ),
//                         child: const Text('View Details', style: TextStyle(fontSize: 11)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

//
// import 'package:flutter/material.dart';
// import './inbox_colors.dart';
// import './inbox_helpers.dart';
// import './inbox_formatters.dart';
//
// class InboxMobileCard extends StatelessWidget {
//   final Map<String, dynamic> request;
//   final VoidCallback onViewDetails;
//   final VoidCallback onApprove;
//   final VoidCallback onReject;
//   final VoidCallback onForward;
//   final VoidCallback onCancelForward;
//   final VoidCallback onNeedChange;
//   final VoidCallback onEditRequest;
//   final bool hasForwarded;
//
//   const InboxMobileCard({
//     Key? key,
//     required this.request,
//     required this.onViewDetails,
//     required this.onApprove,
//     required this.onReject,
//     required this.onForward,
//     required this.onCancelForward,
//     required this.hasForwarded,
//     required this.onNeedChange,
//     required this.onEditRequest,
//   }) : super(key: key);
//
//   Widget _buildMobileChip(String text, IconData icon, Color color) {
//     return Container(
//         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(6),
//           border: Border.all(color: color.withOpacity(0.3)),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 10, color: color),
//             const SizedBox(width: 2),
//             Text(
//               text.length > 8 ? text.substring(0, 8) + '...' : text,
//               style: TextStyle(
//                 fontSize: 9,
//                 color: color,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ));
//     }
//
//   Widget _buildMobileActionButton({
//     required String text,
//     required VoidCallback onPressed,
//     required Color color,
//     bool isOutlined = false,
//     bool isLoading = false,
//   }) {
//     if (isLoading) {
//       return Expanded(
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           alignment: Alignment.center,
//           child: SizedBox(
//             width: 12,
//             height: 12,
//             child: CircularProgressIndicator(
//               strokeWidth: 1.5,
//               valueColor: AlwaysStoppedAnimation<Color>(color),
//             ),
//           ),
//         ),
//       );
//     }
//
//     if (isOutlined) {
//       return Expanded(
//         child: OutlinedButton(
//           onPressed: onPressed,
//           style: OutlinedButton.styleFrom(
//             foregroundColor: color,
//             side: BorderSide(color: color),
//             padding: const EdgeInsets.symmetric(vertical: 4),
//             minimumSize: const Size(0, 30),
//           ),
//           child: Text(text, style: const TextStyle(fontSize: 11)),
//         ),
//       );
//     }
//
//     return Expanded(
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           minimumSize: const Size(0, 30),
//         ),
//         child: Text(text, style: const TextStyle(fontSize: 11)),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final id = request["id"].toString();
//     final title = request["title"] ?? "No Title";
//     final type = request["type"]?["name"] ?? "N/A";
//     final priority = request["priority"] ?? "N/A";
//     final senderName = request["lastSenderName"] ?? request["creator"]?["name"] ?? "Unknown";
//     final createdAt = request["createdAt"];
//     final formattedDate = InboxFormatters.formatDate(createdAt);
//     final forwardStatus = (request['yourCurrentStatus'] ?? 'not-assigned').toString();
//     final isPending = forwardStatus == 'waiting' || forwardStatus == 'not-assigned';
//     final isApproved = forwardStatus == 'approved';
//     final isRejected = forwardStatus == 'rejected';
//     final needsChange = forwardStatus == 'needs_change';
//     final fulfilled = request["fulfilled"] == true;
//     final isUpdating = request['isUpdating'] == true;
//     final statusLabel = fulfilled
//         ? "Fulfilled"
//         : (isApproved ? "Approved" : (needsChange ? "Needs Change" : (isPending ? "Waiting" : "Rejected")));
//     final statusColor = fulfilled
//         ? InboxColors.statusFulfilled
//         : (isApproved
//         ? InboxColors.statusApproved
//         : (needsChange ? Colors.orange : (isPending ? InboxColors.statusWaiting : InboxColors.statusRejected)));
//     final lastForwardSentTo = request['lastForwardSentTo'];
//
//     // 🔹 تحديد ما إذا كان يجب إظهار زر Forward بناءً على المنطق الجديد
//     final canShowForwardButton = !hasForwarded &&
//         (isApproved || isRejected || needsChange || fulfilled) &&
//         !isPending;
//
//     IconData getStatusIcon() {
//       if (fulfilled) return Icons.check_rounded;
//       if (isApproved) return Icons.check_circle_rounded;
//       if (isRejected) return Icons.cancel_rounded;
//       if (needsChange) return Icons.edit_note_rounded;
//       return Icons.hourglass_empty_rounded;
//     }
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Card(
//         elevation: 1,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: InboxColors.cardBg,
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // الصف العلوي: العنوان والحالة
//               Row(
//                 children: [
//                   Stack(
//                     children: [
//                       Container(
//                         width: 32,
//                         height: 32,
//                         decoration: BoxDecoration(
//                           color: statusColor.withOpacity(0.1),
//                           shape: BoxShape.circle,
//                           border: Border.all(color: statusColor.withOpacity(0.3)),
//                         ),
//                         child: Icon(getStatusIcon(), color: statusColor, size: 16),
//                       ),
//                       if (isUpdating)
//                         Positioned(
//                           right: 0,
//                           bottom: 0,
//                           child: Container(
//                             width: 12,
//                             height: 12,
//                             decoration: BoxDecoration(
//                               color: Colors.blue,
//                               shape: BoxShape.circle,
//                               border: Border.all(color: Colors.white, width: 1.5),
//                             ),
//                             child: const Center(
//                               child: SizedBox(
//                                 width: 6,
//                                 height: 6,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 1,
//                                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           title,
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: InboxColors.textPrimary,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         if (isUpdating)
//                           Text(
//                             'Updating...',
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.blue,
//                               fontStyle: FontStyle.italic,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: statusColor.withOpacity(0.3)),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         if (isUpdating)
//                           SizedBox(
//                             width: 10,
//                             height: 10,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 1,
//                               valueColor: AlwaysStoppedAnimation<Color>(statusColor),
//                             ),
//                           ),
//                         if (isUpdating) const SizedBox(width: 4),
//                         Text(
//                           statusLabel,
//                           style: TextStyle(
//                             fontSize: 10,
//                             fontWeight: FontWeight.w600,
//                             color: statusColor,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//
//               // المرسل
//               Row(
//                 children: [
//                   Icon(Icons.person_rounded, size: 12, color: InboxColors.textSecondary),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       "From: $senderName",
//                       style: TextStyle(fontSize: 11, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//
//               // التاريخ
//               Row(
//                 children: [
//                   Icon(Icons.calendar_today_rounded, size: 12, color: InboxColors.textSecondary),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       formattedDate.length > 16 ? formattedDate.substring(0, 16) : formattedDate,
//                       style: TextStyle(fontSize: 11, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//
//               // النوع والأولوية
//               Row(
//                 children: [
//                   _buildMobileChip(type, Icons.category_outlined, InboxColors.primary),
//                   const SizedBox(width: 6),
//                   _buildMobileChip(priority, Icons.flag_outlined, InboxHelpers.getPriorityColor(priority)),
//                 ],
//               ),
//               const SizedBox(height: 8),
//
//               // أزرار الإجراءات
//               if (isUpdating) ...[
//                 Center(
//                   child: Column(
//                     children: [
//                       SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Updating...',
//                         style: TextStyle(
//                           color: InboxColors.textSecondary,
//                           fontSize: 11,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ] else if (isPending) ...[
//                 Column(
//                   children: [
//                     Row(
//                       children: [
//                         _buildMobileActionButton(
//                           text: 'View',
//                           onPressed: onViewDetails,
//                           color: InboxColors.primary,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 6),
//                         _buildMobileActionButton(
//                           text: 'Approve',
//                           onPressed: onApprove,
//                           color: InboxColors.accentGreen,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     Row(
//                       children: [
//                         _buildMobileActionButton(
//                           text: 'Need Change',
//                           onPressed: onNeedChange,
//                           color: Colors.orange,
//                         ),
//                         const SizedBox(width: 6),
//                         _buildMobileActionButton(
//                           text: 'Reject',
//                           onPressed: onReject,
//                           color: InboxColors.accentRed,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ] else if (hasForwarded) ...[
//                 Column(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: InboxColors.bodyBg,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: InboxColors.statBorder),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.send_rounded, size: 14, color: InboxColors.primary),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: Text(
//                               "Forwarded to ${lastForwardSentTo['receiverName']}",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                                 color: InboxColors.textPrimary,
//                               ),
//                             ),
//                           ),
//                           PopupMenuButton<String>(
//                             icon: Icon(Icons.more_vert_rounded, size: 16, color: InboxColors.textSecondary),
//                             itemBuilder: (context) => [
//                               const PopupMenuItem(
//                                 value: 'cancel',
//                                 child: Text('Cancel Forward'),
//                               ),
//                             ],
//                             onSelected: (value) {
//                               if (value == 'cancel') onCancelForward();
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     // فقط أزرار Edit و View بدون Forward
//                     Row(
//                       children: [
//                         _buildMobileActionButton(
//                           text: 'Edit',
//                           onPressed: onEditRequest,
//                           color: Colors.blue,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 6),
//                         _buildMobileActionButton(
//                           text: 'View',
//                           onPressed: onViewDetails,
//                           color: InboxColors.primary,
//                           isOutlined: true,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ] else if (canShowForwardButton) ...[
//                 Column(
//                   children: [
//                     Row(
//                       children: [
//                         _buildMobileActionButton(
//                           text: 'Edit',
//                           onPressed: onEditRequest,
//                           color: Colors.blue,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 6),
//                         _buildMobileActionButton(
//                           text: 'Forward',
//                           onPressed: onForward,
//                           color: InboxColors.primary,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.primary,
//                           side: BorderSide(color: InboxColors.primary),
//                           padding: const EdgeInsets.symmetric(vertical: 6),
//                           minimumSize: const Size(0, 30),
//                         ),
//                         child: const Text('View Details', style: TextStyle(fontSize: 11)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else ...[
//                 Column(
//                   children: [
//                     // زر Edit Request فقط (بدون Forward)
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onEditRequest,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: Colors.blue,
//                           side: BorderSide(color: Colors.blue),
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           minimumSize: const Size(0, 30),
//                         ),
//                         child: const Text('Edit Request', style: TextStyle(fontSize: 11)),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     // زر View Details فقط
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.statusFulfilled,
//                           side: BorderSide(color: InboxColors.statusFulfilled),
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           minimumSize: const Size(0, 30),
//                         ),
//                         child: const Text('View Details', style: TextStyle(fontSize: 11)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import './inbox_colors.dart';
import './inbox_helpers.dart';
import './inbox_formatters.dart';

class InboxMobileCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onViewDetails;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onForward;
  final VoidCallback onCancelForward;
  final VoidCallback onNeedChange;
  final VoidCallback onEditRequest;
  final bool hasForwarded;

  const InboxMobileCard({
    Key? key,
    required this.request,
    required this.onViewDetails,
    required this.onApprove,
    required this.onReject,
    required this.onForward,
    required this.onCancelForward,
    required this.hasForwarded,
    required this.onNeedChange,
    required this.onEditRequest,
  }) : super(key: key);

  Widget _buildMobileChip(BuildContext context, String text, IconData icon, Color color) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 2),
            Text(
              AppLocalizations.of(context)!.translate(text.toLowerCase()),
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ));
    }

  Widget _buildMobileActionButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
    bool isOutlined = false,
    bool isLoading = false,
  }) {
    if (isLoading) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      );
    }

    if (isOutlined) {
      return Expanded(
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 4),
            minimumSize: const Size(0, 30),
          ),
          child: Text(text, style: const TextStyle(fontSize: 11)),
        ),
      );
    }

    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 4),
          minimumSize: const Size(0, 30),
        ),
        child: Text(text, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = request["id"].toString();
    final title = request["title"] ?? "No Title";
    final type = request["type"]?["name"] ?? "N/A";
    final priority = request["priority"] ?? "N/A";
    final senderName = request["lastSenderName"] ?? request["creator"]?["name"] ?? "Unknown";
    final createdAt = request["createdAt"];
    final formattedDate = InboxFormatters.formatDate(createdAt);
    final forwardStatus = (request['yourCurrentStatus'] ?? 'not-assigned').toString();
    final isPending = forwardStatus == 'waiting' || forwardStatus == 'not-assigned';
    final isApproved = forwardStatus == 'approved';
    final isRejected = forwardStatus == 'rejected';
    final needsChange = forwardStatus == 'needs_change';
    final fulfilled = request["fulfilled"] == true;
    final isUpdating = request['isUpdating'] == true;
    final statusLabel = fulfilled
        ? AppLocalizations.of(context)!.translate('fulfilled')
        : (isApproved 
            ? AppLocalizations.of(context)!.translate('approved') 
            : (needsChange 
                ? AppLocalizations.of(context)!.translate('needs_change') 
                : (isPending 
                    ? AppLocalizations.of(context)!.translate('waiting') 
                    : AppLocalizations.of(context)!.translate('rejected'))));
    final statusColor = fulfilled
        ? InboxColors.statusFulfilled
        : (isApproved
        ? InboxColors.statusApproved
        : (needsChange ? Colors.orange : (isPending ? InboxColors.statusWaiting : InboxColors.statusRejected)));
    final lastForwardSentTo = request['lastForwardSentTo'];

    // 🔹 تحديد ما إذا كان يجب إظهار أزرار المعالجة (الموافقة/الرفض/طلب التعديل)
    // تظهر هذه الأزرار عندما تكون العملية في حالة pending وتعود إليك (لست المرسل الأخير)
    final showProcessingButtons = isPending && !hasForwarded;

    // 🔹 تحديد ما إذا كان يجب إظهار زر Forward
    // يظهر هذا الزر عندما تكون العملية ليست في حالة pending (موافق/مرفوض/طلب تعديل/مكتمل)
    // ولا يوجد توجيه نشط
    final showForwardButton = !isPending && !hasForwarded;

    IconData getStatusIcon() {
      if (fulfilled) return Icons.check_rounded;
      if (isApproved) return Icons.check_circle_rounded;
      if (isRejected) return Icons.cancel_rounded;
      if (needsChange) return Icons.edit_note_rounded;
      return Icons.hourglass_empty_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: InboxColors.cardBg,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: العنوان والحالة
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Icon(getStatusIcon(), color: statusColor, size: 16),
                      ),
                      if (isUpdating)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 6,
                                height: 6,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: InboxColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isUpdating)
                          Text(
                            AppLocalizations.of(context)!.translate('updating'),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUpdating)
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                        if (isUpdating) const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // المرسل
              Row(
                children: [
                  Icon(Icons.person_rounded, size: 12, color: InboxColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "${AppLocalizations.of(context)!.translate('from_prefix')} $senderName",
                      style: TextStyle(fontSize: 11, color: InboxColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // التاريخ
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: InboxColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      formattedDate.length > 16 ? formattedDate.substring(0, 16) : formattedDate,
                      style: TextStyle(fontSize: 11, color: InboxColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // النوع والأولوية
              Row(
                children: [
                  _buildMobileChip(context, type, Icons.category_outlined, InboxColors.primary),
                  const SizedBox(width: 6),
                  _buildMobileChip(context, priority, Icons.flag_outlined, InboxHelpers.getPriorityColor(priority)),
                ],
              ),
              const SizedBox(height: 8),

              // أزرار الإجراءات
              if (isUpdating) ...[
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.translate('updating'),
                        style: TextStyle(
                          color: InboxColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (showProcessingButtons) ...[
                // 🔹 أزرار المعالجة (عندما تعود العملية إليك في حالة pending)
                Column(
                  children: [
                    Row(
                      children: [
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('view'),
                          onPressed: onViewDetails,
                          color: InboxColors.primary,
                          isOutlined: true,
                        ),
                        const SizedBox(width: 6),
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('approve'),
                          onPressed: onApprove,
                          color: InboxColors.accentGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('need_change'),
                          onPressed: onNeedChange,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('reject'),
                          onPressed: onReject,
                          color: InboxColors.accentRed,
                        ),
                      ],
                    ),
                  ],
                ),
              ] else if (hasForwarded) ...[
                // 🔹 حالة: أنت أرسلت العملية لشخص آخر (أنت المرسل الأخير)
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: InboxColors.bodyBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: InboxColors.statBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.send_rounded, size: 14, color: InboxColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "${AppLocalizations.of(context)!.translate('forwarded_to_prefix') == 'forwarded_to_prefix' ? 'Forwarded to' : AppLocalizations.of(context)!.translate('forwarded_to_prefix')} ${lastForwardSentTo['receiverName']}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: InboxColors.textPrimary,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, size: 16, color: InboxColors.textSecondary),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'cancel',
                                child: Text(AppLocalizations.of(context)!.translate('cancel_forward')),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'cancel') onCancelForward();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // فقط أزرار Edit و View
                    Row(
                      children: [
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('edit'),
                          onPressed: onEditRequest,
                          color: Colors.blue,
                          isOutlined: true,
                        ),
                        const SizedBox(width: 6),
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('view'),
                          onPressed: onViewDetails,
                          color: InboxColors.primary,
                          isOutlined: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ] else if (showForwardButton) ...[
                // 🔹 حالة: العملية في حالة نهائية (موافق/مرفوض/طلب تعديل/مكتمل) ويمكن التوجيه
                Column(
                  children: [
                    Row(
                      children: [
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('edit'),
                          onPressed: onEditRequest,
                          color: Colors.blue,
                          isOutlined: true,
                        ),
                        const SizedBox(width: 6),
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('forward'),
                          onPressed: onForward,
                          color: InboxColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: InboxColors.primary,
                          side: BorderSide(color: InboxColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: const Size(0, 30),
                        ),
                        child: Text(AppLocalizations.of(context)!.translate('view_details'), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // 🔹 الحالات الأخرى (لا يوجد توجيه نشط ولا يمكن التوجيه)
                Column(
                  children: [
                    // زر Edit Request فقط
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onEditRequest,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 30),
                        ),
                        child: Text(AppLocalizations.of(context)!.translate('edit_request'), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // زر View Details فقط
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: InboxColors.statusFulfilled,
                          side: BorderSide(color: InboxColors.statusFulfilled),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 30),
                        ),
                        child: Text(AppLocalizations.of(context)!.translate('view_details'), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}