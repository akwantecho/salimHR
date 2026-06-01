import 'package:flutter/widgets.dart';

class DSAnimation {
  final Duration fast;
  final Duration normal;
  final Duration slow;
  final Curve curve;

  const DSAnimation({
    this.fast = const Duration(milliseconds: 120),
    this.normal = const Duration(milliseconds: 200),
    this.slow = const Duration(milliseconds: 280),
    this.curve = Curves.easeInOut,
  });
}
