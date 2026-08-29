import 'package:get_it/get_it.dart';
import '../services/i_overload_service.dart';
import '../services/fakes/fake_overload_service.dart';
import '../services/i_baseline_service.dart';
import '../services/fakes/fake_baseline_service.dart';
import '../services/i_slm_explainer_service.dart';
import '../services/fakes/fake_slm_explainer_service.dart';
import '../services/i_goal_context_service.dart';
import '../services/fakes/fake_goal_context_service.dart';
import '../services/i_gamification_service.dart';
import '../services/fakes/fake_gamification_service.dart';
import '../services/i_capture_pipeline_service.dart';
import '../services/fakes/fake_capture_pipeline_service.dart';
import '../services/i_feedback_loop_service.dart';
import '../services/fakes/fake_feedback_loop_service.dart';
import '../services/i_settings_service.dart';
import '../services/fakes/fake_settings_service.dart';
import '../../features/dashboard/viewmodels/dashboard_viewmodel.dart';

final getIt = GetIt.instance;

void setupFakes() {
  getIt.registerLazySingleton<IOverloadService>(() => FakeOverloadService());
  getIt.registerLazySingleton<IBaselineService>(() => FakeBaselineService());
  getIt.registerLazySingleton<ISlmExplainerService>(() => FakeSlmExplainerService());
  getIt.registerLazySingleton<IGoalContextService>(() => FakeGoalContextService());
  getIt.registerLazySingleton<IGamificationService>(() => FakeGamificationService());
  getIt.registerLazySingleton<ICapturePipelineService>(() => FakeCapturePipelineService());
  getIt.registerLazySingleton<IFeedbackLoopService>(() => FakeFeedbackLoopService());
  getIt.registerLazySingleton<ISettingsService>(() => FakeSettingsService());

  getIt.registerFactory(() => DashboardViewModel(
    overloadService: getIt(),
    baselineService: getIt(),
    gamificationService: getIt(),
    feedbackLoopService: getIt(),
  ));
}
