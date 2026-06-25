import 'package:flutter/material.dart';
import 'package:lome/services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() async {
  // 异步初始化必备
  WidgetsFlutterBinding.ensureInitialized();
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
      // 初始路由：启动闪屏页
      initialRoute: '/splash',
      // 统一路由注册表
      routes: {
        '/splash': (context) => const SplashCheck(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// 启动闪屏 + 登录状态校验
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
    // 闪屏停留1秒
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // 使用命名路由跳转，替换当前页面
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
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