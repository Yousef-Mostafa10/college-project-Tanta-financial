import 'package:flutter/material.dart';
import 'tracking_timeline_item.dart';

Widget buildTrackingTimeline({
  required List<dynamic> forwards,
  required bool isMobile,
  required bool isTablet,
}) {
  return Padding(
    padding: EdgeInsets.all(isMobile ? 12 : 16),
    child: ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: forwards.length,
      separatorBuilder: (context, index) => SizedBox(height: isMobile ? 8 : 12),
      itemBuilder: (context, index) {
        final forward = forwards[index];
        final isFirst = index == 0;
        final isLast = index == forwards.length - 1;

        return buildTimelineStep(
          forward: forward,
          stepNumber: forwards.length - index,
          isFirst: isFirst,
          isLast: isLast,
          totalSteps: forwards.length,
          isMobile: isMobile,
          isTablet: isTablet,
        );
      },
    ),
  );
}