import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_exception.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/utils/id_gen.dart';

/// What kind of write is waiting. The wire format groups by this, so the names
/// map onto the arrays in POST /sync/upload.
enum OutboxKind { vaccination, child, visit }

extension OutboxKindX on OutboxKind {
  /// The key this kind occupies in the /sync/upload body.
  String get wireKey => switch (this) {
        OutboxKind.vaccination => 'vaccinations',
        OutboxKind.child => 'newChildren',
        OutboxKind.visit => 'visits',
      };

  String get label => switch (this) {
        OutboxKind.vaccination => 'Vaccination records',
        OutboxKind.child => 'New registrations',
        OutboxKind.visit => 'Visit outcomes',
      };
}

/// One queued write.
class OutboxEntry {
  final String id;
  final OutboxKind kind;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;

  /// How many times an upload has been attempted. Surfaced so a record that
  /// keeps failing is visible rather than silently stuck.
  final int attempts;

  const OutboxEntry({
    required this.id,
    required this.kind,
    required this.payload,
    required this.queuedAt,
    this.attempts = 0,
  });

  OutboxEntry withAttempt() => OutboxEntry(
        id: id,
        kind: kind,
        payload: payload,
        queuedAt: queuedAt,
        attempts: attempts + 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'payload': payload,
        'queuedAt': queuedAt.toIso8601String(),
        'attempts': attempts,
      };

  factory OutboxEntry.fromJson(Map<String, dynamic> j) => OutboxEntry(
        id: j['id'] as String,
        kind: OutboxKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => OutboxKind.visit,
        ),
        payload: Map<String, dynamic>.from(j['payload'] as Map),
        queuedAt:
            DateTime.tryParse(j['queuedAt']?.toString() ?? '') ?? DateTime.now(),
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      );
}

/// The result of a write that may have gone to the server or to the queue.
enum WriteOutcome { synced, queued }

class WriteResult<T> {
  final WriteOutcome outcome;

  /// The server's response, when it reached the server.
  final T? value;

  const WriteResult(this.outcome, [this.value]);

  bool get synced => outcome == WriteOutcome.synced;
  bool get queued => outcome == WriteOutcome.queued;
}

/// Durable outbox for writes made in the field.
///
/// The outbox pattern, applied to a phone that is offline more often than not:
/// every write goes through [submit], which sends it if it can and durably
/// queues it if it cannot. Nothing a health worker records is held only in
/// memory, and the three call sites that used to each hand-roll their own
/// try/queue/catch dance now share one implementation.
///
/// Entries are kept in a single ordered list so replay preserves the sequence a
/// worker actually performed — a registration before the dose given at the same
/// visit, for instance.
class OutboxRepository {
  OutboxRepository(this._prefs) {
    _migrateLegacyQueues();
  }

  final SharedPreferences _prefs;

  static const _kOutbox = 'outbox_v1';

  // Pre-outbox keys, folded in on first construction so work queued by an
  // earlier build is not orphaned by the upgrade.
  static const _legacy = {
    'queue_vaccinations': OutboxKind.vaccination,
    'queue_children': OutboxKind.child,
    'queue_visits': OutboxKind.visit,
  };

  // ── Reading ────────────────────────────────────────────────────────────────
  List<OutboxEntry> get entries {
    final raw = _prefs.getString(_kOutbox);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => OutboxEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  int get pendingCount => entries.length;

  Map<OutboxKind, int> get pendingByKind {
    final counts = {for (final k in OutboxKind.values) k: 0};
    for (final e in entries) {
      counts[e.kind] = (counts[e.kind] ?? 0) + 1;
    }
    return counts;
  }

  /// Payloads for one kind, oldest first — the shape /sync/upload expects.
  List<Map<String, dynamic>> payloadsFor(OutboxKind kind) =>
      entries.where((e) => e.kind == kind).map((e) => e.payload).toList();

  /// Queued registrations, newest first, for showing what is still local.
  List<Map<String, dynamic>> get queuedChildren =>
      entries.where((e) => e.kind == OutboxKind.child).toList().reversed
          .map((e) => e.payload)
          .toList();

  // ── Writing ────────────────────────────────────────────────────────────────
  Future<void> add(OutboxKind kind, Map<String, dynamic> payload) async {
    final list = entries.toList()
      ..add(OutboxEntry(
        id: IdGen.uuid(),
        kind: kind,
        payload: payload,
        queuedAt: DateTime.now(),
      ));
    await _save(list);
  }

  /// Send [request] if the network allows, otherwise queue [payload].
  ///
  /// A network failure mid-request queues rather than throwing: a dose already
  /// given, or a registration already consented to, must not be lost to a
  /// dropped bar of signal. A rejection from the server (validation, auth,
  /// conflict) is a real answer and is rethrown for the caller to show.
  Future<WriteResult<T>> submit<T>({
    required OutboxKind kind,
    required Map<String, dynamic> payload,
    required Future<T> Function() request,
  }) async {
    if (!ConnectivityService.instance.isOnline.value) {
      await add(kind, payload);
      return const WriteResult(WriteOutcome.queued);
    }
    try {
      final value = await request();
      return WriteResult(WriteOutcome.synced, value);
    } on ApiException catch (e) {
      // A route that does not exist yet is not a rejection of the write. Some
      // endpoints are still being built, and the same payload reaches the
      // server in the next /sync/upload batch, so queue rather than lose it.
      final notBuiltYet = e.statusCode == 404 || e.statusCode == 405;
      if (!e.isNetwork && !notBuiltYet) rethrow;
      await add(kind, payload);
      return const WriteResult(WriteOutcome.queued);
    }
  }

  /// Mark every entry as attempted, so repeated failures are visible.
  Future<void> recordAttempt() async {
    final list = entries.map((e) => e.withAttempt()).toList();
    if (list.isEmpty) return;
    await _save(list);
  }

  /// Drop everything — called once the server confirms receipt.
  Future<void> clear() => _prefs.remove(_kOutbox);

  Future<void> _save(List<OutboxEntry> list) =>
      _prefs.setString(_kOutbox, jsonEncode(list.map((e) => e.toJson()).toList()));

  // ── Migration ──────────────────────────────────────────────────────────────
  void _migrateLegacyQueues() {
    final pending = <OutboxEntry>[];
    for (final entry in _legacy.entries) {
      final raw = _prefs.getString(entry.key);
      if (raw == null || raw.isEmpty) continue;
      try {
        for (final item in jsonDecode(raw) as List) {
          pending.add(OutboxEntry(
            id: IdGen.uuid(),
            kind: entry.value,
            payload: Map<String, dynamic>.from(item as Map),
            queuedAt: DateTime.now(),
          ));
        }
      } catch (_) {
        // Unreadable legacy payload — drop it rather than blocking startup.
      }
    }
    if (pending.isEmpty) return;
    final merged = entries.toList()..addAll(pending);
    // Fire and forget: prefs writes are local and the queue is re-read on use.
    _save(merged);
    for (final key in _legacy.keys) {
      _prefs.remove(key);
    }
  }
}
