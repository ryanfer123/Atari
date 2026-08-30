/// The on-device models this app is designed around, and where each one
/// plugs in.
///
/// Every slot here has a deterministic placeholder today
/// (`placeholders/README.md`), so the app is fully usable before any
/// weights exist. This registry is what the Settings screen renders, and
/// what tells you exactly which file to put in which slot.
///
/// Model choices come from Plans/IMPLEMENTATION.md §2 and
/// Plans/PIVOT_PLAN.md §2.5 — the pivot cut the model count from five to
/// three (two required, one optional), and requires them to be loaded
/// one at a time rather than concurrently (§2.2).
library;

enum ModelSlot { slm, embedder, ocr, segmentation, dewarp }

/// How much the product depends on a slot being filled.
enum ModelRequirement {
  /// Core loop degrades to a placeholder but still works end-to-end.
  recommended,

  /// Explicitly stretch-only in the pivot; the MVP path avoids it.
  stretch,
}

class ModelSpec {
  const ModelSpec({
    required this.slot,
    required this.title,
    required this.modelName,
    required this.format,
    required this.approxSize,
    required this.usedFor,
    required this.requirement,
    required this.source,
    this.fallbackModel,
    this.note,
  });

  final ModelSlot slot;

  /// What this slot does, in product terms.
  final String title;

  /// The specific model this project selected.
  final String modelName;

  final String format;
  final String approxSize;

  /// Which app features become model-backed once this is filled.
  final String usedFor;

  final ModelRequirement requirement;

  /// Where to get it.
  final String source;

  /// The documented alternative if the primary doesn't fit.
  final String? fallbackModel;

  final String? note;

  /// Exact filename this slot expects. Auto-detection matches on this,
  /// so it must be what the download actually produces.
  String get expectedFileName => switch (slot) {
    ModelSlot.slm => 'qwen3-4b-q4_k_m.gguf',
    ModelSlot.embedder => 'embeddinggemma-300m-qat-q4_0.gguf',
    ModelSlot.ocr => 'PP-OCRv5_mobile_det.onnx',
    ModelSlot.segmentation => 'edgesam.onnx',
    ModelSlot.dewarp => 'docscanner.onnx',
  };

  /// Files that must sit beside [expectedFileName] for the slot to work.
  ///
  /// PP-OCR is genuinely three files — detection finds text boxes,
  /// recognition reads them, and the charset dictionary decodes
  /// recognition's output indices into characters. Without the dict the
  /// model runs and returns numbers, which would look like garbled OCR
  /// rather than a missing file.
  List<String> get companionFiles => switch (slot) {
    ModelSlot.ocr => const ['PP-OCRv5_mobile_rec.onnx', 'ppocrv5_dict.txt'],
    _ => const [],
  };
}

/// The full set of slots, in the order Settings shows them: required
/// ones first, stretch last.
const List<ModelSpec> modelRegistry = [
  ModelSpec(
    slot: ModelSlot.slm,
    title: 'Language model',
    modelName: 'Qwen3-4B',
    format: 'GGUF, Q4_K_M',
    approxSize: '~2.5 GB',
    usedFor: 'Difficulty scoring, task decomposition, and the one-sentence explanations',
    requirement: ModelRequirement.recommended,
    source: 'huggingface.co/Qwen/Qwen3-4B-GGUF',
    fallbackModel: 'Gemma 3 4B (GGUF) if the Qwen3 tool-calling path is harder to integrate',
    note:
        'Chosen over the original Gemma 3 1B because the confirmed device is a 16GB flagship. '
        'Every call is constrained to a closed enum — it never emits free text that becomes app state.',
  ),
  ModelSpec(
    slot: ModelSlot.ocr,
    title: 'Text extraction (OCR)',
    modelName: 'PP-OCRv5',
    format: 'ONNX (detection + recognition + charset dict)',
    approxSize: '~21 MB total',
    usedFor: 'Reading text out of the region you circle in the capture flow',
    requirement: ModelRequirement.recommended,
    source:
        'huggingface.co/nathanfhh/PaddleOCR-ONNX — an ONNX conversion. The official '
        'PaddlePaddle repos ship Paddle inference format, which would need Paddle Lite '
        'on Android rather than ONNX Runtime.',
    fallbackModel:
        'PaddleOCR-VL (0.9B) only if table/timetable structure is being lost',
    note: 'Classical OCR first — small and deployable. Do not reach for the VLM before measuring.',
  ),
  ModelSpec(
    slot: ModelSlot.embedder,
    title: 'Note & capture embeddings',
    modelName: 'EmbeddingGemma-300M',
    format: 'GGUF, QAT Q4_0',
    approxSize: '~265 MB',
    usedFor: 'Semantic search over notes and past captures, for grounding explanations',
    requirement: ModelRequirement.recommended,
    source:
        'huggingface.co/ggml-org/embeddinggemma-300M-qat-q4_0-GGUF — a GGUF build. '
        'The official google/embeddinggemma-300m repo is gated and ships safetensors.',
    fallbackModel: 'Snowflake Arctic-Embed-XS (22.5M) if memory is tight',
    note: 'Only free-text notes and captures are embedded. Todos and health targets stay field queries.',
  ),
  ModelSpec(
    slot: ModelSlot.segmentation,
    title: 'Precise cutout from your circle',
    modelName: 'EdgeSAM',
    format: 'ONNX',
    approxSize: '~40 MB',
    usedFor: 'Turning your circle into an exact object cutout instead of a rectangle',
    requirement: ModelRequirement.stretch,
    source: 'github.com/chongzhou96/EdgeSAM',
    note: 'Stretch only. The MVP crops to the bounding box of your circle, which is enough to read text.',
  ),
  ModelSpec(
    slot: ModelSlot.dewarp,
    title: 'Page flattening',
    modelName: 'DocScanner',
    format: 'ONNX',
    approxSize: '~30 MB',
    usedFor: 'Flattening a page photographed at an angle before reading it',
    requirement: ModelRequirement.stretch,
    source: 'github.com/fh2019ustc/DocScanner',
    note: 'Stretch only. Screenshots and near-flat photos do not need it.',
  ),
];

ModelSpec specFor(ModelSlot slot) =>
    modelRegistry.firstWhere((s) => s.slot == slot);
