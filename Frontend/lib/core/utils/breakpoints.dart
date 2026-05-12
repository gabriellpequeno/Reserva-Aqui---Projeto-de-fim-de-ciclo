import 'package:flutter/material.dart';

class Breakpoints {
  const Breakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;

  static double widthOf(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static bool isMobile(BuildContext context) => widthOf(context) < tablet;

  static bool isTablet(BuildContext context) {
    final w = widthOf(context);
    return w >= tablet && w < desktop;
  }

  static bool isDesktop(BuildContext context) => widthOf(context) >= desktop;

  static bool isAtLeastTablet(BuildContext context) =>
      widthOf(context) >= tablet;

  static bool isAtLeastDesktop(BuildContext context) =>
      widthOf(context) >= desktop;
}

class ContentMaxWidth {
  const ContentMaxWidth._();

  static const double form = 480;
  static const double profile = 600;
  static const double reading = 720;
  static const double content = 1100;
}

class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = ContentMaxWidth.content,
    this.horizontalPadding = 0,
  });

  final Widget child;
  final double maxWidth;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final padded = horizontalPadding > 0
        ? Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: child,
          )
        : child;

    if (!Breakpoints.isDesktop(context)) return padded;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padded,
      ),
    );
  }
}
