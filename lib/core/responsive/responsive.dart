import 'package:flutter/material.dart';

/// Phone/tablet sizes, derived from the screen size only.
///
/// `Responsive.of(context)` depends on [MediaQuery.sizeOf], so widgets only
/// rebuild when the size changes (not on keyboard or padding changes).
class Responsive {
  /// Devices whose shortest side is at least this wide are tablets.
  static const double tabletBreakpoint = 600;

  final bool isTablet;

  const Responsive._(this.isTablet);

  factory Responsive.of(BuildContext context) =>
      Responsive._(MediaQuery.sizeOf(context).shortestSide >= tabletBreakpoint);

  double get textScaleFactor => isTablet ? 1.3 : 1.0;

  double get iconScaleFactor => isTablet ? 1.4 : 1.0;

  EdgeInsets get contentPadding =>
      isTablet ? const EdgeInsets.all(20.0) : const EdgeInsets.all(16.0);

  double get titleFontSize => isTablet ? 28.0 : 20.0;

  double get bodyFontSize => isTablet ? 24.0 : 16.0;

  double get smallFontSize => isTablet ? 17.0 : 12.0;

  double get buttonHeight => isTablet ? 60.0 : 48.0;

  double iconSize({double baseSize = 26.0}) => isTablet ? baseSize * 1.4 : baseSize;

  EdgeInsets get listPadding => isTablet
      ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)
      : const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0);

  double get cardElevation => isTablet ? 4.0 : 2.0;

  BorderRadius get cardBorderRadius => BorderRadius.circular(isTablet ? 16.0 : 12.0);
}
