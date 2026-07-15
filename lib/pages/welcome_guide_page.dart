import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lome/services/auth_service.dart';
import 'package:lome/pages/home_page.dart';

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

  // 绑定成功相关
  bool _showSuccessPage = false;
  String _partnerNickname = '';

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
    GuidePageData(
      title: '准备好了吗',
      subtitle: '',
      description: '开始你们的专属旅程',
      showCodeSection: false,
      showStartButton: true,
      isSuccessPage: false,
    ),
    GuidePageData(
      title: '🎉 绑定成功！',
      subtitle: '',  // 动态填入伴侣昵称
      description: '开启属于你们的旅程吧 💕',
      showCodeSection: false,
      showStartButton: true,
      isSuccessPage: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAnimations();
  }

  void _startAnimations() async {
    setState(() => _animationStep = 0);
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() => _animationStep = 1);
    await Future.delayed(const Duration(milliseconds: 1200));

    setState(() => _animationStep = 2);
    await Future.delayed(const Duration(milliseconds: 1200));

    setState(() => _animationStep = 3);
  }

  @override
  void dispose() {
    _bindCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
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
    final isSuccess = data.isSuccessPage && _showSuccessPage;
    final displaySubtitle = isSuccess
        ? '你和 $_partnerNickname 成为了伴侣'
        : data.subtitle;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(bgImage),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ===== 顶部：跳过按钮（成功页隐藏） =====
            if (!isSuccess)
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
                    if (data.showCodeSection) ...[
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
                      ),
                    ],

                    if (!data.showCodeSection) ...[
                      if (index == 0) ...[
                        _buildAnimatedWelcomeContent(),
                      ] else if (isSuccess) ...[
                        // ✅ 第4页：绑定成功
                        Column(
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 72,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              data.title,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              displaySubtitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.6),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 40),
                            _buildStartButton(label: '开始旅程'),
                          ],
                        ),
                      ] else ...[
                        // 第3页：准备好了吗
                        if (data.title.isNotEmpty)
                          Text(
                            data.title,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (displaySubtitle.isNotEmpty)
                          Text(
                            displaySubtitle,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (data.description.isNotEmpty)
                          Text(
                            data.description,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 1,
                            ),
                          ),
                        const SizedBox(height: 40),
                        if (data.showStartButton) _buildStartButton(),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            if (!isSuccess)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 1200),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
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

  // ===== 欢迎页动画内容 =====
  Widget _buildAnimatedWelcomeContent() {
    return Column(
      children: [
        if (_animationStep >= 1)
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, opacity, child) {
              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, (1 - opacity) * 50),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                Text(
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
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
              ],
            ),
          ),

        if (_animationStep >= 1) const SizedBox(height: 16),

        if (_animationStep >= 2)
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, opacity, child) {
              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, (1 - opacity) * 30),
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
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, opacity, child) {
              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, (1 - opacity) * 25),
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

  // ===== 毛玻璃卡片 =====
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
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ===== 核心功能区域 =====
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

  // ===== 出示代号按钮 =====
  Widget _buildGenerateButton() {
    return GestureDetector(
      onTap: _generateAndShowCode,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(0.20),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(width: 12),
            Text(
              _isGenerating ? '生成中...' : '出示代号',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.95),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 查找代号按钮 =====
  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSearchMode = true;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(width: 12),
            Text(
              '查找代号',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.95),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 绑定码展示 =====
  Widget _buildCodeDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
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
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _generatedCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已复制代号'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 0.5,
                    ),
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

  // ===== 查找输入框 =====
  Widget _buildSearchInput() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.5,
            ),
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
                  onTap: _handleBindCode,
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
        ),
      ],
    );
  }

  // ===== 生成绑定码 =====
  Future<void> _generateAndShowCode() async {
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
          const SnackBar(
            content: Text('代号已生成，复制发给TA吧'),
            duration: Duration(seconds: 1),
          ),
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

  // ===== 使用绑定码 =====
  Future<void> _handleBindCode() async {
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
        setState(() {
          _showSuccessPage = true;
          _partnerNickname = result['partnerNickname']!;
        });
        _pageController.jumpToPage(3);
        ScaffoldMessenger.of(context).clearSnackBars();
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

  // ===== 开始按钮 =====
  Widget _buildStartButton({String label = '开始'}) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(0.20),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
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