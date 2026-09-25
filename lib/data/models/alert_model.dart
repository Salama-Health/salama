import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum AlertSeverity { critical, warning, info }

enum AlertKind { coldChain, climate, overdueChild, coverage, sync }

extension AlertSeverityX on AlertSeverity {
  Color get color => switch (this) {
        AlertSeverity.critical => AppColors.riskHigh,
        AlertSeverity.warning => AppColors.warningMid,
        AlertSeverity.info => AppColors.info,
      };

  Color get surface => switch (this) {
        AlertSeverity.critical => AppColors.riskHighLight,
        AlertSeverity.warning => AppColors.warningLight,
        AlertSeverity.info => AppColors.infoLight,
      };

  String get label => switch (this) {
        AlertSeverity.critical => 'Critical',
        AlertSeverity.warning => 'Warning',
        AlertSeverity.info => 'Info',
      };

  int get rank => switch (this) {
        AlertSeverity.critical => 0,
        AlertSeverity.warning => 1,
        AlertSeverity.info => 2,
      };
}

extension AlertKindX on AlertKind {
  IconData get icon => switch (this) {
        AlertKind.coldChain => Icons.ac_unit_rounded,
        AlertKind.climate => Icons.cloud_queue_rounded,
        AlertKind.overdueChild => Icons.child_care_rounded,
        AlertKind.coverage => Icons.trending_down_rounded,
        AlertKind.sync => Icons.cloud_upload_outlined,
      };

  String get label => switch (this) {
        AlertKind.coldChain => 'Cold chain',
        AlertKind.climate => 'Climate',
        AlertKind.overdueChild => 'Overdue',
        AlertKind.coverage => 'Coverage',
        AlertKind.sync => 'Sync',
      };
}

class AlertModel {
  /// Stable across rebuilds — read state is keyed on it.
  final String id;
  final AlertKind kind;
  final AlertSeverity severity;
  final String title;
  final String body;

  /// What the worker should do about it.
  final String? action;

  final String? facilityId;
  final String? childId;

  /// Days until the disruption window opens, when the alert is forecast-based.
  final int? daysToWindow;
  final DateTime? createdAt;

  const AlertModel({
    required this.id,
    required this.kind,
    required this.severity,
    required this.title,
    required this.body,
    this.action,
    this.facilityId,
    this.childId,
    this.daysToWindow,
    this.createdAt,
  });

  String get timingLabel {
    if (daysToWindow != null) {
      if (daysToWindow! <= 0) return 'Active now';
      if (daysToWindow == 1) return 'Opens tomorrow';
      return 'Opens in $daysToWindow days';
    }
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  static AlertSeverity severityFromString(String? s) => switch (s) {
        'critical' => AlertSeverity.critical,
        'warning' => AlertSeverity.warning,
        _ => AlertSeverity.info,
      };

  static AlertKind kindFromString(String? s) => switch (s) {
        'coldChain' || 'cold_chain' => AlertKind.coldChain,
        'climate' => AlertKind.climate,
        'overdueChild' || 'overdue_child' => AlertKind.overdueChild,
        'coverage' => AlertKind.coverage,
        'sync' => AlertKind.sync,
        _ => AlertKind.climate,
      };

  factory AlertModel.fromJson(Map<String, dynamic> j) => AlertModel(
        id: j['id'] as String? ?? '',
        kind: kindFromString(j['kind'] as String?),
        severity: severityFromString(j['severity'] as String?),
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        action: j['action'] as String?,
        facilityId: j['facilityId'] as String?,
        childId: j['childId'] as String?,
        daysToWindow: (j['daysToWindow'] as num?)?.toInt(),
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
      );
}
