import 'package:flutter/material.dart';

class AppTheme {
  // ============ 颜色 ============
  static const Color primaryColor = Color(0xFFE8739A);
  static const Color primaryLight = Color(0xFFF5D4DF);
  static const Color primaryDark = Color(0xFFD45A7A);

  static const Color successColor = Color(0xFF52C41A);
  static const Color errorColor = Color(0xFFFF4D4F);
  static const Color warningColor = Color(0xFFFAAD14);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color textWhite = Color(0xFFFFFFFF);

  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgGray = Color(0xFFF5F5F5);
  static const Color dividerColor = Color(0xFFE8E8E8);

  // ============ 设计可选色 ============
  static const Color accentColor = Color(0xFFC4B8A8);      // 冷茶色（强调）
  static const Color accentLight = Color(0xFFD4C8B8);      // 冷茶色（浅）
  static const Color accentBg = Color(0xFFF5F0EB);         // 冷茶色（极淡）

  // ============ 圆角 ============
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 20.0;
  static const double radiusFull = 100.0;

  // ============ 字体大小 ============
  static const double fontSizeTitle = 24.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeNormal = 14.0;
  static const double fontSizeSmall = 12.0;

  // ============ 间距 ============
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ============ 毛玻璃效果 ============
  static const double glassBlur = 5.0;
  static const double glassOpacity = 0.04;
  static const double glassBorderOpacity = 0.08;
  static const double glassButtonOpacity = 0.12;
  static const double glassButtonBorderOpacity = 0.20;

  // ============ 毛玻璃卡片装饰 ============
  static BoxDecoration glassCardDecoration({
    double? opacity,
    double? borderOpacity,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity ?? glassOpacity),
      borderRadius: BorderRadius.circular(borderRadius ?? radiusLarge),
      border: Border.all(
        color: Colors.white.withOpacity(borderOpacity ?? glassBorderOpacity),
        width: 1,
      ),
    );
  }

  // ============ 毛玻璃按钮装饰 ============
  static BoxDecoration glassButtonDecoration({
    double? opacity,
    double? borderOpacity,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity ?? glassButtonOpacity),
      borderRadius: BorderRadius.circular(borderRadius ?? radiusLarge),
      border: Border.all(
        color: Colors.white.withOpacity(borderOpacity ?? glassButtonBorderOpacity),
        width: 1.5,
      ),
    );
  }

  // ============ 输入框装饰 ============
  static InputDecoration inputDecoration({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: textHint,
        fontSize: fontSizeNormal,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: bgGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingM,
      ),
    );
  }

  // ============ 按钮样式 ============
  static ButtonStyle primaryButtonStyle({bool isEnabled = true}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isEnabled ? primaryColor : primaryLight,
      foregroundColor: textWhite,
      disabledBackgroundColor: primaryLight,
      disabledForegroundColor: textWhite,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusFull),
      ),
      textStyle: const TextStyle(
        fontSize: fontSizeMedium,
        fontWeight: FontWeight.w600,
      ),
      elevation: 0,
    );
  }

  static ButtonStyle textButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: primaryColor,
      textStyle: const TextStyle(
        fontSize: fontSizeNormal,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ============ 毛玻璃风格 ElevatedButton ============
  static ButtonStyle glassButtonStyle({bool isEnabled = true}) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withOpacity(isEnabled ? 0.12 : 0.06),
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.white.withOpacity(0.06),
      disabledForegroundColor: Colors.white38,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(
          color: Colors.white.withOpacity(isEnabled ? 0.20 : 0.10),
          width: 1.5,
        ),
      ),
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 4,
      ),
    );
  }
}