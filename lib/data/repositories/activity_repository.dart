import '../../core/api/api_client.dart';
import '../models/activity_model.dart';

class ActivityRepository {
  ActivityRepository(this._api);
  final ApiClient _api;

  Future<List<ActivityModel>> recent({int limit = 10}) async {
    final resp = await _api.get('/activity', query: {'limit': limit});
    return (resp.data as List)
        .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
