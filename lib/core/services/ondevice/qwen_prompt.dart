/// Qwen3 chat formatting for short, non-thinking on-device requests.
///
/// Every call from this app is a small classification or a single
/// sentence, so thinking mode is switched off explicitly: an empty
/// `<think>` block is pre-filled in the assistant turn, which is Qwen3's
/// documented way to skip reasoning. Left on, the model would spend its
/// whole token budget deliberating and get cut off before answering.
String qwenPrompt({required String system, required String user}) =>
    '<|im_start|>system\n$system<|im_end|>\n'
    '<|im_start|>user\n$user<|im_end|>\n'
    '<|im_start|>assistant\n<think>\n\n</think>\n\n';

/// Clamps untrusted text before it goes into a prompt.
///
/// Captured text comes from OCR of whatever the user circled — it is
/// data, never instructions. Truncating bounds the prompt, and the
/// calling prompts state the trust boundary explicitly, matching the
/// contract in `native/model/README.md`.
String clampForPrompt(String text, {int maxChars = 600}) {
  final collapsed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (collapsed.length <= maxChars) return collapsed;
  return '${collapsed.substring(0, maxChars)}…';
}
