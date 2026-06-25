import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lome/services/cloudbase_service.dart';
import 'package:lome/services/auth_service.dart';
import 'home_page.dart';
import 'package:lome/utils/validators.dart';

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

    final result = await CloudBaseService().callFunction('sendSms', {
      'phone': _phoneController.text,
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('💌 验证码已发送，快去查看')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败：${result['message']}')),
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

    // 调用 AuthService 登录
    final result = await AuthService().login(
      _phoneController.text,
      _codeController.text,
    );

    print('登录结果: $result');

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✨ 欢迎回来，${_phoneController.text} ✨')),
      );

      // ⭐ 关键：跳转到主页
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录失败：${result['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // 背景图路径保持不变
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
                // 1. 替换原爱心头部，渐变Lome标题
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

                // 2. 手机号+验证码统一半透圆角大容器
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
                        icon: Icons.circle,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _buildHandwritingField(
                              controller: _codeController,
                              label: '验证码',
                              icon: Icons.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _codeSent ? null : _sendCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.45),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  side: const BorderSide(color: Color(0xFFD8CFC0)),
                                ),
                              ),
                              child: Text(
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
                // 3. 底部登录按钮新样式
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.35),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                        side: const BorderSide(color: Color(0xFFD8CFC0)),
                      ),
                    ),
                    child: const Text(
                      "进入我们的世界→",
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF776655),
                      ),
                    ),
                  ),
                ),
                // 删除底部爱心小点装饰
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 4. 重写输入框组件，匹配圆角填充样式
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
            prefixIcon: Icon(icon, size: 12, color: const Color(0xFFD0C8BB)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

