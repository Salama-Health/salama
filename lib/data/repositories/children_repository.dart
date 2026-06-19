import '../../core/api/api_client.dart';
import '../models/child_model.dart';

class ChildrenRepository {
  ChildrenRepository(this._api);
  final ApiClient _api;

  Future<List<ChildModel>> list({String? status}) async {
    final resp = await _api.get('/children',
        query: status != null ? {'status': status} : null);
    return (resp.data as List)
        .map((e) => ChildModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChildModel> detail(String id) async {
    final resp = await _api.get('/children/$id');
    return ChildModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ChildModel> lookupByQr(String qr) async {
    final resp = await _api.get('/children/lookup', query: {'qr': qr});
    return ChildModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ChildModel> create(Map<String, dynamic> body) async {
    final resp = await _api.post('/children', data: body);
    return ChildModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ChildModel> update(String id, Map<String, dynamic> body) async {
    final resp = await _api.patch('/children/$id', data: body);
    return ChildModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
