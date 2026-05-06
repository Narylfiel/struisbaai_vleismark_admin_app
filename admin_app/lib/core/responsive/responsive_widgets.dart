import 'package:flutter/material.dart';

import 'responsive_breakpoints.dart';

/// Chooses between a horizontal [rowChildren] Row and vertical [columnChildren] Column.
/// Prefer passing the same widgets to both when order matches; spacing is inserted between pairs.
///
/// Desktop / wide: renders `Row(children: rowChildren)` (optionally separated by [spacing]).
/// Narrow: renders `Column(crossAxisAlignment: stretch, children: columnChildren)`.
///
/// Does not modify children; caller supplies complete child lists including [SizedBox] spacers if needed.
class AdaptiveRowColumn extends StatelessWidget {
  const AdaptiveRowColumn({
    super.key,
    required this.widthThreshold,
    required this.rowChildren,
    required this.columnChildren,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.rowSpacing = 0,
    this.columnSpacing = 0,
    this.rowMainAlignment = MainAxisAlignment.start,
  });

  /// Usually [ResponsiveBreakpoints.phoneMaxWidth].
  final double widthThreshold;
  final List<Widget> rowChildren;
  final List<Widget> columnChildren;
  final CrossAxisAlignment crossAxisAlignment;
  final double rowSpacing;
  final double columnSpacing;
  final MainAxisAlignment rowMainAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < widthThreshold;
        if (narrow) {
          return Column(
            crossAxisAlignment: crossAxisAlignment,
            children: _intersperseSpacing(columnChildren, columnSpacing),
          );
        }
        return Row(
          mainAxisAlignment: rowMainAlignment,
          children: _intersperseSpacing(rowChildren, rowSpacing),
        );
      },
    );
  }

  List<Widget> _intersperseSpacing(List<Widget> widgets, double gap) {
    if (widgets.isEmpty || gap <= 0) return widgets.toList(growable: false);
    final out = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      if (i > 0) out.add(SizedBox(width: gap, height: gap));
      out.add(widgets[i]);
    }
    return out;
  }
}

/// Primary actions: **Row / Wrap on wide**, vertically stacked **full-width on phone**.
///
/// Preserves desktop: uses a single Row when `maxWidth >= widthThreshold`.
class AdaptiveActionRow extends StatelessWidget {
  const AdaptiveActionRow({
    super.key,
    required this.children,
    this.widthThreshold = ResponsiveBreakpoints.phoneMaxWidth,
    this.spacing = 12,
    this.runSpacing = 12,
    this.phoneFullWidthStretch = true,
  });

  final List<Widget> children;
  final double widthThreshold;
  final double spacing;
  final double runSpacing;
  final bool phoneFullWidthStretch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < widthThreshold;
        if (!narrow) {
          final rowKids = <Widget>[];
          for (var i = 0; i < children.length; i++) {
            if (i > 0) rowKids.add(SizedBox(width: spacing));
            rowKids.add(children[i]);
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: rowKids,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              if (phoneFullWidthStretch)
                SizedBox(width: double.infinity, child: children[i])
              else
                children[i],
            ],
          ],
        );
      },
    );
  }
}

/// Keeps desktop [DataTable]-style Rows intact but allows horizontal scrolling on narrow widths.
///
/// Uses an explicit [minScrollWidth] so columns keep their intended widths inside the scroll viewport.
class MobileAwareHorizontalTable extends StatelessWidget {
  const MobileAwareHorizontalTable({
    super.key,
    required this.minScrollWidth,
    required this.child,
    this.threshold = ResponsiveBreakpoints.phoneMaxWidth,
  });

  final double minScrollWidth;
  final Widget child;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= threshold) {
          return child;
        }
        return Scrollbar(
          thumbVisibility: true,
          notificationPredicate: (_) => true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minScrollWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
