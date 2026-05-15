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
}
