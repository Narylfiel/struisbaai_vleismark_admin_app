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
/// Implements [PreferredSizeWidget] so it can be used as [AppBar.bottom].
class AdaptiveTabBar extends StatelessWidget implements PreferredSizeWidget {
  const AdaptiveTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.labelColor,
    this.unselectedLabelColor,
    this.indicatorColor,
    this.dividerColor,
    this.onTap,
    this.scrollWidthBreakpoint = 900,
    this.preferredTabBarHeight = kTextTabBarHeight,
  });

  final TabController controller;
  final List<Widget> tabs;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final Color? indicatorColor;
  final Color? dividerColor;

  /// Forwarded to [TabBar.onTap].
  final ValueChanged<int>? onTap;

  /// Viewport width below which tabs scroll (desktop fills width).
  final double scrollWidthBreakpoint;

  /// Height reported to [AppBar] / scaffold (Material tab bar standard).
  final double preferredTabBarHeight;

  @override
  Size get preferredSize => Size.fromHeight(preferredTabBarHeight);

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
          dividerColor: dividerColor,
          onTap: onTap,
          tabs: tabs,
        );
      },
    );
  }
}

/// Preserves the common admin pattern: horizontal then vertical scroll on wide
/// layouts, and replaces it on narrow viewports with [ResponsiveTableScroll]
/// so tables do not compress vertically.
///
/// [child] must be the table widget (e.g. [DataTable] or [Table]).
class AdaptiveDataTableScroller extends StatelessWidget {
  const AdaptiveDataTableScroller({
    super.key,
    required this.child,
    this.breakpoint = ResponsiveBreakpoints.phoneMaxWidth,
    this.narrowMinWidth = 720,
  });

  final Widget child;

  /// Same semantics as [ResponsiveTableScroll.breakpoint].
  final double breakpoint;

  /// Same semantics as [ResponsiveTableScroll.narrowMinWidth].
  final double narrowMinWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.hasBoundedWidth &&
                constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : ResponsiveBreakpoints.widthOf(context);
        final narrow = maxW.isFinite && maxW < breakpoint;
        final vertical = SingleChildScrollView(child: child);
        if (narrow) {
          return ResponsiveTableScroll(
            breakpoint: breakpoint,
            narrowMinWidth: narrowMinWidth,
            child: vertical,
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: vertical,
        );
      },
    );
  }
}

/// Desktop/tablet (width ≥ [breakpoint]): returns [child] unchanged.
///
/// Narrow: wraps [child] in a horizontal [SingleChildScrollView] with
/// [narrowMinWidth] so [DataTable], [Table], and matrix layouts keep readable
/// columns instead of compressing into vertical gibberish.
class ResponsiveTableScroll extends StatelessWidget {
  const ResponsiveTableScroll({
    super.key,
    required this.child,
    this.breakpoint = ResponsiveBreakpoints.phoneMaxWidth,
    this.narrowMinWidth = 720,
    this.verticalPadding = 0,
  });

  final Widget child;

  /// Viewport width below which horizontal scroll applies.
  final double breakpoint;

  /// Minimum width of the scrolled content on narrow layouts.
  final double narrowMinWidth;

  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.hasBoundedWidth &&
                constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : ResponsiveBreakpoints.widthOf(context);
        if (!maxW.isFinite || maxW >= breakpoint) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: child,
          );
        }
        final minInner = math.max(narrowMinWidth, maxW);
        return Scrollbar(
          thumbVisibility: false,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                EdgeInsets.symmetric(vertical: verticalPadding),
            primary: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minInner),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Wraps widgets like [SegmentedButton] so they scroll horizontally on phones
/// instead of overflowing the viewport. No-op at or above [breakpoint].
class NarrowHorizontalScroll extends StatelessWidget {
  const NarrowHorizontalScroll({
    super.key,
    required this.child,
    this.breakpoint = ResponsiveBreakpoints.phoneMaxWidth,
  });

  final Widget child;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.hasBoundedWidth &&
                constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : ResponsiveBreakpoints.widthOf(context);
        if (!maxW.isFinite || maxW >= breakpoint) return child;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: child,
        );
      },
    );
  }
}

/// Horizontally scrolls [child] only when width is constrained below [minWidth].
class HorizontallyScrollableWhenNarrow extends StatelessWidget {
  const HorizontallyScrollableWhenNarrow({
    super.key,
    required this.child,
    required this.scrollBreakpoint,
    this.minWidth = 520,
    this.verticalPadding = 0,
  });

  final Widget child;
  final double scrollBreakpoint;
  final double minWidth;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.hasBoundedWidth &&
                constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : ResponsiveBreakpoints.widthOf(context);
        final narrow =
            maxW.isFinite && maxW < scrollBreakpoint;
        if (!narrow) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: child,
          );
        }
        return Scrollbar(
          thumbVisibility: false,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
