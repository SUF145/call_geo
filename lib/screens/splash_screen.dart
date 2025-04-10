import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/space_theme.dart';
import '../widgets/space_background.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({
    Key? key,
    required this.nextScreen,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rocketAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _rocketAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.6, curve: Curves.easeIn)),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.6, curve: Curves.easeOut)),
    );
    
    _controller.forward();
    
    // Navigate to next screen after animation completes
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeInOut;
            
            var fadeAnimation = Tween(begin: begin, end: end).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );
            
            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpaceBackground(
        starCount: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rocket animation
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -100 * _rocketAnimation.value),
                    child: Opacity(
                      opacity: 1.0,
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Stack(
                          children: [
                            // Rocket
                            Positioned.fill(
                              child: CustomPaint(
                                painter: RocketPainter(
                                  animation: _controller.value,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              // App name with animation
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Text(
                      "CallGeo",
                      style: SpaceTheme.textTheme.displayLarge?.copyWith(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: SpaceTheme.starlightSilver,
                        shadows: [
                          BoxShadow(
                            color: SpaceTheme.pulsarBlue.withOpacity(0.7),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "TRACKER",
                      style: SpaceTheme.orbitronStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: SpaceTheme.nebulaPink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RocketPainter extends CustomPainter {
  final double animation;

  RocketPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw rocket body
    final rocketPath = Path()
      ..moveTo(center.dx, center.dy - size.height * 0.4)
      ..lineTo(center.dx + size.width * 0.15, center.dy + size.height * 0.1)
      ..lineTo(center.dx + size.width * 0.15, center.dy + size.height * 0.3)
      ..lineTo(center.dx - size.width * 0.15, center.dy + size.height * 0.3)
      ..lineTo(center.dx - size.width * 0.15, center.dy + size.height * 0.1)
      ..close();
    
    // Rocket body gradient
    final rocketGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        SpaceTheme.starlightSilver,
        SpaceTheme.pulsarBlue,
      ],
    ).createShader(Rect.fromPoints(
      Offset(center.dx, center.dy - size.height * 0.4),
      Offset(center.dx, center.dy + size.height * 0.3),
    ));
    
    final rocketPaint = Paint()
      ..shader = rocketGradient
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(rocketPath, rocketPaint);
    
    // Draw rocket window
    final windowPaint = Paint()
      ..color = SpaceTheme.deepSpaceNavy
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(center.dx, center.dy - size.height * 0.1),
      size.width * 0.08,
      windowPaint,
    );
    
    // Draw window highlight
    final windowHighlightPaint = Paint()
      ..color = SpaceTheme.starlightSilver.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(center.dx - size.width * 0.02, center.dy - size.height * 0.12),
      size.width * 0.02,
      windowHighlightPaint,
    );
    
    // Draw rocket fins
    final leftFinPath = Path()
      ..moveTo(center.dx - size.width * 0.15, center.dy + size.height * 0.2)
      ..lineTo(center.dx - size.width * 0.3, center.dy + size.height * 0.35)
      ..lineTo(center.dx - size.width * 0.15, center.dy + size.height * 0.3)
      ..close();
    
    final rightFinPath = Path()
      ..moveTo(center.dx + size.width * 0.15, center.dy + size.height * 0.2)
      ..lineTo(center.dx + size.width * 0.3, center.dy + size.height * 0.35)
      ..lineTo(center.dx + size.width * 0.15, center.dy + size.height * 0.3)
      ..close();
    
    final finPaint = Paint()
      ..color = SpaceTheme.nebulaPink
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(leftFinPath, finPaint);
    canvas.drawPath(rightFinPath, finPaint);
    
    // Draw rocket exhaust flames
    if (animation > 0) {
      final flameAnimation = (animation * 10) % 1.0;
      
      final flamePath1 = Path()
        ..moveTo(center.dx - size.width * 0.1, center.dy + size.height * 0.3)
        ..lineTo(center.dx, center.dy + size.height * (0.5 + 0.1 * flameAnimation))
        ..lineTo(center.dx + size.width * 0.1, center.dy + size.height * 0.3)
        ..close();
      
      final flamePath2 = Path()
        ..moveTo(center.dx - size.width * 0.05, center.dy + size.height * 0.3)
        ..lineTo(center.dx, center.dy + size.height * (0.6 - 0.1 * flameAnimation))
        ..lineTo(center.dx + size.width * 0.05, center.dy + size.height * 0.3)
        ..close();
      
      final flameGradient1 = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          SpaceTheme.saturnGold,
          SpaceTheme.marsRed.withOpacity(0.0),
        ],
      ).createShader(Rect.fromPoints(
        Offset(center.dx, center.dy + size.height * 0.3),
        Offset(center.dx, center.dy + size.height * 0.6),
      ));
      
      final flameGradient2 = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          SpaceTheme.marsRed,
          SpaceTheme.nebulaPink.withOpacity(0.0),
        ],
      ).createShader(Rect.fromPoints(
        Offset(center.dx, center.dy + size.height * 0.3),
        Offset(center.dx, center.dy + size.height * 0.7),
      ));
      
      final flamePaint1 = Paint()
        ..shader = flameGradient1
        ..style = PaintingStyle.fill;
      
      final flamePaint2 = Paint()
        ..shader = flameGradient2
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(flamePath1, flamePaint1);
      canvas.drawPath(flamePath2, flamePaint2);
    }
  }

  @override
  bool shouldRepaint(RocketPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
