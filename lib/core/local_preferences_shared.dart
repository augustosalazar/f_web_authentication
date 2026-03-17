import 'package:loggy/loggy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'i_local_preferences.dart';

class LocalPreferencesShared implements ILocalPreferences {
  final SharedPreferencesAsync prefs;

  LocalPreferencesShared() : prefs = SharedPreferencesAsync();

  @override
  Future<T?> retrieveData<T>(String key) async {
    try {
      if (T == bool) {
        return await prefs.getBool(key) as T?;
      } else if (T == double) {
        return await prefs.getDouble(key) as T?;
      } else if (T == int) {
        return await prefs.getInt(key) as T?;
      } else if (T == String) {
        return await prefs.getString(key) as T?;
      } else if (T == List<String>) {
        return await prefs.getStringList(key) as T?;
      } else {
        throw UnsupportedError('Type $T is not supported');
      }
    } catch (e) {
      logError('Error retrieving data for key "$key": $e');
      return null;
    }
  }

  @override
  Future<void> storeData(String key, dynamic value) async {
    try {
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      } else {
        throw UnsupportedError('Type ${value.runtimeType} is not supported');
      }
    } catch (e) {
      logError('Error storing data for key "$key": $e');
      rethrow;
    }
  }

  @override
  Future<void> removeData(String key) async {
    try {
      await prefs.remove(key);
    } catch (e) {
      logError('Error removing data for key "$key": $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await prefs.clear();
    } catch (e) {
      logError('Error clearing all data: $e');
    }
  }
}
