// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isLogin = !_isLogin);
    _animCtrl.forward(from: 0);
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    bool success;
    if (_isLogin) {
      success = await auth.login(_phoneCtrl.text.trim(), _passwordCtrl.text);
    } else {
      success = await auth.register(
        _nameCtrl.text.trim(),
        _phoneCtrl.text.trim(),
        _passwordCtrl.text,
      );
    }
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: IEChilliTheme.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _animCtrl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [IEChilliTheme.chilliGlow, IEChilliTheme.chilliDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: IEChilliTheme.chilliRed.withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(child: Text('🌶️', style: TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'IEchilli',
                        style: TextStyle(
                          color: IEChilliTheme.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Text(
                    _isLogin ? 'Welcome back' : 'Create account',
                    style: const TextStyle(
                      color: IEChilliTheme.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? 'Sign in to continue chatting'
                        : 'Join IEchilli today',
                    style: const TextStyle(
                      color: IEChilliTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Error
                  if (auth.error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: IEChilliTheme.chilliRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: IEChilliTheme.chilliRed.withOpacity(0.3)),
                      ),
                      child: Text(
                        auth.error!,
                        style: const TextStyle(color: IEChilliTheme.chilliGlow, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Name field (register only)
                  if (!_isLogin) ...[
                    _buildField(
                      controller: _nameCtrl,
                      hint: 'Full name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                  ],

                  _buildField(
                    controller: _phoneCtrl,
                    hint: 'Phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _passwordCtrl,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: IEChilliTheme.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: IEChilliTheme.chilliRed,
                        foregroundColor: Colors.white,
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
                              _isLogin ? 'Sign in' : 'Create account',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle
                  Center(
                    child: GestureDetector(
                      onTap: _toggle,
                      child: RichText(
                        text: TextSpan(
                          text: _isLogin ? "Don't have an account? " : 'Already have an account? ',
                          style: const TextStyle(color: IEChilliTheme.textSecondary, fontSize: 14),
                          children: [
                            TextSpan(
                              text: _isLogin ? 'Sign up' : 'Sign in',
                              style: const TextStyle(
                                color: IEChilliTheme.chilliGlow,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: IEChilliTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: IEChilliTheme.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: IEChilliTheme.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: IEChilliTheme.textMuted, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          hintStyle: const TextStyle(color: IEChilliTheme.textMuted),
        ),
      ),
    );
  }
}
