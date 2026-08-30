import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/services/model_services.dart';
import 'core/services/model_slot_service.dart';
import 'core/services/ondevice/llama_channel.dart';
import 'core/services/ondevice/ondevice_difficulty_scorer.dart';
import 'core/services/ondevice/ondevice_embedding_service.dart';
import 'core/services/ondevice/ondevice_item_classifier.dart';
import 'core/services/ondevice/ondevice_ocr_service.dart';
import 'core/services/ondevice/ondevice_slm_explainer.dart';
import 'core/services/ondevice/ondevice_task_decomposer.dart';
import 'core/services/placeholders/placeholder_embedding_service.dart';
import 'core/services/placeholders/placeholder_ocr_service.dart';
import 'core/services/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Auto-detection is what turns an `adb push` into a configured slot;
  // without it freshly-pushed weights stay invisible until the user
  // opens Settings. It only stats files, so it is cheap enough to do
  // before the first frame.
  final slots = ModelSlotService();
  try {
    await slots.autoDetectAll();
  } catch (e) {
    debugPrint('Model auto-detection failed: $e');
  }

  const channel = LlamaChannel();
  final slmReady = await _check(channel.isSlmReady, 'language model');
  final embedder = await OnDeviceEmbeddingService.create(channel: channel);

  // Constructed once, here, so every model-backed capability has a
  // single swap point — see AppServices' doc comment and
  // `lib/core/services/placeholders/README.md`.
  final services = AppServices(
    database: AppDatabase(),
    ocrService: await _resolveOcr(),
    embedder: embedder ?? const PlaceholderEmbeddingService(),
    difficultyScorer: slmReady
        ? const OnDeviceDifficultyScorer(channel: channel)
        : null,
    taskDecomposer: slmReady
        ? const OnDeviceTaskDecomposer(channel: channel)
        : null,
    slmExplainer: slmReady ? const OnDeviceSlmExplainer(channel: channel) : null,
    itemClassifier: slmReady
        ? const OnDeviceItemClassifier(channel: channel)
        : null,
  );

  runApp(AtariApp(services: services));

  // Not awaited: re-arming is a startup self-heal, not something the
  // first frame depends on, and it shouldn't delay it. See
  // AppServices.rearmPendingReminders for why this needs to run at
  // every launch rather than only once.
  unawaited(services.rearmPendingReminders());
}

/// Picks the real OCR model when its files are on the device, and the
/// placeholder otherwise.
///
/// Resolved before the first frame because the banner and the capture
/// badge both read the chosen backend — deciding later would mean the UI
/// briefly claims a capability is a placeholder while a model is in fact
/// about to answer for it.
Future<OcrService> _resolveOcr() async {
  const placeholder = PlaceholderOcrService();
  final onDevice = OnDeviceOcrService(fallback: placeholder);
  return await onDevice.isReady() ? onDevice : placeholder;
}

Future<bool> _check(Future<bool> Function() probe, String label) async {
  try {
    return await probe();
  } catch (e) {
    debugPrint('Could not check the $label: $e');
    return false;
  }
}
