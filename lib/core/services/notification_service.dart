import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/alert_model.dart';

/// On-device notifications.
///
/// Local, not push. A recorded dose is already confirmed by the call we just
/// made, so there is nothing to wait for a server to tell us — and this keeps
/// working when the dose goes to the offline outbox instead, which is exactly
/// when a worker most needs the confirmation.
///
/// The governing rule is that a notification must never repeat what the screen
/// is already saying. A worker who taps Save is looking at a snackbar that
/// confirms the dose; a tray entry with the same words is noise, and noise is
/// how a notification channel gets muted. So:
///
///   * a dose confirmation is suppressed while the app is in the foreground
///   * queued work is **one** notification showing the current count, replaced
///     in place, not one per record
///   * an alert notifies at most once ever, keyed on its id, and several at
///     once collapse into a single summary
///
/// Every method is safe to call before [init], and safe to call on a platform
/// that refuses the permission: notifications are a confirmation, never the
/// thing itself, so a failure here must never break recording a dose.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  SharedPreferences? _prefs;

  /// True while the app is on screen. A confirmation of something the worker
  /// just did belongs in the UI they are looking at, not in the tray.
  bool _foreground = true;

  static const _kNotifiedAlerts = 'notified_alert_ids_v1';

  // Fixed ids, so a notification of the same kind replaces its predecessor
  // instead of stacking.
  static const int _idOutbox = 1001;
  static const int _idAlerts = 1002;
  static const int _idSync = 1003;

  static const AndroidNotificationDetails _androidDose =
      AndroidNotificationDetails(
    'doses',
    'Vaccinations',
    channelDescription: 'Confirmation when a dose is recorded',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    // The worker is looking at the screen they just tapped; a full-screen
    // heads-up alert for their own action would be noise.
    ticker: 'Dose recorded',
  );

  static const AndroidNotificationDetails _androidOutbox =
      AndroidNotificationDetails(
    'outbox',
    'Waiting to sync',
    channelDescription: 'Work recorded on this phone that has not synced yet',
    importance: Importance.low,
    priority: Priority.low,
    ongoing: true,
    autoCancel: false,
    onlyAlertOnce: true,
  );

  static const AndroidNotificationDetails _androidAlert =
      AndroidNotificationDetails(
    'alerts',
    'Risk alerts',
    channelDescription:
        'Cold chain, climate disruption and overdue children',
    importance: Importance.high,
    priority: Priority.high,
    ticker: 'Risk alert',
  );

  Future<void> init([SharedPreferences? prefs]) async {
    // Assigned before the early return: a second init with a live handle must
    // replace a stale one, or the record of what has already been announced is
    // written somewhere nothing reads.
    if (prefs != null) _prefs = prefs;
    if (_ready) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: false,
          requestSoundPermission: true,
        ),
      );
      await _plugin.initialize(settings);

      // Android 13+ requires an explicit runtime grant. Declining is fine:
      // show() below simply becomes a no-op.
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();

      _ready = true;
    } catch (e) {
      // A device that will not give us notifications is not a broken app.
      debugPrint('NotificationService.init failed: $e');
    }
  }

  /// Told by the app's lifecycle observer.
  void setForeground(bool value) => _foreground = value;

  // ── Doses ──────────────────────────────────────────────────────────────────
  /// Confirms a dose was recorded for a child.
  ///
  /// Suppressed while the app is on screen: the sheet already shows a snackbar
  /// saying the same thing, and saying it twice trains a worker to ignore the
  /// channel that later has to carry a cold-chain warning.
  ///
  /// [pending] is true when the dose went to the offline outbox rather than the
  /// server, because "saved on this phone" and "recorded on the server" are
  /// different promises and a health worker should not have to guess which one
  /// they just got.
  Future<void> doseRecorded({
    required String childName,
    required String vaccine,
    bool pending = false,
    bool enabled = true,
  }) async {
    if (!enabled || _foreground) return;
    final body = pending
        ? '$vaccine for $childName saved on this phone. It will sync when you '
            'are back online.'
        : '$vaccine recorded for $childName.';
    await _show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: pending ? 'Dose saved offline' : 'Dose recorded',
      body: body,
      android: _androidDose,
    );
  }

  // ── Outbox ─────────────────────────────────────────────────────────────────
  /// One standing notification for everything waiting to sync.
  ///
  /// Replaced in place as the count changes and cancelled when the queue drains,
  /// so a day of offline work is a single line in the tray rather than thirty.
  Future<void> outboxPending(int count, {bool enabled = true}) async {
    if (!enabled || count <= 0) {
      await cancelOutbox();
      return;
    }
    await _show(
      id: _idOutbox,
      title: '$count ${count == 1 ? "record" : "records"} waiting to sync',
      body: 'Recorded on this phone. They upload when you are back online.',
      android: _androidOutbox,
    );
  }

  Future<void> cancelOutbox() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_idOutbox);
    } catch (_) {/* nothing to cancel */}
  }

  /// Confirms a sync finished. Only worth saying when the worker was not
  /// watching it happen.
  Future<void> syncCompleted(int records, {bool enabled = true}) async {
    if (!enabled || records <= 0 || _foreground) return;
    await _show(
      id: _idSync,
      title: 'Synced',
      body: '$records ${records == 1 ? "record" : "records"} uploaded.',
      android: _androidDose,
    );
  }

  // ── Alerts ─────────────────────────────────────────────────────────────────
  /// Notify about alerts the worker has not been told about before.
  ///
  /// Everything passed in is marked as notified whether or not it is shown, so
  /// an alert can never announce itself twice — not on the next refresh, not
  /// after a restart. Several new alerts collapse into one summary rather than
  /// filling the tray, which matters on a first sync that pulls fourteen.
  Future<void> alertsRaised(
    List<AlertModel> alerts, {
    bool enabled = true,
  }) async {
    final unseen = alerts
        .where((a) =>
            a.severity == AlertSeverity.critical && !_alreadyNotified(a.id))
        .toList();
    if (unseen.isEmpty) return;

    // Mark first: a failure to display must not cause a repeat next time.
    await _markNotified(unseen.map((a) => a.id));
    if (!enabled) return;

    if (unseen.length == 1) {
      final a = unseen.single;
      await _show(
        id: _idAlerts,
        title: a.title,
        body: a.action ?? a.body,
        android: _androidAlert,
      );
      return;
    }
    await _show(
      id: _idAlerts,
      title: '${unseen.length} alerts need attention',
      body: unseen.take(3).map((a) => a.title).join(' · '),
      android: _androidAlert,
    );
  }

  bool _alreadyNotified(String id) => _notifiedIds.contains(id);

  Set<String> get _notifiedIds {
    final raw = _prefs?.getString(_kNotifiedAlerts);
    if (raw == null || raw.isEmpty) return const {};
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return const {};
    }
  }

  Future<void> _markNotified(Iterable<String> ids) async {
    final prefs = _prefs;
    if (prefs == null) return;
    // Keep the most recent 200: enough that nothing repeats in practice,
    // bounded so the key cannot grow without limit.
    final all = <String>[..._notifiedIds, ...ids];
    final trimmed = all.length > 200 ? all.sublist(all.length - 200) : all;
    await prefs.setString(_kNotifiedAlerts, jsonEncode(trimmed));
  }

  // ── Plumbing ───────────────────────────────────────────────────────────────
  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required AndroidNotificationDetails android,
  }) async {
    if (!_ready) await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: android,
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('NotificationService.show failed: $e');
    }
  }
}
