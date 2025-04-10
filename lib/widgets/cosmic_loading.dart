import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/space_theme.dart';

class CosmicLoading extends StatefulWidget {
  final double size;
  final String? message;
  final bool isOverlay;

  const CosmicLoading({
    Key? key,
    this.size = 100.0,
    this.message,
    this.isOverlay = false,
  }) : super(key: key);

  @override
  State<CosmicLoading> createState() => _CosmicLoadingState();
}

class _CosmicLoadingState extends State<CosmicLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget loadingWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: GalaxyPainter(
                  animation: _controller.value,
                  size: widget.size,
                ),
              );
            },
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: SpaceTheme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (widget.isOverlay) {
      return Container(
        color: SpaceTheme.deepSpaceNavy.withOpacity(0.8),
        child: Center(
          child: loadingWidget,
        ),
      );
    }

    return Center(
      child: loadingWidget,
    );
  }
}

class GalaxyPainter extends CustomPainter {
  final double animation;
  final double size;

  GalaxyPainter({
    required this.animation,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw galaxy spiral arms
    _drawSpiralArm(canvas, center, radius, 0, SpaceTheme.pulsarBlue);
    _drawSpiralArm(canvas, center, radius, pi, SpaceTheme.nebulaPink);
    _drawSpiralArm(canvas, center, radius, pi / 2, SpaceTheme.auroraGreen);
    _drawSpiralArm(canvas, center, radius, 3 * pi / 2, SpaceTheme.saturnGold);
    
    // Draw galaxy center
    final centerGradient = RadialGradient(
      colors: [
        Colors.white,
        SpaceTheme.starlightSilver,
        SpaceTheme.pulsarBlue.withOpacity(0.7),
        SpaceTheme.pulsarBlue.withOpacity(0.0),
      ],
      stops: const [0.0, 0.2, 0.5, 1.0],
    );
    
    final centerPaint = Paint()
      ..shader = centerGradient.createShader(
        Rect.fromCircle(center: center, radius: radius * 0.3),
      );
    
    canvas.drawCircle(center, radius * 0.3, centerPaint);
    
    // Draw orbiting stars
    _drawOrbitingStars(canvas, center, radius);
  }
  
  void _drawSpiralArm(Canvas canvas, Offset center, double radius, double startAngle, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    final spiralTightness = 4.0;
    final rotationOffset = animation * 2 * pi;
    
    path.moveTo(center.dx, center.dy);
    
    for (double i = 0.1; i <= 1.0; i += 0.01) {
      final angle = startAngle + rotationOffset + (i * spiralTightness * 2 * pi);
      final distance = i * radius;
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);
      
      path.lineTo(x, y);
    }
    
    // Draw the spiral with a gradient
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.1),
          color.withOpacity(0.7),
        ],
        begin: Alignment.center,
        end: Alignment.topRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = radius * 0.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(path, gradientPaint);
    
    // Add some stars along the spiral
    final random = Random(color.value);
    for (double i = 0.2; i <= 1.0; i += 0.1) {
      final angle = startAngle + rotationOffset + (i * spiralTightness * 2 * pi);
      final distance = i * radius;
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);
      
      final starSize = random.nextDouble() * 3 + 1;
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(0.7 + 0.3 * sin(animation * 2 * pi))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), starSize, starPaint);
    }
  }
  
  void _drawOrbitingStars(Canvas canvas, Offset center, double radius) {
    final random = Random(42);
    final orbitCount = 3;
    
    for (int i = 0; i < orbitCount; i++) {
      final orbitRadius = radius * (0.4 + i * 0.2);
      final starCount = 3 + i * 2;
      
      // Draw orbit path
      final orbitPaint = Paint()
        ..color = SpaceTheme.starlightSilver.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawCircle(center, orbitRadius, orbitPaint);
      
      // Draw stars on orbit
      for (int j = 0; j < starCount; j++) {
        final angle = animation * 2 * pi + (j * 2 * pi / starCount);
        final x = center.dx + orbitRadius * cos(angle);
        final y = center.dy + orbitRadius * sin(angle);
        
        final starSize = 2.0 + random.nextDouble() * 3;
        final starColor = [
          SpaceTheme.pulsarBlue,
          SpaceTheme.nebulaPink,
          SpaceTheme.auroraGreen,
          SpaceTheme.saturnGold,
        ][random.nextInt(4)];
        
        final starPaint = Paint()
          ..color = starColor
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(Offset(x, y), starSize, starPaint);
        
        // Add glow effect
        final glowPaint = Paint()
          ..color = starColor.withOpacity(0.5)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        
        canvas.drawCircle(Offset(x, y), starSize * 1.5, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(GalaxyPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
