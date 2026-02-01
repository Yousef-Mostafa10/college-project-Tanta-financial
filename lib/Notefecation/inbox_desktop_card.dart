// // Notefecation/inbox_desktop_card.dart
// import 'package:flutter/material.dart';
// import './inbox_colors.dart';
// import './inbox_helpers.dart';
// import './inbox_formatters.dart';
//
// class InboxDesktopCard extends StatelessWidget {
//   final Map<String, dynamic> request;
//   final VoidCallback onViewDetails;
//   final VoidCallback onApprove;
//   final VoidCallback onReject;
//   final VoidCallback onForward;
//   final VoidCallback onCancelForward;
//   final bool hasForwarded;
//
//   const InboxDesktopCard({
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
//   Widget _buildDesktopChip(String text, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 14, color: color),
//           const SizedBox(width: 6),
//           Text(
//             text,
//             style: TextStyle(
//               fontSize: 12,
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
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: InboxColors.cardBg,
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 1️⃣ الصف العلوي: العنوان والحالة
//               Row(
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       shape: BoxShape.circle,
//                       border: Border.all(color: statusColor.withOpacity(0.3)),
//                     ),
//                     child: Icon(getStatusIcon(), color: statusColor, size: 20),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: InboxColors.textPrimary,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: statusColor.withOpacity(0.3)),
//                     ),
//                     child: Text(
//                       statusLabel,
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: statusColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//
//               // 2️⃣ معلومات المرسل والتاريخ
//               Row(
//                 children: [
//                   Icon(Icons.person_rounded, size: 14, color: InboxColors.textSecondary),
//                   const SizedBox(width: 6),
//                   Text(
//                     "From: $senderName",
//                     style: TextStyle(fontSize: 13, color: InboxColors.textSecondary),
//                   ),
//                   const SizedBox(width: 24),
//                   Icon(Icons.calendar_today_rounded, size: 14, color: InboxColors.textSecondary),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       formattedDate,
//                       style: TextStyle(fontSize: 13, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//
//               // 3️⃣ النوع والأولوية
//               Row(
//                 children: [
//                   _buildDesktopChip(type, Icons.category_outlined, InboxColors.primary),
//                   const SizedBox(width: 8),
//                   _buildDesktopChip(priority, Icons.flag_outlined, InboxHelpers.getPriorityColor(priority)),
//                 ],
//               ),
//               const SizedBox(height: 16),
//
//               // 4️⃣ أزرار الإجراءات
//               if (isPending) ...[
//                 Row(
//                   children: [
//                     Expanded(
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
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: onApprove,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: InboxColors.accentGreen,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                         ),
//                         child: const Text('Approve'),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: onReject,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: InboxColors.accentRed,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                         ),
//                         child: const Text('Reject'),
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
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                     child: const Text('Forward to Another User'),
//                   ),
//                 ),
//               ] else if (hasForwarded) ...[
//                 Column(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                       decoration: BoxDecoration(
//                         color: InboxColors.bodyBg,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: InboxColors.statBorder),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.send_rounded, size: 16, color: InboxColors.primary),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               "Forwarded to ${lastForwardSentTo['receiverName']}",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                                 color: InboxColors.textPrimary,
//                               ),
//                             ),
//                           ),
//                           PopupMenuButton<String>(
//                             icon: Icon(Icons.more_vert_rounded, size: 18, color: InboxColors.textSecondary),
//                             itemBuilder: (context) => [
//                               const PopupMenuItem(
//                                 value: 'cancel',
//                                 child: Row(
//                                   children: [
//                                     Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
//                                     SizedBox(width: 8),
//                                     Text('Cancel Forward'),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                             onSelected: (value) {
//                               if (value == 'cancel') onCancelForward();
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.primary,
//                           side: BorderSide(color: InboxColors.primary),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
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
//                       padding: const EdgeInsets.symmetric(vertical: 12),
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
//
// import 'package:flutter/material.dart';
// import './inbox_colors.dart';
// import './inbox_helpers.dart';
// import './inbox_formatters.dart';
//
// class InboxDesktopCard extends StatelessWidget {
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
//   const InboxDesktopCard({
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
//   Widget _buildDesktopChip(String text, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 14, color: color),
//           const SizedBox(width: 6),
//           Text(
//             text,
//             style: TextStyle(
//               fontSize: 12,
//               color: color,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButton({
//     required String text,
//     required VoidCallback onPressed,
//     required Color color,
//     bool isOutlined = false,
//     bool isLoading = false,
//   }) {
//     if (isLoading) {
//       return Expanded(
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           alignment: Alignment.center,
//           child: SizedBox(
//             width: 16,
//             height: 16,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
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
//             padding: const EdgeInsets.symmetric(vertical: 8),
//           ),
//           child: Text(text),
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
//           padding: const EdgeInsets.symmetric(vertical: 8),
//         ),
//         child: Text(text),
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
//       if (fulfilled) return Icons.task_alt_rounded;
//       if (isApproved) return Icons.check_circle_rounded;
//       if (isRejected) return Icons.cancel_rounded;
//       if (needsChange) return Icons.edit_note_rounded;
//       return Icons.hourglass_empty_rounded;
//     }
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: InboxColors.cardBg,
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 1️⃣ الصف العلوي: العنوان والحالة
//               Row(
//                 children: [
//                   Stack(
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: statusColor.withOpacity(0.1),
//                           shape: BoxShape.circle,
//                           border: Border.all(color: statusColor.withOpacity(0.3)),
//                         ),
//                         child: Icon(getStatusIcon(), color: statusColor, size: 20),
//                       ),
//                       if (isUpdating)
//                         Positioned(
//                           right: 0,
//                           bottom: 0,
//                           child: Container(
//                             width: 14,
//                             height: 14,
//                             decoration: BoxDecoration(
//                               color: Colors.blue,
//                               shape: BoxShape.circle,
//                               border: Border.all(color: Colors.white, width: 2),
//                             ),
//                             child: const Center(
//                               child: SizedBox(
//                                 width: 8,
//                                 height: 8,
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
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           title,
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: InboxColors.textPrimary,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         if (isUpdating)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 4),
//                             child: Text(
//                               'Updating...',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 color: Colors.blue,
//                                 fontStyle: FontStyle.italic,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
//                             width: 12,
//                             height: 12,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 1,
//                               valueColor: AlwaysStoppedAnimation<Color>(statusColor),
//                             ),
//                           ),
//                         if (isUpdating) const SizedBox(width: 6),
//                         Text(
//                           statusLabel,
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: statusColor,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//
//               // 2️⃣ معلومات المرسل والتاريخ
//               Row(
//                 children: [
//                   Icon(Icons.person_rounded, size: 14, color: InboxColors.textSecondary),
//                   const SizedBox(width: 6),
//                   Text(
//                     "From: $senderName",
//                     style: TextStyle(fontSize: 13, color: InboxColors.textSecondary),
//                   ),
//                   const SizedBox(width: 24),
//                   Icon(Icons.calendar_today_rounded, size: 14, color: InboxColors.textSecondary),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       formattedDate,
//                       style: TextStyle(fontSize: 13, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//
//               // 3️⃣ النوع والأولوية
//               Row(
//                 children: [
//                   _buildDesktopChip(type, Icons.category_outlined, InboxColors.primary),
//                   const SizedBox(width: 8),
//                   _buildDesktopChip(priority, Icons.flag_outlined, InboxHelpers.getPriorityColor(priority)),
//                 ],
//               ),
//               const SizedBox(height: 16),
//
//               // 4️⃣ أزرار الإجراءات
//               if (isUpdating) ...[
//                 Center(
//                   child: Column(
//                     children: [
//                       CircularProgressIndicator(
//                         valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Updating request...',
//                         style: TextStyle(
//                           color: InboxColors.textSecondary,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ] else if (isPending) ...[
//                 Column(
//                   children: [
//                     // صف الأزرار العلوي
//                     Row(
//                       children: [
//                         _buildActionButton(
//                           text: 'View Details',
//                           onPressed: onViewDetails,
//                           color: InboxColors.primary,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 12),
//                         _buildActionButton(
//                           text: 'Approve',
//                           onPressed: onApprove,
//                           color: InboxColors.accentGreen,
//                         ),
//                         const SizedBox(width: 12),
//                         _buildActionButton(
//                           text: 'Need Change',
//                           onPressed: onNeedChange,
//                           color: Colors.orange,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     // زر الرفض فقط (بدون Forward)
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: onReject,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: InboxColors.accentRed,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         child: const Text('Reject'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (hasForwarded) ...[
//                 Column(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                       decoration: BoxDecoration(
//                         color: InboxColors.bodyBg,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: InboxColors.statBorder),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.send_rounded, size: 16, color: InboxColors.primary),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               "Forwarded to ${lastForwardSentTo['receiverName']}",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                                 color: InboxColors.textPrimary,
//                               ),
//                             ),
//                           ),
//                           PopupMenuButton<String>(
//                             icon: Icon(Icons.more_vert_rounded, size: 18, color: InboxColors.textSecondary),
//                             itemBuilder: (context) => [
//                               const PopupMenuItem(
//                                 value: 'cancel',
//                                 child: Row(
//                                   children: [
//                                     Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
//                                     SizedBox(width: 8),
//                                     Text('Cancel Forward'),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                             onSelected: (value) {
//                               if (value == 'cancel') onCancelForward();
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     // فقط أزرار Edit Request و View Details بدون Forward
//                     Row(
//                       children: [
//                         _buildActionButton(
//                           text: 'Edit Request',
//                           onPressed: onEditRequest,
//                           color: Colors.blue,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 12),
//                         _buildActionButton(
//                           text: 'View Details',
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
//                         _buildActionButton(
//                           text: 'Edit Request',
//                           onPressed: onEditRequest,
//                           color: Colors.blue,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 12),
//                         _buildActionButton(
//                           text: 'Forward',
//                           onPressed: onForward,
//                           color: InboxColors.primary,
//                         ),
//                       ],
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
//               ] else if (isRejected) ...[
//                 Column(
//                   children: [
//                     Row(
//                       children: [
//                         _buildActionButton(
//                           text: 'Edit Request',
//                           onPressed: onEditRequest,
//                           color: Colors.blue,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 12),
//                         _buildActionButton(
//                           text: 'Forward',
//                           onPressed: onForward,
//                           color: InboxColors.primary,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.accentRed,
//                           side: BorderSide(color: InboxColors.accentRed),
//                           padding: const EdgeInsets.symmetric(vertical: 8),
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
//                         _buildActionButton(
//                           text: 'Edit Request',
//                           onPressed: onEditRequest,
//                           color: Colors.blue,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 12),
//                         _buildActionButton(
//                           text: 'Forward',
//                           onPressed: onForward,
//                           color: InboxColors.primary,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onViewDetails,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: Colors.orange,
//                           side: BorderSide(color: Colors.orange),
//                           padding: const EdgeInsets.symmetric(vertical: 8),
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
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         child: const Text('Edit Request'),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
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
// //// 2222222222222222222222222222222222
// import 'package:flutter/material.dart';
// import './inbox_colors.dart';
// import './inbox_helpers.dart';
// import './inbox_formatters.dart';
//
// class InboxDesktopCard extends StatelessWidget {
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
//   const InboxDesktopCard({
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
//   Widget _buildDesktopChip(String text, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 14, color: color),
//           const SizedBox(width: 6),
//           Text(
//             text,
//             style: TextStyle(
//               fontSize: 12,
//               color: color,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButton({
//     required String text,
//     required VoidCallback onPressed,
//     required Color color,
//     bool isOutlined = false,
//     bool isLoading = false,
//   }) {
//     if (isLoading) {
//       return Expanded(
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           alignment: Alignment.center,
//           child: SizedBox(
//             width: 16,
//             height: 16,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
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
//             padding: const EdgeInsets.symmetric(vertical: 8),
//           ),
//           child: Text(text),
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
//           padding: const EdgeInsets.symmetric(vertical: 8),
//         ),
//         child: Text(text),
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
//       if (fulfilled) return Icons.task_alt_rounded;
//       if (isApproved) return Icons.check_circle_rounded;
//       if (isRejected) return Icons.cancel_rounded;
//       if (needsChange) return Icons.edit_note_rounded;
//       return Icons.hourglass_empty_rounded;
//     }
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: InboxColors.cardBg,
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 1️⃣ الصف العلوي: العنوان والحالة
//               Row(
//                 children: [
//                   Stack(
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: statusColor.withOpacity(0.1),
//                           shape: BoxShape.circle,
//                           border: Border.all(color: statusColor.withOpacity(0.3)),
//                         ),
//                         child: Icon(getStatusIcon(), color: statusColor, size: 20),
//                       ),
//                       if (isUpdating)
//                         Positioned(
//                           right: 0,
//                           bottom: 0,
//                           child: Container(
//                             width: 14,
//                             height: 14,
//                             decoration: BoxDecoration(
//                               color: Colors.blue,
//                               shape: BoxShape.circle,
//                               border: Border.all(color: Colors.white, width: 2),
//                             ),
//                             child: const Center(
//                               child: SizedBox(
//                                 width: 8,
//                                 height: 8,
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
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           title,
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: InboxColors.textPrimary,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         if (isUpdating)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 4),
//                             child: Text(
//                               'Updating...',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 color: Colors.blue,
//                                 fontStyle: FontStyle.italic,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
//                             width: 12,
//                             height: 12,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 1,
//                               valueColor: AlwaysStoppedAnimation<Color>(statusColor),
//                             ),
//                           ),
//                         if (isUpdating) const SizedBox(width: 6),
//                         Text(
//                           statusLabel,
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: statusColor,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//
//               // 2️⃣ معلومات المرسل والتاريخ
//               Row(
//                 children: [
//                   Icon(Icons.person_rounded, size: 14, color: InboxColors.textSecondary),
//                   const SizedBox(width: 6),
//                   Text(
//                     "From: $senderName",
//                     style: TextStyle(fontSize: 13, color: InboxColors.textSecondary),
//                   ),
//                   const SizedBox(width: 24),
//                   Icon(Icons.calendar_today_rounded, size: 14, color: InboxColors.textSecondary),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       formattedDate,
//                       style: TextStyle(fontSize: 13, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//
//               // 3️⃣ النوع والأولوية
//               Row(
//                 children: [
//                   _buildDesktopChip(type, Icons.category_outlined, InboxColors.primary),
//                   const SizedBox(width: 8),
//                   _buildDesktopChip(priority, Icons.flag_outlined, InboxHelpers.getPriorityColor(priority)),
//                 ],
//               ),
//               const SizedBox(height: 16),
//
//               // 4️⃣ أزرار الإجراءات
//               if (isUpdating) ...[
//                 Center(
//                   child: Column(
//                     children: [
//                       CircularProgressIndicator(
//                         valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Updating request...',
//                         style: TextStyle(
//                           color: InboxColors.textSecondary,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ] else if (isPending) ...[
//                 Column(
//                   children: [
//                     // صف الأزرار العلوي
//                     Row(
//                       children: [
//                         _buildActionButton(
//                           text: 'View Details',
//                           onPressed: onViewDetails,
//                           color: InboxColors.primary,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 12),
//                         _buildActionButton(
//                           text: 'Approve',
//                           onPressed: onApprove,
//                           color: InboxColors.accentGreen,
//                         ),
//                         const SizedBox(width: 12),
//                         _buildActionButton(
//                           text: 'Need Change',
//                           onPressed: onNeedChange,
//                           color: Colors.orange,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     // زر الرفض فقط (بدون Forward)
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: onReject,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: InboxColors.accentRed,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         child: const Text('Reject'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (hasForwarded) ...[
//                 Column(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                       decoration: BoxDecoration(
//                         color: InboxColors.bodyBg,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: InboxColors.statBorder),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.send_rounded, size: 16, color: InboxColors.primary),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               "Forwarded to ${lastForwardSentTo['receiverName']}",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                                 color: InboxColors.textPrimary,
//                               ),
//                             ),
//                           ),
//                           PopupMenuButton<String>(
//                             icon: Icon(Icons.more_vert_rounded, size: 18, color: InboxColors.textSecondary),
//                             itemBuilder: (context) => [
//                               const PopupMenuItem(
//                                 value: 'cancel',
//                                 child: Row(
//                                   children: [
//                                     Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
//                                     SizedBox(width: 8),
//                                     Text('Cancel Forward'),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                             onSelected: (value) {
//                               if (value == 'cancel') onCancelForward();
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     // فقط أزرار Edit Request و View Details بدون Forward
//                     Row(
//                       children: [
//                         _buildActionButton(
//                           text: 'Edit Request',
//                           onPressed: onEditRequest,
//                           color: Colors.blue,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 12),
//                         _buildActionButton(
//                           text: 'View Details',
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
//                         _buildActionButton(
//                           text: 'Edit Request',
//                           onPressed: onEditRequest,
//                           color: Colors.blue,
//                           isOutlined: true,
//                         ),
//                         const SizedBox(width: 12),
//                         _buildActionButton(
//                           text: 'Forward',
//                           onPressed: onForward,
//                           color: InboxColors.primary,
//                         ),
//                       ],
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
//               ] else ...[
//                 Column(
//                   children: [
//                     // زر Edit Request فقط
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: onEditRequest,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: Colors.blue,
//                           side: BorderSide(color: Colors.blue),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         child: const Text('Edit Request'),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
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


import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import './inbox_colors.dart';
import './inbox_helpers.dart';
import './inbox_formatters.dart';

class InboxDesktopCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onViewDetails;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onForward;
  final VoidCallback onCancelForward;
  final VoidCallback onNeedChange;
  final VoidCallback onEditRequest;
  final bool hasForwarded;

  const InboxDesktopCard({
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

  Widget _buildDesktopChip(BuildContext context, String text, IconData icon, Color color) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.translate(text.toLowerCase().replaceAll(' ', '_')),
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
    bool isOutlined = false,
    bool isLoading = false,
  }) {
    if (isLoading) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
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
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Text(text),
        ),
      );
    }

    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(text),
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
      if (fulfilled) return Icons.task_alt_rounded;
      if (isApproved) return Icons.check_circle_rounded;
      if (isRejected) return Icons.cancel_rounded;
      if (needsChange) return Icons.edit_note_rounded;
      return Icons.hourglass_empty_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: InboxColors.cardBg,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1️⃣ الصف العلوي: العنوان والحالة
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Icon(getStatusIcon(), color: statusColor, size: 20),
                      ),
                      if (isUpdating)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 8,
                                height: 8,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: InboxColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isUpdating)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              AppLocalizations.of(context)!.translate('updating'),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                        if (isUpdating) const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2️⃣ معلومات المرسل والتاريخ
              Row(
                children: [
                  Icon(Icons.person_rounded, size: 14, color: InboxColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    "${AppLocalizations.of(context)!.translate('from_prefix')} $senderName",
                    style: TextStyle(fontSize: 13, color: InboxColors.textSecondary),
                  ),
                  const SizedBox(width: 24),
                  Icon(Icons.calendar_today_rounded, size: 14, color: InboxColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: TextStyle(fontSize: 13, color: InboxColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3️⃣ النوع والأولوية
              Row(
                children: [
                  _buildDesktopChip(context, type, Icons.category_outlined, InboxColors.primary),
                  const SizedBox(width: 8),
                  _buildDesktopChip(context, priority, Icons.flag_outlined, InboxHelpers.getPriorityColor(priority)),
                ],
              ),
              const SizedBox(height: 16),

              // 4️⃣ أزرار الإجراءات
              if (isUpdating) ...[
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.translate('updating'),
                        style: TextStyle(
                          color: InboxColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (showProcessingButtons) ...[
                // 🔹 أزرار المعالجة (عندما تعود العملية إليك في حالة pending)
                Column(
                  children: [
                    // صف الأزرار العلوي
                    Row(
                      children: [
                        _buildActionButton(
                          text: AppLocalizations.of(context)!.translate('view_details'),
                          onPressed: onViewDetails,
                          color: InboxColors.primary,
                          isOutlined: true,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          text: AppLocalizations.of(context)!.translate('approve'),
                          onPressed: onApprove,
                          color: InboxColors.accentGreen,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          text: AppLocalizations.of(context)!.translate('need_change'),
                          onPressed: onNeedChange,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // زر الرفض فقط
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onReject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: InboxColors.accentRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(AppLocalizations.of(context)!.translate('reject')),
                      ),
                    ),
                  ],
                ),
              ] else if (hasForwarded) ...[
                // 🔹 حالة: أنت أرسلت العملية لشخص آخر (أنت المرسل الأخير)
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: InboxColors.bodyBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: InboxColors.statBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.send_rounded, size: 16, color: InboxColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${AppLocalizations.of(context)!.translate('forwarded_to_prefix') == 'forwarded_to_prefix' ? 'Forwarded to' : AppLocalizations.of(context)!.translate('forwarded_to_prefix')} ${lastForwardSentTo['receiverName']}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: InboxColors.textPrimary,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, size: 18, color: InboxColors.textSecondary),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'cancel',
                                child: Row(
                                  children: [
                                    const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)!.translate('cancel_forward')),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'cancel') onCancelForward();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // فقط أزرار Edit Request و View Details
                    Row(
                      children: [
                        _buildActionButton(
                          text: AppLocalizations.of(context)!.translate('edit_request'),
                          onPressed: onEditRequest,
                          color: Colors.blue,
                          isOutlined: true,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          text: AppLocalizations.of(context)!.translate('view_details'),
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
                        _buildActionButton(
                          text: AppLocalizations.of(context)!.translate('edit_request'),
                          onPressed: onEditRequest,
                          color: Colors.blue,
                          isOutlined: true,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          text: AppLocalizations.of(context)!.translate('forward'),
                          onPressed: onForward,
                          color: InboxColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: InboxColors.primary,
                          side: BorderSide(color: InboxColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(AppLocalizations.of(context)!.translate('view_details')),
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(AppLocalizations.of(context)!.translate('edit_request')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // زر View Details فقط
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: InboxColors.statusFulfilled,
                          side: BorderSide(color: InboxColors.statusFulfilled),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(AppLocalizations.of(context)!.translate('view_details')),
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