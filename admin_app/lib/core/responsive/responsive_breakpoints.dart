import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Production breakpoints for Admin App responsive layout.
/// Desktop (Windows) remains primary; narrow layouts activate only below these thresholds.
abstract final class ResponsiveBreakpoints {
  /// Phone-ish layouts — stack toolbars, use cards, widen dialogs edge-to-edge.
  static const double phoneMaxWidth = 600;

  /// Tablet range — optional wrap; desktop Row layouts often still fit.
  static const double tabletMaxWidth = 1024;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// True below [phoneMaxWidth]. Does not imply touch device.
  static bool isPhoneLayout(BuildContext context) =>
      widthOf(context) < phoneMaxWidth;

  static bool isTabletLayout(BuildContext context) {
    final w = widthOf(context);
    return w >= phoneMaxWidth && w < tabletMaxWidth;
  }

  static bool isDesktopLayout(BuildContext context) =>
      widthOf(context) >= tabletMaxWidth;

  /// Alias used by shared widgets to reduce repeated width checks.
  static bool isMobile(BuildContext context) => isPhoneLayout(context);

  /// Alias used by shared widgets to reduce repeated width checks.
  static bool isTablet(BuildContext context) => isTabletLayout(context);

  /// Alias used by shared widgets to reduce repeated width checks.
  static bool isDesktop(BuildContext context) => isDesktopLayout(context);

  /// Max width for dialog content — nearly full-width on phones, capped on desktop.
  static double dialogContentMaxWidth(BuildContext context,
      {double desktopMax = 480}) {
    final w = widthOf(context);
    final pad = MediaQuery.paddingOf(context);
    final safeW = (w - pad.horizontal).clamp(0.0, w);
    if (isPhoneLayout(context)) return (safeW - 24).clamp(280.0, safeW);
    return math.min(desktopMax, safeW - 48);
  }

  /// Horizontal padding that scales down slightly on phones (keeps desktop padding).
  static double screenHorizontalPadding(BuildContext context,
      {double desktop = 24}) {
    return isPhoneLayout(context) ? 16 : desktop;
  }
}
