import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// On-device notifications.
///
/// Local, not push. A recorded dose is already confirmed by the call we just
/// made, so there is nothing to wait for a server to tell us - and this keeps
/// working when the dose goes to the offline outbox instead, which is exactly
/// when a worker most needs the confirmation.
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

  Future<void> init() async {
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

  /// Confirms a dose was recorded for a child.
  ///
  /// [pending] is true when the dose went to the offline outbox rather than the
  /// server, because "saved on this phone" and "recorded on the server" are
  /// different promises and a health worker should not have to guess which one
  /// they just got.
  Future<void> doseRecorded({
    required String childName,
    required String vaccine,
    bool pending = false,
  }) async {
    final body = pending
        ? '$vaccine for $childName saved on this phone. It will sync when you '
            'are back online.'
        : '$vaccine recorded for $childName.';
    await _show(
      title: pending ? 'Dose saved offline' : 'Dose recorded',
      body: body,
    );
  }

  Future<void> _show({required String title, required String body}) async {
    if (!_ready) await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        // Distinct id per notification so a second dose does not silently
        // replace the confirmation for the first.
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        const NotificationDetails(
          android: _androidDose,
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('NotificationService.show failed: $e');
    }
  }
}
