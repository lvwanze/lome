import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lome/pages/home_page.dart';

class BindSuccessPage extends StatefulWidget {
  final String partnerNickname;

  const BindSuccessPage({
    super.key,
    required this.partnerNickname,
  });

  @override
  State<BindSuccessPage> createState() => _BindSuccessPageState();
}

class _BindSuccessPageState extends State<BindSuccessPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/welcome_bg_3.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ===== 爱心图标 =====
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.favorite,
                    size: 40,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 24),

                // ===== 标题 =====
                const Text(
                  '🎉 绑定成功！',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),

                // ===== 副标题 =====
                Text(
                  '你和 ${widget.partnerNickname} 成为了伴侣',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                // ===== 描述 =====
                const Text(
                  '开启属于你们的旅程吧 💕',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),

                // ===== 开始旅程按钮 =====
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.12),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.20),
                          width: 1.5,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4,
                      ),
                    ),
                    child: const Text('开始旅程'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}