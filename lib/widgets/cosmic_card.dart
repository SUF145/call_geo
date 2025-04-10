import 'package:flutter/material.dart';
import '../theme/space_theme.dart';

class CosmicCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final bool isGlowing;
  final Color? glowColor;
  final double borderRadius;
  final Color? backgroundColor;

  const CosmicCard({
    Key? key,
    required this.child,
    this.onTap,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.isGlowing = true,
    this.glowColor,
    this.borderRadius = 16,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<CosmicCard> createState() => _CosmicCardState();
}

class _CosmicCardState extends State<CosmicCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? SpaceTheme.pulsarBlue;
    final backgroundColor = widget.backgroundColor ?? 
        SpaceTheme.asteroidGray.withOpacity(0.3);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: glowColor.withOpacity(
                  widget.isGlowing ? (_isHovered ? 0.8 : 0.3 + 0.2 * _glowAnimation.value) : 0.3
                ),
                width: _isHovered ? 2 : 1,
              ),
              boxShadow: widget.isGlowing ? [
                BoxShadow(
                  color: glowColor.withOpacity(_isHovered ? 0.3 : 0.1 * _glowAnimation.value),
                  blurRadius: _isHovered ? 12 : 8 * _glowAnimation.value,
                  spreadRadius: _isHovered ? 1 : 0.5 * _glowAnimation.value,
                ),
              ] : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                splashColor: glowColor.withOpacity(0.1),
                highlightColor: glowColor.withOpacity(0.05),
                child: Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
