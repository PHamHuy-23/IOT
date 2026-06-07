# HƯỚNG DẪN TÍCH HỢP AUTH VÀO DASHBOARD

## 1. Thêm vào pubspec.yaml
Không cần thêm package mới — dùng provider (đã có).

## 2. Đăng ký AuthProvider trong main.dart
```dart
import 'providers/auth_provider.dart';

// Trong MultiProvider:
ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
```

## 3. Thay _buildConnectionChip() trong DashboardScreen

Thay toàn bộ actions: [_buildConnectionChip(provider)] bằng:

```dart
actions: [
  _buildConnectionChip(provider),
  _buildAvatarButton(), // thêm dòng này
],
```

Thêm method mới vào _DashboardScreenState:

```dart
Widget _buildAvatarButton() {
  return Padding(
    padding: const EdgeInsets.only(right: 14),
    child: Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return GestureDetector(
          onTap: () => _openProfileOrAuth(auth),
          child: auth.isLoggedIn
              ? Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.accentRed, AppTheme.accentPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: AppTheme.subtleGrey, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      auth.currentUser!.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.cardDark,
                    border: Border.all(color: AppTheme.subtleGrey, width: 1),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.mutedGrey,
                    size: 18,
                  ),
                ),
        );
      },
    ),
  );
}

void _openProfileOrAuth(AuthProvider auth) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          auth.isLoggedIn ? const ProfileScreen() : const AuthScreen(),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1), // slide từ dưới lên
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}
```

## 4. Import thêm vào đầu dashboard_screen.dart
```dart
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';
```

## 5. Dữ liệu giả lập sẵn sàng cho Firebase
- auth_provider.dart có các TODO comment rõ ràng
- Khi cần Firebase: xóa _fakeAccounts, bỏ comment phần Firebase
- AppUser model đã sẵn sàng với fromFirestore factory

## Tài khoản demo
| Username | Password | Role  |
|----------|----------|-------|
| admin    | 123      | Admin |
| user1    | 123      | User  |
