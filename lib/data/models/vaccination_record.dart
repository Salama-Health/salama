enum DoseStatus { given, due, missed }

class VaccinationRecord {
  final String vaccine;
  final String dose;
  final String date;
  final DoseStatus status;
  final String? batch;

  const VaccinationRecord({
    required this.vaccine,
    required this.dose,
    required this.date,
    required this.status,
    this.batch,
  });

  static DoseStatus statusFromString(String? s) {
    switch (s) {
      case 'given':
        return DoseStatus.given;
      case 'missed':
        return DoseStatus.missed;
      default:
        return DoseStatus.due;
    }
  }

  factory VaccinationRecord.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    String dateLabel;
    if (rawDate == null) {
      dateLabel = 'Due now';
    } else {
      final parsed = DateTime.tryParse(rawDate.toString());
      dateLabel = parsed != null ? fmtDate(parsed) : rawDate.toString();
    }
    return VaccinationRecord(
      vaccine: json['vaccine'] as String? ?? '',
      dose: json['dose'] as String? ?? '',
      date: dateLabel,
      status: statusFromString(json['status'] as String?),
      batch: json['batch'] as String?,
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String fmtDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
}
