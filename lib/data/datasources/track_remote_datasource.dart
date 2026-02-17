import 'package:dio/dio.dart';
import 'package:untitled1/core/constants/api_constants.dart';
import 'package:untitled1/core/errors/exceptions.dart';
import 'package:untitled1/core/network/dio_client.dart';
import 'package:untitled1/data/models/track_model.dart';
import 'package:untitled1/data/models/track_detail_model.dart';

abstract class TrackRemoteDatasource {
  /// Fetches tracks from Deezer search API.
  Future<List<TrackModel>> searchTracks({
    required String query,
    required int index,
    int limit = 50,
  });

  /// Fetches tracks from a Deezer playlist.
  Future<List<TrackModel>> getPlaylistTracks({
    required String playlistId,
    required int index,
    int limit = 100,
  });

  /// Fetches full track details from Deezer.
  Future<TrackDetailModel> getTrackDetails({required int trackId});
}

class TrackRemoteDatasourceImpl implements TrackRemoteDatasource {
  final DioClient dioClient;

  const TrackRemoteDatasourceImpl({required this.dioClient});

  @override
  Future<List<TrackModel>> searchTracks({
    required String query,
    required int index,
    int limit = 50,
  }) async {
    try {
      final response = await dioClient.deezerDio.get(
        ApiConstants.searchTracksEndpoint,
        queryParameters: {'q': query, 'index': index, 'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final trackList = data['data'] as List<dynamic>? ?? [];

        return trackList
            .map((json) => TrackModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw const ServerException(message: 'Failed to fetch tracks');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NoInternetException();
      }
      throw ServerException(message: e.message ?? 'Failed to fetch tracks');
    }
  }

  @override
  Future<List<TrackModel>> getPlaylistTracks({
    required String playlistId,
    required int index,
    int limit = 100,
  }) async {
    try {
      final response = await dioClient.deezerDio.get(
        '/playlist/$playlistId/tracks',
        queryParameters: {'index': index, 'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final trackList = data['data'] as List<dynamic>? ?? [];

        return trackList
            .map((json) => TrackModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw const ServerException(message: 'Failed to fetch playlist tracks');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NoInternetException();
      }
      throw ServerException(
        message: e.message ?? 'Failed to fetch playlist tracks',
      );
    }
  }

  @override
  Future<TrackDetailModel> getTrackDetails({required int trackId}) async {
    try {
      final response = await dioClient.deezerDio.get(
        '${ApiConstants.trackDetailEndpoint}/$trackId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return TrackDetailModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw const ServerException(message: 'Failed to fetch track details');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NoInternetException();
      }
      throw ServerException(
        message: e.message ?? 'Failed to fetch track details',
      );
    }
  }
}
