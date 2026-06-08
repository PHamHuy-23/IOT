import 'package:flutter/material.dart';
import '../models/health_metrics.dart';
import '../services/supabase_service.dart';

class SupabaseProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _currentUserId;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  String? get errorMessage => _errorMessage;

  SupabaseProvider() {
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    _currentUserId = _supabaseService.getCurrentUserId();
    _isAuthenticated = _currentUserId != null;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = await _supabaseService.signUp(email, password, username);
      if (userId != null) {
        _currentUserId = userId;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _supabaseService.signIn(email, password);
      if (success) {
        _checkAuthStatus();
      } else {
        _errorMessage = 'Sign in failed';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
      _currentUserId = null;
      _isAuthenticated = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> saveHealthMetric(HealthMetrics metric) async {
    try {
      await _supabaseService.saveHealthMetric(metric);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<HealthMetrics>> getTodayMetrics() async {
    try {
      return await _supabaseService.getTodayMetrics();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<HealthMetrics>> getMetricsByDateRange(DateTime start, DateTime end) async {
    try {
      return await _supabaseService.getMetricsByDateRange(start, end);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDailySummary(DateTime date) async {
    try {
      return await _supabaseService.getDailySummary(date);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklySummary(DateTime weekStart) async {
    try {
      return await _supabaseService.getWeeklySummary(weekStart);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlySummary(int year, int month) async {
    try {
      return await _supabaseService.getMonthlySummary(year, month);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getYearlySummary(int year) async {
    try {
      return await _supabaseService.getYearlySummary(year);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<void> deleteOldRecords() async {
    try {
      await _supabaseService.deleteOldRecords();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
