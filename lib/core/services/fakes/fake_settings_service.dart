import 'dart:async';
import '../i_settings_service.dart';

class FakeSettingsService implements ISettingsService {
  @override
  Future<List<String>> getEssentialApps() async => ['com.whatsapp', 'com.google.android.gm', 'com.android.calendar'];
  
  @override
  Future<void> setEssentialApps(List<String> packageNames) async {}
  
  @override
  Future<bool> get isTtsEnabled async => true;
  
  @override
  Future<void> setTtsEnabled(bool enabled) async {}
  
  @override
  Future<bool> get isOnboardingComplete async => true;
  
  @override
  Future<void> setOnboardingComplete(bool complete) async {}
  
  @override
  Future<bool> get hasUsageAccessPermission async => true;
  
  @override
  Future<bool> get hasNotificationAccessPermission async => true;
  
  @override
  Future<void> requestUsageAccess() async {}
  
  @override
  Future<void> requestNotificationAccess() async {}
}
