import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum FacilityRisk { danger, warning, ok }

extension FacilityRiskX on FacilityRisk {
  Color get color => switch (this) {
        FacilityRisk.danger => AppColors.riskHigh,
        FacilityRisk.warning => AppColors.warningMid,
        FacilityRisk.ok => AppColors.success,
      };

  Color get surface => switch (this) {
        FacilityRisk.danger => AppColors.riskHighLight,
        FacilityRisk.warning => AppColors.warningLight,
        FacilityRisk.ok => AppColors.successLight,
      };

  String get label => switch (this) {
        FacilityRisk.danger => 'Danger',
        FacilityRisk.warning => 'Warning',
        FacilityRisk.ok => 'Stable',
      };
}

class FacilityModel {
  final String id;
  final String name;
  final String county;
  final int children;
  final double cdiScore;
  final FacilityRisk risk;
  final String hazard;
  final int daysToWindow;
  final String hazardDetail;
  final String hazardTimeframe;
  final int highPriority;
  final int dueSoon;
  final int recentlyVisited;
  final bool assigned;

  /// When the satellite radar behind the CDI was observed. Null means the score
  /// came from seasonal estimates rather than an actual pass — materially
  /// weaker evidence, so the app says so instead of presenting it as measured.
  final DateTime? sarObservedAt;

  const FacilityModel({
    this.id = '',
    required this.name,
    required this.county,
    required this.children,
    required this.cdiScore,
    required this.risk,
    required this.hazard,
    required this.daysToWindow,
    required this.hazardDetail,
    required this.hazardTimeframe,
    required this.highPriority,
    required this.dueSoon,
    required this.recentlyVisited,
    this.assigned = false,
    this.sarObservedAt,
  });

  /// "observed today" / "radar 3 days old" / "seasonal estimate".
  String get cdiSourceLabel {
    if (sarObservedAt == null) return 'Seasonal estimate — no radar pass';
    final days = DateTime.now().difference(sarObservedAt!).inDays;
    if (days <= 0) return 'Radar observed today';
    if (days == 1) return 'Radar observed yesterday';
    return 'Radar observed $days days ago';
  }

  bool get cdiFromRadar => sarObservedAt != null;

  /// Backend returns the 4-level CDI band (Low/Medium/High/Critical); map it to
  /// the app's 3-level visual risk enum.
  static FacilityRisk riskFromString(String? s) {
    switch (s) {
      case 'Critical':
      case 'High':
        return FacilityRisk.danger;
      case 'Medium':
        return FacilityRisk.warning;
      default:
        return FacilityRisk.ok;
    }
  }

  factory FacilityModel.fromJson(Map<String, dynamic> json) {
    return FacilityModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Facility',
      county: [json['county'], json['state']]
          .where((e) => e != null && e.toString().isNotEmpty)
          .join(', '),
      children: (json['children'] as num?)?.toInt() ?? 0,
      cdiScore: (json['cdiScore'] as num?)?.toDouble() ?? 0.0,
      risk: riskFromString(json['risk'] as String?),
      hazard: json['hazard'] as String? ?? 'No active hazard',
      daysToWindow: (json['daysToWindow'] as num?)?.toInt() ?? 0,
      hazardDetail: json['hazardDetail'] as String? ?? '',
      hazardTimeframe: json['hazardTimeframe'] as String? ?? '',
      highPriority: (json['highPriority'] as num?)?.toInt() ?? 0,
      dueSoon: (json['dueSoon'] as num?)?.toInt() ?? 0,
      recentlyVisited: (json['recentlyVisited'] as num?)?.toInt() ?? 0,
      assigned: json['assigned'] as bool? ?? false,
      sarObservedAt: json['sarObservedAt'] != null
          ? DateTime.tryParse(json['sarObservedAt'].toString())
          : null,
    );
  }
}
