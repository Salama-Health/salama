import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum ActivityType { vaccination, visit, sync, alert, registration }

extension ActivityTypeX on ActivityType {
  IconData get icon => switch (this) {
        ActivityType.vaccination => Icons.vaccines_outlined,
        ActivityType.visit => Icons.check_circle_outline_rounded,
        ActivityType.sync => Icons.cloud_done_outlined,
        ActivityType.alert => Icons.warning_amber_rounded,
        ActivityType.registration => Icons.person_add_alt_1_outlined,
      };

  Color get color => switch (this) {
        ActivityType.vaccination => AppColors.info,
        ActivityType.visit => AppColors.success,
        ActivityType.sync => AppColors.primary,
        ActivityType.alert => AppColors.warningMid,
        ActivityType.registration => AppColors.accentPurple,
      };
}

class ActivityModel {
  final ActivityType type;
  final String title;
  final String subtitle;
  final String time;

  const ActivityModel({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
