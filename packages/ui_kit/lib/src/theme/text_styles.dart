import 'package:flutter/material.dart';

/// Named text style constants used throughout the app.
abstract final class AppTextStyles {
  /// Used for list titles — 18sp, medium weight.
  static const TextStyle listTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  /// Used for item titles — 16sp, regular weight.
  static const TextStyle itemTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  /// Used for incomplete-count badges — 12sp, bold.
  static const TextStyle badge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  /// Used for dates and secondary info — 12sp, muted (60 % opacity).
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0x99000000), // black @ 60 %
  );
}
