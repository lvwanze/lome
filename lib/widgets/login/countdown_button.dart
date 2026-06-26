import 'dart:async';
import 'package:flutter/material.dart';
import '../../styles/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';

class CountdownButton extends StatefulWidget {
  final TextEditingController phoneController;
  final VoidCallback onSendSuccess;

  const CountdownButton({
    super.key,
    required this.phoneController,
    required this.onSendSuccess,
  });

  @override
  State<CountdownButton> createState() => _CountdownButtonState();
}

class _CountdownButtonState extends State<CountdownButton> {
  int _countdown = 0;
  bool _isLoading = false;
  Timer? _timer;

  bool get _canSend => _countdown == 0 && !_isLoading;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _countdown = 0);
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendCode() async {
    final phone = widget.phoneController.text.trim();

    // 校验手机号
    if (!Validators.isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().sendCode(phone);
      _startCountdown();
      widget.onSendSuccess();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码已发送')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _canSend ? _sendCode : null,
      style: AppTheme.textButtonStyle(),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            )
          : Text(
              _countdown > 0 ? '${_countdown}s' : '获取验证码',
              style: TextStyle(
                color: _canSend ? AppTheme.primaryColor : AppTheme.textHint,
                fontSize: AppTheme.fontSizeNormal,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }
}