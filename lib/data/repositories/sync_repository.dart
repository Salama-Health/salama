import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/api_routes.dart';
import '../../core/storage/offline_cache.dart';
import '../models/sync_models.dart';
import 'outbox_repository.dart';

/// Sync between the device outbox and the server.
///
/// The queue itself lives in [OutboxRepository]; this type owns the transport:
/// reading status, flushing the outbox, and keeping the last-synced stamp.
class SyncRepository {
  SyncRepository(this._api, this._outbox, this._cache);

  final ApiClient _api;
  final OutboxRepository _outbox;
  final OfflineCache _cache;

  // ── Local queue view ───────────────────────────────────────────────────────
  int get pendingCount => _outbox.pendingCount;

  ({int vaccinations, int children, int visits}) get pendingBreakdown {
    final byKind = _outbox.pendingByKind;
    return (
      vaccinations: byKind[OutboxKind.vaccination] ?? 0,
      children: byKind[OutboxKind.child] ?? 0,
      visits: byKind[OutboxKind.visit] ?? 0,
    );
  }

  /// The oldest thing still waiting, for telling the worker how far behind the
  /// device is.
  DateTime? get oldestPending {
    final entries = _outbox.entries;
    if (entries.isEmpty) return null;
    return entries
        .map((e) => e.queuedAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  List<Map<String, dynamic>> get queuedChildren => _outbox.queuedChildren;

  // ── Server status ──────────────────────────────────────────────────────────
  /// Never throws on a network failure. The pending count lives on this device,
  /// so it must stay visible precisely when the server cannot be reached —
  /// otherwise the app reports "0 waiting" at the moment work is piling up.
  Future<SyncStatus> status() async {
    try {
      final resp = await _api.get(ApiRoutes.syncStatus);
      final server = SyncStatus.fromJson(resp.data as Map<String, dynamic>);
      if (server.lastSync != null) {
        await _cache.write(
            OfflineCache.kLastSync, server.lastSync!.toIso8601String());
      }
      return SyncStatus(
        lastSync: server.lastSync,
        pendingRecords: server.pendingRecords + pendingCount,
      );
    } on ApiException catch (e) {
      if (!e.isNetwork) rethrow;
      final cached = _cache.read(OfflineCache.kLastSync);
      return SyncStatus(
        lastSync: cached is String ? DateTime.tryParse(cached) : null,
        pendingRecords: pendingCount,
      );
    }
  }

  /// Flush the outbox. Clears it only once the server has confirmed receipt.
  Future<SyncResult> upload() async {
    await _outbox.recordAttempt();

    final body = {
      for (final kind in OutboxKind.values)
        kind.wireKey: _outbox.payloadsFor(kind),
    };

    final resp = await _api.post(ApiRoutes.syncUpload, data: body);
    final result = SyncResult.fromJson(resp.data as Map<String, dynamic>);

    // The queue is only dropped on a confirmed response. A thrown request
    // leaves every entry in place for the next attempt.
    await _outbox.clear();
    await _cache.write(
        OfflineCache.kLastSync, DateTime.now().toIso8601String());

    return result;
  }
}
