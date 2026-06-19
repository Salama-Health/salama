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
  // Override at build time:
  //   flutter run --dart-define=API_BASE_URL=https://your-host
  // Android emulator reaches the host machine via 10.0.2.2.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // Route names
  static const String routeSplash = '/';
  static const String routeHome = '/home';
  static const String routeLogin = '/login';
  static const String routeChildQr = '/child-qr';

  // Facility / location
  static const String facility = 'Bentiu PHCC';
  static const String region = 'Unity State';

  // Poweredby
  static const String poweredBy = 'celo';
}
