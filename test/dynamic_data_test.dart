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

    test('a score of exactly zero is a real result, not an unscored child', () {
      // The index is multiplicative: no vaccination debt scores 0, which means
      // fully up to date. Treating it as unscored hid the least urgent children
      // behind an "Awaiting score" badge.
      final c = ChildModel.fromJson({
        'id': 'c1',
        'name': 'Deng Majok',
        'riskScore': 0.0,
      });
      expect(c.riskPending, isFalse);
      expect(c.riskBand, RiskBand.low);
      expect(c.priorityLabel, 'Routine');
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

  group('risk bands are fitted to the live score distribution', () {
    ChildModel scored(double score) => ChildModel.fromJson({
          'id': 'c1',
          'name': 'Deng Majok',
          'riskScore': score,
        });

    test('cut-offs match the server', () {
      expect(ChildModel.highCut, 0.193);
      expect(ChildModel.mediumCut, 0.068);
      expect(ChildModel.watchCut, 0.022);
    });

    test('bands split at the fitted thresholds', () {
      expect(scored(0.42).riskBand, RiskBand.high);
      expect(scored(0.193).riskBand, RiskBand.high);
      expect(scored(0.192).riskBand, RiskBand.medium);
      expect(scored(0.068).riskBand, RiskBand.medium);
      expect(scored(0.067).riskBand, RiskBand.watch);
      expect(scored(0.022).riskBand, RiskBand.watch);
      expect(scored(0.021).riskBand, RiskBand.low);
    });

    test('a child with real overdue doses is no longer filed as routine', () {
      // The regression the old 0.90/0.80/0.72 cut-offs caused: 79 of 80
      // children landed in routine, including one with six doses outstanding.
      final overdue = ChildModel.fromJson({
        'id': 'c1',
        'name': 'Nyawal Gatluak',
        'riskScore': 0.21,
        'dueVaccines': ['BCG', 'OPV-0', 'Penta-1', 'PCV-1', 'Rota-1', 'OPV-1'],
      });
      expect(overdue.riskBand, RiskBand.high);
    });

    test('the server band wins over the local calculation', () {
      final c = ChildModel.fromJson({
        'id': 'c1',
        'name': 'Deng Majok',
        'riskScore': 0.001,
        'riskBand': 'High',
      });
      expect(c.riskBand, RiskBand.high,
          reason: 'the server holds the live distribution');
    });

    test('an unrecognised band falls back to the local cut-offs', () {
      final c = ChildModel.fromJson({
        'id': 'c1',
        'name': 'Deng Majok',
        'riskScore': 0.5,
        'riskBand': 'Elevated',
      });
      expect(c.riskBand, RiskBand.high);
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
