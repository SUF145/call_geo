import 'package:flutter/material.dart';
import '../theme/space_theme.dart';

class CosmicTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool enabled;

  const CosmicTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffix,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CosmicTextField> createState() => _CosmicTextFieldState();
}

class _CosmicTextFieldState extends State<CosmicTextField> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFocused = false;

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
    
    widget.focusNode?.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (widget.focusNode?.hasFocus ?? false) {
      _controller.forward();
      setState(() => _isFocused = true);
    } else {
      _controller.reverse();
      setState(() => _isFocused = false);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isFocused 
                    ? SpaceTheme.pulsarBlue.withOpacity(0.3 * _animation.value)
                    : Colors.transparent,
                blurRadius: 8 * _animation.value,
                spreadRadius: 1 * _animation.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        onChanged: widget.onChanged,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        style: SpaceTheme.textTheme.bodyMedium,
        cursorColor: SpaceTheme.pulsarBlue,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon != null 
              ? Icon(widget.prefixIcon, color: SpaceTheme.starlightSilver)
              : null,
          suffix: widget.suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: SpaceTheme.starlightSilver, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: SpaceTheme.starlightSilver, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: SpaceTheme.pulsarBlue, width: 2),
          ),
          filled: true,
          fillColor: SpaceTheme.asteroidGray.withOpacity(0.3),
        ),
      ),
    );
  }
}
