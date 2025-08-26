// lib/core/api_client.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'i_local_preferences.dart';

class ApiClient {
  static const _baseUrl = 'https://roble-api.openlab.uninorte.edu.co';
  final Dio dio;

  ApiClient._(this.dio);

  factory ApiClient() {
    final prefs = Get.find<ILocalPreferences>();

    // Cliente base de Dio
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 5000),
    ));

    // Añadimos el interceptor de token
    dio.interceptors.add(TokenInterceptor(dio, prefs));

    return ApiClient._(dio);
  }
}

/// Interceptor que:
/// 1) En onRequest: añade Authorization header si hay token.
/// 2) En onError(401): usa un Completer para refrescar token sólo una vez,
///    y reintenta las peticiones pendientes con el nuevo token.
class TokenInterceptor extends QueuedInterceptorsWrapper {
  final Dio dio;
  final ILocalPreferences prefs;

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  TokenInterceptor(this.dio, this.prefs);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await prefs.retrieveData<String>('token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Si no hay otro refresh en curso, lo iniciamos
      if (!_isRefreshing) {
        _isRefreshing = true;
        _refreshCompleter = Completer<void>();
        try {
          final refreshToken = await prefs.retrieveData<String>('refreshToken');
          if (refreshToken != null) {
            // Llamada al endpoint de refresh
            final resp = await dio.post(
              '/auth/contract_flutterdemo_ebabe79ab0/refresh-token',
              data: {'refreshToken': refreshToken},
            );
            final newToken = resp.data['accessToken'] as String;
            await prefs.storeData('token', newToken);
            _refreshCompleter?.complete();
          } else {
            _refreshCompleter?.completeError(err);
          }
        } catch (e) {
          _refreshCompleter?.completeError(e);
        } finally {
          _isRefreshing = false;
        }
      }

      try {
        // Esperamos a que termine el refresh
        await _refreshCompleter?.future;
        // Reintentamos la petición original con el nuevo token
        final opts = err.requestOptions;
        opts.headers['Authorization'] =
            'Bearer ${await prefs.retrieveData<String>('token')}';
        final cloned = await dio.fetch(opts);
        return handler.resolve(cloned);
      } catch (_) {
        // Si falla el refresh, dejamos pasar el error original
        return handler.next(err);
      }
    }

    // Para otros errores, seguimos normalmente
    handler.next(err);
  }
}
