import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lome/services/auth_service.dart';
import 'package:lome/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lome/pages/Profile_Page.dart';
import 'package:lome/pages/settings_page.dart';
import 'package:lome/pages/calendar_home_page.dart';
import 'package:lome/pages/message_board_page.dart';
import 'package:lome/pages/slow_message_home_page.dart'; // ✅ 引入慢信主页

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // 退出登录弹窗
// ignore: unused_element
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFDF7F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "退出登录",
          style: GoogleFonts.caveat(
            fontSize: 24,
            color: const Color(0xFF5D4E3C),
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text("确定要退出当前账号吗？"),
        contentTextStyle: TextStyle(color: Colors.grey[600]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("取消", style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("退出登录", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user;
  // ignore: unused_field
  bool _isLoading = true;
  int _selectedTab = 0;
  double _infoEntryScale = 1.0;
  double _settingsScale = 1.0;
  double _chatScale = 1.0;
  double _avatarSwitchScale = 1.0;

  final List<Map<String, dynamic>> _tabs = [
    {'label': '日历', 'icon': 'assets/images/icon_calendar.png'},
    {'label': '留言板', 'icon': 'assets/images/icon_message_board.png'},
    {'label': '慢信', 'icon': 'assets/images/icon_slow_message.png'},
    {'label': '共读', 'icon': 'assets/images/icon_co_read.png'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().getUserInfo();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ✅ 修复核心：使用 Column 加 Expanded 解决溢出
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16.0 : 100.0,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            _buildUserCard(isSmallScreen),
                            const SizedBox(height: 20),
                            _buildDivider(isSmallScreen),
                            const SizedBox(height: 20),
                            _buildCloudButtons(isSmallScreen),
                            // 底部留白，防止内容贴底
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 底部导航固定在底部
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16.0 : 100.0,
                      vertical: 10.0,
                    ),
                    child: _buildBottomNavigation(isSmallScreen),
                  ),
                ],
              ),
              // ✅ 聊天悬浮按钮：移出绝对定位的坑
              _buildChatEntry(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 统一缩放基准：窄屏以 430 为基准，宽屏以 1340 为基准
  // ============================================================
  double _scaleOf(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return (width / 430.0).clamp(0.86, 1.2);
    return width / 1340.0;
  }

  // ============================================================
  // 1. 顶部用户卡片
  // ============================================================
  Widget _buildUserCard(bool isSmallScreen) {
    final s = _scaleOf(context);

    final cardWidth = (isSmallScreen ? 330.0 : 550.0) * s;
    final cardHeight = (isSmallScreen ? 88.0 : 180.0) * s;
    final cardY = (isSmallScreen ? 8.0 : 10.0) * s;

    final avatarSize = (isSmallScreen ? 56.0 : 90.0) * s;
    final fontSize = (isSmallScreen ? 19.0 : 26.0) * s;
    final settingsSize = (isSmallScreen ? 44.0 : 54.0) * s;

    return Padding(
      padding: EdgeInsets.only(top: cardY),
      child: SizedBox(
        height: cardHeight,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: _buildUserInfoEntry(
                cardWidth: cardWidth,
                cardHeight: cardHeight,
                avatarSize: avatarSize,
                fontSize: fontSize,
              ),
            ),
            Positioned(
              right: 0,
              top: (cardHeight - settingsSize) / 2,
              child: _buildSettingsButton(size: settingsSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isSmallScreen) {
    return Center(
      child: Container(
        width: isSmallScreen ? double.infinity : 1600.0,
        height: 10.0,
        decoration: BoxDecoration(
          color: const Color(0xFFAFC5AE).withOpacity(0.3),
          borderRadius: BorderRadius.circular(100.0),
        ),
      ),
    );
  }

  // ============================================================
  // 2. 用户信息入口
  // ============================================================
  Widget _buildUserInfoEntry({
    required double cardWidth,
    required double cardHeight,
    required double avatarSize,
    required double fontSize,
  }) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _infoEntryScale = 0.92),
      onTapUp: (_) => setState(() => _infoEntryScale = 1.0),
      onTapCancel: () => setState(() => _infoEntryScale = 1.0),
      onTap: () {
        _onTapWithHaptic(() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfilePage(isBound: _user?.isBound ?? false),
            ),
          ).then((result) {
            if (result == true) {
              _loadUserData();
            }
          });
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        curve: Curves.elasticOut,
        scale: _infoEntryScale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              width: cardWidth,
              height: cardHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD9D9D9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      (_user?.nickname ?? 'USERNAME'),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 3. 设置按钮
  // ============================================================
  Widget _buildSettingsButton({required double size}) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _settingsScale = 0.92),
      onTapUp: (_) => setState(() => _settingsScale = 1.0),
      onTapCancel: () => setState(() => _settingsScale = 1.0),
      onTap: () {
        _onTapWithHaptic(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        curve: Curves.elasticOut,
        scale: _settingsScale,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/settings_icon.png',
              width: size * 0.72,
              height: size * 0.72,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 5. 云朵互动按钮
  // ============================================================
  Widget _buildCloudButtons(bool isSmallScreen) {
    final s = _scaleOf(context);

    final buttonWidth = (isSmallScreen ? 118.0 : 260.0) * s;
    final buttonHeight = buttonWidth * 0.54;
    final fontSize = (isSmallScreen ? 17.0 : 36.0) * s;
    final switchSize = (isSmallScreen ? 42.0 : 56.0) * s;

    final interactions = <Map<String, dynamic>>[
      {'label': '干杯', 'image': 'assets/images/button_cloud.png', 'x': 0.03, 'y': 0.14},
      {'label': '抱抱', 'image': 'assets/images/button_cloud.png', 'x': 0.26, 'y': 0.66},
      {'label': '贴贴', 'image': 'assets/images/button_cloud.png', 'x': 0.60, 'y': 0.36},
    ];

    final areaHeight = (isSmallScreen ? 380.0 : 580.0) * _scaleOf(context);

    return SizedBox(
      height: areaHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final areaWidth = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ...interactions.map((item) {
                return Positioned(
                  left: (item['x'] as double) * areaWidth,
                  top: (item['y'] as double) * areaHeight,
                  child: CloudButton(
                    label: item['label'] as String,
                    image: item['image'] as String,
                    width: buttonWidth,
                    height: buttonHeight,
                    fontSize: fontSize,
                  ),
                );
              }),
              Positioned(
                left: areaWidth * 0.5 - switchSize / 2,
                top: areaHeight - switchSize - 4,
                child: _buildSwitchAvatarButton(switchSize),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchAvatarButton(double buttonSize) {

    return GestureDetector(
      onTapDown: (_) => setState(() => _avatarSwitchScale = 0.85),
      onTapUp: (_) => setState(() => _avatarSwitchScale = 1.0),
      onTapCancel: () => setState(() => _avatarSwitchScale = 1.0),
      onTap: () {
        _onTapWithHaptic(() {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔄 切换虚拟形象'),
              duration: Duration(seconds: 1),
            ),
          );
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        curve: Curves.elasticOut,
        scale: _avatarSwitchScale,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.20),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.autorenew,
            color: Colors.white.withOpacity(0.7),
            size: buttonSize * 0.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 7. 聊天入口按钮 (✅ 修复：改为使用 Align 或 Positioned 且不超出屏幕边界)
  // ============================================================
  Widget _buildChatEntry(bool isSmallScreen) {
    final entryWidth = (isSmallScreen ? 76.0 : 110.0) * _scaleOf(context);
    final entryHeight = entryWidth * 1.35;

    // 固定在右侧偏上的位置
    return Positioned(
      right: isSmallScreen ? 10 : 30,
      top: MediaQuery.of(context).size.height * 0.45, // 屏幕中间偏上
      child: GestureDetector(
        onTapDown: (_) => setState(() => _chatScale = 0.92),
        onTapUp: (_) => setState(() => _chatScale = 1.0),
        onTapCancel: () => setState(() => _chatScale = 1.0),
        onTap: () {
          _onTapWithHaptic(() {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('💬 聊天功能开发中')),
            );
          });
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          curve: Curves.elasticOut,
          scale: _chatScale,
          child: Container(
            width: entryWidth,
            height: entryHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/images/mess.png',
                width: entryWidth * 0.55,
                height: entryWidth * 0.55,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 8. 底部导航
  // ============================================================
  Widget _buildBottomNavigation(bool isSmallScreen) {
    final s=_scaleOf(context);
    final iconSize= (isSmallScreen ? 32.0 : 48.0) * _scaleOf(context);
    final fontSize = (isSmallScreen ? 12.0 : 14.0) * _scaleOf(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          height: (isSmallScreen ? 80 : 110) * _scaleOf(context),
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) {
              final isSelected = _selectedTab == index;
              return GestureDetector(
                onTap: () {
                  _onTapWithHaptic(() {
                    setState(() {
                      _selectedTab = index;
                    });

                    switch (index) {
                      case 0:
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CalendarPage(),
                          ),
                        );
                        break;
                      case 1:
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MessageBoardPage(),
                          ),
                        );
                        break;
                      case 2:
                        // ✅ 跳转慢信主页
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SlowMessageHomePage(),
                          ),
                        );
                        break;
                      case 3:
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('共读开发中')),
                        );
                        break;
                    }
                  });
                },
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  scale: isSelected ? 1.12 : 1.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        _tabs[index]['icon'] as String,
                        width: iconSize,
                        height: iconSize,
                      ),
                      SizedBox(height: 4*_scaleOf(context)),
                      Text(
                        _tabs[index]['label'] as String,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.6),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 通用：点击弹动反馈
  // ============================================================
  void _onTapWithHaptic(VoidCallback action) {
    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android) {
      HapticFeedback.lightImpact();
    }
    action();
  }
}

// ============================================================
// CloudButton 云朵按钮组件（保持不变）
// ============================================================
class CloudButton extends StatefulWidget {
  final String label;
  final String image;
  final double width;
  final double height;
  final double fontSize;

  const CloudButton({
    super.key,
    required this.label,
    required this.image,
    required this.width,
    required this.height,
    required this.fontSize,
  });

  @override
  State<CloudButton> createState() => _CloudButtonState();
}

class _CloudButtonState extends State<CloudButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onTap() {
    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android) {
      HapticFeedback.lightImpact();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💕 发送了 ${widget.label}！'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    widget.image,
                    width: widget.width,
                    height: widget.height,
                    color: Colors.white.withOpacity(0.9),
                    fit: BoxFit.contain,
                  ),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFEBD9D9),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}