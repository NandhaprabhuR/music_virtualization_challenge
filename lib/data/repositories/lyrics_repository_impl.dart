import 'package:untitled1/core/errors/exceptions.dart';
import 'package:untitled1/core/network/connectivity_checker.dart';
import 'package:untitled1/data/datasources/lyrics_remote_datasource.dart';
import 'package:untitled1/domain/entities/lyrics.dart';
import 'package:untitled1/domain/repositories/lyrics_repository.dart';

class LyricsRepositoryImpl implements LyricsRepository {
  final LyricsRemoteDatasource remoteDatasource;
  final ConnectivityChecker connectivityChecker;

  const LyricsRepositoryImpl({
    required this.remoteDatasource,
    required this.connectivityChecker,
  });

  @override
  Future<Lyrics> getLyrics({
    required String trackName,
    required String artistName,
    required String albumName,
    required int duration,
  }) async {
    final isConnected = await connectivityChecker.isConnected;

    if (!isConnected) {
      throw const NoInternetException();
    }

    try {
      return await remoteDatasource.getLyrics(
        trackName: trackName,
        artistName: artistName,
        albumName: albumName,
        duration: duration,
      );
    } on NoInternetException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
