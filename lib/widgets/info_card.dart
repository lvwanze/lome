import 'package:flutter/material.dart';
import 'package:lome/styles/app_colors.dart';
import 'package:lome/styles/app_text_styles.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    this.assetPath,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppTextStyles.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title),
                const SizedBox(height: AppTextStyles.spacingXS),
                Text(body, style: AppTextStyles.body),
              ],
            ),
          ),
          if (assetPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                assetPath!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}
