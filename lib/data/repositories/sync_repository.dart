import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../models/sync_models.dart';

/// Offline-first sync. Actions recorded while offline are queued locally and
/// flushed to POST /sync/upload. Every queued item carries a clientUuid so the
/// server de-duplicates re-uploads.
class SyncRepository {
  SyncRepository(this._api, this._prefs);

  final ApiClient _api;
  final SharedPreferences _prefs;

  static const _kVaccinations = 'queue_vaccinations';
  static const _kChildren = 'queue_children';
  static const _kVisits = 'queue_visits';

  // ── queue writers ──────────────────────────────────────────────────────────
  Future<void> queueVaccination(Map<String, dynamic> item) =>
      _append(_kVaccinations, item);

  Future<void> queueChild(Map<String, dynamic> item) =>
      _append(_kChildren, item);

  Future<void> queueVisit(Map<String, dynamic> item) =>
      _append(_kVisits, item);

  Future<void> _append(String key, Map<String, dynamic> item) async {
    final list = _read(key)..add(item);
    await _prefs.setString(key, jsonEncode(list));
  }

  List<Map<String, dynamic>> _read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  int get pendingCount =>
      _read(_kVaccinations).length +
      _read(_kChildren).length +
      _read(_kVisits).length;

  // ── server status ──────────────────────────────────────────────────────────
  Future<SyncStatus> status() async {
    final resp = await _api.get('/sync/status');
    final server = SyncStatus.fromJson(resp.data as Map<String, dynamic>);
    // Surface local pending count on top of the server's bookkeeping.
    return SyncStatus(
      lastSync: server.lastSync,
      pendingRecords: server.pendingRecords + pendingCount,
    );
  }

  /// Flush queued actions to the server. Clears the queue on success.
  Future<SyncResult> upload() async {
    final vaccinations = _read(_kVaccinations);
    final children = _read(_kChildren);
    final visits = _read(_kVisits);

    final resp = await _api.post('/sync/upload', data: {
      'vaccinations': vaccinations,
      'newChildren': children,
      'visits': visits,
    });

    await _prefs.remove(_kVaccinations);
    await _prefs.remove(_kChildren);
    await _prefs.remove(_kVisits);

    return SyncResult.fromJson(resp.data as Map<String, dynamic>);
  }
}
