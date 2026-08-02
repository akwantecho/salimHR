import 'package:flutter/widgets.dart';

import '../ds_provider.dart';
import '../tokens/colors.dart';

class SoftBlobBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const SoftBlobBackground({
    super.key,
    required this.child,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _BlobPainter(
              base: ds.colors,
              opacity: opacity,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  final DSColors base;
  final double opacity;

  _BlobPainter({required this.base, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = base.primary.withValues(alpha: 0.12 * opacity)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = base.secondary.withValues(alpha: 0.14 * opacity)
      ..style = PaintingStyle.fill;

    final paint3 = Paint()
      ..color = base.accent.withValues(alpha: 0.1 * opacity)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(size.width * 0.2, size.height * 0.05)
      ..cubicTo(
        size.width * 0.45,
        size.height * 0.02,
        size.width * 0.5,
        size.height * 0.28,
        size.width * 0.28,
        size.height * 0.32,
      )
      ..cubicTo(
        size.width * 0.05,
        size.height * 0.36,
        size.width * 0.04,
        size.height * 0.1,
        size.width * 0.2,
        size.height * 0.05,
      );

    final path2 = Path()
      ..moveTo(size.width * 0.8, size.height * 0.1)
      ..cubicTo(
        size.width * 1.05,
        size.height * 0.08,
        size.width * 1.1,
        size.height * 0.35,
        size.width * 0.86,
        size.height * 0.38,
      )
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.42,
        size.width * 0.65,
        size.height * 0.12,
        size.width * 0.8,
        size.height * 0.1,
      );

    final path3 = Path()
      ..moveTo(size.width * 0.3, size.height * 0.7)
      ..cubicTo(
        size.width * 0.5,
        size.height * 0.6,
        size.width * 0.8,
        size.height * 0.82,
        size.width * 0.6,
        size.height * 0.95,
      )
      ..cubicTo(
        size.width * 0.32,
        size.height * 1.08,
        size.width * 0.12,
        size.height * 0.84,
        size.width * 0.3,
        size.height * 0.7,
      );

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) {
    return oldDelegate.base != base || oldDelegate.opacity != opacity;
  }
}
