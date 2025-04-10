import 'package:flutter/material.dart';
import '../theme/space_theme.dart';

class CosmicButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  final bool isGlowing;
  final bool isOutlined;
  final double width;
  final double height;

  const CosmicButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color,
    this.isGlowing = true,
    this.isOutlined = false,
    this.width = double.infinity,
    this.height = 56,
  }) : super(key: key);

  @override
  State<CosmicButton> createState() => _CosmicButtonState();
}

class _CosmicButtonState extends State<CosmicButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
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
    final buttonColor = widget.color ?? SpaceTheme.cosmicPurple;
    
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
              borderRadius: BorderRadius.circular(30),
              boxShadow: widget.isGlowing ? [
                BoxShadow(
                  color: buttonColor.withOpacity(_isHovered ? 0.5 : 0.3 * _glowAnimation.value),
                  blurRadius: _isHovered ? 15 : 10 * _glowAnimation.value,
                  spreadRadius: _isHovered ? 2 : 1 * _glowAnimation.value,
                ),
              ] : null,
            ),
            child: child,
          );
        },
        child: widget.isOutlined
            ? OutlinedButton(
                onPressed: widget.onPressed,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: buttonColor,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _buildButtonContent(),
              )
            : ElevatedButton(
                onPressed: widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _buildButtonContent(),
              ),
      ),
    );
  }

  Widget _buildButtonContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: SpaceTheme.textTheme.labelLarge,
        ),
      ],
    );
  }
}
