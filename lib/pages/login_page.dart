import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lome/services/auth_service.dart';
import 'package:lome/services/cloudbase_service.dart';
import 'package:lome/utils/validators.dart';
import 'home_page.dart';

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
        MaterialPageRoute(builder: (context) => const HomePage()),
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
                const SizedBox(height: 100),
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
                const SizedBox(height: 100),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.42),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: const Color(0xFFD8CFC0), width: 1),
                  ),
                  child: Column(
                    children: [
                      _buildHandwritingField(
                        controller: _phoneController,
                        label: '手机号',
                        icon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _buildHandwritingField(
                              controller: _codeController,
                              label: '验证码',
                              icon: Icons.mail_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _canSendCode ? _sendCode : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.45),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  side: const BorderSide(color: Color(0xFFD8CFC0)),
                                ),
                              ),
                              child: _isLoading && !_codeSent
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF665544),
                                      ),
                                    )
                                  : Text(
                                      _codeSent ? '$_countdown s后重发' : '获取验证码',
                                      style: const TextStyle(
                                        color: Color(0xFF665544),
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _canLogin ? _login : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canLogin
                          ? Colors.white.withOpacity(0.35)
                          : Colors.white.withOpacity(0.15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                        side: BorderSide(
                          color: _canLogin
                              ? const Color(0xFFD8CFC0)
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: _isLoading && _codeSent
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF776655),
                            ),
                          )
                        : const Text(
                            "进入我们的世界 →",
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFF776655),
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

  Widget _buildHandwritingField({
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
            fontSize: 16,
            color: Color(0xFF665544),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF5D4E3C),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: const BorderSide(color: Color(0xFFD8CFC0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: const BorderSide(color: Color(0xFFD8CFC0)),
            ),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFFD0C8BB)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}