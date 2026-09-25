import '../../core/api/api_client.dart';
import '../../core/storage/offline_cache.dart';
import '../models/route_models.dart';

class RoutesRepository {
  RoutesRepository(this._api, this._cache);
  final ApiClient _api;
  final OfflineCache _cache;

  /// The optimized visit order. Cached because a route is most needed exactly
  /// where the signal runs out — on the way to the next village.
  Future<OptimizedRoute> optimized() {
    return _cache.readThrough<OptimizedRoute>(
      key: OfflineCache.kRoute,
      fetchJson: () async => (await _api.get('/routes/optimized')).data,
      decode: (json) => OptimizedRoute.fromJson(json as Map<String, dynamic>),
    );
  }
}
