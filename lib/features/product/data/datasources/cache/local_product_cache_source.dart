import 'dart:convert';

import 'package:f_web_authentication/core/i_local_preferences.dart';
import 'package:f_web_authentication/features/product/domain/models/product.dart';
import 'package:loggy/loggy.dart';

class LocalProductCacheSource {
  final ILocalPreferences prefs;

  static const String _cacheKey = 'cache_products';
  static const String _cacheTimestampKey = 'cache_products_timestamp';
  static const int _cacheTTLMinutes = 10;

  LocalProductCacheSource(this.prefs);

  Future<bool> isCacheValid() async {
    try {
      final timestampStr = await prefs.getString(_cacheTimestampKey);
      if (timestampStr == null) return false;

      final timestamp = DateTime.parse(timestampStr);
      final difference = DateTime.now().difference(timestamp).inMinutes;
      final isValid = difference < _cacheTTLMinutes;

      logInfo(
          '⏱️ Product cache age: ${difference}m / TTL: ${_cacheTTLMinutes}m → ${isValid ? "VALID" : "EXPIRED"}');

      return isValid;
    } catch (e) {
      logError('Error checking product cache validity: $e');
      return false;
    }
  }

  Future<void> cacheProductData(List<Product> products) async {
    try {
      final jsonList = products.map((p) => p.toJson()).toList();
      final encoded = jsonEncode(jsonList);

      await prefs.setString(_cacheKey, encoded);
      await prefs.setString(
          _cacheTimestampKey, DateTime.now().toIso8601String());

      logInfo('💾 Product cache saved: ${products.length} products');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getCachedProductData() async {
    try {
      final encoded = await prefs.getString(_cacheKey);
      if (encoded == null || encoded.isEmpty) {
        logInfo('📦 No product cache found');
        throw Exception('No product cache found');
      }

      final decoded = jsonDecode(encoded) as List;
      final dogs = decoded
          .map((x) => Product.fromJson(x as Map<String, dynamic>))
          .toList();

      logInfo('📦 Product cache loaded: ${dogs.length} products');
      return dogs;
    } catch (e) {
      logError('Error reading product cache: $e');
      throw Exception('Failed to read product cache');
    }
  }

  Future<void> clearCache() async {
    try {
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      logInfo('🗑️ Product cache invalidated');
    } catch (e) {
      logError('Error invalidating product cache: $e');
    }
  }
}
