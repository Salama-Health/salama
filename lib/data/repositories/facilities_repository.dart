import '../../core/api/api_client.dart';
import '../models/facility_model.dart';

class FacilitiesRepository {
  FacilitiesRepository(this._api);
  final ApiClient _api;

  Future<List<FacilityModel>> list({bool assignedOnly = false}) async {
    final resp = await _api.get('/facilities',
        query: assignedOnly ? {'assignedOnly': true} : null);
    return (resp.data as List)
        .map((e) => FacilityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FacilityModel> detail(String id) async {
    final resp = await _api.get('/facilities/$id');
    return FacilityModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
