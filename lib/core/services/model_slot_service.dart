import 'package:flutter/services.dart';

import 'model_registry.dart';

/// Validation state of the file a slot points at.
enum ModelFileStatus {
  notConfigured,
  fileNotFound,
  notReadable,
  wrongFormat,

  /// The main file is fine but a required companion is missing — see
  /// `ModelSpec.companionFiles`.
  missingCompanions,

  looksValid,
}

class ModelSlotStatus {
  const ModelSlotStatus({
    required this.slot,
    required this.status,
    this.path,
    this.fileSizeBytes,
    this.missingCompanions = const [],
  });

  final ModelSlot slot;
  final ModelFileStatus status;
  final String? path;

  /// Total size including companions, so the number matches what was
  /// actually put on the device.
  final int? fileSizeBytes;

  final List<String> missingCompanions;

  bool get isFilled => status == ModelFileStatus.looksValid;

  String get label => switch (status) {
    ModelFileStatus.notConfigured => 'Not added yet',
    ModelFileStatus.fileNotFound => 'No file at that path',
    ModelFileStatus.notReadable => 'File is not readable',
    ModelFileStatus.wrongFormat => 'That file is not the expected format',
    ModelFileStatus.missingCompanions =>
      'Missing: ${missingCompanions.join(', ')}',
    ModelFileStatus.looksValid => 'Added · ${_megabytes(fileSizeBytes)}',
  };

  static String _megabytes(int? bytes) {
    final mb = (bytes ?? 0) / (1024 * 1024);
    return mb >= 1024
        ? '${(mb / 1024).toStringAsFixed(2)} GB'
        : '${mb.toStringAsFixed(1)} MB';
  }
}

/// Dart-side client for per-slot model file configuration, over the
/// `atari.dev/models` platform channel.
///
/// Configuring a path records and validates the file; it does not load
/// it. The OCR slot is picked up by `OnDeviceOcrService` and actually
/// runs (ONNX Runtime). The SLM and embedder slots are GGUF and still
/// await a llama.cpp build, so filling them validates the file but does
/// not yet change any behaviour.
class ModelSlotService {
  ModelSlotService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('atari.dev/models');

  final MethodChannel _channel;

  Future<void> setPath(ModelSlot slot, String path) {
    return _channel.invokeMethod<void>('setModelPath', {
      'slot': slot.name,
      'path': path,
    });
  }

  Future<void> clear(ModelSlot slot) {
    return _channel.invokeMethod<void>('clearModelPath', {'slot': slot.name});
  }

  /// Directory the app can always read without any permission grant —
  /// what the UI tells you to `adb push` into.
  Future<String?> modelsDirectory() {
    return _channel.invokeMethod<String?>('getModelsDirectory');
  }

  /// Looks for the slot's expected filename in the models directory and
  /// records it if present. Saves typing a long path by hand.
  Future<bool> autoDetect(ModelSlot slot) async {
    final found = await _channel.invokeMethod<bool>('autoDetect', {
      'slot': slot.name,
      'fileName': specFor(slot).expectedFileName,
    });
    return found ?? false;
  }

  /// Runs [autoDetect] for every slot; returns how many were newly found.
  Future<int> autoDetectAll() async {
    var found = 0;
    for (final spec in modelRegistry) {
      try {
        if (await autoDetect(spec.slot)) found++;
      } catch (_) {
        // One unreadable slot shouldn't abort the scan.
      }
    }
    return found;
  }

  Future<ModelSlotStatus> status(ModelSlot slot) async {
    final raw = await _channel.invokeMapMethod<String, Object?>(
      'getModelStatus',
      {'slot': slot.name, 'companions': specFor(slot).companionFiles},
    );
    return _parse(slot, raw);
  }

  Future<Map<ModelSlot, ModelSlotStatus>> allStatuses() async {
    final result = <ModelSlot, ModelSlotStatus>{};
    for (final spec in modelRegistry) {
      // Each slot is read independently so one failure can't blank the
      // whole screen.
      try {
        result[spec.slot] = await status(spec.slot);
      } catch (_) {
        result[spec.slot] = ModelSlotStatus(
          slot: spec.slot,
          status: ModelFileStatus.notConfigured,
        );
      }
    }
    return result;
  }

  ModelSlotStatus _parse(ModelSlot slot, Map<String, Object?>? raw) {
    final name = raw?['status'] as String?;
    final status = ModelFileStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => ModelFileStatus.notConfigured,
    );
    return ModelSlotStatus(
      slot: slot,
      status: status,
      path: raw?['path'] as String?,
      fileSizeBytes: raw?['fileSizeBytes'] as int?,
      missingCompanions:
          (raw?['missing'] as List<Object?>?)?.cast<String>() ?? const [],
    );
  }
}
