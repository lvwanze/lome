import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lome/services/auth_service.dart';
import 'package:lome/pages/welcome_guide_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _codeSent = false;
  int _countdown = 0;
  bool _isLoading = false;

  bool get _canLogin =>
      _phoneController.text.length == 11 &&
      _codeController.text.length == 6 &&
      !_isLoading;

  bool get _canSendCode =>
      _phoneController.text.length == 11 && !_codeSent && !_isLoading;

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_countdown > 0 && mounted) {
        setState(() => _countdown--);
        _startCountdown();
      } else if (mounted) {
        setState(() => _codeSent = false);
      }
    });
  }

  void _sendCode() async {
    if (!_canSendCode) return;

    setState(() => _isLoading = true);

    try {
      await AuthService().sendCode(_phoneController.text.trim());

      if (!mounted) return;

      setState(() {
        _codeSent = true;
        _countdown = 60;
        _isLoading = false;
      });
      _startCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('💌 验证码已发送，快去查看')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败：$e')),
      );
    }
  }

  void _login() async {
    if (!_canLogin) return;

    setState(() => _isLoading = true);

    try {
      final user = await AuthService().login(
        _phoneController.text.trim(),
        _codeController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✨ 欢迎回来，${user.nickname} ✨')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeGuidePage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/login_bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Lome",
                        style: TextStyle(
                          fontSize: 90,
                          fontWeight: FontWeight.w300,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFFF9F290), Color(0xFFFFE8E8)],
                            ).createShader(const Rect.fromLTWH(0, 0, 220, 100)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "你和TA的专属空间",
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF888888),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),

                // ===== 毛玻璃卡片 =====
                ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildGlassInputField(
                            controller: _phoneController,
                            label: '手机号',
                            icon: Icons.phone_outlined,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _buildGlassInputField(
                                  controller: _codeController,
                                  label: '验证码',
                                  icon: Icons.mail_outline,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _canSendCode ? _sendCode : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.12),
                                    foregroundColor: Colors.white,
                                    splashFactory: NoSplash.splashFactory,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.20),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: _isLoading && !_codeSent
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white70,
                                          ),
                                        )
                                      : Text(
                                          _codeSent ? '$_countdown s' : '获取验证码',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ===== 登录按钮（毛玻璃风格） =====
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canLogin ? _login : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canLogin
                          ? Colors.white.withOpacity(0.15)
                          : Colors.white.withOpacity(0.06),
                      foregroundColor: Colors.white,
                      splashFactory: NoSplash.splashFactory,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                        side: BorderSide(
                          color: _canLogin
                              ? Colors.white.withOpacity(0.25)
                              : Colors.white.withOpacity(0.10),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: _isLoading && _codeSent
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white70,
                            ),
                          )
                        : const Text(
                            "进入我们的世界 →",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.12),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.12),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            prefixIcon: Icon(icon, size: 20, color: Colors.white38),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            hintStyle: TextStyle(
              color: Colors.white30,
              fontSize: 14,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}