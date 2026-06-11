import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../themes/app_theme.dart';

// ══════════════════════════════════════════════════════════════
// AUTH SCREEN — Đăng nhập / Tạo tài khoản
// ══════════════════════════════════════════════════════════════
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _obscure = true;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  // Đăng nhập: username hoặc email — đăng ký: email
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _loginCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Chuyển mode login ↔ signup ───────────────────────────
  void _toggleMode() {
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _isLogin = !_isLogin;
        _formKey.currentState?.reset();
        _nameCtrl.clear();
        _loginCtrl.clear();
        _passCtrl.clear();
        context.read<AuthProvider>().clearError();
      });
      _fadeCtrl.forward();
    });
  }

  // ── Submit ───────────────────────────────────────────────
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    bool success;

    if (_isLogin) {
      // XỬ LÝ CHO TÀI KHOẢN CŨ:
      String loginInput = _loginCtrl.text.trim();
      
      // Nếu là username thô (không có @), tự động nối đuôi legacy.local
      if (!loginInput.contains('@')) {
        loginInput = '$loginInput@legacy.local';
      }

      success = await auth.signIn(
        loginInput,
        _passCtrl.text,
      );
    } else {
      success = await auth.signUp(
        name: _nameCtrl.text.trim(),
        email: _loginCtrl.text.trim(),
        password: _passCtrl.text,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  // ── Tự điền demo ────────────────────────────────────────
  void _fillDemo(String login, String pass) {
    _loginCtrl.text = login;
    _passCtrl.text = pass;
    // Xoá lỗi cũ nếu có
    context.read<AuthProvider>().clearError();
    setState(() {});
  }

  // ── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: Column(
          children: [
            // Thanh trên
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(color: AppTheme.accentRed, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // Logo
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.accentRed, AppTheme.accentPurple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          _isLogin ? 'Xin chào!' : 'Tạo tài khoản',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLogin
                              ? 'Đăng nhập để lưu & theo dõi sức khỏe'
                              : 'Bắt đầu hành trình sức khỏe của bạn',
                          style: const TextStyle(
                            color: AppTheme.mutedGrey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Họ tên — chỉ signup
                        if (!_isLogin) ...[
                          _buildField(
                            controller: _nameCtrl,
                            label: 'Họ và tên',
                            hint: 'Nguyễn Văn A',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nhập họ tên của bạn'
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Username / Email
                        _buildField(
                          controller: _loginCtrl,
                          label: _isLogin ? 'Tài khoản hoặc email' : 'Email',
                          hint: _isLogin ? 'admin hoặc admin@health.app' : 'email@example.com',
                          icon: _isLogin
                              ? Icons.person_rounded
                              : Icons.email_outlined,
                          keyboardType: _isLogin
                              ? TextInputType.emailAddress
                              : TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return _isLogin
                                  ? 'Nhập tên tài khoản hoặc email'
                                  : 'Nhập địa chỉ email';
                            }
                            if (!_isLogin && !v.contains('@')) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Mật khẩu
                        _buildField(
                          controller: _passCtrl,
                          label: 'Mật khẩu',
                          hint: '••••••',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppTheme.mutedGrey,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Nhập mật khẩu';
                            if (!_isLogin && v.length < 6) {
                              return 'Tối thiểu 6 ký tự';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 28),

                        // Nút submit + error message
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return Column(
                              children: [
                                // Error banner
                                if (auth.error.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: Colors.redAccent,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            auth.error,
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Submit button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: auth.isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentRed,
                                      disabledBackgroundColor:
                                          AppTheme.accentRed.withOpacity(0.5),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            _isLogin
                                                ? 'Đăng nhập'
                                                : 'Tạo tài khoản',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Phân cách
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                  color: AppTheme.subtleGrey, thickness: 0.5),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'hoặc',
                                style: TextStyle(
                                    color: AppTheme.mutedGrey, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                  color: AppTheme.subtleGrey, thickness: 0.5),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Chuyển mode
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _toggleMode,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppTheme.subtleGrey, width: 0.5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              _isLogin
                                  ? 'Tạo tài khoản mới'
                                  : 'Đã có tài khoản? Đăng nhập',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),

                        // Demo hint — chỉ hiện khi login mode
                        if (_isLogin) ...[
                          const SizedBox(height: 20),
                          _DemoHint(onFill: _fillDemo),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Text field dùng chung ─────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            const TextStyle(color: AppTheme.mutedGrey, fontSize: 13),
        hintStyle:
            const TextStyle(color: AppTheme.subtleGrey, fontSize: 14),
        prefixIcon: Icon(icon, color: AppTheme.mutedGrey, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.cardDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.accentRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DEMO HINT WIDGET
// Tách ra widget riêng để gọn — hiện các tài khoản demo
// ══════════════════════════════════════════════════════════════
class _DemoHint extends StatelessWidget {
  final void Function(String login, String pass) onFill;

  const _DemoHint({required this.onFill});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDarker,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppTheme.mutedGrey, size: 14),
              SizedBox(width: 6),
              Text(
                'Tài khoản demo  •  mật khẩu: 123456',
                style: TextStyle(
                  color: AppTheme.mutedGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DemoRow(
            label: 'Admin',
            login: 'admin',
            onTap: () => onFill('admin', '123456'),
          ),
          const SizedBox(height: 4),
          _DemoRow(
            label: 'Nguyễn Văn A',
            login: 'vana',
            onTap: () => onFill('vana', '123456'),
          ),
          const SizedBox(height: 4),
          _DemoRow(
            label: 'Lê Thị B',
            login: 'lethib',
            onTap: () => onFill('lethib', '123456'),
          ),
        ],
      ),
    );
  }
}

class _DemoRow extends StatelessWidget {
  final String label;
  final String login;
  final VoidCallback onTap;

  const _DemoRow({
    required this.label,
    required this.login,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              login,
              style: const TextStyle(
                color: AppTheme.mutedGrey,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            const Text(
              'Điền',
              style: TextStyle(color: AppTheme.accentRed, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}