import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// USER MODEL — khớp với Firestore document sau này
// ══════════════════════════════════════════════════════════════
class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String role; // 'admin' | 'user'
  final String? avatarUrl; // null → dùng initials

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.role = 'user',
    this.avatarUrl,
  });

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.substring(0, displayName.length.clamp(0, 2)).toUpperCase();
  }

  bool get isAdmin => role == 'admin';

  // TODO Firebase: factory AppUser.fromFirestore(DocumentSnapshot doc) { ... }
}

// ══════════════════════════════════════════════════════════════
// AUTH PROVIDER
// ══════════════════════════════════════════════════════════════
class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String _error = '';

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String get error => _error;

  // ── Tài khoản giả lập (xóa khi kết nối Firebase) ──────────
  static const _fakeAccounts = {
    'admin': {'password': '123', 'uid': 'fake-uid-admin', 'name': 'Admin User', 'email': 'admin@healthapp.vn', 'role': 'admin'},
    'user1': {'password': '123', 'uid': 'fake-uid-user1', 'name': 'Nguyễn Ngọc Thư', 'email': 'thu@healthapp.vn', 'role': 'user'},
  };

  // ── Đăng nhập ──────────────────────────────────────────────
  Future<bool> signIn(String username, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800)); // giả lập network

    // TODO Firebase: thay bằng FirebaseAuth.instance.signInWithEmailAndPassword(...)
    final account = _fakeAccounts[username.trim().toLowerCase()];
    if (account != null && account['password'] == password) {
      _currentUser = AppUser(
        uid: account['uid']!,
        displayName: account['name']!,
        email: account['email']!,
        role: account['role']!,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _error = 'Tài khoản hoặc mật khẩu không đúng.';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ── Tạo tài khoản ─────────────────────────────────────────
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));

    // TODO Firebase:
    //   final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
    //   await cred.user!.updateDisplayName(name);
    //   await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({...});

    // Giả lập: tạo tài khoản tạm thời trong phiên hiện tại
    _currentUser = AppUser(
      uid: 'fake-uid-${DateTime.now().millisecondsSinceEpoch}',
      displayName: name,
      email: email,
      role: 'user',
    );
    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ── Đăng xuất ─────────────────────────────────────────────
  Future<void> signOut() async {
    // TODO Firebase: await FirebaseAuth.instance.signOut();
    _currentUser = null;
    _error = '';
    notifyListeners();
  }

  // ── Khởi động app — kiểm tra phiên đã đăng nhập ───────────
  Future<void> initialize() async {
    // TODO Firebase:
    //   FirebaseAuth.instance.authStateChanges().listen((user) {
    //     if (user != null) { _currentUser = await _fetchUser(user.uid); }
    //     notifyListeners();
    //   });
    notifyListeners();
  }
}
