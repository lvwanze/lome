import 'package:flutter/material.dart';
import 'package:lome/pages/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ===== 返回按钮 =====
  Widget _buildBackButton(VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF6EFE4).withOpacity(0.16),
          border: Border.all(
            color: const Color(0xFFF6EFE4).withOpacity(0.28),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 2,
              offset: Offset(0, 1),
              spreadRadius: 0,
            )
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: Color(0xFF98B4BC),
        ),
      ),
    );
  }

  // ===== 毛玻璃列表项 =====
  Widget _buildItemGlass({
    required String title,
    String subText = "",
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF).withOpacity(0.34),
          border: Border.all(
            color: const Color(0xFFFFFFFF).withOpacity(0.48),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 7,
              offset: Offset(4, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Color(0x26FFFFFF),
              blurRadius: 4,
              offset: Offset(-2, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF6B5F4F),
              ),
            ),
            const Spacer(),
            if (subText.isNotEmpty)
              Text(
                subText,
                style: TextStyle(
                  fontSize: 18,
                  color: const Color(0xFF6B5F4F).withOpacity(0.65),
                ),
              ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: const Color(0xFF6B5F4F).withOpacity(0.55),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/summer wallpaper-mobile.JPG"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // ===== 顶部：返回按钮 + 标题 =====
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildBackButton(() => Navigator.pop(context)),
                    ),
                    const Text(
                      "设置",
                      style: TextStyle(
                        fontSize: 28,
                        color: Color(0xFFBED5DB),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== 分割条 =====
                Center(
                  child: Container(
                    width: 1600.0,
                    height: 10.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFAFC5AE).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(100.0),
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // ===== 毛玻璃底板 =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 70,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF).withOpacity(0.5),
                    border: Border.all(
                      color: const Color(0xFFFFFFFF).withOpacity(0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                        spreadRadius: 4,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildItemGlass(
                        title: "       隐私",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('隐私设置')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildItemGlass(
                        title: "       通知",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('通知设置')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildItemGlass(
                        title: "       账号安全",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('账号安全')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildItemGlass(
                        title: "       界面与显示",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('界面与显示')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildItemGlass(
                        title: "       帮助与反馈",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('帮助与反馈')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildItemGlass(
                        title: "       关于",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('关于')),
                          );
                        },
                      ),
                    ],
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