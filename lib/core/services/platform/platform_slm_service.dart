import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/models.dart';
import '../i_slm_explainer_service.dart';
import 'platform_channels.dart';

/// Concrete implementation of [ISlmExplainerService] invoking on-device SLM inference via JNI.
class PlatformSlmService implements ISlmExplainerService {
  PlatformSlmService({MethodChannel? methodChannel})
      : _methodChannel = methodChannel ?? PlatformChannels.slm;

  final MethodChannel _methodChannel;

  @override
  Future<Explanation> generateExplanation(
    OverloadEvent event, {
    List<ContextBullet> contextBullets = const [],
  }) async {
    try {
      final payload = {
        'fragmentationScore': event.severity,
        'appSwitchZ': event.signalScores['app_switches'] ?? -1000.0,
        'unlockZ': event.signalScores['unlocks'] ?? -1000.0,
        'notifZ': event.signalScores['notif_latency_ms'] ?? -1000.0,
        'timeBucket': event.baselineContext,
        'contextBullets': contextBullets.map((b) => b.toJson()).toList(),
      };

      final result = await _methodChannel.invokeMapMethod<String, dynamic>(
        'explain',
        payload,
      );

      if (result == null) {
        return Explanation(
          sentence: 'Behavioral overload detected. Take a short pause.',
          contextBullets: contextBullets,
          generatedAt: DateTime.now(),
          usedModel: false,
          fallbackReason: 'channel_returned_null',
        );
      }

      return Explanation.fromJson(result);
    } catch (e) {
      return Explanation(
        sentence: 'Behavioral overload detected. Take a short pause.',
        contextBullets: contextBullets,
        generatedAt: DateTime.now(),
        usedModel: false,
        fallbackReason: 'channel_exception: $e',
      );
    }
  }

  @override
  Future<SourceSelection> selectSources({
    required String triggerSignal,
    required String topSignal,
    List<GoalContextSource> allowedSources = GoalContextSource.values,
    int maxCalls = 3,
  }) async {
    try {
      final payload = {
        'triggerSignal': triggerSignal,
        'topSignal': topSignal,
        'allowedSources': allowedSources.map((s) => s.name).toList(),
        'maxCalls': maxCalls,
      };

      final result = await _methodChannel.invokeMapMethod<String, dynamic>(
        'selectSources',
        payload,
      );

      if (result == null) {
        return SourceSelection(
          sources: allowedSources.take(maxCalls).toList(),
          reasoning: 'Fallback: null channel response',
          usedModel: false,
        );
      }

      return SourceSelection.fromJson(result);
    } catch (_) {
      return SourceSelection(
        sources: allowedSources.take(maxCalls).toList(),
        reasoning: 'Fallback: channel unavailable',
        usedModel: false,
      );
    }
  }

  @override
  Future<bool> isReady() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isModelReady');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Initialize the GGML backend. Call once before [loadModel].
  Future<Map<String, dynamic>> initRuntime() async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, dynamic>('initRuntime');
      if (result?['success'] == true) {
        // Automatically load model from internal files directory or candidate paths
        final supportDir = await getApplicationSupportDirectory();
        final docsDir = await getApplicationDocumentsDirectory();
        final candidatePaths = [
          '${supportDir.path}/model.gguf',
          '${docsDir.path}/model.gguf',
          '/data/user/0/com.atari/files/model.gguf',
          '/data/data/com.atari/files/model.gguf',
        ];
        String modelPath = candidatePaths.first;
        for (final p in candidatePaths) {
          if (await File(p).exists()) {
            modelPath = p;
            break;
          }
        }
        final loadResult = await loadModel(modelPath);
        if (loadResult['success'] == true) {
          return {'success': true, 'message': 'GGML init & model loaded from $modelPath'};
        } else {
          return {'success': false, 'message': 'GGML init OK, but load failed: ${loadResult['message']}'};
        }
      }
      return result ?? {'success': false, 'message': 'null response'};
    } catch (e) {
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  /// Load a GGUF model file. [contextTokens] controls KV cache size.
  Future<Map<String, dynamic>> loadModel(String modelPath, {int contextTokens = 1024}) async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, dynamic>('loadModel', {
        'modelPath': modelPath,
        'contextTokens': contextTokens,
      });
      return result ?? {'success': false, 'message': 'null response'};
    } catch (e) {
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  /// Unload the current model and free native memory.
  Future<void> unloadModel() async {
    try {
      await _methodChannel.invokeMethod('unloadModel');
    } catch (_) {}
  }

  /// Get runtime telemetry (load time, generation speed, TTFT, etc.).
  Future<Map<String, dynamic>> getRuntimeStatus() async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, dynamic>('getRuntimeStatus');
      return result ?? {};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  String _fallbackSentence(OverloadEvent event) {
    switch (event.topSignal) {
      case 'app_switches':
        return 'Your app-switching is higher than your usual ${event.baselineContext} pattern.';
      case 'unlocks':
        return 'You are unlocking your phone more frequently than your usual ${event.baselineContext} pattern.';
      case 'notif_latency_ms':
        return 'You are responding to notifications faster than your usual ${event.baselineContext} pattern.';
      default:
        return 'Your phone activity is unusually fragmented for a ${event.baselineContext}.';
    }
  }
}
