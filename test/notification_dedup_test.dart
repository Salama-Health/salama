import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salama/core/services/notification_service.dart';
import 'package:salama/data/models/alert_model.dart';

AlertModel alert(String id, {AlertSeverity severity = AlertSeverity.critical}) =>
    AlertModel(
      id: id,
      kind: AlertKind.overdueChild,
      severity: severity,
      title: 'Nyakuoth Pal is high risk',
      body: '13 overdue doses.',
    );

/// A notification must never repeat what the screen already said, and an alert
/// must never announce itself twice. Both rules are enforced without a platform
/// channel, so they can be tested.
///
/// `show` itself is a no-op here (the plugin is never initialised), which is the
/// point: what is asserted is the bookkeeping that decides whether a
/// notification would be sent at all.
void main() {
  late NotificationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = NotificationService.instance;
    await service.init(await SharedPreferences.getInstance());
    service.setForeground(true);
  });

  test('an alert is recorded as announced the first time only', () async {
    final a = [alert('overdue-1'), alert('overdue-2')];

    await service.alertsRaised(a);
    final afterFirst =
        (await SharedPreferences.getInstance()).getString('notified_alert_ids_v1');
    expect(afterFirst, contains('overdue-1'));
    expect(afterFirst, contains('overdue-2'));

    // The same alerts arriving again on the next refresh add nothing.
    await service.alertsRaised(a);
    final afterSecond =
        (await SharedPreferences.getInstance()).getString('notified_alert_ids_v1');
    expect(afterSecond, afterFirst,
        reason: 'a refresh must not re-announce what was already sent');
  });

  test('only critical alerts are announced', () async {
    await service.alertsRaised([
      alert('warn-1', severity: AlertSeverity.warning),
      alert('info-1', severity: AlertSeverity.info),
    ]);
    final stored =
        (await SharedPreferences.getInstance()).getString('notified_alert_ids_v1');
    expect(stored, isNull,
        reason: 'a warning belongs in the list, not in the tray');
  });

  test('the record survives a restart', () async {
    await service.alertsRaised([alert('overdue-1')]);

    // A fresh prefs handle stands in for a relaunch.
    await service.init(await SharedPreferences.getInstance());
    await service.alertsRaised([alert('overdue-1')]);

    final stored = (await SharedPreferences.getInstance())
        .getString('notified_alert_ids_v1')!;
    expect('overdue-1'.allMatches(stored).length, 1,
        reason: 'restarting the app must not re-announce old alerts');
  });

  test('the announced list stays bounded', () async {
    for (var i = 0; i < 250; i++) {
      await service.alertsRaised([alert('a$i')]);
    }
    final stored = (await SharedPreferences.getInstance())
        .getString('notified_alert_ids_v1')!;
    expect(','.allMatches(stored).length + 1, lessThanOrEqualTo(200));
    expect(stored, contains('a249'), reason: 'the newest are kept');
  });

  test('disabled alerts still mark as seen, so re-enabling is not a flood',
      () async {
    await service.alertsRaised([alert('overdue-1')], enabled: false);
    final stored =
        (await SharedPreferences.getInstance()).getString('notified_alert_ids_v1');
    expect(stored, contains('overdue-1'));
  });

  test('foreground and background are tracked for dose confirmations',
      () async {
    // No platform channel in a test, so these must simply not throw: the
    // suppression decision is made before any plugin call.
    service.setForeground(true);
    await service.doseRecorded(childName: 'Nyaluak', vaccine: 'BCG');
    service.setForeground(false);
    await service.doseRecorded(childName: 'Nyaluak', vaccine: 'BCG');
    await service.outboxPending(0);
    await service.outboxPending(3);
    await service.syncCompleted(2);
  });
}
