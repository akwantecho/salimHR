import 'package:flutter/widgets.dart';

class DSShadows {
  final List<BoxShadow> level1;
  final List<BoxShadow> level2;
  final List<BoxShadow> floating;

  const DSShadows({
    required this.level1,
    required this.level2,
    required this.floating,
  });

  factory DSShadows.soft(Color shadowColor) {
    return DSShadows(
      level1: const [
        BoxShadow(
          color: Color(0x0D0F172A), // rgba(15,23,42,0.05)
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
      level2: const [
        BoxShadow(
          color: Color(0x1A0F172A), // rgba(15,23,42,0.1)
          blurRadius: 6,
          offset: Offset(0, 4),
          spreadRadius: -1,
        ),
      ],
      floating: const [
        BoxShadow(
          color: Color(0x1A0F172A),
          blurRadius: 25,
          offset: Offset(0, 20),
          spreadRadius: -5,
        ),
        BoxShadow(
          color: Color(0x140F172A),
          blurRadius: 10,
          offset: Offset(0, 8),
          spreadRadius: -6,
        ),
      ],
    );
  }
}
