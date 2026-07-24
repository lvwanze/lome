import 'package:flutter/material.dart';
import 'package:lome/styles/app_text_styles.dart';

class FeatureNavItem extends StatelessWidget {
  const FeatureNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: AppTextStyles.spacingXS),
          Text(label, style: AppTextStyles.navLabel),
        ],
      ),
    );
  }
}
