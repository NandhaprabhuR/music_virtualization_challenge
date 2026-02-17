import 'package:dio/dio.dart';
import 'package:untitled1/core/constants/api_constants.dart';
import 'package:untitled1/core/errors/exceptions.dart';
import 'package:untitled1/core/network/dio_client.dart';
import 'package:untitled1/data/models/lyrics_model.dart';

abstract class LyricsRemoteDatasource {
  /// Fetches lyrics from LRCLIB cached endpoint.
  Future<LyricsModel> getLyrics({
    required String trackName,
    required String artistName,
    required String albumName,
    required int duration,
  });
}

class LyricsRemoteDatasourceImpl implements LyricsRemoteDatasource {
  final DioClient dioClient;

  const LyricsRemoteDatasourceImpl({required this.dioClient});

  @override
  Future<LyricsModel> getLyrics({
    required String trackName,
    required String artistName,
    required String albumName,
    required int duration,
  }) async {
    try {
      final response = await dioClient.lrclibDio.get(
        ApiConstants.lyricsEndpoint,
        queryParameters: {'track_name': trackName, 'artist_name': artistName},
      );

      if (response.statusCode == 200 && response.data != null) {
        final results = response.data as List<dynamic>;

        if (results.isEmpty) {
          throw const ServerException(message: 'No lyrics found');
        }

        // Pick the first result that has lyrics
        for (final item in results) {
          final json = item as Map<String, dynamic>;
          final plain = json['plainLyrics'] as String? ?? '';
          final synced = json['syncedLyrics'] as String? ?? '';
          if (plain.isNotEmpty || synced.isNotEmpty) {
            return LyricsModel.fromJson(json);
          }
        }

        // No result had lyrics, return first anyway
        return LyricsModel.fromJson(results.first as Map<String, dynamic>);
      }

      throw const ServerException(message: 'Failed to fetch lyrics');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NoInternetException();
      }
      throw ServerException(message: e.message ?? 'Failed to fetch lyrics');
    }
  }
}
