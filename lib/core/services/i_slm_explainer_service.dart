import '../models/explanation.dart';
import '../models/overload_event.dart';

abstract class ISlmExplainerService {
  Future<Explanation> generateExplanation(OverloadEvent event);
  Stream<String> generateExplanationStream(OverloadEvent event);
}
