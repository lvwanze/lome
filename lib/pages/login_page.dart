import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lome/services/auth_service.dart';
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
        });
      }
    });
  }

  void _sendCode() async {
    if (_phoneController.text.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📝 写对手机号哦')),
      );
      return;
    }

    setState(() {
      _codeSent = true;
      _countdown = 60;
    });
    _startCountdown();

    try {
      await AuthService().sendCode(_phoneController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('💌 验证码已发送，快去查看')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败：$e')),
      );
      setState(() {
        _codeSent = false;
        _countdown = 0;
      });
    }
  }

  void _login() async {
    if (_phoneController.text.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📝 写对手机号哦')),
      );
      return;
    }

    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔐 输入验证码吧')),
      );
      return;
    }

    // 调用 AuthService 登录（成功返回 User，失败抛异常）
    try {
      final user = await AuthService().login(
        _phoneController.text,
        _codeController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✨ 欢迎回来，${user.nickname} ✨')),
      );
      // ⭐ 关键：跳转到主页
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录失败：$e')),
      );
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
                _buildHandwritingField(
                  controller: _phoneController,
                  label: '手机号',
                  icon: Icons.phone_outlined,
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 24),
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
                    const SizedBox(width: 16),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _codeSent ? null : _sendCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Colors.pink.shade200,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _codeSent ? '$_countdown 秒' : '获取验证码',
                          style: GoogleFonts.caveat(
                            fontSize: 16,
                            color: Colors.pink.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8DCD0),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: Text(
                      '进入我们的世界 →',
                      style: GoogleFonts.caveat(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5D4E3C),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
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
                      Icon(Icons.favorite, size: 12, color: Colors.pink.shade100),
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

