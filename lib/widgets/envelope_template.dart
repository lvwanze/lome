import 'dart:math' as math;

import 'package:flutter/material.dart';

class EnvelopeTemplate extends StatelessWidget {
  const EnvelopeTemplate({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.shadowColor,
  });

  final Widget child;
  final double borderRadius;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (shadowColor != null)
            BoxShadow(
              color: shadowColor!,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: EnvelopeTemplatePainter(borderRadius: borderRadius),
          ),
          child,
        ],
      ),
    );
  }
}

class EnvelopeTemplatePainter extends CustomPainter {
  const EnvelopeTemplatePainter({required this.borderRadius});

  final double borderRadius;

  static const Color _lineColor = Color(0xFFE8E8E8);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
    );

    final paint = Paint()
      ..color = _lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
      paint,
    );

    final apex = Offset(size.width / 2, size.height * 0.36);

    canvas.drawLine(Offset.zero, apex, paint);
    canvas.drawLine(Offset(size.width, 0), apex, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant EnvelopeTemplatePainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius;
  }
}

class StampTemplate extends StatelessWidget {
  const StampTemplate({
    super.key,
    this.child,
    this.contentPadding = const EdgeInsets.all(6),
  });

  final Widget? child;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    final content = child;
    return CustomPaint(
      painter: const StampTemplatePainter(),
      child: content == null
          ? const SizedBox.expand()
          : Padding(
              padding: contentPadding,
              child: content,
            ),
    );
  }
}

class StampTemplatePainter extends CustomPainter {
  const StampTemplatePainter();

  static const Color _fillColor = Color(0xFFFFFAEC);
  static const Color _lineColor = Color(0xFFC9C9C9);
  static const double _notch = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    canvas.drawPath(path, Paint()..color = _fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = _lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  Path _buildPath(Size size) {
    final width = size.width;
    final height = size.height;
    final columns = math.max(3, (width / (2 * _notch)).round());
    final rows = math.max(3, (height / (2 * _notch)).round());
    final rx = width / (2 * columns);
    final ry = height / (2 * rows);
    final radius = Radius.elliptical(rx, ry);

    final path = Path()..moveTo(rx, ry);

    for (var i = 0; i < columns - 1; i++) {
      path.arcToPoint(
        Offset(rx + 2 * rx * (i + 1), ry),
        radius: radius,
        clockwise: true,
      );
    }
    for (var i = 0; i < rows - 1; i++) {
      path.arcToPoint(
        Offset(width - rx, ry + 2 * ry * (i + 1)),
        radius: radius,
        clockwise: true,
      );
    }
    for (var i = 0; i < columns - 1; i++) {
      path.arcToPoint(
        Offset(width - rx - 2 * rx * (i + 1), height - ry),
        radius: radius,
        clockwise: true,
      );
    }
    for (var i = 0; i < rows - 1; i++) {
      path.arcToPoint(
        Offset(rx, height - ry - 2 * ry * (i + 1)),
        radius: radius,
        clockwise: true,
      );
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}