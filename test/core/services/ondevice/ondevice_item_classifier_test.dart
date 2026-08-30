import 'package:atari/core/models/captured_item.dart';
import 'package:atari/core/services/ondevice/llama_channel.dart';
import 'package:atari/core/services/ondevice/ondevice_item_classifier.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The classifier maps three plain words onto [ItemType]. The grammar
/// guarantees one of those words is emitted; these cover what it cannot
/// — the mapping, and what happens when the model is unavailable.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('atari.dev/models');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void mockGenerate(String? reply) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'slmGenerate') return null;
      if (reply == null) {
        throw PlatformException(code: 'llama_failed', message: 'no model');
      }
      return reply;
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  const classifier = OnDeviceItemClassifier(channel: LlamaChannel());

  test('files each of the three words onto its ItemType', () async {
    mockGenerate('todo');
    expect(await classifier.classify('Submit the form'), ItemType.todo);

    mockGenerate('note');
    expect(await classifier.classify('Library shuts at 9'), ItemType.note);

    // The model answers "health"; the enum value is healthTarget.
    mockGenerate('health');
    expect(await classifier.classify('Sleep 7 hours'), ItemType.healthTarget);
  });

  test('tolerates whitespace and casing around the answer', () async {
    mockGenerate('  Todo\n');
    expect(await classifier.classify('Pay the rent'), ItemType.todo);
  });

  test('falls back to heuristics when the model is unavailable', () async {
    mockGenerate(null);
    // Must still return a usable type rather than throwing — a batch of
    // pasted lines has to sort into something the user can correct.
    expect(
      await classifier.classify('Submit OS assignment tomorrow'),
      isA<ItemType>(),
    );
  });

  test('falls back on a word outside the enum', () async {
    mockGenerate('reminder');
    expect(await classifier.classify('Anything at all'), isA<ItemType>());
  });
}
