import '../../core/api/api_client.dart';
import '../../core/api/api_routes.dart';
import '../models/administered_dose.dart';
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

  /// Every dose this worker has administered, newest first.
  ///
  /// Omitting `childId` is what makes the server return the worker's own
  /// record across all their children. Building this client-side would mean
  /// one request per child - 80 for a full caseload.
  /// [scope] 'mine' is this worker's own doses; 'region' is every dose given
  /// in their county, whoever gave it.
  Future<List<AdministeredDose>> administered({
    int limit = 200,
    String scope = 'mine',
  }) async {
    final resp = await _api.get(ApiRoutes.vaccinations,
        query: {'limit': limit, 'scope': scope});
    return (resp.data as List)
        .map((e) => AdministeredDose.fromJson(e as Map<String, dynamic>))
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
