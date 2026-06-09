import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ══════════════════════════════════════════════════════════════
// USER MODEL
// ══════════════════════════════════════════════════════════════
class AppUser {
  final String id;
  final String email;
  final String username;
  final String displayName;
  final bool isAdmin;
  final String avatarColor;

  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    required this.isAdmin,
    required this.avatarColor,
  });

  /// 2 chữ cái đầu của displayName — dùng cho avatar
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.substring(0, displayName.length.clamp(1, 2)).toUpperCase();
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      username: map['username'] as String,
      displayName: (map['display_name'] as String?) ?? (map['username'] as String),
      isAdmin: (map['is_admin'] as bool?) ?? false,
      avatarColor: (map['avatar_color'] as String?) ?? 'red',
    );
  }

  AppUser copyWith({
    String? displayName,
    String? avatarColor,
  }) {
    return AppUser(
      id: id,
      email: email,
      username: username,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// USER STATS MODEL
// ══════════════════════════════════════════════════════════════
class UserStats {
  final int daysTracked;
  final int totalSyncs;
  final int badgeCount;

  const UserStats({
    required this.daysTracked,
    required this.totalSyncs,
    required this.badgeCount,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      daysTracked: (map['days_tracked'] as num?)?.toInt() ?? 0,
      totalSyncs:  (map['total_syncs']  as num?)?.toInt() ?? 0,
      badgeCount:  (map['badge_count']  as num?)?.toInt() ?? 0,
    );
  }

  static const empty = UserStats(
    daysTracked: 0,
    totalSyncs: 0,
    badgeCount: 0,
  );
}

// ══════════════════════════════════════════════════════════════
// AUTH PROVIDER
// ══════════════════════════════════════════════════════════════
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  AppUser? _currentUser;
  UserStats _stats = UserStats.empty;
  bool _isLoading = false;
  String _error = '';

  // ── Getters ────────────────────────────────────────────────
  AppUser? get currentUser => _currentUser;
  UserStats get stats => _stats;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String get error => _error;

  // ── Khởi tạo — gọi trong main() sau Supabase.initialize() ──
  /// Kiểm tra session còn hiệu lực khi app khởi động.
  /// Supabase lưu session trong secure storage nên không cần lưu thủ công.
  Future<void> initialize() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _loadUserProfile(session.user.id);
    }

    // Lắng nghe thay đổi auth state (token refresh, logout từ tab khác...)
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _stats = UserStats.empty;
        notifyListeners();
      }
    });
  }

  // ══════════════════════════════════════════════════════════
  // SIGN IN
  // Dùng custom bcrypt check vì schema không dùng Supabase Auth
  // mà lưu password_hash tự quản lý.
  // ══════════════════════════════════════════════════════════
  Future<bool> signIn(String usernameOrEmail, String password) async {
    _setLoading(true);
    clearError();

    try {
      // Gọi RPC function để check bcrypt an toàn phía server
      final result = await _supabase.rpc(
        'authenticate_user',
        params: {
          'p_login': usernameOrEmail.trim().toLowerCase(),
          'p_password': password,
        },
      );

      // RPC trả về row đầu tiên hoặc null nếu sai credentials
      if (result == null || (result is List && result.isEmpty)) {
        _setError('Tên đăng nhập hoặc mật khẩu không đúng');
        return false;
      }

      final userData = result is List ? result.first : result;
      _currentUser = AppUser.fromMap(userData as Map<String, dynamic>);
      
      // Tự động tải thống kê của user sau khi đăng nhập thành công
      await getStats();
      
      notifyListeners();
      return true;
    } on PostgrestException catch (e) {
      _setError(_mapPostgrestError(e));
      return false;
    } catch (e) {
      _setError('Đã xảy ra lỗi. Vui lòng thử lại.');
      debugPrint('[AuthProvider.signIn] $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ══════════════════════════════════════════════════════════
  // SIGN UP
  // ══════════════════════════════════════════════════════════
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    clearError();

    // Validate cơ bản phía client
    if (password.length < 6) {
      _setError('Mật khẩu tối thiểu 6 ký tự');
      _setLoading(false);
      return false;
    }

    try {
      // Kiểm tra email đã tồn tại chưa
      final existing = await _supabase
          .from('users')
          .select('id')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      if (existing != null) {
        _setError('Email này đã được sử dụng');
        return false;
      }

      // Tạo username từ email (phần trước @)
      final baseUsername = email.split('@').first.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      final username = await _generateUniqueUsername(baseUsername);

      // Gọi RPC để insert + hash password phía server
      final result = await _supabase.rpc(
        'create_user',
        params: {
          'p_email': email.trim().toLowerCase(),
          'p_username': username,
          'p_display_name': name.trim(),
          'p_password': password,
        },
      );

      if (result == null) {
        _setError('Không thể tạo tài khoản. Vui lòng thử lại.');
        return false;
      }

      final userData = result is List ? result.first : result;
      _currentUser = AppUser.fromMap(userData as Map<String, dynamic>);
      
      // Tải stats cho user mới tạo (thường trả về các giá trị bằng 0)
      await getStats();
      
      notifyListeners();
      return true;
    } on PostgrestException catch (e) {
      _setError(_mapPostgrestError(e));
      return false;
    } catch (e) {
      _setError('Đã xảy ra lỗi. Vui lòng thử lại.');
      debugPrint('[AuthProvider.signUp] $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ══════════════════════════════════════════════════════════
  // SIGN OUT
  // ══════════════════════════════════════════════════════════
  Future<void> signOut() async {
    _currentUser = null;
    _stats = UserStats.empty;
    clearError();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // UPDATE PROFILE
  // ══════════════════════════════════════════════════════════
  Future<bool> updateProfile({
    String? displayName,
    String? avatarColor,
  }) async {
    if (_currentUser == null) return false;
    _setLoading(true);

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        if (displayName != null) 'display_name': displayName.trim(),
        if (avatarColor != null) 'avatar_color': avatarColor,
      };

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', _currentUser!.id);

      _currentUser = _currentUser!.copyWith(
        displayName: displayName,
        avatarColor: avatarColor,
      );
      notifyListeners();
      return true;
    } on PostgrestException catch (e) {
      _setError(_mapPostgrestError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ══════════════════════════════════════════════════════════
  // GET STATS
  // ══════════════════════════════════════════════════════════
  Future<void> getStats() async {
    if (_currentUser == null) return;

    try {
      final result = await _supabase.rpc(
        'get_user_stats',
        params: {'p_user_id': _currentUser!.id},
      );

      if (result != null) {
        final data = result is List ? result.first : result;
        _stats = UserStats.fromMap(data as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthProvider.getStats] $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════

  Future<void> _loadUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('id, email, username, display_name, is_admin, avatar_color')
          .eq('id', userId)
          .single();
      _currentUser = AppUser.fromMap(data);
      
      // Tự động tải thống kê khi phục hồi phiên đăng nhập thành công
      await getStats();
      
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthProvider._loadUserProfile] $e');
    }
  }

  Future<String> _generateUniqueUsername(String base) async {
    var candidate = base.isEmpty ? 'user' : base;
    var suffix = 0;
    while (true) {
      final name = suffix == 0 ? candidate : '$candidate$suffix';
      final existing = await _supabase
          .from('users')
          .select('id')
          .eq('username', name)
          .maybeSingle();
      if (existing == null) return name;
      suffix++;
    }
  }

  String _mapPostgrestError(PostgrestException e) {
    switch (e.code) {
      case '23505':
        if (e.message.contains('email')) return 'Email đã được sử dụng';
        if (e.message.contains('username')) return 'Tên đăng nhập đã tồn tại';
        return 'Dữ liệu bị trùng lặp';
      case '42501':
        return 'Không có quyền thực hiện thao tác này';
      case 'PGRST116':
        return 'Tên đăng nhập hoặc mật khẩu không đúng';
      default:
        return 'Lỗi máy chủ (${e.code}). Vui lòng thử lại.';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}