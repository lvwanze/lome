import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  static TextStyle get heroDate => GoogleFonts.caveat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get heroTitle => GoogleFonts.caveat(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get title => GoogleFonts.notoSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.notoSans(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.45,
      );

  static TextStyle get caption => GoogleFonts.notoSans(
        fontSize: 12,
        color: AppColors.textHint,
      );

  static TextStyle get navLabel => GoogleFonts.notoSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );
}
