import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salama/core/api/api_exception.dart';
import 'package:salama/core/storage/offline_cache.dart';
import 'package:salama/core/utils/id_gen.dart';
import 'package:salama/core/utils/immunization_schedule.dart';
import 'package:salama/data/models/alert_model.dart';
import 'package:salama/data/models/child_model.dart';
import 'package:salama/data/models/facility_model.dart';
import 'package:salama/data/repositories/alerts_repository.dart';
import 'package:salama/presentation/providers/data_providers.dart';

ChildModel _child({
  String id = 'c1',
  String name = 'Nyawal Gatluak',
  String code = 'SSD-AAAA-BBBB',
  double risk = 0.95,
  String location = 'Rubkona',
  List<String> due = const ['Penta-2'],
  VisitStatus status = VisitStatus.toVisit,
  String? parent,
  String? phone,
}) {
  return ChildModel(
    id: id,
    code: code,
    name: name,
    gender: 'Female',
    ageLabel: '6 months',
    bornDate: 'Mar 14, 2025',
    riskScore: risk,
    distanceKm: 3.4,
    lastSeen: 'Last seen 4d ago',
    currentLocation: location,
    parentName: parent,
    parentPhone: phone,
    dueVaccines: due,
    status: status,
  );
}

void main() {
  group('OfflineCache', () {
    late OfflineCache cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      cache = OfflineCache(await SharedPreferences.getInstance());
    });

    test('serves the cached copy when the network is unreachable', () async {
      final fresh = await cache.readThrough<List<String>>(
        key: 'k',
        fetchJson: () async => ['a', 'b'],
        decode: (json) => (json as List).cast<String>(),
      );
      expect(fresh, ['a', 'b']);
      expect(cache.servingStale.value, isFalse);

      final stale = await cache.readThrough<List<String>>(
        key: 'k',
        fetchJson: () async => throw const ApiException('offline',
            isNetwork: true),
        decode: (json) => (json as List).cast<String>(),
      );
      expect(stale, ['a', 'b'], reason: 'must fall back to the saved copy');
      expect(cache.servingStale.value, isTrue);
    });

    test('rethrows a server rejection instead of masking it with cache',
        () async {
      await cache.write('k', ['cached']);

      expect(
        () => cache.readThrough<List<String>>(
          key: 'k',
          fetchJson: () async =>
              throw const ApiException('nope', statusCode: 401),
          decode: (json) => (json as List).cast<String>(),
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('rethrows when offline with nothing cached', () async {
      expect(
        () => cache.readThrough<List<String>>(
          key: 'empty',
          fetchJson: () async =>
              throw const ApiException('offline', isNetwork: true),
          decode: (json) => (json as List).cast<String>(),
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('clearAll removes data and timestamps', () async {
      await cache.write('k', {'a': 1});
      expect(cache.entryCount, 1);
      expect(cache.savedAt('k'), isNotNull);

      await cache.clearAll();
      expect(cache.entryCount, 0);
      expect(cache.read('k'), isNull);
      expect(cache.savedAt('k'), isNull);
    });
  });

  group('ImmunizationSchedule', () {
    test('a newborn is due only the birth doses', () {
      final due = ImmunizationSchedule.dueFor(DateTime.now());
      expect(due, ['BCG', 'OPV-0']);
    });

    test('a six-month-old is due everything through 14 weeks', () {
      final dob = DateTime.now().subtract(const Duration(days: 182));
      final due = ImmunizationSchedule.dueFor(dob);
      expect(due, contains('Penta-3'));
      expect(due, isNot(contains('Measles-1')),
          reason: 'measles is a 9-month dose');
    });

    test('next dose is reported with the weeks remaining', () {
      final dob = DateTime.now().subtract(const Duration(days: 7));
      final next = ImmunizationSchedule.nextFor(dob);
      expect(next?.vaccine, 'OPV-1');
      expect(next?.inWeeks, 5);
    });

    test('age labels read the way a worker would say them', () {
      final now = DateTime.now();
      expect(ImmunizationSchedule.ageLabel(now), 'newborn');
      expect(
          ImmunizationSchedule.ageLabel(now.add(const Duration(days: 2))),
          'not yet born');
      expect(
          ImmunizationSchedule.ageLabel(
              now.subtract(const Duration(days: 21))),
          '3 weeks');
      expect(
          ImmunizationSchedule.ageLabel(
              now.subtract(const Duration(days: 210))),
          '7 months');
    });
  });

  group('IdGen', () {
    test('child codes are readable and free of ambiguous glyphs', () {
      for (var i = 0; i < 200; i++) {
        final code = IdGen.childCode();
        expect(RegExp(r'^SSD-[A-Z2-9]{4}-[A-Z2-9]{4}$').hasMatch(code), isTrue,
            reason: code);
        expect(code.contains('0'), isFalse);
        expect(code.contains('O'), isFalse);
        expect(code.contains('1'), isFalse);
        expect(code.contains('I'), isFalse);
      }
    });

    test('uuids are unique and v4 shaped', () {
      final ids = List.generate(500, (_) => IdGen.uuid()).toSet();
      expect(ids.length, 500);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
            .hasMatch(ids.first),
        isTrue,
      );
    });

    test('qr payload carries the code', () {
      expect(IdGen.qrPayload('SSD-AAAA-BBBB'), 'SALAMA:CHILD:SSD-AAAA-BBBB');
    });
  });

  group('searchChildren', () {
    final all = [
      _child(id: '1', name: 'Nyawal Gatluak', location: 'Rubkona'),
      _child(
          id: '2',
          name: 'Deng Majok',
          code: 'SSD-ZZZZ-9999',
          location: 'Bentiu',
          parent: 'Achol Majok',
          phone: '+211920555111'),
    ];

    test('empty query returns everything', () {
      expect(searchChildren(all, '  ').length, 2);
    });

    test('matches on name, village, code and caregiver', () {
      expect(searchChildren(all, 'nyawal').single.id, '1');
      expect(searchChildren(all, 'bentiu').single.id, '2');
      expect(searchChildren(all, 'zzzz').single.id, '2');
      expect(searchChildren(all, 'achol').single.id, '2');
      expect(searchChildren(all, '555111').single.id, '2');
    });
  });

  group('derived alerts', () {
    final facility = FacilityModel(
      id: 'f1',
      name: 'Bentiu PHCC',
      county: 'Rubkona',
      children: 412,
      cdiScore: 0.82,
      risk: FacilityRisk.danger,
      hazard: 'Flooding',
      daysToWindow: 6,
      hazardDetail: 'Flooding is forecast to cut the road.',
      hazardTimeframe: '10-14 days',
      highPriority: 38,
      dueSoon: 91,
      recentlyVisited: 26,
      assigned: true,
    );

    test('a facility in danger raises a critical alert', () {
      final alerts = AlertsRepository.derive(
        facilities: [facility],
        children: const [],
        pendingRecords: 0,
      );
      final first = alerts.first;
      expect(first.kind, AlertKind.climate,
          reason: 'flooding is a climate hazard, not a cold-chain one');
      expect(first.severity, AlertSeverity.critical);
      expect(first.facilityId, 'f1');
      expect(first.timingLabel, 'Opens in 6 days');
    });

    test('cold chain is read from the hazard, not from a score threshold', () {
      // The live index clusters low — a facility the server flags as
      // "Heatwave cold chain risk" scores 0.1962, under any cut-off worth
      // picking. The hazard text is the reliable signal.
      final coldChain = FacilityModel(
        id: 'f2',
        name: 'Walgak PHCC',
        county: 'Akobo, Jonglei',
        children: 14,
        cdiScore: 0.1962,
        risk: FacilityRisk.warning,
        hazard: 'Heatwave cold chain risk',
        daysToWindow: 2,
        hazardDetail: 'Cold-chain failure risk (P=0.32).',
        hazardTimeframe: '3 days',
        highPriority: 2,
        dueSoon: 5,
        recentlyVisited: 1,
      );

      final alerts = AlertsRepository.derive(
        facilities: [coldChain],
        children: const [],
        pendingRecords: 0,
      );
      expect(alerts.single.kind, AlertKind.coldChain);
    });

    test('overdue children and the sync queue both surface', () {
      final alerts = AlertsRepository.derive(
        facilities: const [],
        children: [_child(risk: 0.95)],
        pendingRecords: 3,
      );
      expect(alerts.any((a) => a.kind == AlertKind.overdueChild), isTrue);
      final sync = alerts.firstWhere((a) => a.kind == AlertKind.sync);
      expect(sync.title, '3 records waiting to sync');
    });

    test('already-visited children raise nothing', () {
      final alerts = AlertsRepository.derive(
        facilities: const [],
        children: [_child(status: VisitStatus.visited)],
        pendingRecords: 0,
      );
      expect(alerts, isEmpty);
    });

    test('critical alerts sort above warnings', () {
      final alerts = AlertsRepository.derive(
        facilities: [facility],
        children: [_child(risk: 0.82)], // medium band -> warning
        pendingRecords: 1,
      );
      expect(alerts.first.severity, AlertSeverity.critical);
      expect(alerts.last.severity, AlertSeverity.info);
    });
  });
}
