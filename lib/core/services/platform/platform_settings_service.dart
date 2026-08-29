import '../i_settings_service.dart';

/// Concrete implementation of [ISettingsService] managing device settings and offline toggles.
class PlatformSettingsService implements ISettingsService {
  PlatformSettingsService();

  List<String> _essentialApps = const [
    'com.google.android.apps.docs',
    'com.google.android.calculator',
    'com.android.calendar',
  ];
  bool _ttsEnabled = true;
  bool _onboardingComplete = false;

  @override
  Future<List<String>> getEssentialApps() async => _essentialApps;

  @override
  Future<void> setEssentialApps(List<String> packageNames) async {
    _essentialApps = List.unmodifiable(packageNames);
  }

  @override
  Future<bool> get isTtsEnabled async => _ttsEnabled;

  @override
  Future<void> setTtsEnabled(bool enabled) async {
    _ttsEnabled = enabled;
  }

  @override
  Future<bool> get isOnboardingComplete async => _onboardingComplete;

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    _onboardingComplete = complete;
  }
}
