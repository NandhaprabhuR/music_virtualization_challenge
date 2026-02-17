import 'package:untitled1/domain/entities/track_detail.dart';
import 'package:untitled1/domain/repositories/track_repository.dart';

class GetTrackDetails {
  final TrackRepository repository;

  const GetTrackDetails(this.repository);

  Future<TrackDetail> call({required int trackId}) {
    return repository.getTrackDetails(trackId: trackId);
  }
}
