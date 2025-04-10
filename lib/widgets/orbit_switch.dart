import 'package:flutter/material.dart';
import '../theme/space_theme.dart';

class OrbitSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final String? label;
  final double width;
  final double height;

  const OrbitSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.label,
    this.width = 60.0,
    this.height = 30.0,
  }) : super(key: key);

  @override
  State<OrbitSwitch> createState() => _OrbitSwitchState();
}

class _OrbitSwitchState extends State<OrbitSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _orbitAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _orbitAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(OrbitSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? SpaceTheme.pulsarBlue;
    final inactiveColor = widget.inactiveColor ?? SpaceTheme.asteroidGray;
    
    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: SpaceTheme.textTheme.bodyMedium,
            ),
            const SizedBox(width: 8),
          ],
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final trackColor = Color.lerp(
                inactiveColor,
                activeColor,
                _animation.value,
              )!;
              
              return Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  color: trackColor.withOpacity(0.3),
                  border: Border.all(
                    color: trackColor,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: trackColor.withOpacity(0.3 * _animation.value),
                      blurRadius: 8 * _animation.value,
                      spreadRadius: 1 * _animation.value,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Orbit path
                    Center(
                      child: Container(
                        height: widget.height * 0.4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.height / 2),
                          border: Border.all(
                            color: SpaceTheme.starlightSilver.withOpacity(0.3),
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignCenter,
                          ),
                        ),
                      ),
                    ),
                    
                    // Thumb/planet
                    Positioned(
                      left: Tween<double>(
                        begin: 2.0,
                        end: widget.width - widget.height + 2.0,
                      ).evaluate(_animation),
                      top: 2.0,
                      child: Container(
                        width: widget.height - 4,
                        height: widget.height - 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.value ? SpaceTheme.pulsarBlue : SpaceTheme.starlightSilver,
                              widget.value ? SpaceTheme.auroraGreen : SpaceTheme.asteroidGray,
                            ],
                            center: const Alignment(-0.3, -0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (widget.value ? activeColor : inactiveColor).withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: (widget.height - 4) * 0.3,
                            height: (widget.height - 4) * 0.3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 2,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Small orbiting moon
                    Positioned(
                      left: Tween<double>(
                        begin: 2.0,
                        end: widget.width - widget.height + 2.0,
                      ).evaluate(_animation),
                      top: 2.0,
                      child: Transform.translate(
                        offset: Offset(
                          (widget.height - 4) * 0.7 * cos(2 * 3.14159 * _orbitAnimation.value),
                          (widget.height - 4) * 0.7 * sin(2 * 3.14159 * _orbitAnimation.value),
                        ),
                        child: Container(
                          width: (widget.height - 4) * 0.25,
                          height: (widget.height - 4) * 0.25,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SpaceTheme.starlightSilver,
                            boxShadow: [
                              BoxShadow(
                                color: SpaceTheme.starlightSilver.withOpacity(0.5),
                                blurRadius: 2,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helper function to convert degrees to radians
double cos(double radians) {
  return Math.cos(radians);
}

double sin(double radians) {
  return Math.sin(radians);
}

// Import dart:math as Math to avoid conflicts
import 'dart:math' as Math;
