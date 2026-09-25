import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_exception.dart';

/// Read-through cache backed by SharedPreferences.
///
/// Every list the app shows is fetched network-first and mirrored to disk. When
/// the network is unreachable the last good copy is served instead, so a health
/// worker who opens the app in a village with no signal still sees their
/// children, their priority list and their facility risk scores.
///
/// Only genuine network failures fall back to cache — a 401 or a 404 is a real
/// answer from the server and is allowed through untouched.
class OfflineCache {
  OfflineCache(this._prefs);

  final SharedPreferences _prefs;

  static const _dataPrefix = 'cache_v1_';
  static const _stampPrefix = 'cache_at_v1_';

  // ── Known cache keys ───────────────────────────────────────────────────────
  static const kChildren = 'children';
  static const kFacilities = 'facilities';
  static const kActivity = 'activity';
  static const kReports = 'reports';
  static const kRoute = 'route';
  static const kWorker = 'worker';
  static const kAlerts = 'alerts';
  static const kLastSync = 'last_sync';

  /// True when the most recent read was served from disk rather than the
  /// network. Drives the "showing saved data" banner.
  final ValueNotifier<bool> servingStale = ValueNotifier<bool>(false);

  // ── Raw access ─────────────────────────────────────────────────────────────
  Future<void> write(String key, Object? json) async {
    await _prefs.setString('$_dataPrefix$key', jsonEncode(json));
    await _prefs.setInt(
        '$_stampPrefix$key', DateTime.now().millisecondsSinceEpoch);
  }

  dynamic read(String key) {
    final raw = _prefs.getString('$_dataPrefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  bool has(String key) => _prefs.containsKey('$_dataPrefix$key');

  DateTime? savedAt(String key) {
    final ms = _prefs.getInt('$_stampPrefix$key');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Human label for how old the cached copy is — "just now", "12m ago".
  String? savedAtLabel(String key) {
    final at = savedAt(key);
    if (at == null) return null;
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays}d ago';
  }

  /// The freshest timestamp across the caches the home screen depends on.
  DateTime? get newestStamp {
    final stamps = [kChildren, kFacilities, kActivity]
        .map(savedAt)
        .whereType<DateTime>()
        .toList();
    if (stamps.isEmpty) return null;
    stamps.sort();
    return stamps.last;
  }

  // ── Read-through ───────────────────────────────────────────────────────────
  /// Fetch from the network, mirror the raw JSON to disk, and fall back to the
  /// mirror when the network is unreachable.
  ///
  /// The bytes stored are exactly the bytes the server sent, so a cached read
  /// and a live read run through the same [decode] and produce identical
  /// objects — there is no second, drifting representation to maintain.
  Future<T> readThrough<T>({
    required String key,
    required Future<dynamic> Function() fetchJson,
    required T Function(dynamic json) decode,
  }) async {
    try {
      final json = await fetchJson();
      await write(key, json);
      servingStale.value = false;
      return decode(json);
    } on ApiException catch (e) {
      if (!e.isNetwork) rethrow;
      final cached = read(key);
      if (cached == null) rethrow;
      servingStale.value = true;
      return decode(cached);
    }
  }

  // ── Housekeeping ───────────────────────────────────────────────────────────
  Iterable<String> get _dataKeys =>
      _prefs.getKeys().where((k) => k.startsWith(_dataPrefix));

  int get entryCount => _dataKeys.length;

  /// Rough on-disk size of the cached payloads, in kilobytes.
  double get approxSizeKb {
    var bytes = 0;
    for (final k in _dataKeys) {
      bytes += (_prefs.getString(k) ?? '').length;
    }
    return bytes / 1024;
  }

  Future<void> clearAll() async {
    for (final k in _prefs.getKeys().toList()) {
      if (k.startsWith(_dataPrefix) || k.startsWith(_stampPrefix)) {
        await _prefs.remove(k);
      }
    }
    servingStale.value = false;
  }
}
