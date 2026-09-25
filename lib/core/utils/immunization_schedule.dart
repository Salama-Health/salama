/// The national EPI schedule used in South Sudan (WHO recommended).
///
/// Ages are in weeks from birth. Registering a child computes which doses are
/// already due from the date of birth alone, so a worker meeting a nine-month-old
/// for the first time does not have to remember the whole schedule under a tree.
class ImmunizationSchedule {
  ImmunizationSchedule._();

  /// (vaccine, age due in weeks)
  static const List<({String vaccine, int weeks})> schedule = [
    (vaccine: 'BCG', weeks: 0),
    (vaccine: 'OPV-0', weeks: 0),
    (vaccine: 'OPV-1', weeks: 6),
    (vaccine: 'Penta-1', weeks: 6),
    (vaccine: 'PCV-1', weeks: 6),
    (vaccine: 'Rota-1', weeks: 6),
    (vaccine: 'OPV-2', weeks: 10),
    (vaccine: 'Penta-2', weeks: 10),
    (vaccine: 'PCV-2', weeks: 10),
    (vaccine: 'Rota-2', weeks: 10),
    (vaccine: 'OPV-3', weeks: 14),
    (vaccine: 'Penta-3', weeks: 14),
    (vaccine: 'PCV-3', weeks: 14),
    (vaccine: 'Measles-1', weeks: 39), // 9 months
    (vaccine: 'Yellow Fever', weeks: 39),
    (vaccine: 'Measles-2', weeks: 78), // 18 months
  ];

  /// Every vaccine in the schedule, in the order it is given.
  static List<String> get allVaccines =>
      schedule.map((e) => e.vaccine).toList();

  /// Doses this child is already old enough to have received.
  static List<String> dueFor(DateTime birthDate, {DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final weeks = now.difference(birthDate).inDays ~/ 7;
    if (weeks < 0) return const [];
    return schedule
        .where((e) => weeks >= e.weeks)
        .map((e) => e.vaccine)
        .toList();
  }

  /// The next dose that falls due, and how many weeks away it is.
  static ({String vaccine, int inWeeks})? nextFor(DateTime birthDate,
      {DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final weeks = now.difference(birthDate).inDays ~/ 7;
    for (final e in schedule) {
      if (e.weeks > weeks) {
        return (vaccine: e.vaccine, inWeeks: e.weeks - weeks);
      }
    }
    return null;
  }

  /// "3 weeks" / "7 months" / "2 years" for a date of birth.
  static String ageLabel(DateTime birthDate, {DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final days = now.difference(birthDate).inDays;
    if (days < 0) return 'not yet born';
    if (days == 0) return 'newborn';
    if (days < 7) return days == 1 ? '1 day' : '$days days';
    final weeks = days ~/ 7;
    if (weeks < 16) return weeks == 1 ? '1 week' : '$weeks weeks';
    final months = days ~/ 30;
    if (months < 24) return '$months months';
    final years = months ~/ 12;
    return years == 1 ? '1 year' : '$years years';
  }
}
