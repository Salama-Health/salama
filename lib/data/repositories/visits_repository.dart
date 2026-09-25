import '../../core/api/api_client.dart';
import '../../core/api/api_routes.dart';

/// Visit outcomes recorded while running a route.
///
/// Previously a visit could only ever reach the server inside a sync batch, even
/// with a live connection. It now posts directly when online and falls back to
/// the outbox when not.
class VisitsRepository {
  VisitsRepository(this._api);
  final ApiClient _api;

  Future<void> record(Map<String, dynamic> visit) async {
    await _api.post(ApiRoutes.visits, data: visit);
  }
}
