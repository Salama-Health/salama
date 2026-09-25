/// Every path the app calls, in one place.
///
/// Endpoint strings were previously inline in each repository, which made the
/// surface the backend has to implement impossible to see at a glance and easy
/// to typo. This is the list to check against docs/API_CONTRACT.md.
class ApiRoutes {
  ApiRoutes._();

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String changePin = '/auth/change-pin';

  /// Paths that must never trigger a token refresh on 401: a rejected login or
  /// a rejected refresh is a final answer.
  static const Set<String> noRefresh = {login, refresh};

  // ── Children ───────────────────────────────────────────────────────────────
  static const String children = '/children';
  static const String childLookup = '/children/lookup';
  static String child(String id) => '/children/$id';

  // ── Vaccinations ───────────────────────────────────────────────────────────
  static const String vaccinations = '/vaccinations';

  // ── Visits ─────────────────────────────────────────────────────────────────
  static const String visits = '/visits';

  // ── Facilities ─────────────────────────────────────────────────────────────
  static const String facilities = '/facilities';
  static String facility(String id) => '/facilities/$id';

  // ── Activity ───────────────────────────────────────────────────────────────
  static const String activity = '/activity';

  // ── Reports ────────────────────────────────────────────────────────────────
  static const String reportsSummary = '/reports/summary';
  static const String reportsDosesWeekly = '/reports/doses-weekly';
  static const String reportsCoverage = '/reports/coverage-by-vaccine';

  // ── Routes ─────────────────────────────────────────────────────────────────
  static const String optimizedRoute = '/routes/optimized';

  // ── Sync ───────────────────────────────────────────────────────────────────
  static const String syncStatus = '/sync/status';
  static const String syncUpload = '/sync/upload';

  // ── Alerts ─────────────────────────────────────────────────────────────────
  static const String alerts = '/alerts';
}
