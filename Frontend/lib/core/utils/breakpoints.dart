import 'package:flutter/widgets.dart';

class Breakpoints {
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double maxContentWidth = 600;
  static const double maxFormWidth = 480;
}

bool isTablet(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.tablet;

bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.desktop;
