abstract class ISettingsService {
  Future<List<String>> getEssentialApps();
  Future<void> setEssentialApps(List<String> packageNames);
  Future<bool> get isTtsEnabled;
  Future<void> setTtsEnabled(bool enabled);
  Future<bool> get isOnboardingComplete;
  Future<void> setOnboardingComplete(bool complete);
  Future<bool> get hasUsageAccessPermission;
  Future<bool> get hasNotificationAccessPermission;
  Future<void> requestUsageAccess();
  Future<void> requestNotificationAccess();
}
