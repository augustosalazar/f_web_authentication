import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:roble/roble.dart';

import 'i_local_preferences.dart';

class RoblePreferencesStorage implements RobleTokenStorage {
  const RoblePreferencesStorage(this._preferences);

  final ILocalPreferences _preferences;

  @override
  Future<String?> getItem(String key) => _preferences.getString(key);

  @override
  Future<void> setItem(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> removeItem(String key) => _preferences.remove(key);
}

RobleApiDataBase createRobleClient() {
  final projectId = dotenv.get('EXPO_PUBLIC_ROBLE_PROJECT_ID');
  final configuredBaseUrl = dotenv.get(
    'BASE_URL',
    fallback: 'roble-api.test-openlab.uninorte.edu.co',
  );
  final baseUrl = configuredBaseUrl.startsWith('http')
      ? configuredBaseUrl
      : 'https://$configuredBaseUrl';

  final config = RobleApiConfig.fromContract(
    baseUrl: baseUrl,
    contractId: projectId,
  );

  return RobleApiDataBase(
    config: config,
  );
}
