/// Contract for offline Android TextToSpeech audio playback.
abstract class ITtsService {
  /// Speaks the provided explanation text aloud using the local TTS engine.
  Future<bool> speak(String text);

  /// Stops ongoing speech.
  Future<void> stop();

  /// Checks if TTS engine is ready.
  Future<bool> isReady();
}
