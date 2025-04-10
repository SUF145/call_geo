import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/space_theme.dart';

class SpaceBackground extends StatefulWidget {
  final Widget child;
  final bool animateStars;
  final int starCount;
  final bool showNebula;

  const SpaceBackground({
    Key? key,
    required this.child,
    this.animateStars = true,
    this.starCount = 100,
    this.showNebula = true,
  }) : super(key: key);

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Star> _stars;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _stars = List.generate(
      widget.starCount,
      (_) => Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2 + 1,
        opacity: _random.nextDouble() * 0.7 + 0.3,
        twinkleSpeed: _random.nextDouble() * 2 + 1,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: SpaceTheme.deepSpaceGradient,
      ),
      child: Stack(
        children: [
          // Nebula effect
          if (widget.showNebula)
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: CustomPaint(
                  painter: NebulaPainter(),
                ),
              ),
            ),
          
          // Stars
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: StarfieldPainter(
                    stars: _stars,
                    animation: widget.animateStars ? _controller.value : 0,
                  ),
                );
              },
            ),
          ),
          
          // Content
          widget.child,
        ],
      ),
    );
  }
}

class Star {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double twinkleSpeed;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.twinkleSpeed,
  });

  double getCurrentOpacity(double animation) {
    return (sin(animation * twinkleSpeed * 2 * pi) * 0.3 + 0.7) * opacity;
  }
}

class StarfieldPainter extends CustomPainter {
  final List<Star> stars;
  final double animation;

  StarfieldPainter({
    required this.stars,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      final paint = Paint()
        ..color = SpaceTheme.starlightSilver.withOpacity(
            star.getCurrentOpacity(animation))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class NebulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Create nebula gradients
    final purpleGradient = RadialGradient(
      center: const Alignment(-0.5, -0.6),
      radius: 1.2,
      colors: [
        SpaceTheme.cosmicPurple.withOpacity(0.7),
        SpaceTheme.cosmicPurple.withOpacity(0.0),
      ],
    );
    
    final pinkGradient = RadialGradient(
      center: const Alignment(0.7, 0.3),
      radius: 1.0,
      colors: [
        SpaceTheme.nebulaPink.withOpacity(0.5),
        SpaceTheme.nebulaPink.withOpacity(0.0),
      ],
    );
    
    final blueGradient = RadialGradient(
      center: const Alignment(0.2, 0.8),
      radius: 0.8,
      colors: [
        SpaceTheme.pulsarBlue.withOpacity(0.4),
        SpaceTheme.pulsarBlue.withOpacity(0.0),
      ],
    );
    
    // Draw nebula clouds
    canvas.drawRect(rect, Paint()..shader = purpleGradient.createShader(rect));
    canvas.drawRect(rect, Paint()..shader = pinkGradient.createShader(rect));
    canvas.drawRect(rect, Paint()..shader = blueGradient.createShader(rect));
  }

  @override
  bool shouldRepaint(NebulaPainter oldDelegate) => false;
}
