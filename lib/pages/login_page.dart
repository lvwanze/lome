import 'package:flutter/material.dart';
import 'package:lome/services/auth_service.dart';
import 'package:lome/pages/home_page.dart';

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

  // 按钮是否可点击
  bool get _canLogin =>
      _phoneController.text.length == 11 &&
      _codeController.text.length == 6 &&
      !_isLoading;

  bool get _canSendCode =>
      _phoneController.text.length == 11 && !_codeSent && !_isLoading;

  // ===== 倒计时 =====
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

  // ===== 发送验证码 =====
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
        const SnackBar(content: Text('验证码已发送')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败：$e')),
      );
    }
  }

  // ===== 登录 =====
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
        SnackBar(content: Text('欢迎回来，${user.nickname}')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ===== Logo =====
              const Icon(
                Icons.favorite_outlined,
                size: 64,
                color: Color(0xFFE8739A),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lome',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8739A),
                ),
              ),
              const SizedBox(height: 48),

              // ===== 手机号 =====
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  hintText: '请输入手机号',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // ===== 验证码 + 按钮 =====
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: '验证码',
                        hintText: '6位数字',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _canSendCode ? _sendCode : null,
                    child: _isLoading && !_codeSent
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_codeSent ? '$_countdown s' : '获取'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ===== 登录按钮 =====
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _canLogin ? _login : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canLogin
                        ? const Color(0xFFE8739A)
                        : Colors.grey.shade300,
                  ),
                  child: _isLoading && _codeSent
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '登录',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
