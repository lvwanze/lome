import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:lome/services/auth_service.dart';
import 'package:lome/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeGuidePage extends StatefulWidget {
  const WelcomeGuidePage({super.key});

  @override
  State<WelcomeGuidePage> createState() => _WelcomeGuidePageState();
}

class _WelcomeGuidePageState extends State<WelcomeGuidePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isGenerating = false;
  String _generatedCode = '';

  // 输入绑定码相关
  bool _isSearchMode = false;
  final TextEditingController _bindCodeController = TextEditingController();
  bool _isBinding = false;

  // 动画步数控制
  int _animationStep = 0;

  final List<GuidePageData> _pages = const [
    GuidePageData(
      title: '欢迎来到 LOME',
      subtitle: '你和TA的专属空间',
      showCodeSection: false,
      showStartButton: false,
      isSuccessPage: false,
    ),
    GuidePageData(
      title: '邀请TA',
      subtitle: '一起加入',
      description: '与你喜欢的人，共同开启这段旅程',
      showCodeSection: true,
      showStartButton: false,
      isSuccessPage: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAnimations();
  }

  void _startAnimations() async {
    if (!mounted) return;
    setState(() => _animationStep = 0);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _animationStep = 1);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _animationStep = 2);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _animationStep = 3);
  }

   @override
  void dispose() {
    _bindCodeController.dispose();
    _pageController.dispose();   // ← 新增
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            body: PageView(
        controller: _pageController,
        scrollBehavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: const {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
            PointerDeviceKind.invertedStylus,
          },
        ),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
            if (index != 1) {
              _isSearchMode = false;
              _bindCodeController.clear();
            }
            if (index == 0) {
              _startAnimations();
            }
          });
        },
        children: _pages.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return _buildPage(data, index);
        }).toList(),
      ),
    );
  }

  Widget _buildPage(GuidePageData data, int index) {
    final bgImage = 'assets/images/welcome_bg_${index + 1}.png';
    // 只在第二页(index=1)向左偏移裁剪，隐藏图片右侧封条；首页保持默认居中
    final imageAlignment = index == 1 ? const Alignment(-0.08, 0) : Alignment.center;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(bgImage),
          fit: BoxFit.cover,
          alignment: imageAlignment,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 顶部跳过按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      );
                    },
                    child: Text(
                      '跳过',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (data.showCodeSection)
                      _buildGlassCard(
                        child: Column(
                          children: [
                            Text(
                              '邀请TA',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '一起加入',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '与你喜欢的人，共同开启这段旅程',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.7),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _buildCodeSection(),
                          ],
                        ),
                      )
                    else
                      _buildAnimatedWelcomeContent(),
                  ],
                ),
              ),
            ),

            // 底部指示器
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (pageIndex) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: _currentPage == pageIndex ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == pageIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildAnimatedWelcomeContent() {
    return Column(
      children: [
        if (_animationStep >= 1)
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                const Text(
                  '欢迎来到LOME',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 2,
                  color: Colors.white.withOpacity(0.25),
                ),
              ],
            ),
          ),
        if (_animationStep >= 1) const SizedBox(height: 16),
        if (_animationStep >= 2)
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: const Text(
              '柔软 · 看见 · 成长',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
          ),
        if (_animationStep >= 2) const SizedBox(height: 12),
        if (_animationStep >= 3)
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 25 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: const Text(
              '你们的专属空间',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCodeSection() {
    return Column(
      children: [
        if (_isSearchMode) ...[
          _buildSearchInput(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSearchMode = false;
                    _bindCodeController.clear();
                  });
                },
                child: Text(
                  '返回',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ] else if (_generatedCode.isNotEmpty) ...[
          _buildCodeDisplay(),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _generatedCode = '';
              });
            },
            child: Text(
              '重新生成',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ),
        ] else ...[
          _buildGenerateButton(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '或',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchButton(),
        ],
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.12),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          side: BorderSide(color: Colors.white.withOpacity(0.20), width: 1.5),
          elevation: 0,
        ),
        onPressed: _isGenerating ? null : _generateBindCode,
        child: Text(
          _isGenerating ? '生成中...' : '出示代号',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.95),
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.06),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
          elevation: 0,
        ),
        onPressed: () {
          setState(() {
            _isSearchMode = true;
          });
        },
        child: Text(
          '查找代号',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.95),
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildCodeDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: [
          Text(
            '你的代号',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _generatedCode,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: _generatedCode));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已复制代号')),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
                  ),
                  child: Text(
                    '复制',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '有效期 10 分钟',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _bindCodeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                hintText: '请输入6位代号',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: 14,
                  letterSpacing: 1,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_bindCodeController.text.length == 6)
            GestureDetector(
              onTap: _isBinding ? null : _submitBindCode,
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: _isBinding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      )
                    : Text(
                        '绑定',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Future<void> _generateBindCode() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final code = await AuthService().generateBindCode();
      if (mounted) {
        setState(() {
          _generatedCode = code;
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('代号已生成，发给TA即可')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败：$e')),
        );
      }
    }
  }

  Future<void> _submitBindCode() async {
    if (_isBinding) return;
    final code = _bindCodeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入6位代号')),
      );
      return;
    }
    setState(() => _isBinding = true);
    try {
      final result = await AuthService().useBindCode(code);
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bind_date', DateTime.now().toIso8601String());
        // 返回上一页，带回绑定成功信息
        Navigator.pop(context, {
          'success': true,
          'partnerNickname': result['partnerNickname'],
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBinding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('绑定失败：$e')),
        );
      }
    }
  }
}

class GuidePageData {
  final String title;
  final String subtitle;
  final String description;
  final bool showCodeSection;
  final bool showStartButton;
  final bool isSuccessPage;

  const GuidePageData({
    required this.title,
    required this.subtitle,
    this.description = '',
    this.showCodeSection = false,
    this.showStartButton = false,
    this.isSuccessPage = false,
  });
}