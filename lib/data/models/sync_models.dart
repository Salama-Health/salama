class SyncStatus {
  final DateTime? lastSync;
  final int pendingRecords;

  const SyncStatus({this.lastSync, this.pendingRecords = 0});

  factory SyncStatus.fromJson(Map<String, dynamic> j) => SyncStatus(
        lastSync: j['lastSync'] != null
            ? DateTime.tryParse(j['lastSync'].toString())
            : null,
        pendingRecords: (j['pendingRecords'] as num?)?.toInt() ?? 0,
      );

  String get lastSyncLabel {
    if (lastSync == null) return 'Never';
    final d = lastSync!.toLocal();
    final now = DateTime.now();
    final sameDay =
        d.year == now.year && d.month == now.month && d.day == now.day;
    final hh = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final time = '$hh:${d.minute.toString().padLeft(2, '0')} $ampm';
    return sameDay ? 'Today, $time' : '${d.day}/${d.month}, $time';
  }
}

class SyncResult {
  final int vaccinationsSaved;
  final int childrenSaved;
  final int visitsSaved;
  final int duplicatesSkipped;
  final List<String> errors;

  const SyncResult({
    this.vaccinationsSaved = 0,
    this.childrenSaved = 0,
    this.visitsSaved = 0,
    this.duplicatesSkipped = 0,
    this.errors = const [],
  });

  int get totalSaved => vaccinationsSaved + childrenSaved + visitsSaved;

  factory SyncResult.fromJson(Map<String, dynamic> j) => SyncResult(
        vaccinationsSaved: (j['vaccinationsSaved'] as num?)?.toInt() ?? 0,
        childrenSaved: (j['childrenSaved'] as num?)?.toInt() ?? 0,
        visitsSaved: (j['visitsSaved'] as num?)?.toInt() ?? 0,
        duplicatesSkipped: (j['duplicatesSkipped'] as num?)?.toInt() ?? 0,
        errors: (j['errors'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
      );
}
