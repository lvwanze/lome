import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lome/utils/app_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部：日期 + 虚拟形象
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '5月11日',
                        style: GoogleFonts.caveat(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5D4E3C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '26年',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  // 虚拟形象占位
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade200, Colors.pink.shade100],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // 欢迎语
              Text(
                '今天想和TA',
                style: GoogleFonts.caveat(
                  fontSize: 28,
                  color: const Color(0xFF5D4E3C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '一起做什么呢？',
                style: GoogleFonts.caveat(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5D4E3C),
                ),
              ),
              
              const Spacer(),

              // 装饰元素
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle_outlined, size: 8, color: Colors.grey.shade300),
                    const SizedBox(width: 12),
                    Icon(Icons.favorite, size: 14, color: Colors.pink.shade200),
                    const SizedBox(width: 12),
                    Icon(Icons.circle_outlined, size: 8, color: Colors.grey.shade300),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 4个核心功能入口（底部）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFeatureItem(
                    icon: Icons.calendar_today,
                    label: '日历',
                    color: Colors.orange.shade300,
                    onTap: () {},
                  ),
                  _buildFeatureItem(
                    icon: Icons.message_outlined,
                    label: '留言板',
                    color: Colors.blue.shade300,
                    onTap: () {},
                  ),
                  _buildFeatureItem(
                    icon: Icons.mail_outline,
                    label: '慢信',
                    color: Colors.purple.shade300,
                    onTap: () {},
                  ),
                  _buildFeatureItem(
                    icon: Icons.menu_book_outlined,
                    label: '共读',
                    color: Colors.green.shade300,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final mutedColor = AppFonts.muted(color);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: mutedColor.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 32,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppFonts.featureLabel(),
          ),
        ],
      ),
    );
  }
}
