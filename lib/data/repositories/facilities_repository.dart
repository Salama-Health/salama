import '../../core/api/api_client.dart';
import '../../core/storage/offline_cache.dart';
import '../models/facility_model.dart';

class FacilitiesRepository {
  FacilitiesRepository(this._api, this._cache);
  final ApiClient _api;
  final OfflineCache _cache;

  /// Facility risk scores. Cached — the CDI figures a worker plans around are
  /// forecasts, so yesterday's copy is still worth showing when offline.
  Future<List<FacilityModel>> list({bool assignedOnly = false}) {
    return _cache.readThrough<List<FacilityModel>>(
      key: OfflineCache.kFacilities,
      fetchJson: () async => (await _api.get('/facilities',
              query: assignedOnly ? {'assignedOnly': true} : null))
          .data,
      decode: (json) => (json as List)
          .map((e) => FacilityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<FacilityModel> detail(String id) async {
    final resp = await _api.get('/facilities/$id');
    return FacilityModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
