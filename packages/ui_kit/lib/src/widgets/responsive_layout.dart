import 'package:flutter/material.dart';

/// A layout builder that adapts to the screen width.
///
/// - **mobile**: width < 600dp (default phone)
/// - **tablet**: 600dp <= width < 900dp (small tablet / large phone landscape)
/// - **desktop**: width >= 900dp (tablet landscape / desktop)
class ResponsiveLayout extends StatelessWidget {
  /// Creates a [ResponsiveLayout].
  const ResponsiveLayout({
    required this.mobile,
    super.key,
    this.tablet,
    this.desktop,
  });

  /// Widget shown on mobile screens (< 600dp wide).
  final Widget mobile;

  /// Widget shown on tablet screens (>= 600dp wide).
  final Widget? tablet;

  /// Widget shown on desktop screens (>= 900dp wide).
  final Widget? desktop;

  /// Whether the current screen is considered mobile (< 600dp wide).
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  /// Whether the current screen is considered tablet (600-900 dp wide).
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 900;
  }

  /// Whether the current screen is considered desktop (>= 900dp wide).
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  /// Returns a value based on the current screen size.
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= 600) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// A constrained content wrapper that limits max-width on wide screens
/// while keeping content centered.
class ConstrainedContent extends StatelessWidget {
  /// Creates a [ConstrainedContent].
  const ConstrainedContent({
    required this.child,
    super.key,
    this.maxWidth = 640,
    this.padding = EdgeInsets.zero,
  });

  /// The maximum width for the content area.
  final double maxWidth;

  /// Padding around the content.
  final EdgeInsetsGeometry padding;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
