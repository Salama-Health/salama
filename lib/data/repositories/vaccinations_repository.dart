import '../../core/api/api_client.dart';
import '../../core/api/api_routes.dart';
import '../models/vaccination_record.dart';

class VaccinationsRepository {
  VaccinationsRepository(this._api);
  final ApiClient _api;

  /// Doses recorded for one child, newest first as the server orders them.
  Future<List<VaccinationRecord>> history(String childId) async {
    final resp =
        await _api.get(ApiRoutes.vaccinations, query: {'childId': childId});
    return (resp.data as List)
        .map((e) => VaccinationRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Record a dose.
  ///
  /// Takes the payload whole rather than as arguments, so the object sent live
  /// and the object queued in the outbox are built once at the call site and
  /// cannot drift apart.
  Future<VaccinationRecord> record(Map<String, dynamic> payload) async {
    final resp = await _api.post(ApiRoutes.vaccinations, data: payload);
    return VaccinationRecord.fromJson(resp.data as Map<String, dynamic>);
  }
}
