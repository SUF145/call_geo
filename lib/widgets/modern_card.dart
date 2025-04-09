import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// A modern card with animations and customizable styling
class ModernCard extends StatelessWidget {
  /// The child widget to display inside the card
  final Widget child;
  
  /// The background color of the card
  final Color? backgroundColor;
  
  /// The border radius of the card
  final double borderRadius;
  
  /// The elevation of the card
  final double elevation;
  
  /// The padding inside the card
  final EdgeInsetsGeometry padding;
  
  /// The margin around the card
  final EdgeInsetsGeometry margin;
  
  /// Whether to animate the card when it appears
  final bool animate;
  
  /// The animation delay in milliseconds
  final int animationDelayMs;

  const ModernCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderRadius = 16,
    this.elevation = 2,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.animate = true,
    this.animationDelayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Card(
      margin: margin,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      color: backgroundColor ?? AppTheme.cardBackgroundColor,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (animate) {
      return cardContent
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: animationDelayMs),
            duration: 400.ms,
          )
          .slideY(
            begin: 0.1,
            end: 0,
            delay: Duration(milliseconds: animationDelayMs),
            duration: 400.ms,
          );
    }

    return cardContent;
  }
}

/// A section card with a title and customizable styling
class SectionCard extends StatelessWidget {
  /// The title of the section
  final String title;
  
  /// The child widget to display inside the card
  final Widget child;
  
  /// The color accent for the title
  final Color? color;
  
  /// The background color of the card
  final Color? backgroundColor;
  
  /// The border radius of the card
  final double borderRadius;
  
  /// The elevation of the card
  final double elevation;
  
  /// The padding inside the card
  final EdgeInsetsGeometry padding;
  
  /// The margin around the card
  final EdgeInsetsGeometry margin;
  
  /// Whether to animate the card when it appears
  final bool animate;
  
  /// The animation delay in milliseconds
  final int animationDelayMs;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.color,
    this.backgroundColor,
    this.borderRadius = 16,
    this.elevation = 2,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.animate = true,
    this.animationDelayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = color ?? AppTheme.primaryColor;
    
    return ModernCard(
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      elevation: elevation,
      padding: EdgeInsets.zero,
      margin: margin,
      animate: animate,
      animationDelayMs: animationDelayMs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: titleColor.withAlpha(20),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          
          // Content section
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// A status card with a value and icon
class StatusCard extends StatelessWidget {
  /// The title of the status
  final String title;
  
  /// The value to display
  final String value;
  
  /// The icon to display
  final IconData icon;
  
  /// The color accent for the card
  final Color? color;
  
  /// The background color of the card
  final Color? backgroundColor;
  
  /// Whether to animate the card when it appears
  final bool animate;
  
  /// The animation delay in milliseconds
  final int animationDelayMs;

  const StatusCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.animate = true,
    this.animationDelayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = color ?? AppTheme.primaryColor;
    
    Widget cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? statusColor.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and icon
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );

    if (animate) {
      return cardContent
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: animationDelayMs),
            duration: 400.ms,
          )
          .slideY(
            begin: 0.1,
            end: 0,
            delay: Duration(milliseconds: animationDelayMs),
            duration: 400.ms,
          );
    }

    return cardContent;
  }
}

/// A feature card with an icon, title, and description
class FeatureCard extends StatelessWidget {
  /// The title of the feature
  final String title;
  
  /// The description of the feature
  final String description;
  
  /// The icon to display
  final IconData icon;
  
  /// The color accent for the card
  final Color? color;
  
  /// The function to call when the card is tapped
  final VoidCallback? onTap;
  
  /// Whether to animate the card when it appears
  final bool animate;
  
  /// The animation delay in milliseconds
  final int animationDelayMs;

  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.color,
    this.onTap,
    this.animate = true,
    this.animationDelayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    final featureColor = color ?? AppTheme.primaryColor;
    
    Widget cardContent = Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: featureColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: featureColor,
                  size: 30,
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: featureColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.secondaryTextColor,
                          ),
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color: featureColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );

    if (animate) {
      return cardContent
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: animationDelayMs),
            duration: 600.ms,
          )
          .slideX(
            begin: 0.1,
            end: 0,
            delay: Duration(milliseconds: animationDelayMs),
            duration: 600.ms,
          );
    }

    return cardContent;
  }
}
