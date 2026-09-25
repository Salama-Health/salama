import 'package:flutter_test/flutter_test.dart';

import 'package:salama/data/models/child_model.dart';
import 'package:salama/data/models/report_models.dart';
import 'package:salama/data/models/worker_model.dart';

/// Nothing the app displays should be hardcoded. These lock down the values
/// that used to be constants.
void main() {
  group('worker posting label', () {
    test('is built from the profile, not a constant', () {
      final w = WorkerModel.fromJson({
        'name': 'Nyakuma Deng',
        'facility': 'Leer PHCU',
        'county': 'Leer',
      });
      expect(w.postingLabel, 'Leer • Leer PHCU');
    });

    test('degrades to whichever half the server sent', () {
      expect(
        WorkerModel.fromJson({'facility': 'Leer PHCU'}).postingLabel,
        'Leer PHCU',
      );
      expect(WorkerModel.fromJson({}).postingLabel, isEmpty,
          reason: 'an empty profile must render no posting line at all');
    });

    test('carries support contacts when the server supplies them', () {
      final w = WorkerModel.fromJson({
        'supportEmail': 'help@programme.org',
        'supportPhone': '+211900000001',
      });
      expect(w.supportEmail, 'help@programme.org');
      expect(w.supportPhone, '+211900000001');
      expect(WorkerModel.fromJson({}).supportEmail, isNull,
          reason: 'no placeholder address may be invented');
    });
  });

  group('risk scoring is the server\'s job', () {
    test('a child with no score shows as awaiting one', () {
      final c = ChildModel.fromJson({
        'id': 'c1',
        'name': 'Deng Majok',
        'dueVaccines': ['BCG'],
      });
      expect(c.riskPending, isTrue);
      expect(c.priorityLabel, 'Awaiting score');
    });

    test('a scored child gets a real band', () {
      final c = ChildModel.fromJson({
        'id': 'c1',
        'name': 'Deng Majok',
        'riskScore': 0.93,
        'dueVaccines': ['BCG'],
      });
      expect(c.riskPending, isFalse);
      expect(c.riskBand, RiskBand.high);
      expect(c.priorityLabel, 'High priority');
    });

    test('an offline registration is flagged, never scored locally', () {
      final c = ChildModel.fromJson({
        'id': 'c1',
        'name': 'Deng Majok',
        'riskScore': 0.0,
        'pendingSync': true,
        'dueVaccines': ['BCG'],
      });
      expect(c.riskPending, isTrue);
      expect(c.priorityLabel, 'Awaiting score');
    });
  });

  group('report period', () {
    test('prefers the label the server sent', () {
      final s = ReportSummary.fromJson({
        'dosesThisMonth': 10,
        'period': 'August 2026',
      });
      expect(s.period, 'August 2026');
    });

    test('falls back to the device month only when absent', () {
      expect(ReportSummary.fromJson({}).period, isNull);
      expect(currentPeriodLabel(DateTime(2026, 9, 25)), 'September 2026');
    });
  });
}
