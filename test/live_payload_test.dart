import 'package:flutter_test/flutter_test.dart';

import 'package:salama/data/models/alert_model.dart';
import 'package:salama/data/models/child_model.dart';
import 'package:salama/data/models/facility_model.dart';
import 'package:salama/data/models/worker_model.dart';

/// Parsed from responses captured off the live API on 25 Sep 2026, so a change
/// in what the server actually sends fails here rather than in the field.
void main() {
  test('worker, as /auth/login returns it', () {
    final w = WorkerModel.fromJson({
      'id': 'b0d3…',
      'workerId': 'CHW-001',
      'name': 'Nyabuoy Gatwech',
      'role': 'CHW',
      'facility': 'Nhialdiu PHCU',
      'facilityId': 'f1',
      'county': 'Rubkona',
      'phone': '+211920000001',
      'facilitiesCount': 1,
      'active': true,
    });
    expect(w.workerId, 'CHW-001');
    expect(w.postingLabel, 'Rubkona • Nhialdiu PHCU');
    expect(w.supportEmail, isNull, reason: 'not served yet; no placeholder');
  });

  test('child, as /children returns it', () {
    final c = ChildModel.fromJson({
      'id': '601a92c0-4ac2-422a-8a17-ae6c24158235',
      'qrCode': 'C-00001',
      'name': 'Nyaluak Nhial',
      'gender': 'F',
      'bornDate': '2025-02-14',
      'riskScore': 0.0817,
      'riskBand': 'Medium',
      'riskPending': false,
      'distanceKm': 3.4,
      'lastSeen': null,
      'currentLocation': 'Nhialdiu',
      'dueVaccines': ['OPV-0', 'Measles-1', 'Yellow Fever', 'Measles-2'],
      'status': 'toVisit',
      'history': null,
    });

    expect(c.code, 'C-00001');
    expect(c.riskBand, RiskBand.medium, reason: 'server band is authoritative');
    expect(c.priorityLabel, 'Elevated');
    expect(c.riskPending, isFalse);
    expect(c.lastSeen, 'Never contacted');
    expect(c.history, isEmpty, reason: 'the list omits history; detail carries it');
  });

  test('a 0.0 score from the live set is Low, not unscored', () {
    // Nine of the eighty children score exactly zero: no vaccination debt.
    final c = ChildModel.fromJson({
      'id': 'x',
      'name': 'Test',
      'riskScore': 0.0,
      'riskBand': 'Low',
    });
    expect(c.riskPending, isFalse);
    expect(c.priorityLabel, 'Routine');
  });

  test('facility, as /facilities returns it', () {
    final f = FacilityModel.fromJson({
      'id': 'fac-1',
      'name': 'Walgak PHCC',
      'county': 'Akobo',
      'state': 'Jonglei',
      'children': 14,
      'cdiScore': 0.1962,
      'risk': 'Low',
      'hazard': 'Heatwave cold chain risk',
      'daysToWindow': 0,
      'hazardDetail':
          'Cold-chain failure risk (P=0.32) — temperatures exceeding the 8°C threshold.',
      'hazardTimeframe': 'No disruption forecast',
      'highPriority': 2,
      'dueSoon': 5,
      'recentlyVisited': 3,
      'assigned': false,
      'latitude': 9.04,
      'longitude': 29.67,
    });

    expect(f.county, 'Akobo, Jonglei');
    expect(f.risk, FacilityRisk.ok, reason: 'the server band decides the colour');
    expect(f.cdiFromRadar, isFalse);
    expect(f.cdiSourceLabel, isEmpty,
        reason: 'an unreported field must not be shown as a seasonal estimate');
  });

  test('alert, as /devices/alerts returns it', () {
    final a = AlertModel.fromJson({
      'id': 'overdue-6b0017ed',
      'type': 'overdue',
      'title': 'Nyakuoth Pal is high risk',
      'body': '13 overdue dose(s). Prioritise this visit.',
      'facilityId': null,
      'childId': '27bf0658-bb2a-412a-9e5d-15cb345628f7',
      'severity': 'danger',
      'createdAt': '2026-09-25T06:00:00Z',
    });

    expect(a.kind, AlertKind.overdueChild, reason: 'server says "type", not "kind"');
    expect(a.severity, AlertSeverity.critical,
        reason: '"danger" is critical — it was rendering as blue Info');
    expect(a.childId, isNotNull);
  });

  test('a hazard alert about the cold chain is filed as cold chain', () {
    final a = AlertModel.fromJson({
      'id': 'hazard-1',
      'type': 'hazard',
      'title': 'Heatwave cold chain risk — Walgak PHCC',
      'body': 'Temperatures exceeding the 8°C threshold.',
      'severity': 'danger',
    });
    expect(a.kind, AlertKind.coldChain);
  });

  test('history entry, as /vaccinations returns it', () {
    final r = ChildModel.fromJson({
      'id': 'x',
      'name': 'Test',
      'riskScore': 0.1,
      'history': [
        {
          'id': 'a64bd566',
          'childId': 'x',
          'vaccine': 'Penta-3',
          'dose': '3',
          'date': '2025-06-03T00:00:00',
          'status': 'given',
          'batch': 'PT2506A',
        }
      ],
    }).history.single;

    expect(r.vaccine, 'Penta-3');
    expect(r.dose, '3');
    expect(r.batch, 'PT2506A');
    expect(r.date, 'Jun 03, 2025');
  });
}
