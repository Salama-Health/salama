import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/activity_model.dart';
import '../../data/models/alert_model.dart';
import '../../data/models/child_model.dart';
import '../../data/models/facility_model.dart';
import '../../data/models/report_models.dart';
import '../../data/models/route_models.dart';
import '../../data/models/sync_models.dart';
import '../../data/models/vaccination_record.dart';
import '../../data/repositories/alerts_repository.dart';
import '../../data/repositories/settings_repository.dart';
import 'core_providers.dart';

/// All children assigned to the signed-in worker (enriched with risk scores).
final childrenProvider = FutureProvider<List<ChildModel>>((ref) async {
  return ref.watch(childrenRepositoryProvider).list();
});

/// Single child detail (with vaccination history), keyed by id.
final childDetailProvider =
    FutureProvider.family<ChildModel, String>((ref, id) async {
  return ref.watch(childrenRepositoryProvider).detail(id);
});

/// A child's dose history from the server. The child object already carries a
/// history for the list view; this fetches the authoritative record when the
/// timeline is actually opened.
final vaccinationHistoryProvider =
    FutureProvider.family<List<VaccinationRecord>, String>((ref, childId) async {
  return ref.watch(vaccinationsRepositoryProvider).history(childId);
});

/// Facilities visible to the worker, sorted by CDI (highest first).
final facilitiesProvider = FutureProvider<List<FacilityModel>>((ref) async {
  final list = await ref.watch(facilitiesRepositoryProvider).list();
  list.sort((a, b) => b.cdiScore.compareTo(a.cdiScore));
  return list;
});

/// One facility, fetched fresh when its detail sheet opens.
final facilityDetailProvider =
    FutureProvider.family<FacilityModel, String>((ref, id) async {
  return ref.watch(facilitiesRepositoryProvider).detail(id);
});

/// Recent activity feed for the home screen.
final activityProvider = FutureProvider<List<ActivityModel>>((ref) async {
  return ref.watch(activityRepositoryProvider).recent(limit: 50);
});

/// Reports bundle (summary + weekly doses + coverage).
final reportsProvider = FutureProvider<ReportsBundle>((ref) async {
  return ref.watch(reportsRepositoryProvider).bundle();
});

/// Server-optimised visit route.
final routeProvider = FutureProvider<OptimizedRoute>((ref) async {
  return ref.watch(routesRepositoryProvider).optimized();
});

/// Sync status (server last-sync + local pending count).
final syncStatusProvider = FutureProvider<SyncStatus>((ref) async {
  return ref.watch(syncRepositoryProvider).status();
});

// ── Alerts ───────────────────────────────────────────────────────────────────
/// Alerts from the server when it serves them, otherwise derived on-device from
/// facility risk, the priority list and the offline queue.
final alertsProvider = FutureProvider<List<AlertModel>>((ref) async {
  final repo = ref.watch(alertsRepositoryProvider);

  final server = await repo.fetchServer();
  if (server != null && server.isNotEmpty) return server;

  // Derive. Each source is optional — an alerts screen should still show what
  // it can when one of the underlying lists is unavailable.
  var facilities = const <FacilityModel>[];
  var children = const <ChildModel>[];
  try {
    facilities = await ref.watch(facilitiesProvider.future);
  } catch (_) {/* leave empty */}
  try {
    children = await ref.watch(childrenProvider.future);
  } catch (_) {/* leave empty */}

  return AlertsRepository.derive(
    facilities: facilities,
    children: children,
    pendingRecords: ref.watch(syncRepositoryProvider).pendingCount,
  );
});

/// Bumped whenever alerts are marked read, so the badge recomputes.
final alertReadTickProvider = StateProvider<int>((ref) => 0);

/// Unread alert count — the number on the bell.
final unreadAlertCountProvider = Provider<int>((ref) {
  ref.watch(alertReadTickProvider);
  final alerts = ref.watch(alertsProvider).valueOrNull ?? const <AlertModel>[];
  return ref.watch(alertsRepositoryProvider).unreadCount(alerts);
});

// ── Search ───────────────────────────────────────────────────────────────────
/// Free-text search across the caseload (name, code, village, caregiver).
final childSearchProvider = StateProvider<String>((ref) => '');

/// Filter a caseload by the current search query.
List<ChildModel> searchChildren(List<ChildModel> all, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return all;
  return all.where((c) {
    return c.name.toLowerCase().contains(q) ||
        c.code.toLowerCase().contains(q) ||
        c.currentLocation.toLowerCase().contains(q) ||
        (c.parentName?.toLowerCase().contains(q) ?? false) ||
        (c.parentPhone?.contains(q) ?? false);
  }).toList();
}

// ── Settings ─────────────────────────────────────────────────────────────────
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._repo) : super(_repo.load());
  final SettingsRepository _repo;

  Future<void> update(AppSettings next) async {
    state = next;
    await _repo.save(next);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});
