import '../../core/api/api_client.dart';
import '../../core/api/api_routes.dart';
import '../../core/storage/offline_cache.dart';
import '../models/report_models.dart';

class ReportsRepository {
  ReportsRepository(this._api, this._cache);
  final ApiClient _api;
  final OfflineCache _cache;

  /// The three report endpoints are cached as one bundle, so the Reports tab
  /// shows the last known figures offline instead of an error.
  Future<ReportsBundle> bundle() {
    return _cache.readThrough<ReportsBundle>(
      key: OfflineCache.kReports,
      fetchJson: () async {
        final results = await Future.wait([
          _api.get(ApiRoutes.reportsSummary),
          _api.get(ApiRoutes.reportsDosesWeekly),
          _api.get(ApiRoutes.reportsCoverage),
        ]);
        return {
          'summary': results[0].data,
          'weekly': results[1].data,
          'coverage': results[2].data,
        };
      },
      decode: (json) {
        final map = json as Map<String, dynamic>;
        final summary =
            ReportSummary.fromJson(map['summary'] as Map<String, dynamic>);
        final weekly =
            ((map['weekly'] as Map<String, dynamic>?)?['days'] as List?)
                    ?.map((e) => DayCount.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                const [];
        final coverage =
            ((map['coverage'] as Map<String, dynamic>?)?['vaccines'] as List?)
                    ?.map((e) =>
                        VaccineCoverage.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                const [];
        return ReportsBundle(
            summary: summary, weeklyDoses: weekly, coverage: coverage);
      },
    );
  }
}
