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
  final bool isTestAccount;
  final String avatarColor;

  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    required this.isAdmin,
    this.isTestAccount = false,
    required this.avatarColor,
  });

  /// Admin hoặc testing → dùng dữ liệu mô phỏng khi không có BLE
  bool get usesSimulation => isAdmin || isTestAccount;

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
      isTestAccount: (map['is_test_account'] as bool?) ?? false,
      avatarColor: (map['avatar_color'] as String?) ?? 'red',
    );
  }

  AppUser copyWith({
    String? displayName,
    String? avatarColor,
    bool? isTestAccount,
  }) {
    return AppUser(
      id: id,
      email: email,
      username: username,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin,
      isTestAccount: isTestAccount ?? this.isTestAccount,
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
  bool _isLoading = true;
  String _error = '';

  // ── Getters ────────────────────────────────────────────────
  AppUser? get currentUser => _currentUser;
  UserStats get stats => _stats;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String get error => _error;

  // ── Khởi tạo — gọi trong main() sau Supabase.initialize() ──
  /// Kiểm tra session còn hiệu lực khi app khởi động.
  /// Dùng session storage nội bộ của Supabase SDK để persist qua các lần kill app.
  // ── Khởi tạo — gọi trong main() ──
  Future<void> initialize() async {
    // 1. Kiểm tra xem Supabase SDK có giữ session cũ nào trong bộ nhớ máy không
    final initialSession = _supabase.auth.currentSession;
    
    if (initialSession != null) {
      final userId = initialSession.user.id;
      
      // Khởi tạo user "tạm thời" để app KHÔNG bị đá ra màn hình đăng nhập khi mất mạng
      _currentUser = AppUser(
        id: userId,
        email: initialSession.user.email ?? '',
        username: 'loading...',
        displayName: 'Người dùng',
        isAdmin: false,
        avatarColor: 'red',
      );
      
      // Chạy ngầm việc tải thông tin thật từ Database và Stats (nếu có mạng sẽ cập nhật lại)
      _loadUserProfile(userId).then((_) => getStats());
    }

    // Tắt trạng thái loading ban đầu của App
    _isLoading = false;
    notifyListeners();

    // 2. Lắng nghe dòng sự kiện thay đổi trạng thái Auth (Login, Logout, Token Refreshed)
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      debugPrint('[Supabase Auth Event]: $event');

      if (session != null) {
        // Nếu có session mới (vừa đăng nhập thành công hoặc token tự động gia hạn thành công)
        if (_currentUser == null || _currentUser!.id != session.user.id) {
          await _loadUserProfile(session.user.id);
          await getStats();
        }
      } else {
        // Nếu session bằng null (Người dùng bấm SignOut hoặc Token bị hủy từ server)
        _currentUser = null;
        _stats = UserStats.empty;
        notifyListeners();
      }
    });
  }

  // ══════════════════════════════════════════════════════════
  // SIGN IN (Cập nhật theo chuẩn Supabase Auth)
  // ══════════════════════════════════════════════════════════
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    clearError();

    try {
      final loginEmail = await _resolveLoginEmail(email);

      // Dùng hàm chuẩn của Supabase Auth để đăng nhập bằng Email
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: loginEmail,
        password: password,
      );

      if (res.user == null) {
        _setError('Đăng nhập thất bại');
        return false;
      }

      // Đăng nhập thành công -> Lấy thông tin chi tiết từ bảng 'users' của bạn
      await _loadUserProfile(res.user!.id);
      return true;
    } on AuthException catch (e) {
      // Bắt các lỗi auth của Supabase (sai mật khẩu, sai email...)
      _setError(e.message); // Hoặc dịch sang tiếng Việt: 'Email hoặc mật khẩu không đúng'
      return false;
    } catch (e) {
      _setError('Đã xảy ra lỗi hệ thống.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String> _resolveLoginEmail(String login) async {
    final normalized = login.trim().toLowerCase();
    if (normalized.contains('@')) return normalized;

    try {
      final result = await _supabase.rpc(
        'resolve_login_email',
        params: {'p_login': normalized},
      );
      final resolved = result?.toString().trim().toLowerCase();
      if (resolved != null && resolved.isNotEmpty) return resolved;
    } catch (e) {
      debugPrint('[AuthProvider._resolveLoginEmail] $e');
    }

    return normalized;
  }

  // ══════════════════════════════════════════════════════════
  // SIGN UP (Cập nhật theo chuẩn Supabase Auth)
  // ══════════════════════════════════════════════════════════
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    clearError();

    if (password.length < 6) {
      _setError('Mật khẩu tối thiểu 6 ký tự');
      _setLoading(false);
      return false;
    }

    try {
      // 1. Đăng ký tài khoản vào hệ thống Auth gốc của Supabase
      final AuthResponse res = await _supabase.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final supabaseUser = res.user;
      if (supabaseUser == null) {
        _setError('Không thể tạo tài khoản');
        return false;
      }

      // 2. Tạo username duy nhất giống logic cũ của bạn
      final baseUsername = email.split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final username = await _generateUniqueUsername(baseUsername);

      // 3. Chèn thông tin meta vào bảng công khai 'users' bằng ID từ Supabase Auth cấp
      await _supabase.from('users').insert({
        'id': supabaseUser.id, // Bắt buộc trùng với ID của bên Auth
        'email': email.trim().toLowerCase(),
        'username': username,
        'display_name': name.trim(),
        'avatar_color': 'red',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Đọc lại profile và stats
      await _loadUserProfile(supabaseUser.id);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Đã xảy ra lỗi trong quá trình đăng ký.');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  // ══════════════════════════════════════════════════════════
  // SIGN OUT (Cập nhật)
  // ══════════════════════════════════════════════════════════
  Future<void> signOut() async {
    _currentUser = null;
    _stats = UserStats.empty;
    clearError();
    
    // Gọi hàm logout của Supabase để xóa token trên thiết bị
    await _supabase.auth.signOut();
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

  Future<void> _enrichUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('is_admin, is_test_account, display_name, avatar_color')
          .eq('id', userId)
          .single();
      if (_currentUser == null) return;
      final u = _currentUser!;
      _currentUser = AppUser(
        id: u.id,
        email: u.email,
        username: u.username,
        displayName: (data['display_name'] as String?) ?? u.displayName,
        isAdmin: (data['is_admin'] as bool?) ?? u.isAdmin,
        isTestAccount: (data['is_test_account'] as bool?) ?? false,
        avatarColor: (data['avatar_color'] as String?) ?? u.avatarColor,
      );
    } catch (e) {
      debugPrint('[AuthProvider._enrichUserProfile] $e');
    }
  }


  Future<void> _loadUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('id, email, username, display_name, is_admin, is_test_account, avatar_color')
          .eq('id', userId)
          .single();

      _currentUser = AppUser.fromMap(data);
      notifyListeners();
    } catch (e) {
      // Nếu lỗi mạng, giữ nguyên _currentUser tạm thời ở hàm initialize() để người dùng không bị văng ra
      debugPrint('[AuthProvider._loadUserProfile Ngầm] Không thể cập nhật profile mới nhất: $e');
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
