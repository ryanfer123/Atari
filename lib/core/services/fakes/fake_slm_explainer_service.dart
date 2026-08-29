import 'dart:async';
import '../i_slm_explainer_service.dart';
import '../../models/explanation.dart';
import '../../models/overload_event.dart';
import '../../models/context_bullet.dart';

class FakeSlmExplainerService implements ISlmExplainerService {
  @override
  Future<Explanation> generateExplanation(OverloadEvent event) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return Explanation(
      sentence: 'You seem distracted. Focus on your upcoming study session.',
      contextBullets: [
        const ContextBullet(source: 'todo', text: 'Study session due at 3pm')
      ],
      generatedAt: DateTime.now(),
    );
  }

  @override
  Stream<String> generateExplanationStream(OverloadEvent event) async* {
    final words = ['You', 'seem', 'distracted.', 'Focus', 'on', 'your', 'upcoming', 'study', 'session.'];
    for (var w in words) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield w + ' ';
    }
  }
}
