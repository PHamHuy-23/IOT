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
  final _userCtrl = TextEditingController(); // username (login) hoặc email (signup)
  final _passCtrl = TextEditingController();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _fadeCtrl.reverse().then((_) {
      setState(() {
        _isLogin = !_isLogin;
        _formKey.currentState?.reset();
        _nameCtrl.clear();
        _userCtrl.clear();
        _passCtrl.clear();
      });
      _fadeCtrl.forward();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    bool success;

    if (_isLogin) {
      success = await auth.signIn(_userCtrl.text.trim(), _passCtrl.text);
    } else {
      success = await auth.signUp(
        name: _nameCtrl.text.trim(),
        email: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Thanh trên ──
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

                        // ── Logo ──
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

                        // ── Họ tên (chỉ signup) ──
                        if (!_isLogin) ...[
                          _buildField(
                            controller: _nameCtrl,
                            label: 'Họ và tên',
                            hint: 'Nguyễn Văn A',
                            icon: Icons.person_outline_rounded,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Nhập họ tên của bạn' : null,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── Username / Email ──
                        _buildField(
                          controller: _userCtrl,
                          label: _isLogin ? 'Tài khoản' : 'Email',
                          hint: _isLogin ? 'admin' : 'email@example.com',
                          icon: _isLogin
                              ? Icons.person_rounded
                              : Icons.email_outlined,
                          keyboardType: _isLogin
                              ? TextInputType.text
                              : TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return _isLogin
                                  ? 'Nhập tên tài khoản'
                                  : 'Nhập địa chỉ email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // ── Mật khẩu ──
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
                            onPressed: () => setState(() => _obscure = !_obscure),
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

                        // ── Nút submit ──
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return Column(
                              children: [
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
                                        const Icon(Icons.error_outline_rounded,
                                            color: Colors.redAccent, size: 16),
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
                                        borderRadius: BorderRadius.circular(14),
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
                                            _isLogin ? 'Đăng nhập' : 'Tạo tài khoản',
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

                        // ── Phân cách ──
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: AppTheme.subtleGrey,
                                    thickness: 0.5)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'hoặc',
                                style: TextStyle(
                                    color: AppTheme.mutedGrey, fontSize: 13),
                              ),
                            ),
                            Expanded(
                                child: Divider(
                                    color: AppTheme.subtleGrey,
                                    thickness: 0.5)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Chuyển mode ──
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _toggleMode,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppTheme.subtleGrey, width: 0.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
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

                        // ── Gợi ý demo ──
                        if (_isLogin)
                          Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.cardDarker,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded,
                                          color: AppTheme.mutedGrey, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Tài khoản demo',
                                        style: TextStyle(
                                          color: AppTheme.mutedGrey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _demoFill('Admin', 'admin', '123'),
                                  const SizedBox(height: 4),
                                  _demoFill('User 1', 'user1', '123'),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),
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

  // ── Nút tự điền demo ──────────────────────────────────────
  Widget _demoFill(String label, String user, String pass) {
    return GestureDetector(
      onTap: () {
        _userCtrl.text = user;
        _passCtrl.text = pass;
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text(
              '$user / $pass',
              style: const TextStyle(
                  color: AppTheme.mutedGrey, fontSize: 12),
            ),
            const Spacer(),
            const Text('Điền', style: TextStyle(color: AppTheme.accentRed, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ── Shared text field ─────────────────────────────────────
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
        labelStyle: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13),
        hintStyle: const TextStyle(color: AppTheme.subtleGrey, fontSize: 14),
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
          borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}
