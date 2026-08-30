import 'package:flutter/services.dart';

/// Dart-side client for the llama.cpp bridge on `atari.dev/models`.
///
/// Kotlin's `LlamaSessions` keeps at most one model resident and swaps
/// on demand (Plans/PIVOT_PLAN.md §2.2), so a call that switches slots
/// pays a model load. Callers should finish their work with one slot
/// before reaching for the other.
class LlamaChannel {
  const LlamaChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('atari.dev/models');

  final MethodChannel _channel;

  Future<bool> isSlmReady() async =>
      await _channel.invokeMethod<bool>('isSlmReady') ?? false;

  Future<bool> isEmbedderReady() async =>
      await _channel.invokeMethod<bool>('isEmbedderReady') ?? false;

  /// Generates at most [maxTokens] tokens.
  ///
  /// When [grammar] is given, the sampler can only emit strings the
  /// grammar accepts — malformed output becomes impossible rather than
  /// something to detect afterwards. Sampling is greedy, so the same
  /// prompt always gives the same answer.
  Future<String> generate({
    required String prompt,
    int maxTokens = 64,
    String? grammar,
  }) async {
    final out = await _channel.invokeMethod<String>('slmGenerate', {
      'prompt': prompt,
      'maxTokens': maxTokens,
      'grammar': grammar,
    });
    return out ?? '';
  }

  Future<List<double>> embed(String text) async {
    final raw = await _channel.invokeListMethod<double>('embedText', {
      'text': text,
    });
    return raw ?? const [];
  }

  Future<int> embeddingDimensions() async =>
      await _channel.invokeMethod<int>('embeddingDimensions') ?? 0;

  /// Frees whatever model is resident. Worth calling when the app goes
  /// to the background, since the SLM alone is ~2.5GB of mapped pages.
  Future<void> unload() => _channel.invokeMethod<void>('unloadModels');
}

/// GBNF grammars that make each masked enum the *only* thing the model
/// can emit.
///
/// This is the constrained-decoding half of the defence-in-depth in
/// Plans/PIVOT_PLAN.md §2.3. The post-hoc parse in each service is the
/// second half — a grammar guarantees well-formed output, not that the
/// weights loaded or that the string maps onto a value we know.
abstract final class LlamaGrammars {
  /// `DifficultyTier`, lowercase, bare — no quotes or prose.
  static const difficulty =
      'root ::= "trivial" | "light" | "moderate" | "heavy"';

  /// One to [maxSubtasks] objects. The repetition is spelled out rather
  /// than written as `item*` precisely so the cap is enforced by the
  /// grammar instead of by truncating a longer answer afterwards.
  static const decomposition = r'''
root   ::= "[" ws item (ws "," ws item)? (ws "," ws item)? (ws "," ws item)? ws "]"
item   ::= "{" ws "\"title\":" ws title ws "," ws "\"minutes\":" ws minutes ws "," ws "\"tier\":" ws tier ws "," ws "\"tool\":" ws tool ws "}"
title  ::= "\"" char{1,80} "\""
char   ::= [^"\\\x00-\x1F]
minutes ::= [1-9] [0-9]? [0-9]?
tier   ::= "\"trivial\"" | "\"light\"" | "\"moderate\"" | "\"heavy\""
tool   ::= "\"setReminder\"" | "\"setAlarm\"" | "\"startTimer\"" | "\"addTodo\"" | "\"none\""
ws     ::= [ \t\n]*
''';

  /// One or two sentences of plain prose, ending in a full stop.
  ///
  /// The explanation is the one place the model writes words a person
  /// reads, so the grammar bounds its *shape* — no lists, no newlines —
  /// while `OnDeviceSlmExplainer` checks its content. Deliberately
  /// allows a period anywhere in the body, not only at the very end:
  /// excluding "." mid-string (the original shape of this grammar)
  /// makes every decimal number ungrammatical too — "50.0 unlocks" is
  /// literally impossible to emit — which is what made the explanation
  /// unable to ever state a real figure. The length ceiling and
  /// `OnDeviceSlmExplainer`'s own instruction not to write more than two
  /// sentences are what keep this from turning into a paragraph.
  static const explanation = r'''
root ::= [A-Z] [^\n]{20,280} "."
''';
}
