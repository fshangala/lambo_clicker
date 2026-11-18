import 'package:flutter/services.dart';

class VolumeUpService {
  static const EventChannel _channel = EventChannel(
    'com.fshangala.apps.lambo_clicker/volume_up',
  );

  Stream<dynamic> get presses => _channel.receiveBroadcastStream();
}
