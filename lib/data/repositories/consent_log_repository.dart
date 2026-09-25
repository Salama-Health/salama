import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One caregiver's consent, as taken in the field.
class ConsentRecord {
  final String childCode;
  final String childName;
  final String caregiverName;
  final String? workerId;
  final DateTime consentAt;

  const ConsentRecord({
    required this.childCode,
    required this.childName,
    required this.caregiverName,
    required this.consentAt,
    this.workerId,
  });

  Map<String, dynamic> toJson() => {
        'childCode': childCode,
        'childName': childName,
        'caregiverName': caregiverName,
        'workerId': workerId,
        'consentAt': consentAt.toIso8601String(),
      };

  factory ConsentRecord.fromJson(Map<String, dynamic> j) => ConsentRecord(
        childCode: j['childCode'] as String? ?? '',
        childName: j['childName'] as String? ?? '',
        caregiverName: j['caregiverName'] as String? ?? '',
        workerId: j['workerId'] as String?,
        consentAt:
            DateTime.tryParse(j['consentAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

/// A local, append-only record of consent taken before each registration.
///
/// The server currently accepts `consentGiven` and `consentAt` on
/// POST /children and discards them. The outbox drops a payload once the server
/// confirms it, so without this the only evidence that consent was ever taken
/// would disappear at the moment a registration succeeds.
///
/// This is a stopgap, not the system of record: it lives on one phone and is
/// only as durable as that phone. It exists so that when the server does start
/// storing consent, the registrations made in the meantime can be reconciled
/// rather than being permanently unattested. Nothing clears it automatically.
class ConsentLogRepository {
  ConsentLogRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kLog = 'consent_log_v1';

  List<ConsentRecord> get records {
    final raw = _prefs.getString(_kLog);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => ConsentRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  int get count => records.length;

  Future<void> record(ConsentRecord entry) async {
    final list = records.toList()..add(entry);
    await _prefs.setString(
        _kLog, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  /// CSV, so the log can be handed over or filed as an attestation.
  String toCsv() {
    final b = StringBuffer()
      ..writeln('child_code,child_name,caregiver_name,worker_id,consent_at');
    for (final r in records) {
      b.writeln('${r.childCode},"${r.childName}","${r.caregiverName}",'
          '${r.workerId ?? ""},${r.consentAt.toIso8601String()}');
    }
    return b.toString();
  }

  /// Only ever called when the person explicitly asks, after exporting.
  Future<void> clear() => _prefs.remove(_kLog);
}
