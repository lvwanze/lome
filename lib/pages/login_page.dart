import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lome/services/auth_service.dart';
import 'package:lome/styles/app_theme.dart';
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
  bool _isLoggingIn = false;
  bool _isSendingCode = false;

  // 判断登录按钮是否可点击
  bool get _canLogin {
    return _phoneController.text.length == 11 &&
           _codeController.text.length == 6 &&
           !_isLoggingIn;
  }

  // 判断获取验证码按钮是否可点击
  bool get _canSendCode {
    return _phoneController.text.length == 11 &&
           !_codeSent &&
           !_isSendingCode;
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_countdown > 0 && mounted) {
        setState(() {
          _countdown--;
        });
        _startCountdown();
      } else {
        setState(() {
          _codeSent = false;
          _countdown = 0;
        });
      }
    });
  }

  void _sendCode() async {
    if (!_canSendCode) return;

    setState(() {
      _isSendingCode = true;
    });

    try {
      await AuthService().sendCode(_phoneController.text.trim());

      if (!mounted) return;

      // 发送成功，开始倒计时
      setState(() {
        _codeSent = true;
        _countdown = 60;
        _isSendingCode = false;
      });
      _startCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('💌 验证码已发送，快去查看')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingCode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败：$e')),
      );
    }
  }

  void _login() async {
    if (!_canLogin) return;

    setState(() {
      _isLoggingIn = true;
    });

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
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // ===== Logo区域 =====
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.shade100,
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_outlined,
                          size: 56,
                          color: Colors.pink.shade300,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Lome',
                        style: GoogleFonts.dancingScript(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D4E3C),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '你和TA的专属空间',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // ===== 手机号输入 =====
                _buildHandwritingField(
                  controller: _phoneController,
                  label: '手机号',
                  icon: Icons.phone_outlined,
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 24),

                // ===== 验证码输入 + 获取按钮 =====
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _buildHandwritingField(
                        controller: _codeController,
                        label: '验证码',
                        icon: Icons.mail_outline,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _canSendCode ? _sendCode : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: _canSendCode
                                  ? Colors.pink.shade200
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isSendingCode
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.pink.shade400,
                                ),
                              )
                            : Text(
                                _codeSent ? '$_countdown 秒' : '获取验证码',
                                style: GoogleFonts.caveat(
                                  fontSize: 16,
                                  color: _canSendCode
                                      ? Colors.pink.shade400
                                      : Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // ===== 登录按钮 =====
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canLogin ? _login : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canLogin
                          ? const Color(0xFFE8DCD0)
                          : Colors.grey.shade200,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: _isLoggingIn
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: const Color(0xFF5D4E3C),
                            ),
                          )
                        : Text(
                            '进入我们的世界 →',
                            style: GoogleFonts.caveat(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: _canLogin
                                  ? const Color(0xFF5D4E3C)
                                  : Colors.grey.shade500,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 40),

                // ===== 底部装饰 =====
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.circle_outlined,
                        size: 8,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.favorite,
                        size: 12,
                        color: Colors.pink.shade100,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.circle_outlined,
                        size: 8,
                        color: Colors.grey.shade300,
                      ),
                    ],
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
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.caveat(
            fontSize: 14,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.caveat(
                    fontSize: 18,
                    color: const Color(0xFF5D4E3C),
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
