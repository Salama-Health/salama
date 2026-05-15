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

  const FacilityModel({
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
  });
}
