import 'vaccination_record.dart';

enum VisitStatus { toVisit, visited, missed }

enum RiskBand { high, medium, watch, low }

class ChildModel {
  final String id;
  final String name;
  final String gender;
  final String ageLabel;
  final String bornDate;
  final double riskScore;
  final double distanceKm;
  final String lastSeen;
  final String currentLocation;
  final String? parentName;
  final String? parentPhone;
  final List<String> dueVaccines;
  final List<VaccinationRecord> history;
  final VisitStatus status;

  const ChildModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.ageLabel,
    required this.bornDate,
    required this.riskScore,
    required this.distanceKm,
    required this.lastSeen,
    required this.currentLocation,
    this.parentName,
    this.parentPhone,
    required this.dueVaccines,
    this.history = const [],
    this.status = VisitStatus.toVisit,
  });

  RiskBand get riskBand {
    if (riskScore >= 0.90) return RiskBand.high;
    if (riskScore >= 0.80) return RiskBand.medium;
    if (riskScore >= 0.72) return RiskBand.watch;
    return RiskBand.low;
  }

  String get priorityLabel => switch (riskBand) {
        RiskBand.high => 'High priority',
        RiskBand.medium => 'Elevated',
        RiskBand.watch => 'Watch',
        RiskBand.low => 'Routine',
      };
}
