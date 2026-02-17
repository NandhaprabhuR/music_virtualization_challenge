// GENERATED-LIKE CODE — hand-written Hive TypeAdapter for TrackModel
// This avoids needing build_runner for the adapter.

import 'package:hive/hive.dart';
import 'package:untitled1/data/models/track_model.dart';

class TrackModelAdapter extends TypeAdapter<TrackModel> {
  @override
  final int typeId = 0;

  @override
  TrackModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackModel(
      trackId: fields[0] as int,
      trackTitle: fields[1] as String,
      trackArtistName: fields[2] as String,
      trackDuration: fields[3] as int,
      trackAlbumTitle: fields[4] as String,
      trackAlbumCoverSmall: fields[5] as String,
      trackAlbumCoverMedium: fields[6] as String,
      trackPreview: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TrackModel obj) {
    writer
      ..writeByte(8) // number of fields
      ..writeByte(0)
      ..write(obj.trackId)
      ..writeByte(1)
      ..write(obj.trackTitle)
      ..writeByte(2)
      ..write(obj.trackArtistName)
      ..writeByte(3)
      ..write(obj.trackDuration)
      ..writeByte(4)
      ..write(obj.trackAlbumTitle)
      ..writeByte(5)
      ..write(obj.trackAlbumCoverSmall)
      ..writeByte(6)
      ..write(obj.trackAlbumCoverMedium)
      ..writeByte(7)
      ..write(obj.trackPreview);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
