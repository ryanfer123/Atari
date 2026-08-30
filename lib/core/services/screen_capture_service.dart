import 'dart:async';

import 'package:flutter/services.dart';

/// Dart-side client for Circle-to-Search capture, over the
/// `atari.dev/capture` platform channel.
///
/// The heavy lifting lives in `CaptureOverlayService` on the Android
/// side: a foreground service holds the screen-projection consent for
/// the session and owns a floating bubble drawn over other apps. That's
/// what lets the user circle something in *any* app rather than only
/// inside ATARI. When they finish a selection, the service crops the
/// frame and pushes the file path back through [captures].
class ScreenCaptureService {
  ScreenCaptureService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('atari.dev/capture') {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final MethodChannel _channel;
  final _controller = StreamController<String>.broadcast();

  /// Paths of cropped captures, pushed from the overlay service.
  Stream<String> get captures => _controller.stream;

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onCaptureReady') {
      final path = (call.arguments as Map?)?['path'] as String?;
      if (path != null) _controller.add(path);
    }
  }

  /// Whether the floating bubble is currently active.
  Future<bool> isEnabled() async =>
      await _channel.invokeMethod<bool>('isEnabled') ?? false;

  /// Whether the app may draw over other apps — required for the bubble
  /// and the selection overlay.
  Future<bool> canDrawOverlays() async =>
      await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;

  /// Opens the "display over other apps" settings screen. There is no
  /// runtime dialog for this permission.
  Future<void> requestOverlayPermission() =>
      _channel.invokeMethod<void>('requestOverlayPermission');

  /// Prompts for screen-projection consent and, if granted, starts the
  /// bubble. Returns whether it was granted.
  Future<bool> enable() async =>
      await _channel.invokeMethod<bool>('enable') ?? false;

  Future<void> disable() => _channel.invokeMethod<void>('disable');

  /// Triggers a capture immediately, backgrounding the app first so the
  /// shot is of whatever was behind it.
  Future<void> captureNow() => _channel.invokeMethod<void>('captureNow');

  void dispose() => _controller.close();
}
