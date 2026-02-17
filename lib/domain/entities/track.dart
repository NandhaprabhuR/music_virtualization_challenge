import 'package:equatable/equatable.dart';

class Track extends Equatable {
  final int id;
  final String title;
  final String artistName;
  final int duration;
  final String albumTitle;
  final String albumCoverSmall;
  final String albumCoverMedium;
  final String preview; // 30s preview URL

  const Track({
    required this.id,
    required this.title,
    required this.artistName,
    required this.duration,
    required this.albumTitle,
    required this.albumCoverSmall,
    required this.albumCoverMedium,
    required this.preview,
  });

  /// Returns the first letter of the title (uppercased) for grouping
  String get groupLetter {
    if (title.isEmpty) return '#';
    final first = title[0].toUpperCase();
    if (RegExp(r'[A-Z]').hasMatch(first)) return first;
    return '#';
  }

  @override
  List<Object?> get props => [id];
}
