import '../../core/api/api_client.dart';
import '../models/vaccination_record.dart';

class VaccinationsRepository {
  VaccinationsRepository(this._api);
  final ApiClient _api;

  Future<List<VaccinationRecord>> history(String childId) async {
    final resp = await _api.get('/vaccinations', query: {'childId': childId});
    return (resp.data as List)
        .map((e) => VaccinationRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Record a dose. Returns the created record.
  Future<VaccinationRecord> record({
    required String childId,
    required String vaccine,
    String? dose,
    String? batchNumber,
    String status = 'given',
    String? clientUuid,
  }) async {
    final resp = await _api.post('/vaccinations', data: {
      'childId': childId,
      'vaccine': vaccine,
      if (dose != null) 'dose': dose,
      if (batchNumber != null) 'batchNumber': batchNumber,
      'status': status,
      'dateGiven': DateTime.now().toUtc().toIso8601String(),
      if (clientUuid != null) 'clientUuid': clientUuid,
    });
    return VaccinationRecord.fromJson(resp.data as Map<String, dynamic>);
  }
}
