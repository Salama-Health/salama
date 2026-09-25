import '../../core/api/api_client.dart';
import '../../core/api/api_routes.dart';
import '../../core/storage/offline_cache.dart';
import '../models/activity_model.dart';

class ActivityRepository {
  ActivityRepository(this._api, this._cache);
  final ApiClient _api;
  final OfflineCache _cache;

  Future<List<ActivityModel>> recent({int limit = 10}) {
    return _cache.readThrough<List<ActivityModel>>(
      key: OfflineCache.kActivity,
      fetchJson: () async =>
          (await _api.get(ApiRoutes.activity, query: {'limit': limit})).data,
      decode: (json) => (json as List)
          .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
