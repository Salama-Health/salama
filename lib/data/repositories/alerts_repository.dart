import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/storage/offline_cache.dart';
import '../models/alert_model.dart';
import '../models/child_model.dart';
import '../models/facility_model.dart';

/// Alerts shown on the bell and the Alerts screen.
///
/// Two sources, in priority order:
///   1. `GET /alerts` — once the backend serves them, they win.
///   2. Derived on-device from facility CDI scores, the child priority list and
///      the offline queue. This keeps the alerts screen truthful before the
///      endpoint exists, and keeps it working with no signal.
class AlertsRepository {
  AlertsRepository(this._api, this._prefs, this._cache);

  final ApiClient _api;
  final SharedPreferences _prefs;
  final OfflineCache _cache;

  static const _kRead = 'alerts_read_ids';

  // ── Server ─────────────────────────────────────────────────────────────────
  /// Fetch server alerts. Returns null when the endpoint is absent or
  /// unreachable, so the caller can fall back to derived alerts rather than
  /// showing an error over what is fundamentally advisory information.
  Future<List<AlertModel>?> fetchServer() async {
    try {
      final list = await _cache.readThrough<List<AlertModel>>(
        key: OfflineCache.kAlerts,
        fetchJson: () async => (await _api.get('/alerts')).data,
        decode: (json) => (json as List)
            .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return list;
    } on ApiException {
      return null;
    }
  }

  // ── Derived ────────────────────────────────────────────────────────────────
  /// Build alerts from data the app already holds.
  static List<AlertModel> derive({
    required List<FacilityModel> facilities,
    required List<ChildModel> children,
    required int pendingRecords,
  }) {
    final out = <AlertModel>[];

    // Facility climate / cold-chain risk.
    for (final f in facilities) {
      if (f.risk == FacilityRisk.ok) continue;
      final critical = f.risk == FacilityRisk.danger;
      final coldChain = f.cdiScore >= 0.75;
      out.add(AlertModel(
        id: 'facility-${f.id.isEmpty ? f.name : f.id}',
        kind: coldChain ? AlertKind.coldChain : AlertKind.climate,
        severity:
            critical ? AlertSeverity.critical : AlertSeverity.warning,
        title: coldChain
            ? 'Cold chain at risk — ${f.name}'
            : '${f.hazard} forecast — ${f.name}',
        body: f.hazardDetail.isNotEmpty
            ? f.hazardDetail
            : '${f.hazard} may disrupt immunization at ${f.name}. '
                'CDI ${f.cdiScore.toStringAsFixed(2)}.',
        action: critical
            ? 'Move doses forward and pre-position vaccines'
            : 'Plan visits before the window opens',
        facilityId: f.id.isEmpty ? null : f.id,
        daysToWindow: f.daysToWindow,
      ));
    }

    // Children overdue on doses, worst first.
    final overdue = children
        .where((c) =>
            c.status != VisitStatus.visited &&
            c.dueVaccines.isNotEmpty &&
            (c.riskBand == RiskBand.high || c.riskBand == RiskBand.medium))
        .toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    for (final c in overdue.take(12)) {
      final doses = c.dueVaccines.length;
      out.add(AlertModel(
        id: 'child-${c.id}',
        kind: AlertKind.overdueChild,
        severity: c.riskBand == RiskBand.high
            ? AlertSeverity.critical
            : AlertSeverity.warning,
        title: '${c.name} is overdue',
        body: '$doses ${doses == 1 ? "dose" : "doses"} outstanding — '
            '${c.dueVaccines.take(3).join(", ")}'
            '${doses > 3 ? "…" : ""}. ${c.lastSeen}.',
        action: 'Visit ${c.currentLocation}',
        childId: c.id,
      ));
    }

    // Unsynced work sitting on the device.
    if (pendingRecords > 0) {
      out.add(AlertModel(
        id: 'sync-pending',
        kind: AlertKind.sync,
        severity: AlertSeverity.info,
        title: '$pendingRecords '
            '${pendingRecords == 1 ? "record" : "records"} waiting to sync',
        body: 'Work recorded offline is stored on this device and has not '
            'reached the server yet.',
        action: 'Sync when you have a connection',
        createdAt: DateTime.now(),
      ));
    }

    out.sort((a, b) {
      final bySeverity = a.severity.rank.compareTo(b.severity.rank);
      if (bySeverity != 0) return bySeverity;
      return (a.daysToWindow ?? 999).compareTo(b.daysToWindow ?? 999);
    });
    return out;
  }

  // ── Read state ─────────────────────────────────────────────────────────────
  Set<String> get readIds {
    final raw = _prefs.getString(_kRead);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> markRead(String id) async {
    final ids = readIds..add(id);
    await _prefs.setString(_kRead, jsonEncode(ids.toList()));
  }

  Future<void> markAllRead(Iterable<String> ids) async {
    final all = readIds..addAll(ids);
    await _prefs.setString(_kRead, jsonEncode(all.toList()));
  }

  Future<void> clearRead() => _prefs.remove(_kRead);

  int unreadCount(List<AlertModel> alerts) {
    final read = readIds;
    return alerts.where((a) => !read.contains(a.id)).length;
  }
}
