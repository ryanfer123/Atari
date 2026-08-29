import 'dart:async';
import '../i_baseline_service.dart';
import '../../models/signal_snapshot.dart';
import '../../models/baseline_bucket.dart';

class FakeBaselineService implements IBaselineService {
  final _streamController = StreamController<SignalSnapshot>.broadcast();

  FakeBaselineService() {
    Future.delayed(const Duration(seconds: 1), () {
      _streamController.add(SignalSnapshot(
        unlockCount: 15,
        appSwitchCount: 42,
        avgNotifLatencyMs: 1200,
        zScores: {'unlocks': 0.5, 'app_switches': 2.5},
        windowStart: DateTime.now(), // would be earlier
        windowEnd: DateTime.now(),
      ));
    });
  }

  @override
  Future<SignalSnapshot> getCurrentSnapshot() async {
    return SignalSnapshot(
      unlockCount: 15,
      appSwitchCount: 42,
      avgNotifLatencyMs: 1200,
      zScores: {'unlocks': 0.5, 'app_switches': 2.5},
      windowStart: DateTime.now(),
      windowEnd: DateTime.now(),
    );
  }

  @override
  Future<List<BaselineBucket>> getBuckets({required String signal}) async {
    return [
      BaselineBucket(signal: signal, hourOfDay: 14, dayOfWeek: 3, sampleCount: 10, mean: 20, standardDeviation: 5)
    ];
  }

  @override
  Stream<SignalSnapshot> get snapshotStream => _streamController.stream;
}
