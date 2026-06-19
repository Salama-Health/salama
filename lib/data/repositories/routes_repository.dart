import '../../core/api/api_client.dart';
import '../models/route_models.dart';

class RoutesRepository {
  RoutesRepository(this._api);
  final ApiClient _api;

  Future<OptimizedRoute> optimized() async {
    final resp = await _api.get('/routes/optimized');
    return OptimizedRoute.fromJson(resp.data as Map<String, dynamic>);
  }
}
