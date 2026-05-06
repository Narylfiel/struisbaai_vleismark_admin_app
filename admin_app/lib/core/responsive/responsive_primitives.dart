import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'responsive_breakpoints.dart';

class ResponsiveSectionContainer extends StatelessWidget {
  const ResponsiveSectionContainer({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final horizontal = ResponsiveBreakpoints.screenHorizontalPadding(context);
    return Padding(
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: horizontal, vertical: 12),
      child: child,
    );
  }
}

class ResponsiveToolbar extends StatelessWidget {
  const ResponsiveToolbar({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.mobileBreakpoint = ResponsiveBreakpoints.phoneMaxWidth,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double mobileBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) SizedBox(height: runSpacing),
              ],
            ],
          );
        }
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        );
      },
    );
  }
}

class ResponsiveDialogBody extends StatelessWidget {
  const ResponsiveDialogBody({
    super.key,
    required this.child,
    this.desktopMaxWidth = 560,
    this.maxHeightFactor = 0.82,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 8),
  });

  final Widget child;
  final double desktopMaxWidth;
  final double maxHeightFactor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxWidth = ResponsiveBreakpoints.dialogContentMaxWidth(
      context,
      desktopMax: desktopMaxWidth,
    );
    final maxHeight = math.max(280.0, size.height * maxHeightFactor);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: padding.add(
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        ),
        child: child,
      ),
    );
  }
}

/// Tab bar that becomes horizontally scrollable below [scrollWidthBreakpoint]
/// to prevent tab label/icon overflow on phones and tablet portrait.
class AdaptiveTabBar extends StatelessWidget {
  const AdaptiveTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.labelColor,
    this.unselectedLabelColor,
    this.indicatorColor,
    this.scrollWidthBreakpoint = 900,
  });

  final TabController controller;
  final List<Widget> tabs;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final Color? indicatorColor;

  /// Viewport width below which tabs scroll (desktop fills width).
  final double scrollWidthBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scroll = constraints.maxWidth < scrollWidthBreakpoint;
        return TabBar(
          controller: controller,
          isScrollable: scroll,
          tabAlignment: scroll ? TabAlignment.start : TabAlignment.fill,
          labelColor: labelColor,
          unselectedLabelColor: unselectedLabelColor,
          indicatorColor: indicatorColor,
          tabs: tabs,
        );
      },
    );
  }
}
