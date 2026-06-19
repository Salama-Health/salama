import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/activity_model.dart';
import '../../data/models/child_model.dart';
import '../../data/models/facility_model.dart';
import '../../data/models/report_models.dart';
import '../../data/models/route_models.dart';
import '../../data/models/sync_models.dart';
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

/// Facilities visible to the worker, sorted by CDI (highest first).
final facilitiesProvider = FutureProvider<List<FacilityModel>>((ref) async {
  final list = await ref.watch(facilitiesRepositoryProvider).list();
  list.sort((a, b) => b.cdiScore.compareTo(a.cdiScore));
  return list;
});

/// Recent activity feed for the home screen.
final activityProvider = FutureProvider<List<ActivityModel>>((ref) async {
  return ref.watch(activityRepositoryProvider).recent(limit: 10);
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
