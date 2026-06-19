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

  static ActivityType typeFromString(String? s) {
    switch (s) {
      case 'vaccination':
        return ActivityType.vaccination;
      case 'visit':
        return ActivityType.visit;
      case 'sync':
        return ActivityType.sync;
      case 'alert':
        return ActivityType.alert;
      case 'registration':
        return ActivityType.registration;
      default:
        return ActivityType.visit;
    }
  }

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      type: typeFromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      time: _relative(json['createdAt']?.toString()),
    );
  }

  static String _relative(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
