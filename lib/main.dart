import 'package:flutter/material.dart';
import 'pages/login_page.dart';

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
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}