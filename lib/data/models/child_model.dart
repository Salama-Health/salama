import 'vaccination_record.dart';

enum VisitStatus { toVisit, visited, missed }

enum RiskBand { high, medium, watch, low }

class ChildModel {
  final String id;            // backend UUID — used for API calls
  final String code;          // human-readable code (QR / register no.)
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
  final String? facilityId;
  final String? workerId;
  final double? latitude;
  final double? longitude;
  final List<String> dueVaccines;
  final List<VaccinationRecord> history;
  final VisitStatus status;

  /// True when the risk model has not scored this child yet — a registration
  /// made on the device that has not synced. The app shows "Awaiting score"
  /// rather than presenting a band it has not been given.
  final bool riskPending;

  /// The band the server assigned, when it sent one. Preferred over deriving a
  /// band from [riskScore] locally: the server holds the live distribution the
  /// cut-offs were fitted to.
  final RiskBand? serverBand;

  const ChildModel({
    required this.id,
    String? code,
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
    this.facilityId,
    this.workerId,
    this.latitude,
    this.longitude,
    required this.dueVaccines,
    this.history = const [],
    this.status = VisitStatus.toVisit,
    this.riskPending = false,
    this.serverBand,
  }) : code = code ?? id;

  // Cut-offs fitted to the live score distribution (25 Sep 2026). The IGS is
  // multiplicative, soft-capped and normalised, so scores cluster far lower
  // than a 0-1 reading suggests: p90 is 0.193, not 0.90. The previous 0.90 /
  // 0.80 / 0.72 thresholds put 79 of 80 children in "routine", including one
  // with six overdue doses.
  //
  // These split the caseload 10 / 20 / 30 / 40 percent, roughly five High per
  // worker.
  static const double highCut = 0.193;
  static const double mediumCut = 0.068;
  static const double watchCut = 0.022;

  RiskBand get riskBand {
    if (serverBand != null) return serverBand!;
    if (riskScore >= highCut) return RiskBand.high;
    if (riskScore >= mediumCut) return RiskBand.medium;
    if (riskScore >= watchCut) return RiskBand.watch;
    return RiskBand.low;
  }

  /// Parse the server's band name. It emits High | Medium | Watch | Low; the
  /// app's display wording (High priority / Elevated / Watch / Routine) is a
  /// presentation choice layered on top.
  static RiskBand? bandFromString(String? s) => switch (s) {
        'High' => RiskBand.high,
        'Medium' => RiskBand.medium,
        'Watch' => RiskBand.watch,
        'Low' => RiskBand.low,
        _ => null,
      };

  String get priorityLabel => riskPending
      ? 'Awaiting score'
      : switch (riskBand) {
          RiskBand.high => 'High priority',
          RiskBand.medium => 'Elevated',
          RiskBand.watch => 'Watch',
          RiskBand.low => 'Routine',
        };

  static VisitStatus statusFromString(String? s) {
    switch (s) {
      case 'visited':
        return VisitStatus.visited;
      case 'missed':
        return VisitStatus.missed;
      default:
        return VisitStatus.toVisit;
    }
  }

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    final born = DateTime.tryParse(json['bornDate']?.toString() ?? '');
    return ChildModel(
      id: json['id'] as String,
      code: (json['qrCode'] as String?) ?? (json['id'] as String),
      name: json['name'] as String? ?? 'Unknown',
      gender: _gender(json['gender'] as String?),
      ageLabel: _ageLabel(born),
      bornDate: born != null ? VaccinationRecord.fmtDate(born) : '—',
      riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      lastSeen: _lastSeen(json['lastSeen']?.toString()),
      currentLocation: json['currentLocation'] as String? ?? 'Location unknown',
      parentName: json['parentName'] as String?,
      parentPhone: json['parentPhone'] as String?,
      facilityId: json['facilityId'] as String?,
      workerId: json['workerId'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      dueVaccines:
          (json['dueVaccines'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      history: (json['history'] as List?)
              ?.map((e) => VaccinationRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      status: statusFromString(json['status'] as String?),
      // A score of exactly 0.0 is a real result — the index is multiplicative,
      // so a child with no vaccination debt scores zero, meaning fully up to
      // date. Only an absent score means unscored.
      riskPending: json['riskPending'] as bool? ??
          json['pendingSync'] as bool? ??
          json['riskScore'] == null,
      serverBand: bandFromString(json['riskBand'] as String?),
    );
  }

  static String _gender(String? g) {
    if (g == null) return '—';
    if (g.toUpperCase() == 'F') return 'Female';
    if (g.toUpperCase() == 'M') return 'Male';
    return g;
  }

  static String _ageLabel(DateTime? born) {
    if (born == null) return '—';
    final days = DateTime.now().difference(born).inDays;
    if (days < 0) return 'newborn';
    final weeks = days ~/ 7;
    if (weeks < 16) return '$weeks weeks';
    final months = days ~/ 30;
    if (months < 24) return '$months months';
    return '${months ~/ 12} years';
  }

  static String _lastSeen(String? iso) {
    if (iso == null || iso.isEmpty) return 'Never contacted';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Never contacted';
    final days = DateTime.now().difference(dt).inDays;
    if (days <= 0) return 'Last seen today';
    if (days == 1) return 'Last seen yesterday';
    return 'Last seen ${days}d ago';
  }
}
