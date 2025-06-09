import 'package:flutter/material.dart';

/// Animated Mushroom logo widget matching Angular's splash logo
class MushroomLogo extends StatefulWidget {
  final double size;
  final bool showAnimation;
  final Color? color;

  const MushroomLogo({
    super.key,
    this.size = 100,
    this.showAnimation = false,
    this.color,
  });

  @override
  State<MushroomLogo> createState() => _MushroomLogoState();
}

class _MushroomLogoState extends State<MushroomLogo>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    if (widget.showAnimation) {
      _sparkleController = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      )..repeat();
      
      _pulseController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    if (widget.showAnimation) {
      _sparkleController.dispose();
      _pulseController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? const Color(0xFF0A6CBC);
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: MushroomPainter(
          primaryColor: primaryColor,
          sparkleAnimation: widget.showAnimation ? _sparkleController : null,
          pulseAnimation: widget.showAnimation ? _pulseController : null,
        ),
      ),
    );
  }
}

/// Custom painter for the mushroom logo matching Angular's SVG design
class MushroomPainter extends CustomPainter {
  final Color primaryColor;
  final Animation<double>? sparkleAnimation;
  final Animation<double>? pulseAnimation;

  MushroomPainter({
    required this.primaryColor,
    this.sparkleAnimation,
    this.pulseAnimation,
  }) : super(repaint: sparkleAnimation ?? pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 140; // Base size from Angular SVG
    
    // Stem (matches Angular's rect element)
    final stemPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    
    final stemRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 15 * scale),
        width: 28 * scale,
        height: 30 * scale,
      ),
      Radius.circular(8 * scale),
    );
    canvas.drawRRect(stemRect, stemPaint);
    
    // Main mushroom cap (matches Angular's path element)
    final capPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    
    final capPath = Path();
    capPath.moveTo(25 * scale + center.dx - 70 * scale, 55 * scale + center.dy - 70 * scale);
    capPath.quadraticBezierTo(
      25 * scale + center.dx - 70 * scale, 30 * scale + center.dy - 70 * scale,
      70 * scale + center.dx - 70 * scale, 20 * scale + center.dy - 70 * scale,
    );
    capPath.quadraticBezierTo(
      115 * scale + center.dx - 70 * scale, 30 * scale + center.dy - 70 * scale,
      115 * scale + center.dx - 70 * scale, 55 * scale + center.dy - 70 * scale,
    );
    capPath.quadraticBezierTo(
      115 * scale + center.dx - 70 * scale, 80 * scale + center.dy - 70 * scale,
      70 * scale + center.dx - 70 * scale, 75 * scale + center.dy - 70 * scale,
    );
    capPath.quadraticBezierTo(
      25 * scale + center.dx - 70 * scale, 80 * scale + center.dy - 70 * scale,
      25 * scale + center.dx - 70 * scale, 55 * scale + center.dy - 70 * scale,
    );
    canvas.drawPath(capPath, capPaint);
    
    // Bottom of mushroom cap (matches Angular's ellipse)
    final bottomPaint = Paint()
      ..color = const Color(0xFF084E88)
      ..style = PaintingStyle.fill;
    
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, 60 * scale + center.dy - 70 * scale),
        width: 90 * scale,
        height: 36 * scale,
      ),
      bottomPaint,
    );
    
    // Eyes with sparkle animation
    _drawEyes(canvas, center, scale);
    
    // Spots on mushroom cap
    _drawSpots(canvas, center, scale);
    
    // Pulse effect if animation is enabled
    if (pulseAnimation != null) {
      _drawPulseEffect(canvas, center, scale);
    }
  }

  void _drawEyes(Canvas canvas, Offset center, double scale) {
    final eyePaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    
    final pupilPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    
    // Left eye
    canvas.drawCircle(
      Offset(50 * scale + center.dx - 70 * scale, 50 * scale + center.dy - 70 * scale),
      10 * scale,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(50 * scale + center.dx - 70 * scale, 50 * scale + center.dy - 70 * scale),
      4 * scale,
      pupilPaint,
    );
    
    // Right eye
    canvas.drawCircle(
      Offset(90 * scale + center.dx - 70 * scale, 50 * scale + center.dy - 70 * scale),
      10 * scale,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(90 * scale + center.dx - 70 * scale, 50 * scale + center.dy - 70 * scale),
      4 * scale,
      pupilPaint,
    );
    
    // Sparkles if animation is enabled
    if (sparkleAnimation != null) {
      _drawSparkles(canvas, center, scale);
    }
  }

  void _drawSparkles(Canvas canvas, Offset center, double scale) {
    final sparklePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final sparklePositions = [
      Offset(55 * scale + center.dx - 70 * scale, 45 * scale + center.dy - 70 * scale),
      Offset(48 * scale + center.dx - 70 * scale, 53 * scale + center.dy - 70 * scale),
      Offset(95 * scale + center.dx - 70 * scale, 45 * scale + center.dy - 70 * scale),
      Offset(88 * scale + center.dx - 70 * scale, 53 * scale + center.dy - 70 * scale),
    ];
    
    for (int i = 0; i < sparklePositions.length; i++) {
      final opacity = (sparkleAnimation!.value + i * 0.25) % 1.0;
      final sparkleSize = (1.5 + i * 0.5) * scale;
      
      sparklePaint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(sparklePositions[i], sparkleSize, sparklePaint);
    }
  }

  void _drawSpots(Canvas canvas, Offset center, double scale) {
    final spotPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    
    // Large spots matching Angular's design
    canvas.drawCircle(
      Offset(40 * scale + center.dx - 70 * scale, 40 * scale + center.dy - 70 * scale),
      8 * scale,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(70 * scale + center.dx - 70 * scale, 35 * scale + center.dy - 70 * scale),
      5 * scale,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(100 * scale + center.dx - 70 * scale, 40 * scale + center.dy - 70 * scale),
      7 * scale,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(60 * scale + center.dx - 70 * scale, 30 * scale + center.dy - 70 * scale),
      4 * scale,
      spotPaint,
    );
  }

  void _drawPulseEffect(Canvas canvas, Offset center, double scale) {
    final pulsePaint = Paint()
      ..color = primaryColor.withOpacity(0.3 * pulseAnimation!.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;
    
    final pulseRadius = 80 * scale * (1 + pulseAnimation!.value * 0.2);
    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
