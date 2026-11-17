import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/providers/app_settings_backup.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'only listed settings are read, never secrets or device state',
    () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 2,
        'user_nickname': 'Ace',
        'currency_reminder_leads': ['days30'],
        'adsb_disabled_track_providers': ['opensky'],
        // Not settings to carry around.
        'carto_api_key': 'secret',
        'dropbox_access_token': 'token',
        'backup_local_last_hash': 'abc',
        'onboarding_complete': true,
        'last_time_updated': 123,
      });
      final read = AppSettingsBackup.read(
        await SharedPreferences.getInstance(),
      );
      expect(read, {
        'theme_mode': 2,
        'user_nickname': 'Ace',
        'currency_reminder_leads': ['days30'],
        'adsb_disabled_track_providers': ['opensky'],
      });
    },
  );

  test('restoring replaces listed settings and resets missing ones', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 1,
      'measurement_unit': 1,
      'carto_api_key': 'kept',
      'onboarding_complete': true,
    });
    final prefs = await SharedPreferences.getInstance();
    await AppSettingsBackup.write(prefs, {
      'theme_mode': 2,
      'currency_reminder_leads': ['days7', 'days30'],
      'map_source': 'osm',
      // Ignored: not listed, or of the wrong type.
      'carto_api_key': 'from backup',
      'evil': 'x',
      'currency_notifications_enabled': 'yes',
    });
    expect(prefs.getInt('theme_mode'), 2);
    expect(prefs.getStringList('currency_reminder_leads'), ['days7', 'days30']);
    expect(prefs.getString('map_source'), 'osm');
    // Missing from the backup: back to the default.
    expect(prefs.containsKey('measurement_unit'), isFalse);
    expect(prefs.containsKey('currency_notifications_enabled'), isFalse);
    // Untouched.
    expect(prefs.getString('carto_api_key'), 'kept');
    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(prefs.containsKey('evil'), isFalse);
  });

  test("the pilot's names are replaced, never cleared", () async {
    SharedPreferences.setMockInitialValues({
      'user_nickname': 'Ace',
      'user_signature_name': 'John Smith',
    });
    final prefs = await SharedPreferences.getInstance();
    await AppSettingsBackup.write(prefs, {'user_nickname': '  '});
    expect(prefs.getString('user_nickname'), 'Ace');
    expect(prefs.getString('user_signature_name'), 'John Smith');

    await AppSettingsBackup.write(prefs, {'user_signature_name': 'Jane Doe'});
    expect(prefs.getString('user_signature_name'), 'Jane Doe');
  });
}
