import 'package:flutter/material.dart';

class ElasticButton extends StatefulWidget {
  const ElasticButton({
    super.key,
    required this.onTap,
    required this.child,
    this.hoverScale = 1.02,
    this.clickScale = 0.95,
    this.animationDuration = const Duration(milliseconds: 120),
  });

  final VoidCallback onTap;
  final Widget child;
  final double hoverScale;
  final double clickScale;
  final Duration animationDuration;

  @override
  State<ElasticButton> createState() => _ElasticButtonState();
}

class _ElasticButtonState extends State<ElasticButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final clickScaleValue =
                1.0 - (1.0 - widget.clickScale) * _controller.value;
            final finalScale = _isHovering ? widget.hoverScale : clickScaleValue;
            return Transform.scale(
              scale: finalScale,
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}