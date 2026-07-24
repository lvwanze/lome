import 'package:flutter/material.dart';
import 'package:lome/pages/login_page.dart';
import 'package:lome/pages/welcome_guide_page.dart';

class ProfilePage extends StatefulWidget {
  final bool isBound;
  const ProfilePage({super.key, required this.isBound});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late bool _isBound;

  @override
  void initState() {
    super.initState();
    _isBound = widget.isBound;
  }

  void _showLogoutDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("提示"),
        content: const Text("确定退出登录账号？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("取消")),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.of(ctx).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LoginPage()),
                (route) => false,
              );
            },
            child: const Text("确认"),
          ),
        ],
      ),
    );
  }

  // 返回按钮
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

  // 内部条目：增大阴影偏移，按钮更“浮起”，明暗对比增强
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
            // 右下投影：更大偏移，营造悬浮距离
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 7,
              offset: Offset(4, 4),
              spreadRadius: 0,
            ),
            // 左上高光，强化凸起感
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
            image: AssetImage("assets/images/Profile_bg.png"),
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildBackButton(() => Navigator.pop(context)),
                    ),
                    const Text(
                      "个人信息",
                      style: TextStyle(
                        fontSize:30,
                        color: Color(0xFFBED5DB),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 30),

                // 圆形头像
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFFFFF).withOpacity(1),
                    border: Border.all(
                      color: const Color(0xFFF6EFE4).withOpacity(0),
                      width: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "UserName",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFFC4B8A8),
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 20),

                // 绑定状态标签
                _isBound
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(222, 238, 222, 0.45),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Text(
                          "✓ 已绑定",
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF507850),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(244, 224, 224, 0.45),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Text(
                          "✗ 未绑定",
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF965656),
                          ),
                        ),
                      ),

                const SizedBox(height: 30),

                // 外层大底板
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
                        title: "       伴侣名称",
                        subText: _isBound ? "Name" : "暂无伴侣",
                        onTap: () {},
                      ),
                      const SizedBox(height: 16),
                      _buildItemGlass(
                        title: "       加入日期",
                        subText: "Time",
                        onTap: () {},
                      ),
                      const SizedBox(height: 16),
                      _buildItemGlass(
                        title: _isBound ? "       解除绑定" : "       前往绑定",
                        onTap: () async {
                          if (!_isBound) {
                            // 跳转欢迎绑定页面
                            final bindSuccess = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => WelcomeGuidePage()),
                            );
                            // 绑定成功后刷新页面状态
                            if (bindSuccess == true) {
                              setState(() {
                                _isBound = true;
                              });
                            }
                          } else {
                            setState(() => _isBound = !_isBound);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildItemGlass(
                        title: "       退出登录",
                        onTap: () => _showLogoutDialog(context),
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