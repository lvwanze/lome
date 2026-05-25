import 'package:flutter/material.dart';
import 'package:lome/services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const LomeApp());
}

class LomeApp extends StatelessWidget {
  const LomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lome',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        useMaterial3: true,
      ),
      home: const SplashCheck(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashCheck extends StatefulWidget {
  const SplashCheck({super.key});

  @override
  State<SplashCheck> createState() => _SplashCheckState();
}

class _SplashCheckState extends State<SplashCheck> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final isLoggedIn = await AuthService().isLoggedIn();
    
    // 延迟1秒，显示启动画面
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                size: 40,
                color: Colors.pink.shade300,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Lome',
              style: const TextStyle(
                fontSize: 32,
                color: Color(0xFF5D4E3C),
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}