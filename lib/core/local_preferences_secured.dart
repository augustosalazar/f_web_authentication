import 'dart:convert';
import 'package:f_web_authentication/core/i_local_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalPreferencesSecured implements ILocalPreferences {
  LocalPreferencesSecured({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.unlocked,
              ),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getString(String key) => _storage.read(key: key);

  @override
  Future<void> setString(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<int?> getInt(String key) async {
    final raw = await _storage.read(key: key);
    return raw == null ? null : int.tryParse(raw);
  }

  @override
  Future<void> setInt(String key, int value) =>
      _storage.write(key: key, value: value.toString());

  @override
  Future<double?> getDouble(String key) async {
    final raw = await _storage.read(key: key);
    return raw == null ? null : double.tryParse(raw);
  }

  @override
  Future<void> setDouble(String key, double value) =>
      _storage.write(key: key, value: value.toString());

  @override
  Future<bool?> getBool(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;

    final v = raw.toLowerCase();
    if (v == 'true') return true;
    if (v == 'false') return false;
    return null; // contenido inválido
  }

  @override
  Future<void> setBool(String key, bool value) =>
      _storage.write(key: key, value: value.toString());

  @override
  Future<List<String>?> getStringList(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded.cast<String>();
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> setStringList(String key, List<String> value) =>
      _storage.write(key: key, value: jsonEncode(value));

  @override
  Future<void> remove(String key) => _storage.delete(key: key);

  @override
  Future<void> clear() => _storage.deleteAll();
}
