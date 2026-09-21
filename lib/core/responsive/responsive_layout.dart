import 'package:flutter/material.dart';

/// Screen size category based on width breakpoints:
/// - Compact: < 600dp (Phones in portrait)
/// - Medium: 600dp - 840dp (Foldables, small tablets, phones in landscape)
/// - Expanded: > 840dp (Large tablets, iPads, desktop)
enum ScreenType { compact, medium, expanded }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get screenPadding => MediaQuery.paddingOf(this);
  double get textScaleFactor => MediaQuery.textScalerOf(this).scale(1.0);

  ScreenType get screenType {
    final width = screenWidth;
    if (width < 600) return ScreenType.compact;
    if (width <= 840) return ScreenType.medium;
    return ScreenType.expanded;
  }

  bool get isCompact => screenType == ScreenType.compact;
  bool get isMedium => screenType == ScreenType.medium;
  bool get isExpanded => screenType == ScreenType.expanded;
  bool get isTablet => screenType != ScreenType.compact;

  /// Clamps hero elements (circular progress buttons, illustrations)
  /// so they look proportional on small phones (320dp) as well as tablets.
  double responsiveSize(
    double baseSize, {
    double minSize = 48,
    double? maxSize,
  }) {
    final factor = (screenWidth / 390.0).clamp(0.8, 1.3);
    final calculated = baseSize * factor;
    if (maxSize != null && calculated > maxSize) return maxSize;
    if (calculated < minSize) return minSize;
    return calculated;
  }
}

/// A responsive wrapper widget that constrains content width on large screens
/// (tablets and web) and ensures safe scrolling and keyboard insets on small screens.
class ResponsiveScaffoldBody extends StatelessWidget {
  final Widget child;
  final double maxContentWidth;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  const ResponsiveScaffoldBody({
    super.key,
    required this.child,
    this.maxContentWidth = 560,
    this.padding,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0);

    if (scrollable && child is! ScrollView) {
      return SafeArea(
        child: Padding(
          padding: effectivePadding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: child,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: effectivePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
