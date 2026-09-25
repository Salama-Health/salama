class ReportSummary {
  final int dosesThisMonth;
  final double coverageRate; // 0..1
  final int childrenReached;
  final double dropoutRate; // 0..1

  /// The period these figures cover, as the server labels it ("September 2026").
  /// The app displays this rather than assuming the device month matches what
  /// was aggregated.
  final String? period;

  const ReportSummary({
    required this.dosesThisMonth,
    required this.coverageRate,
    required this.childrenReached,
    required this.dropoutRate,
    this.period,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> j) => ReportSummary(
        dosesThisMonth: (j['dosesThisMonth'] as num?)?.toInt() ?? 0,
        coverageRate: (j['coverageRate'] as num?)?.toDouble() ?? 0,
        childrenReached: (j['childrenReached'] as num?)?.toInt() ?? 0,
        dropoutRate: (j['dropoutRate'] as num?)?.toDouble() ?? 0,
        period: j['period'] as String?,
      );
}

/// Month and year from the device clock, used only when the server does not
/// label the period itself.
String currentPeriodLabel([DateTime? now]) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final d = now ?? DateTime.now();
  return '${months[d.month - 1]} ${d.year}';
}

class DayCount {
  final String label;
  final int count;
  const DayCount({required this.label, required this.count});

  factory DayCount.fromJson(Map<String, dynamic> j) => DayCount(
        label: j['label'] as String? ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

class VaccineCoverage {
  final String name;
  final double coverage; // 0..1
  const VaccineCoverage({required this.name, required this.coverage});

  factory VaccineCoverage.fromJson(Map<String, dynamic> j) => VaccineCoverage(
        name: j['name'] as String? ?? '',
        coverage: (j['coverage'] as num?)?.toDouble() ?? 0,
      );
}

/// Aggregated payload for the Reports screen.
class ReportsBundle {
  final ReportSummary summary;
  final List<DayCount> weeklyDoses;
  final List<VaccineCoverage> coverage;

  const ReportsBundle({
    required this.summary,
    required this.weeklyDoses,
    required this.coverage,
  });
}
