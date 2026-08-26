import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Favorite toggle with a quick scale bounce.
class AnimatedFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onToggle;
  final double iconSize;

  const AnimatedFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.iconSize = 20,
  });

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: AppColors.navy.withValues(alpha: 0.12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onToggle,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ScaleTransition(
            scale: _scale,
            child: Icon(
              widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: widget.isFavorite ? const Color(0xFFE53935) : AppColors.textSecondary,
              size: widget.iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
