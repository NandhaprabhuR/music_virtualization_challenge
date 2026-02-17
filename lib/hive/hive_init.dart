import 'package:hive_flutter/hive_flutter.dart';
import 'package:untitled1/data/models/track_model.dart';
import 'package:untitled1/hive/adapters/track_adapter.dart';

class HiveInit {
  static const String trackBoxName = 'tracks';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TrackModelAdapter());
    }

    // Open boxes
    await Hive.openBox<TrackModel>(trackBoxName);
  }

  static Box<TrackModel> getTrackBox() {
    return Hive.box<TrackModel>(trackBoxName);
  }

  static Future<void> close() async {
    await Hive.close();
  }
}
