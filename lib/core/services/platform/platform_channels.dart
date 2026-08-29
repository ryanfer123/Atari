import 'package:flutter/services.dart';

/// Central registry of Flutter MethodChannels and EventChannels for ATARI.
abstract class PlatformChannels {
  static const MethodChannel sensing = MethodChannel('com.atari/sensing');
  static const EventChannel sensingStream = EventChannel('com.atari/sensing_stream');

  static const MethodChannel slm = MethodChannel('com.atari/slm');
  static const EventChannel slmStream = EventChannel('com.atari/slm_stream');

  static const MethodChannel tts = MethodChannel('com.atari/tts');
  static const MethodChannel capture = MethodChannel('com.atari/capture');
}
