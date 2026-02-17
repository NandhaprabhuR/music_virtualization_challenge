class ServerException implements Exception {
  final String message;

  const ServerException({this.message = 'A server error occurred'});

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'A cache error occurred'});

  @override
  String toString() => 'CacheException: $message';
}

class NoInternetException implements Exception {
  final String message;

  const NoInternetException({this.message = 'NO INTERNET CONNECTION'});

  @override
  String toString() => 'NoInternetException: $message';
}
