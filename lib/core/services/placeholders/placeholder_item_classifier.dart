import '../../models/captured_item.dart';
import '../../../engine/capture/captured_item_parser.dart';
import '../model_services.dart';

/// Deterministic stand-in for model-based filing.
///
/// Reuses `CapturedItemParser`'s heuristics rather than inventing a second
/// rule set, so the placeholder and the model are judged on the same
/// input and the app behaves identically in shape with no weights
/// present. This is also the fallback the real classifier returns to when
/// a model call fails.
class PlaceholderItemClassifier implements ItemClassifier {
  const PlaceholderItemClassifier();

  @override
  ModelBackend get backend => ModelBackend.placeholder;

  @override
  Future<ItemType> classify(String text) async =>
      CapturedItemParser().parse(text).suggestedType;
}
