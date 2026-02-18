import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:untitled1/core/constants/api_constants.dart';

class DioClient {
  late final Dio deezerDio;
  late final Dio lrclibDio;

  DioClient() {
    deezerDio = _createDio(ApiConstants.deezerBaseUrl);
    lrclibDio = _createDio(ApiConstants.lrclibBaseUrl);
  }

  Dio _createDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'Accept': 'application/json'},
      ),
    );

    if (kIsWeb) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Build the full URL with query params, then wrap in CORS proxy
            final fullUri = options.uri;
            final proxiedUrl =
                'https://corsproxy.io/?${Uri.encodeComponent(fullUri.toString())}';
            options.baseUrl = '';
            options.path = proxiedUrl;
            options.queryParameters = {};
            handler.next(options);
          },
        ),
      );
    }

    return dio;
  }
}
