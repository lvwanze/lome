import 'package:flutter/material.dart';

class AppTheme {
  // ============ 颜色 ============
  // 主色（会议中确定）
  static const Color primaryColor = Color(0xFFE8739A);      // 主色（品牌粉）
  static const Color primaryLight = Color(0xFFF5D4DF);      // 浅粉（按钮禁用/背景）
  static const Color primaryDark = Color(0xFFD45A7A);       // 深粉（按压状态）

  // 辅助色
  static const Color successColor = Color(0xFF52C41A);      // 成功绿
  static const Color errorColor = Color(0xFFFF4D4F);        // 错误红
  static const Color warningColor = Color(0xFFFAAD14);      // 警告黄

  // 中性色
  static const Color textPrimary = Color(0xFF1A1A1A);       // 主要文字
  static const Color textSecondary = Color(0xFF666666);     // 次要文字
  static const Color textHint = Color(0xFF999999);          // 占位文字
  static const Color textWhite = Color(0xFFFFFFFF);         // 白色文字

  static const Color bgWhite = Color(0xFFFFFFFF);           // 背景白
  static const Color bgGray = Color(0xFFF5F5F5);            // 背景灰
  static const Color dividerColor = Color(0xFFE8E8E8);      // 分割线

  // ============ 圆角 ============
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 20.0;
  static const double radiusFull = 100.0;                   // 胶囊按钮

  // ============ 字体大小 ============
  static const double fontSizeTitle = 24.0;                 // 页面标题
  static const double fontSizeLarge = 18.0;                 // 大号文字
  static const double fontSizeMedium = 16.0;                // 中号文字（按钮）
  static const double fontSizeNormal = 14.0;                // 常规文字
  static const double fontSizeSmall = 12.0;                 // 小号文字（提示）

  // ============ 间距 ============
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

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
}