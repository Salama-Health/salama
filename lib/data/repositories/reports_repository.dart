import '../../core/api/api_client.dart';
import '../models/report_models.dart';

class ReportsRepository {
  ReportsRepository(this._api);
  final ApiClient _api;

  Future<ReportsBundle> bundle() async {
    final results = await Future.wait([
      _api.get('/reports/summary'),
      _api.get('/reports/doses-weekly'),
      _api.get('/reports/coverage-by-vaccine'),
    ]);

    final summary =
        ReportSummary.fromJson(results[0].data as Map<String, dynamic>);
    final weekly = ((results[1].data as Map<String, dynamic>)['days'] as List?)
            ?.map((e) => DayCount.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final coverage =
        ((results[2].data as Map<String, dynamic>)['vaccines'] as List?)
                ?.map((e) => VaccineCoverage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [];

    return ReportsBundle(
        summary: summary, weeklyDoses: weekly, coverage: coverage);
  }
}
