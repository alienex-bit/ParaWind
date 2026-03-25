import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/site.dart';

class WindCompass extends StatefulWidget {
  final double currentWind;
  final double faceDirection;
  final List<WindDirectionRange> optimalRanges;
  final Color arrowColor;
  const WindCompass({
    super.key,
    required this.currentWind,
    required this.faceDirection,
    required this.optimalRanges,
    required this.arrowColor,
  });
  @override
  State<WindCompass> createState() => _WindCompassState();
}

class _WindCompassState extends State<WindCompass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: WindDirectionPainter(
              currentWind: widget.currentWind,
              faceDirection: widget.faceDirection,
              optimalRanges: widget.optimalRanges,
              arrowColor: widget.arrowColor,
              dividerColor: Theme.of(
                context,
              ).dividerColor.withValues(alpha: 0.2),
              textColor: Colors.transparent,
              flowProgress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class WindDirectionPainter extends CustomPainter {
  final double currentWind;
  final double faceDirection;
  final List<WindDirectionRange> optimalRanges;
  final Color arrowColor;
  final Color dividerColor;
  final Color textColor;
  final double flowProgress;
  WindDirectionPainter({
    required this.currentWind,
    required this.faceDirection,
    required this.optimalRanges,
    required this.arrowColor,
    required this.dividerColor,
    required this.textColor,
    this.flowProgress = 0,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    // Background circle
    final bgPaint = Paint()
      ..color = dividerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);
    // Border
    final borderPaint = Paint()
      ..color = dividerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, borderPaint);
    // Optimal Ranges
    final rangePaint = Paint()
      ..color = Colors.greenAccent
          .withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (var range in optimalRanges) {
      double startAngle = (range.min - 90) * (math.pi / 180);
      double sweepAngle = (range.max - range.min) * (math.pi / 180);
      if (range.max < range.min) {
        sweepAngle = (360 - range.min + range.max) * (math.pi / 180);
      }
      canvas.drawArc(
        rect.inflate(-3),
        startAngle,
        sweepAngle,
        false,
        rangePaint,
      );
    }
    // Draw Flowing Arrows
    double windRad = (currentWind + 90) * (math.pi / 180);
    const arrowCount = 3;
    final totalLen = radius * 1.5;
    for (int i = 0; i < arrowCount; i++) {
      double individualProgress = (flowProgress + (i / arrowCount)) % 1.0;
      double dist = (individualProgress - 0.5) * totalLen;
      double posX = center.dx + dist * math.cos(windRad);
      double posY = center.dy + dist * math.sin(windRad);
      double opacity = 1.0;
      if (individualProgress < 0.2) opacity = individualProgress / 0.2;
      if (individualProgress > 0.8) opacity = (1.0 - individualProgress) / 0.2;
      final parrowPaint = Paint()
        ..color = arrowColor.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      double headLen = 4.0;
      double headAngle = math.pi / 6;
      double distFromCenter = math.sqrt(
        math.pow(posX - center.dx, 2) + math.pow(posY - center.dy, 2),
      );
      if (distFromCenter < radius - 2) {
        canvas.drawLine(
          Offset(posX, posY),
          Offset(
            posX - headLen * math.cos(windRad - headAngle),
            posY - headLen * math.sin(windRad - headAngle),
          ),
          parrowPaint,
        );
        canvas.drawLine(
          Offset(posX, posY),
          Offset(
            posX - headLen * math.cos(windRad + headAngle),
            posY - headLen * math.sin(windRad + headAngle),
          ),
          parrowPaint,
        );
        canvas.drawLine(
          Offset(posX, posY),
          Offset(
            posX - headLen * 1.5 * math.cos(windRad),
            posY - headLen * 1.5 * math.sin(windRad),
          ),
          parrowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WindDirectionPainter oldDelegate) {
    return oldDelegate.flowProgress != flowProgress ||
        oldDelegate.currentWind != currentWind ||
        oldDelegate.arrowColor != arrowColor;
  }
}
