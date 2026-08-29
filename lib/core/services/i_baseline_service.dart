import '../models/signal_snapshot.dart';
import '../models/baseline_bucket.dart';

abstract class IBaselineService {
  Future<SignalSnapshot> getCurrentSnapshot();
  Future<List<BaselineBucket>> getBuckets({required String signal});
  Stream<SignalSnapshot> get snapshotStream;
}
