import 'package:flutter/material.dart';

/// 点击时下沉 5px，松手弹回原位的按钮
class PressableButton extends StatefulWidget {
  const PressableButton({
    super.key,
    required this.onTap,
    required this.child,
    this.downOffset = 5.0,      // 下沉像素
    this.durationMs = 100,      // 动画时长（毫秒）
  });

  final VoidCallback onTap;
  final Widget child;
  final double downOffset;
  final int durationMs;

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> {
  double _yOffset = 0;

  void _onTapDown(TapDownDetails _) {
    setState(() {
      _yOffset = widget.downOffset;
    });
  }

  void _onTapUp(TapUpDetails _) {
    setState(() {
      _yOffset = 0;
    });
  }

  void _onTapCancel() {
    setState(() {
      _yOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: Duration(milliseconds: widget.durationMs),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _yOffset, 0),
        child: widget.child,
      ),
    );
  }
}