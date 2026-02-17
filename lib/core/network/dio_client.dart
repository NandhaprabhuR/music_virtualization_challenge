import 'package:dio/dio.dart';
import 'package:untitled1/core/constants/api_constants.dart';

class DioClient {
  late final Dio deezerDio;
  late final Dio lrclibDio;

  DioClient() {
    deezerDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.deezerBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );

    lrclibDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.lrclibBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );
  }
}
