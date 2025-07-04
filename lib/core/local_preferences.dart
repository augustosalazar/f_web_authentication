import 'package:loggy/loggy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPreferences {
  // Singleton instance
  static final LocalPreferences _instance = LocalPreferences._internal();

  // Private constructor
  LocalPreferences._internal();

  // Factory constructor
  factory LocalPreferences() {
    return _instance;
  }

  Future<T?> retrieveData<T>(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (T == bool) {
      return prefs.getBool(key) as T?;
    } else if (T == double) {
      return prefs.getDouble(key) as T?;
    } else if (T == int) {
      return prefs.getInt(key) as T?;
    } else if (T == String) {
      return prefs.getString(key) as T?;
    } else if (T == List<String>) {
      return prefs.getStringList(key) as T?;
    } else {
      throw Exception("Unsupported type");
    }
  }

  Future<void> storeData(String key, dynamic value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool result = false;

    if (value is bool) {
      result = await prefs.setBool(key, value);
      logInfo("LocalPreferences setBool with key $key got $result");
    } else if (value is double) {
      result = await prefs.setDouble(key, value);
      logInfo("LocalPreferences setDouble with key $key got $result");
    } else if (value is int) {
      result = await prefs.setInt(key, value);
      logInfo("LocalPreferences setInt with key $key got $result");
    } else if (value is String) {
      result = await prefs.setString(key, value);
      logInfo("LocalPreferences setString with key $key got $result");
    } else if (value is List<String>) {
      result = await prefs.setStringList(key, value);
      logInfo("LocalPreferences setStringList with key $key got $result");
    } else {
      throw Exception("Unsupported type");
    }

    if (!result) {
      logInfo("Failed to store $key with value $value");
    }
  }

  Future<void> removeData(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool result = await prefs.remove(key);
    logInfo("LocalPreferences removeData with key $key got $result");
  }
}
