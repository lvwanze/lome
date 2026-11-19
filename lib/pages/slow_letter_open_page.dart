import 'package:flutter/material.dart';

class SlowLetterOpenPage extends StatefulWidget {
  final String letterNo;
  final String title;
  final String content;
  final String recipientLabel;

  const SlowLetterOpenPage({
    super.key,
    required this.letterNo,
    required this.title,
    required this.content,
    required this.recipientLabel,
  });

  @override
  State<SlowLetterOpenPage> createState() =>
      _SlowLetterOpenPageState();
}

class _SlowLetterOpenPageState extends State<SlowLetterOpenPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _envelopeScale;
  late Animation<double> _envelopeOpacity;
  late Animation<double> _sealOpacity;
  late Animation<double> _flapRotation;
  late Animation<double> _paperOpacity;
  late Animation<Offset> _paperSlide;
  late Animation<double> _paperScale;

  bool _isOpening = false;
  bool _isOpened = false;

  static const Color _textColor = Color(0xFF82766F);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _envelopeScale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    _envelopeOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.76, 1.0, curve: Curves.easeOut),
      ),
    );

    _sealOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.30, curve: Curves.easeIn),
      ),
    );

    _flapRotation = Tween<double>(
      begin: 3.1416,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.29, 0.58, curve: Curves.easeInOutCubic),
      ),
    );

    _paperOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 0.68, curve: Curves.easeIn),
      ),
    );

    _paperSlide = Tween<Offset>(
      begin: const Offset(0, 0.55),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _paperScale = Tween<double>(
      begin: 0.86,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _isOpened = true;
          _isOpening = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 开始开信
  Future<void> _openLetter() async {
    if (_isOpening || _isOpened) return;

    setState(() {
      _isOpening = true;
    });

    await _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final envelopeWidth = width < 600 ? width : 560.0;
          final envelopeHeight = envelopeWidth * 0.57;
          final envelopeLeft = (width - envelopeWidth) / 2;
          final paperWidth = envelopeWidth * 0.9;
          final paperLeft = (width - paperWidth) / 2;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. 页面背景
                  Image.asset(
                    'assets/images/letter_bg.png',
                    fit: BoxFit.cover,
                  ),

                  // 2. 信封后层底片
                  Positioned(
                    left: envelopeLeft,
                    width: envelopeWidth,
                    bottom: 0,
                    height: envelopeHeight,
                    child: Transform.scale(
                      scale: _envelopeScale.value,
                      child: Opacity(
                        opacity: _envelopeOpacity.value,
                        child: Image.asset(
                          'assets/images/纯色信封后层底形 · 下半部分.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),

                  // 3. 翻盖绕底边从倒置翻至正向
                  Positioned(
                    left: envelopeLeft,
                    width: envelopeWidth,
                    bottom: envelopeHeight * 0.18,
                    height: envelopeHeight,
                    child: Transform(
                      alignment: const Alignment(0, 0.45),
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015)
                        ..rotateX(_flapRotation.value),
                      child: Opacity(
                        opacity: _envelopeOpacity.value,
                        child: Image.asset(
                          'assets/images/纯色信封后层底形 · 上半部分.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),

                  // 4. 信纸：翻盖打开后从信封内部向上展开
                  if (_controller.value > 0)
                    Positioned(
                      left: paperLeft,
                      width: paperWidth,
                      top: height * 0.105,
                      height: height * 0.79,
                      child: FadeTransition(
                        opacity: _paperOpacity,
                        child: SlideTransition(
                          position: _paperSlide,
                          child: Transform.scale(
                            scale: _paperScale.value,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // 信纸图片
                                Image.asset(
                                  'assets/images/信纸-纯白心事.png',
                                  fit: BoxFit.fill,
                                ),

                                // 信件编号
                                Positioned(
                                  top: height * 0.015,
                                  left: 0,
                                  right: 0,
                                  child: Text(
                                    widget.letterNo,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 30,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),

                                // 信件标题
                                Positioned(
                                  top: height * 0.17,
                                  left: paperWidth * 0.07,
                                  right: paperWidth * 0.07,
                                  child: Text(
                                    widget.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Color(0xFFC9B5B3),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),

                                // 信件正文
                                Positioned(
                                  top: height * 0.235,
                                  left: paperWidth * 0.075,
                                  right: paperWidth * 0.075,
                                  bottom: height * 0.105,
                                  child: SingleChildScrollView(
                                    child: Text(
                                      widget.content,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.9,
                                        color: _textColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),

                                // 收件人称呼
                                Positioned(
                                  bottom: height * 0.025,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF0E9)
                                            .withValues(alpha: 0.75),
                                        border: Border.all(
                                          color: const Color(0xFFC8D2C9),
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Text(
                                        'to (${widget.recipientLabel})',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          color: Color(0xFF929B94),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 5. 信封前片
                  Positioned(
                    left: envelopeLeft,
                    width: envelopeWidth,
                    bottom: 0,
                    height: envelopeHeight,
                    child: Transform.scale(
                      scale: _envelopeScale.value,
                      child: Opacity(
                        opacity: _envelopeOpacity.value,
                        child: Image.asset(
                          'assets/images/纯色信封底形.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),

                  // 6. 封口贴
                  if (!_isOpened)
                    Positioned(
                      left: width / 2 - envelopeWidth * 0.11,
                      width: envelopeWidth * 0.22,
                      bottom: envelopeHeight * 0.47,
                      height: height * 0.10,
                      child: Opacity(
                        opacity: _sealOpacity.value,
                        child: GestureDetector(
                          onTap: _openLetter,
                          child: Image.asset(
                            'assets/images/封口贴图案.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                  // 7. 点击提示
                  if (!_isOpening && !_isOpened)
                    Positioned(
                      bottom: envelopeHeight * 0.12,
                      left: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _openLetter,
                        child: const Text(
                          '轻触信封，开启这封来信',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF66816B),
                            fontSize: 15,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),

                  // 8. 返回按钮
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 18,
                    left: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 62,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}