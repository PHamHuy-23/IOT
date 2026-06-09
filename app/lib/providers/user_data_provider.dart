import 'package:flutter/foundation.dart';
import '../models/daily_summary_model.dart';
import '../models/user_medical_profile.dart';
import '../models/user_settings.dart';
import '../services/health_data_service.dart';
import '../services/user_profile_service.dart';

class UserDataProvider extends ChangeNotifier {
  final HealthDataService _health = HealthDataService();
  final UserProfileService _profile = UserProfileService();

  String? _userId;
  DailySummaryModel? _todaySummary;
  UserMedicalProfile? _medicalProfile;
  UserSettings? _settings;
  ShareTokenInfo? _shareToken;
  bool _loading = false;
  String _error = '';

  DailySummaryModel? get todaySummary => _todaySummary;
  UserMedicalProfile? get medicalProfile => _medicalProfile;
  UserSettings? get settings => _settings;
  ShareTokenInfo? get shareToken => _shareToken;
  bool get isLoading => _loading;
  String get error => _error;

  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    if (userId == null) {
      _clear();
      notifyListeners();
      return;
    }
    loadAll();
  }

  void _clear() {
    _todaySummary = null;
    _medicalProfile = null;
    _settings = null;
    _shareToken = null;
    _error = '';
  }

  Future<void> loadAll() async {
    if (_userId == null) return;
    _loading = true;
    notifyListeners();

    try {
      await Future.wait([
        refreshTodaySummary(),
        loadMedicalProfile(),
        loadSettings(),
      ]);
      _error = '';
    } catch (e) {
      _error = e.toString();
      debugPrint('[UserDataProvider.loadAll] $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTodaySummary() async {
    if (_userId == null) return;
    _todaySummary = await _health.getDailySummary(_userId!, DateTime.now());
    notifyListeners();
  }

  Future<void> loadMedicalProfile() async {
    if (_userId == null) return;
    _medicalProfile = await _profile.getMedicalProfile(_userId!);
    notifyListeners();
  }

  Future<void> saveMedicalProfile(UserMedicalProfile profile) async {
    await _profile.upsertMedicalProfile(profile);
    _medicalProfile = profile;
    notifyListeners();
  }

  Future<void> loadSettings() async {
    if (_userId == null) return;
    _settings = await _profile.getSettings(_userId!);
    notifyListeners();
  }

  Future<void> saveSettings(UserSettings settings) async {
    await _profile.upsertSettings(settings);
    _settings = settings;
    notifyListeners();
  }

  Future<ShareTokenInfo?> loadShareToken() async {
    if (_userId == null) return null;
    _shareToken = await _profile.getOrCreateShareToken(_userId!);
    notifyListeners();
    return _shareToken;
  }

  String? get shareUrl {
    if (_shareToken == null) return null;
    return _profile.buildShareUrl(_shareToken!.token);
  }

  Future<String?> exportData() async {
    if (_userId == null) return null;
    return _health.exportUserDataJson(_userId!);
  }

  Future<bool> deleteHealthData() async {
    if (_userId == null) return false;
    try {
      await _health.deleteUserHealthData(_userId!);
      _todaySummary = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
