import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/offline_cache.dart';
import '../../core/storage/token_storage.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/repositories/alerts_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/children_repository.dart';
import '../../data/repositories/facilities_repository.dart';
import '../../data/repositories/reports_repository.dart';
import '../../data/repositories/routes_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/repositories/vaccinations_repository.dart';
import 'auth_provider.dart';

/// Overridden in main() once SharedPreferences is initialised.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Read-through cache that keeps the app usable without a connection.
final offlineCacheProvider =
    Provider<OfflineCache>((ref) => OfflineCache(ref.watch(sharedPrefsProvider)));

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(
    storage: storage,
    onAuthFailure: () async {
      // Refresh was rejected → drop session so the router sends us to login.
      await ref.read(authProvider.notifier).forceLogout();
    },
  );
});

// ── Repositories ─────────────────────────────────────────────────────────────
final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(offlineCacheProvider),
  ),
);

final childrenRepositoryProvider = Provider((ref) => ChildrenRepository(
      ref.watch(apiClientProvider),
      ref.watch(offlineCacheProvider),
    ));

final facilitiesRepositoryProvider = Provider((ref) => FacilitiesRepository(
      ref.watch(apiClientProvider),
      ref.watch(offlineCacheProvider),
    ));

final vaccinationsRepositoryProvider =
    Provider((ref) => VaccinationsRepository(ref.watch(apiClientProvider)));

final activityRepositoryProvider = Provider((ref) => ActivityRepository(
      ref.watch(apiClientProvider),
      ref.watch(offlineCacheProvider),
    ));

final reportsRepositoryProvider = Provider((ref) => ReportsRepository(
      ref.watch(apiClientProvider),
      ref.watch(offlineCacheProvider),
    ));

final routesRepositoryProvider = Provider((ref) => RoutesRepository(
      ref.watch(apiClientProvider),
      ref.watch(offlineCacheProvider),
    ));

final syncRepositoryProvider = Provider(
  (ref) => SyncRepository(
    ref.watch(apiClientProvider),
    ref.watch(sharedPrefsProvider),
    ref.watch(offlineCacheProvider),
  ),
);

final alertsRepositoryProvider = Provider(
  (ref) => AlertsRepository(
    ref.watch(apiClientProvider),
    ref.watch(sharedPrefsProvider),
    ref.watch(offlineCacheProvider),
  ),
);

final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(sharedPrefsProvider)));
