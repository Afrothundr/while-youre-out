import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Named text style constants used throughout the app.
abstract final class AppTextStyles {
  /// Used for list titles — 16sp, semi-bold weight.
  static TextStyle get listTitle =>
      GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600);

  /// Used for item titles — 14sp, regular weight.
  static TextStyle get itemTitle =>
      GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400);

  /// Used for incomplete-count badges — 11sp, bold.
  static TextStyle get badge =>
      GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700);

  /// Used for dates and secondary info — 12sp, muted (60 % opacity).
  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0x99000000), // black @ 60 %
      );
}
