import 'package:shared_preferences/shared_preferences.dart';

/// A language the app can be set to. Only English ships translated today; the
/// rest are listed because they are what people actually speak in Unity State,
/// and the roadmap commits to them.
enum AppLanguage { english, jubaArabic, nuer, dinka }

extension AppLanguageX on AppLanguage {
  String get label => switch (this) {
        AppLanguage.english => 'English',
        AppLanguage.jubaArabic => 'Juba Arabic',
        AppLanguage.nuer => 'Nuer (Thok Naath)',
        AppLanguage.dinka => 'Dinka (Thuɔŋjäŋ)',
      };

  String get nativeLabel => switch (this) {
        AppLanguage.english => 'English',
        AppLanguage.jubaArabic => 'عربي جوبا',
        AppLanguage.nuer => 'Thok Naath',
        AppLanguage.dinka => 'Thuɔŋjäŋ',
      };

  /// Translations land with the multilingual release; until then the picker
  /// records the preference but the interface stays in English.
  bool get available => this == AppLanguage.english;

  String get code => switch (this) {
        AppLanguage.english => 'en',
        AppLanguage.jubaArabic => 'apd',
        AppLanguage.nuer => 'nus',
        AppLanguage.dinka => 'din',
      };
}

class AppSettings {
  final AppLanguage language;
  final bool alertNotifications;
  final bool visitReminders;
  final bool syncNotifications;
  final bool autoSync;
  final bool syncOnMobileData;

  const AppSettings({
    this.language = AppLanguage.english,
    this.alertNotifications = true,
    this.visitReminders = true,
    this.syncNotifications = false,
    this.autoSync = true,
    this.syncOnMobileData = true,
  });

  AppSettings copyWith({
    AppLanguage? language,
    bool? alertNotifications,
    bool? visitReminders,
    bool? syncNotifications,
    bool? autoSync,
    bool? syncOnMobileData,
  }) =>
      AppSettings(
        language: language ?? this.language,
        alertNotifications: alertNotifications ?? this.alertNotifications,
        visitReminders: visitReminders ?? this.visitReminders,
        syncNotifications: syncNotifications ?? this.syncNotifications,
        autoSync: autoSync ?? this.autoSync,
        syncOnMobileData: syncOnMobileData ?? this.syncOnMobileData,
      );
}

/// Device-local preferences. Nothing here needs the server.
class SettingsRepository {
  SettingsRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kLanguage = 'setting_language';
  static const _kAlerts = 'setting_alert_notifications';
  static const _kReminders = 'setting_visit_reminders';
  static const _kSyncNotif = 'setting_sync_notifications';
  static const _kAutoSync = 'setting_auto_sync';
  static const _kMobileData = 'setting_sync_mobile_data';

  AppSettings load() {
    return AppSettings(
      language: AppLanguage.values.firstWhere(
        (l) => l.name == _prefs.getString(_kLanguage),
        orElse: () => AppLanguage.english,
      ),
      alertNotifications: _prefs.getBool(_kAlerts) ?? true,
      visitReminders: _prefs.getBool(_kReminders) ?? true,
      syncNotifications: _prefs.getBool(_kSyncNotif) ?? false,
      autoSync: _prefs.getBool(_kAutoSync) ?? true,
      syncOnMobileData: _prefs.getBool(_kMobileData) ?? true,
    );
  }

  Future<void> save(AppSettings s) async {
    await _prefs.setString(_kLanguage, s.language.name);
    await _prefs.setBool(_kAlerts, s.alertNotifications);
    await _prefs.setBool(_kReminders, s.visitReminders);
    await _prefs.setBool(_kSyncNotif, s.syncNotifications);
    await _prefs.setBool(_kAutoSync, s.autoSync);
    await _prefs.setBool(_kMobileData, s.syncOnMobileData);
  }
}
