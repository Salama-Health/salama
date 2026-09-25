import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salama/core/api/api_exception.dart';
import 'package:salama/core/services/connectivity_service.dart';
import 'package:salama/data/repositories/outbox_repository.dart';

/// The outbox is the reason nothing a health worker records can be lost, so its
/// behaviour is pinned down here rather than left to manual testing in the field.
void main() {
  late SharedPreferences prefs;
  late OutboxRepository outbox;

  Future<void> build({Map<String, Object> seed = const {}}) async {
    SharedPreferences.setMockInitialValues(seed);
    prefs = await SharedPreferences.getInstance();
    outbox = OutboxRepository(prefs);
  }

  setUp(() async {
    ConnectivityService.instance.isOnline.value = true;
    await build();
  });

  tearDown(() => ConnectivityService.instance.isOnline.value = true);

  group('submit', () {
    test('sends and returns the server value when online', () async {
      final result = await outbox.submit<String>(
        kind: OutboxKind.vaccination,
        payload: {'vaccine': 'BCG'},
        request: () async => 'saved',
      );

      expect(result.synced, isTrue);
      expect(result.value, 'saved');
      expect(outbox.pendingCount, 0, reason: 'nothing to queue on success');
    });

    test('queues without attempting the request when offline', () async {
      ConnectivityService.instance.isOnline.value = false;
      var attempted = false;

      final result = await outbox.submit<String>(
        kind: OutboxKind.child,
        payload: {'name': 'Nyawal'},
        request: () async {
          attempted = true;
          return 'saved';
        },
      );

      expect(attempted, isFalse, reason: 'no point dialling with no signal');
      expect(result.queued, isTrue);
      expect(result.value, isNull);
      expect(outbox.pendingCount, 1);
    });

    test('queues when the connection drops mid-request', () async {
      final result = await outbox.submit<String>(
        kind: OutboxKind.vaccination,
        payload: {'vaccine': 'Penta-1'},
        request: () async =>
            throw const ApiException('unreachable', isNetwork: true),
      );

      expect(result.queued, isTrue);
      expect(outbox.pendingCount, 1,
          reason: 'a dose already given must survive a dropped connection');
    });

    test('queues when the endpoint is not deployed yet', () async {
      // POST /visits does not exist on the server yet. A 404 is not the write
      // being refused, and the same payload reaches the server in the next
      // /sync/upload batch — so it must be kept, not thrown away.
      for (final code in [404, 405]) {
        await build();
        final result = await outbox.submit<String>(
          kind: OutboxKind.visit,
          payload: {'status': 'visited'},
          request: () async =>
              throw ApiException('no route', statusCode: code),
        );
        expect(result.queued, isTrue, reason: 'status $code');
        expect(outbox.pendingCount, 1, reason: 'status $code');
      }
    });

    test('rethrows a server rejection and queues nothing', () async {
      await expectLater(
        outbox.submit<String>(
          kind: OutboxKind.child,
          payload: {'name': 'Nyawal'},
          request: () async =>
              throw const ApiException('duplicate code', statusCode: 409),
        ),
        throwsA(isA<ApiException>()),
      );

      expect(outbox.pendingCount, 0,
          reason: 'a rejected write must not be retried forever');
    });
  });

  group('queue contents', () {
    test('counts and groups by kind', () async {
      await outbox.add(OutboxKind.vaccination, {'vaccine': 'BCG'});
      await outbox.add(OutboxKind.vaccination, {'vaccine': 'OPV-0'});
      await outbox.add(OutboxKind.child, {'name': 'Nyawal'});
      await outbox.add(OutboxKind.visit, {'status': 'visited'});

      expect(outbox.pendingCount, 4);
      expect(outbox.pendingByKind[OutboxKind.vaccination], 2);
      expect(outbox.pendingByKind[OutboxKind.child], 1);
      expect(outbox.pendingByKind[OutboxKind.visit], 1);
    });

    test('preserves the order the worker performed the writes in', () async {
      await outbox.add(OutboxKind.child, {'name': 'first'});
      await outbox.add(OutboxKind.child, {'name': 'second'});

      final payloads = outbox.payloadsFor(OutboxKind.child);
      expect(payloads.map((p) => p['name']), ['first', 'second']);
    });

    test('wire keys match the sync upload contract', () {
      expect(OutboxKind.vaccination.wireKey, 'vaccinations');
      expect(OutboxKind.child.wireKey, 'newChildren');
      expect(OutboxKind.visit.wireKey, 'visits');
    });

    test('survives a rebuild from disk', () async {
      await outbox.add(OutboxKind.visit, {'status': 'skipped'});

      final reopened = OutboxRepository(prefs);
      expect(reopened.pendingCount, 1);
      expect(reopened.payloadsFor(OutboxKind.visit).single['status'], 'skipped');
    });

    test('recordAttempt increments without dropping anything', () async {
      await outbox.add(OutboxKind.visit, {'status': 'visited'});
      await outbox.recordAttempt();
      await outbox.recordAttempt();

      expect(outbox.pendingCount, 1);
      expect(outbox.entries.single.attempts, 2);
    });

    test('clear empties the queue', () async {
      await outbox.add(OutboxKind.child, {'name': 'Nyawal'});
      await outbox.clear();
      expect(outbox.pendingCount, 0);
    });
  });

  group('migration', () {
    test('folds pre-outbox queues in rather than orphaning them', () async {
      await build(seed: {
        'queue_vaccinations': jsonEncode([
          {'vaccine': 'BCG'}
        ]),
        'queue_children': jsonEncode([
          {'name': 'Nyawal'}
        ]),
        'queue_visits': jsonEncode([
          {'status': 'visited'},
          {'status': 'skipped'},
        ]),
      });

      expect(outbox.pendingCount, 4);
      expect(outbox.pendingByKind[OutboxKind.visit], 2);
      expect(prefs.containsKey('queue_vaccinations'), isFalse,
          reason: 'legacy keys are consumed, not left to double-upload');
    });

    test('an unreadable legacy payload does not block startup', () async {
      await build(seed: {'queue_children': 'not json at all'});
      expect(outbox.pendingCount, 0);
    });
  });
}
