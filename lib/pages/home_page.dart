import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lome/services/auth_service.dart';
import 'package:lome/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lome/pages/Profile_Page.dart';
import 'package:lome/pages/settings_page.dart';
import 'package:lome/pages/calendar_home_page.dart';


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
          // 取消按钮
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "取消",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          // 退出登录按钮
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              "退出登录",
              style: TextStyle(color: Colors.white),
            ),
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
      print('📦 昵称: ${user.nickname}');
      print('📦 绑定状态: ${user.isBound}');
      print('📦 伴侣昵称: ${user.partnerNickname}');
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
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16.0 : 100.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,  // ✅ 上下分散排列
                  children: [
                    // 顶部内容
                    Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildUserCard(isSmallScreen),
                        const SizedBox(height: 20),      // 调整间距
                        _buildDivider(isSmallScreen),    // ✅ 新增分割条
                        const SizedBox(height: 20),      // 调整间距
                        _buildCloudButtons(isSmallScreen),

                      ],
                    ),
                    // 底部导航
                    _buildBottomNavigation(isSmallScreen),
                  ],
                ),
              ),
              _buildChatEntry(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 1. 顶部用户卡片
  // ============================================================
  Widget _buildUserCard(bool isSmallScreen) {
    const baseWidth = 1340.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / baseWidth;

    final cardWidth = 550.0 * scaleFactor;
    final cardHeight = 180.0 * scaleFactor;
    final cardX = 10.0 * scaleFactor;
    final cardY = 10.0 * scaleFactor;

    final avatarSize = 90.0;
    final fontSize = isSmallScreen ? 18.0 : 26.0;

    return Padding(
      padding: EdgeInsets.only(top: cardY),
      child: SizedBox(
        height: cardHeight,
        child: Stack(
          children: [
            Positioned(
              left: cardX,
              child: _buildUserInfoEntry(
                cardWidth: cardWidth,
                cardHeight: cardHeight,
                avatarSize: avatarSize,
                fontSize: fontSize,
              ),
            ),
            Positioned(
              right: isSmallScreen ? 16 : 40,
              top: (cardHeight - avatarSize * 0.7) / 2,
              child: _buildSettingsButton(avatarSize: avatarSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isSmallScreen) {
    return Center(
      child:Container(
        width: isSmallScreen ? 400.0 : 1600.0,
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
              builder: (_) => ProfilePage(
                isBound: _user?.isBound ?? false,
              ),
            ),
          );
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
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
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
  Widget _buildSettingsButton({required double avatarSize}) {
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
          width: avatarSize * 0.6,
          height: avatarSize * 0.6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Image.asset(
            'assets/images/settings_icon.png',
            width: avatarSize * 0.8,
            height: avatarSize * 0.8,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }


  // ============================================================
  // 5. 云朵互动按钮
  // ============================================================
  Widget _buildCloudButtons(bool isSmallScreen) {
    const baseWidth = 1340.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / baseWidth;

    final buttonWidth = 260.0 * scaleFactor;
    final buttonHeight = 140.0 * scaleFactor;
    final fontSize = 36.0 * scaleFactor;

    // ✅ 所有 y 值在 0.0~1.0 之间，保证点击正常
    final interactions = [
      {'label': '干杯', 'image': 'assets/images/button_cloud.png', 'x': 0.05, 'y': 0.20},
      {'label': '抱抱', 'image': 'assets/images/button_cloud.png', 'x': 0.30, 'y': 0.80},
      {'label': '贴贴', 'image': 'assets/images/button_cloud.png', 'x': 0.60, 'y': 0.50},
    ];

    const double areaSize = 580;

    return SizedBox(
      height: areaSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 云朵按钮
          ...interactions.map((item) {
            return Positioned(
              left: (item['x'] as double) * areaSize,
              top: (item['y'] as double) * areaSize,
              child: CloudButton(
                label: item['label'] as String,
                image: item['image'] as String,
                width: buttonWidth,
                height: buttonHeight,
                fontSize: fontSize,
              ),
            );
          }).toList(),
          // ✅ 切换虚拟形象按钮（抱抱正下方居中）
          Positioned(
            left: 0.34 * areaSize,
            top: 0.94 * areaSize,
            child: _buildSwitchAvatarButton(isSmallScreen),
          ),
        ],
      ),
    );
  }

// ============================================================
// 切换虚拟形象按钮（毛玻璃 + 动效）
// ============================================================
  Widget _buildSwitchAvatarButton(bool isSmallScreen) {
    final buttonSize = isSmallScreen ? 40.0 : 56.0;

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
  // 7. 聊天入口按钮
  // ============================================================
  Widget _buildChatEntry(bool isSmallScreen) {
    const baseWidth = 1340.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / baseWidth;

    final entryHeight = 155.0 * scaleFactor;
    final entryX = 850.0 * scaleFactor;
    final entryY = 541.0 * scaleFactor;

    final entryWidth = 150.0 * scaleFactor;
    final scale = 1.2;
    final maxWidth = MediaQuery.of(context).size.width * 0.4;
    final finalWidth = entryWidth > maxWidth ? maxWidth : entryWidth;

    return Positioned(
      left: entryX * scale,
      top: entryY * scale,
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
            width: finalWidth * scale,
            height: entryHeight * scale,
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
                width: entryHeight * 0.8 * scale,
                height: entryHeight * 0.8 * scale,
              ),
            ),
          ),
        ),
      ),
    );
  }
  // ============================================================
  // 8. 底部导航【已修改：增加日历跳转逻辑】
  // ============================================================
  Widget _buildBottomNavigation(bool isSmallScreen) {
    final iconSize = isSmallScreen ? 32.0 : 48.0;
    final fontSize = isSmallScreen ? 12.0 : 14.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          height: isSmallScreen ? 80 : 110,
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

                    if (index == 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CalendarPage(),
                        ),
                      );
                    }
                  });
                },
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  scale: isSelected ? 1.15 : 1.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        _tabs[index]['icon'] as String,
                        width: iconSize,
                        height: iconSize,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tabs[index]['label'] as String,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
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
// CloudButton 云朵按钮组件（独立于 HomePage）
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