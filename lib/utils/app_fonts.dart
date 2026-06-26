import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  // 私有构造，禁止外部实例化工具类
  AppFonts._();

  /// 功能入口标签：圆润中文手写风（站酷小薇体）
  static TextStyle featureLabel({
    double fontSize = 17,
    Color color = const Color(0xFF5D4E3C),
  }) {
    return GoogleFonts.zcoolXiaoWei(
      fontSize: fontSize,
      color: color,
      height: 1.2,
    );
  }

  /// 降低颜色饱和度，让图标更柔和
  static Color muted(Color color, {double saturationScale = 0.38}) {
    final HSLColor hsl = HSLColor.fromColor(color);
    // 饱和度限制 0~1
    double newSaturation = (hsl.saturation * saturationScale).clamp(0.0, 1.0);
    // 亮度微调，限制 0~1
    double newLightness = (hsl.lightness * 0.92 + 0.06).clamp(0.0, 1.0);
    return hsl
        .withSaturation(newSaturation)
        .withLightness(newLightness)
        .toColor();
  }
}