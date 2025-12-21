import 'package:flutter/material.dart';

/// Consistent spacing values throughout the app
class AppSpacing {
  AppSpacing._();

  // Base spacing unit (4px)
  static const double unit = 4.0;

  // Named spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Screen padding
  static const double screenPadding = 20.0;
  static const EdgeInsets screenInsets = EdgeInsets.all(screenPadding);
  static const EdgeInsets screenHorizontal =
      EdgeInsets.symmetric(horizontal: screenPadding);

  // Card padding
  static const double cardPadding = 16.0;
  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);

  // Button padding
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0);
  static const EdgeInsets buttonPaddingSmall =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0);

  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  static const BorderRadius borderRadiusSm =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg =
      BorderRadius.all(Radius.circular(radiusLg));
}
