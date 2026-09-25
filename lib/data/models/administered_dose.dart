/// A dose this worker has given, as returned by `GET /vaccinations` with no
/// `childId`.
///
/// Distinct from [VaccinationRecord], which is a child's timeline row: that
/// model formats its date into a display string at parse time, which is right
/// for a timeline but useless for grouping and sorting across children. This
/// one keeps the real [DateTime] and carries the child's name, because the
/// worker view spans many children.
class AdministeredDose {
  final String id;
  final String childId;
  final String childName;
  final String vaccine;
  final DateTime? givenAt;
  final String? batch;
  final String? site;
  /// Worker who gave the dose. Matters in the region view, where the list
  /// spans colleagues.
  final String? administeredBy;

  const AdministeredDose({
    required this.id,
    required this.childId,
    required this.childName,
    required this.vaccine,
    this.givenAt,
    this.batch,
    this.site,
    this.administeredBy,
  });

  factory AdministeredDose.fromJson(Map<String, dynamic> json) {
    final raw = json['date'];
    return AdministeredDose(
      id: json['id'] as String? ?? '',
      childId: json['childId'] as String? ?? '',
      // Falls back rather than showing an empty row: a dose with no resolvable
      // child is still a dose the worker gave.
      childName: json['childName'] as String? ?? 'Unknown child',
      vaccine: json['vaccine'] as String? ?? '',
      givenAt: raw == null ? null : DateTime.tryParse(raw.toString()),
      batch: json['batch'] as String?,
      site: json['site'] as String?,
      administeredBy: json['administeredBy'] as String?,
    );
  }
}

/// One child, with every dose this worker has given them.
class VaccinatedChild {
  final String childId;
  final String childName;
  final List<AdministeredDose> doses;

  const VaccinatedChild({
    required this.childId,
    required this.childName,
    required this.doses,
  });

  /// Most recent dose for this child, used to order the list.
  DateTime? get lastGivenAt {
    DateTime? latest;
    for (final d in doses) {
      final at = d.givenAt;
      if (at == null) continue;
      if (latest == null || at.isAfter(latest)) latest = at;
    }
    return latest;
  }

  /// Groups a flat, newest-first dose list by child, preserving that order:
  /// the first child seen is the most recently vaccinated.
  static List<VaccinatedChild> groupByChild(List<AdministeredDose> doses) {
    final order = <String>[];
    final byChild = <String, List<AdministeredDose>>{};
    for (final d in doses) {
      if (!byChild.containsKey(d.childId)) {
        byChild[d.childId] = [];
        order.add(d.childId);
      }
      byChild[d.childId]!.add(d);
    }
    return [
      for (final id in order)
        VaccinatedChild(
          childId: id,
          childName: byChild[id]!.first.childName,
          doses: byChild[id]!,
        ),
    ];
  }
}
