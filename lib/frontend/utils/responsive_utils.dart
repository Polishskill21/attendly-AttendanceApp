import 'package:flutter/material.dart';

class ResponsiveUtils {
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortest = size.shortestSide;
    // Treat devices with shortestSide >= 600dp as tablets
    return shortest >= 600;
  }

  static double getTextScaleFactor(BuildContext context) {
    return isTablet(context) ? 1.3 : 1.0;
  }

  static double getIconScaleFactor(BuildContext context) {
    return isTablet(context) ? 1.4 : 1.0;
  }

  static EdgeInsets getContentPadding(BuildContext context) {
    return isTablet(context)
        ? const EdgeInsets.all(20.0)
        : const EdgeInsets.all(16.0);
  }

  static double getTitleFontSize(BuildContext context) {
    return isTablet(context) ? 28.0 : 20.0;
  }
  
  static double getBodyFontSize(BuildContext context) {
    return isTablet(context) ? 24.0 : 16.0;
  }

  static double getSmallFontSize(BuildContext context){
    return isTablet(context) ? 17.0 : 12.0;
  }
  
  static double getButtonHeight(BuildContext context) {
    return isTablet(context) ? 60.0 : 48.0;
  }
  
  static double getIconSize(BuildContext context, {double baseSize = 26.0}) {
    return isTablet(context) ? baseSize * 1.4 : baseSize;
  }
  
  static EdgeInsets getListPadding(BuildContext context) {
    return isTablet(context)
        ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)
        : const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0);
  }
  
  static double getCardElevation(BuildContext context) {
    return isTablet(context) ? 4.0 : 2.0;
  }
  
  static BorderRadius getCardBorderRadius(BuildContext context) {
    return BorderRadius.circular(isTablet(context) ? 16.0 : 12.0);
  }
}