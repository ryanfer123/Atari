import 'package:flutter/services.dart';
import '../i_tts_service.dart';
import 'platform_channels.dart';

/// Concrete implementation of [ITtsService] invoking native Android TextToSpeech engine.
class PlatformTtsService implements ITtsService {
  PlatformTtsService({MethodChannel? methodChannel})
      : _methodChannel = methodChannel ?? PlatformChannels.tts;

  final MethodChannel _methodChannel;

  @override
  Future<bool> speak(String text) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('speak', {'text': text});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod<void>('stop');
    } catch (_) {}
  }

  @override
  Future<bool> isReady() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isReady');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
