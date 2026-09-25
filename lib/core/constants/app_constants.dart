class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Salama Health';
  static const String appTagline = 'Better health, stronger communities.';
  static const String appMotto =
      'We predict climate risks that disrupt immunization, and help health '
      'workers protect children before it’s too late.';

  // Asset paths
  static const String logo = 'assets/logo.png';
  static const String landingBg = 'assets/landing_screen_bg.png';

  // ── Backend API ──
  // Production, over TLS (Let's Encrypt). Plain HTTP 308-redirects here, and
  // Android trusts the chain, so no cleartext exception is needed.
  // Override at build time for a local backend:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://salamahealth.duckdns.org',
  );

  // Route names
  static const String routeSplash = '/';
  static const String routeHome = '/home';
  static const String routeLogin = '/login';
  static const String routeChildQr = '/child-qr';

  // Poweredby
  static const String poweredBy = 'celo';

  // ── Build info ──
  // Passed in by CI so the About sheet cannot drift from the built artifact:
  //   flutter build apk --dart-define=APP_VERSION=1.0.0 --dart-define=BUILD_NUMBER=1
  static const String appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  static const String buildNumber =
      String.fromEnvironment('BUILD_NUMBER', defaultValue: '1');

  // Facility, region and support contacts are not constants — they belong to
  // the signed-in worker and arrive from GET /auth/me.
}
