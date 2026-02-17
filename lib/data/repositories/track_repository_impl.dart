import 'package:untitled1/core/errors/exceptions.dart';
import 'package:untitled1/core/network/connectivity_checker.dart';
import 'package:untitled1/data/datasources/track_remote_datasource.dart';
import 'package:untitled1/data/local/track_local_datasource.dart';
import 'package:untitled1/data/models/track_model.dart';
import 'package:untitled1/domain/entities/track.dart';
import 'package:untitled1/domain/entities/track_detail.dart';
import 'package:untitled1/domain/repositories/track_repository.dart';

class TrackRepositoryImpl implements TrackRepository {
  final TrackRemoteDatasource remoteDatasource;
  final TrackLocalDatasource localDatasource;
  final ConnectivityChecker connectivityChecker;

  const TrackRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
    required this.connectivityChecker,
  });

  @override
  Future<List<Track>> getTracks({
    required String query,
    required int index,
    int limit = 50,
  }) async {
    final isConnected = await connectivityChecker.isConnected;

    if (!isConnected) {
      // If offline, try returning cached tracks on first load
      if (index == 0) {
        final cached = localDatasource.getCachedTracks();
        if (cached.isNotEmpty) {
          return cached;
        }
      }
      throw const NoInternetException();
    }

    try {
      final tracks = await remoteDatasource.searchTracks(
        query: query,
        index: index,
        limit: limit,
      );

      // Cache the fetched tracks in background
      if (tracks.isNotEmpty) {
        localDatasource.cacheTracks(tracks);
      }

      return tracks;
    } on NoInternetException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<Track>> getPlaylistTracks({
    required String playlistId,
    required int index,
    int limit = 100,
  }) async {
    final isConnected = await connectivityChecker.isConnected;

    if (!isConnected) {
      if (index == 0) {
        final cached = localDatasource.getCachedTracks();
        if (cached.isNotEmpty) return cached;
      }
      throw const NoInternetException();
    }

    try {
      final tracks = await remoteDatasource.getPlaylistTracks(
        playlistId: playlistId,
        index: index,
        limit: limit,
      );

      if (tracks.isNotEmpty) {
        localDatasource.cacheTracks(tracks);
      }

      return tracks;
    } on NoInternetException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TrackDetail> getTrackDetails({required int trackId}) async {
    final isConnected = await connectivityChecker.isConnected;

    if (!isConnected) {
      throw const NoInternetException();
    }

    try {
      return await remoteDatasource.getTrackDetails(trackId: trackId);
    } on NoInternetException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<Track>> getCachedTracks() async {
    try {
      return localDatasource.getCachedTracks();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheTracks(List<Track> tracks) async {
    try {
      final models = tracks.map((t) => TrackModel.fromEntity(t)).toList();
      await localDatasource.cacheTracks(models);
    } catch (_) {
      // Silently fail on cache errors
    }
  }
}
