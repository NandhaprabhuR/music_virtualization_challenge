import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:untitled1/core/network/connectivity_checker.dart';
import 'package:untitled1/core/network/dio_client.dart';
import 'package:untitled1/core/theme/app_theme.dart';
import 'package:untitled1/data/datasources/lyrics_remote_datasource.dart';
import 'package:untitled1/data/datasources/track_remote_datasource.dart';
import 'package:untitled1/data/local/track_local_datasource.dart';
import 'package:untitled1/data/repositories/lyrics_repository_impl.dart';
import 'package:untitled1/data/repositories/track_repository_impl.dart';
import 'package:untitled1/domain/repositories/lyrics_repository.dart';
import 'package:untitled1/domain/repositories/track_repository.dart';
import 'package:untitled1/domain/usecases/get_lyrics.dart';
import 'package:untitled1/domain/usecases/get_track_details.dart';
import 'package:untitled1/domain/usecases/get_tracks.dart';
import 'package:untitled1/domain/usecases/search_tracks.dart';
import 'package:untitled1/hive/hive_init.dart';
import 'package:untitled1/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:untitled1/presentation/blocs/library/library_bloc.dart';
import 'package:untitled1/presentation/blocs/audio/audio_player_cubit.dart';
import 'package:untitled1/presentation/blocs/now_playing/now_playing_cubit.dart';
import 'package:untitled1/presentation/screens/home_screen.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Core
  getIt.registerLazySingleton<DioClient>(() => DioClient());
  getIt.registerLazySingleton<ConnectivityChecker>(
    () => ConnectivityCheckerImpl(),
  );

  // Data sources
  getIt.registerLazySingleton<TrackRemoteDatasource>(
    () => TrackRemoteDatasourceImpl(dioClient: getIt<DioClient>()),
  );
  getIt.registerLazySingleton<LyricsRemoteDatasource>(
    () => LyricsRemoteDatasourceImpl(dioClient: getIt<DioClient>()),
  );
  getIt.registerLazySingleton<TrackLocalDatasource>(
    () => TrackLocalDatasourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<TrackRepository>(
    () => TrackRepositoryImpl(
      remoteDatasource: getIt<TrackRemoteDatasource>(),
      localDatasource: getIt<TrackLocalDatasource>(),
      connectivityChecker: getIt<ConnectivityChecker>(),
    ),
  );
  getIt.registerLazySingleton<LyricsRepository>(
    () => LyricsRepositoryImpl(
      remoteDatasource: getIt<LyricsRemoteDatasource>(),
      connectivityChecker: getIt<ConnectivityChecker>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<GetTracks>(
    () => GetTracks(getIt<TrackRepository>()),
  );
  getIt.registerLazySingleton<SearchTracks>(
    () => SearchTracks(getIt<TrackRepository>()),
  );
  getIt.registerLazySingleton<GetTrackDetails>(
    () => GetTrackDetails(getIt<TrackRepository>()),
  );
  getIt.registerLazySingleton<GetLyrics>(
    () => GetLyrics(getIt<LyricsRepository>()),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveInit.init();

  // Setup dependency injection
  await setupDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectivityCubit>(
          create: (_) => ConnectivityCubit(
            connectivityChecker: getIt<ConnectivityChecker>(),
          ),
        ),
        BlocProvider<LibraryBloc>(
          create: (_) => LibraryBloc(
            getTracks: getIt<GetTracks>(),
            searchTracks: getIt<SearchTracks>(),
          ),
        ),
        BlocProvider<NowPlayingCubit>(create: (_) => NowPlayingCubit()),
        BlocProvider<AudioPlayerCubit>(create: (_) => AudioPlayerCubit()),
      ],
      child: MaterialApp(
        title: 'Music Library',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
