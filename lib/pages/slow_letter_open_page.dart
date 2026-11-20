import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../services/slow_letter_api.dart';

class SlowLetterOpenPage extends StatefulWidget {
  final String letterId;
  final String letterNo;
  final String recipientLabel;

  const SlowLetterOpenPage({
    super.key,
    required this.letterId,
    required this.letterNo,
    this.recipientLabel = '你',
  });

  @override
  State<SlowLetterOpenPage> createState() => _SlowLetterOpenPageState();
}

class _SlowLetterOpenPageState extends State<SlowLetterOpenPage>
    with TickerProviderStateMixin {
  late final AnimationController _openingController;
  late final AnimationController _paperController;
  late final Animation<double> _sealAnimation;
  late final Animation<double> _flapAnimation;
  late final Animation<double> _paperAnimation;
  bool _openingStarted = false;
  bool _flapIsBehind = false;
  bool _contentLoading = false;
  bool _readInProgress = false;
  bool _readCompleted = false;
  String? _loadError;
  String? _readError;
  String? _attachmentError;
  String _title = '';
  String _content = '';
  String? _viewToken;
  Uint8List? _attachmentBytes;

  static const Color _textColor = Color(0xFF82766F);

  @override
  void initState() {
    super.initState();
    _openingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _paperController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _sealAnimation = CurvedAnimation(
      parent: _openingController,
      curve: const Interval(0, 0.24, curve: Curves.easeInOut),
    );
    _flapAnimation = CurvedAnimation(
      parent: _openingController,
      curve: const Interval(0.16, 1, curve: Curves.easeInOutCubic),
    );
    _flapAnimation.addListener(_updateFlapLayer);
    _paperAnimation = CurvedAnimation(
      parent: _paperController,
      curve: Curves.easeInOutCubic,
    );
  }

  // 翻盖旋转到 90° 后，切换到信纸后方。
  void _updateFlapLayer() {
    final shouldBeBehind = _flapAnimation.value >= 0.5;
    if (_flapIsBehind != shouldBeBehind && mounted) {
      setState(() {
        _flapIsBehind = shouldBeBehind;
      });
    }
  }

  // 开始开信
  Future<void> _openLetter() async {
    if (_contentLoading || _openingStarted) return;

    setState(() {
      _openingStarted = true;
      _loadError = null;
    });
    try {
      await _openingController.forward();
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    await _loadLetterContent();
  }

  Future<void> _loadLetterContent() async {
    if (_contentLoading) return;
    setState(() {
      _contentLoading = true;
      _loadError = null;
    });

    try {
      final data = await SlowLetterApi.instance.content(widget.letterId);
      final attachment = data['attachment'];
      Uint8List? attachmentBytes;
      String? attachmentError;
      if (attachment is Map && attachment['attachmentId'] != null) {
        try {
          attachmentBytes = await SlowLetterApi.instance.attachment(
            letterId: widget.letterId,
            attachmentId: attachment['attachmentId'].toString(),
          );
        } catch (_) {
          attachmentError = '图片暂时无法显示，信件正文仍可阅读';
        }
      }
      if (!mounted) return;
      setState(() {
        _title = data['title']?.toString() ?? '';
        _content = data['content']?.toString() ?? '';
        _viewToken = data['viewToken']?.toString();
        _attachmentBytes = attachmentBytes;
        _attachmentError = attachmentError;
        _contentLoading = false;
      });
      await _acknowledgeRead();
      if (mounted) await _paperController.forward();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _contentLoading = false;
        _loadError = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _flapAnimation.removeListener(_updateFlapLayer);
    _openingController.dispose();
    _paperController.dispose();
    super.dispose();
  }

  Future<void> _acknowledgeRead() async {
    var token = _viewToken;
    if (token == null || token.isEmpty || _readInProgress || _readCompleted) {
      return;
    }
    final shouldRefreshToken = _readError != null;
    setState(() {
      _readInProgress = true;
      _readError = null;
    });
    try {
      if (shouldRefreshToken) {
        final refreshed = await SlowLetterApi.instance.content(widget.letterId);
        token = refreshed['viewToken']?.toString() ?? '';
        if (token.isEmpty) {
          if (mounted) {
            setState(() {
              _readCompleted = true;
              _viewToken = null;
            });
          }
          return;
        }
        _viewToken = token;
      }
      await SlowLetterApi.instance.acknowledgeRead(
        letterId: widget.letterId,
        viewToken: token,
      );
      if (!mounted) return;
      setState(() {
        _readCompleted = true;
        _viewToken = null;
      });
    } catch (error) {
      if (mounted) setState(() => _readError = error.toString());
    } finally {
      if (mounted) setState(() => _readInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _loadError ?? _readError;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final envelopeWidth = width < 600 ? width : 560.0;
          final envelopeHeight = envelopeWidth * 0.57;
          final envelopeLeft = (width - envelopeWidth) / 2;
          final stampHeight = envelopeHeight * 0.27;
          final stampWidth = stampHeight * 0.84;
          final maxPaperHeight =
              math
                  .max(
                    140.0,
                    constraints.maxHeight -
                        envelopeHeight -
                        MediaQuery.of(context).padding.top -
                        72,
                  )
                  .toDouble();
          final paperWidth =
              math.min(envelopeWidth * 0.68, maxPaperHeight / 1.72).toDouble();
          final paperHeight = paperWidth * 1.72;
            final paperStartOffset = paperHeight * 1.8;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/letter_bg.png', fit: BoxFit.cover),
              Positioned(
                left: envelopeLeft,
                width: envelopeWidth,
                bottom: 0,
                height: envelopeHeight,
                child: Image.asset(
                  'assets/images/纯色信封后层底形 · 下半部分.png',
                  fit: BoxFit.fill,
                ),
              ),
              // 翻盖打开到 90° 后，切换到信纸后方。
              if (_flapIsBehind)
                Positioned(
                left: envelopeLeft - envelopeWidth * 0.04,
                width: envelopeWidth * 1.08,
                bottom: -envelopeHeight * 0.12,
                height: envelopeHeight * 1.08,
                child: AnimatedBuilder(
                  animation: _flapAnimation,
                  builder: (context, child) {
                    return Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(-math.pi * _flapAnimation.value),
                      child: child,
                    );
                  },
                  child: Transform.rotate(
                    angle: math.pi,
                    child: Image.asset(
                      'assets/images/纯色信封后层底形 · 上半部分.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),


              // 第二阶段：翻盖打开后，信纸才开始向上抽出。
              AnimatedBuilder(
                animation: _paperAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: envelopeLeft + (envelopeWidth - paperWidth) / 2,
                    top: 0,
                    bottom: envelopeHeight,
                    width: paperWidth,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        minWidth: paperWidth,
                        maxWidth: paperWidth,
                        minHeight: paperHeight,
                        maxHeight: paperHeight,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            paperStartOffset * (1 - _paperAnimation.value),
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: SizedBox(
                  width: paperWidth,
                  height: paperHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/信纸-纯白心事.png',
                        fit: BoxFit.fill,
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          paperWidth * 0.10,
                          paperHeight * 0.09,
                          paperWidth * 0.10,
                          paperHeight * 0.07,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title.isEmpty ? '来信' : _title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _textColor,
                                fontSize:
                                    (paperWidth * 0.052)
                                        .clamp(15.0, 20.0)
                                        .toDouble(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Divider(height: 18, color: Color(0xFFD8D3C9)),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _content,
                                      style: TextStyle(
                                        color: _textColor,
                                        height: 1.7,
                                        fontSize:
                                            (paperWidth * 0.040)
                                                .clamp(13.0, 16.0)
                                                .toDouble(),
                                      ),
                                    ),
                                    if (_attachmentBytes != null) ...[
                                      const SizedBox(height: 14),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.memory(
                                          _attachmentBytes!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                    if (_attachmentError != null) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        _attachmentError!,
                                        style: const TextStyle(
                                          color: Color(0xFF9A6F5C),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              // 信封底形始终位于信纸前方，遮挡信纸下端。
              Positioned(
                left: envelopeLeft,
                width: envelopeWidth,
                bottom: 0,
                height: envelopeHeight,
                child: Image.asset(
                  'assets/images/纯色信封底形.png',
                  fit: BoxFit.fill,
                ),
              ),


              // 初始状态及翻盖翻转前半段：翻盖位于信纸前方。
              if (!_flapIsBehind)
                Positioned(
                left: envelopeLeft - envelopeWidth * 0.04,
                width: envelopeWidth * 1.08,
                bottom: -envelopeHeight * 0.08,
                height: envelopeHeight * 1.08,
                child: AnimatedBuilder(
                  animation: _flapAnimation,
                  builder: (context, child) {
                    return Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(-math.pi * _flapAnimation.value),
                      child: child,
                    );
                  },
                  child: Transform.rotate(
                    angle: math.pi,
                    child: Image.asset(
                      'assets/images/纯色信封后层底形 · 上半部分.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: envelopeLeft,
                width: envelopeWidth,
                bottom: 0,
                height: envelopeHeight,
                child: Stack(
                  children: [
                    Positioned(
                      left: (envelopeWidth - envelopeWidth * 0.22) / 2,
                      width: envelopeWidth * 0.22,
                      bottom: envelopeHeight * 0.12,
                      height: envelopeHeight * 0.18,
                      child: AnimatedBuilder(
                        animation: _sealAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 1 - _sealAnimation.value,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                envelopeHeight * 0.28 * _sealAnimation.value,
                              ),
                              child: Transform.rotate(
                                angle: 0.55 * _sealAnimation.value,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: _openLetter,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/封口贴图案.png',
                                fit: BoxFit.contain,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'to (${widget.recipientLabel.trim().isEmpty ? '你' : widget.recipientLabel.trim()})',
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF82766F),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: envelopeHeight * 0.02,
                      right: envelopeWidth * 0.08,
                      width: stampWidth,
                      height: stampHeight,
                      child: AnimatedBuilder(
                        animation: _sealAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 1 - _sealAnimation.value,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                envelopeHeight *
                                    0.28 *
                                    _sealAnimation.value,
                              ),
                              child: Transform.rotate(
                                angle: 0.55 * _sealAnimation.value,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Image.asset(
                          'assets/images/邮票v1.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 18,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.60),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF7F9A5E,
                          ).withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF8FA57F),
                      size: 20,
                    ),
                  ),
                ),
              ),
              if (_contentLoading || _readInProgress)
                const Center(
                  child: CircularProgressIndicator(color: _textColor),
                ),
              if (errorMessage != null)
                Positioned(
                  left: 24,
                  right: 24,
                  top: MediaQuery.of(context).padding.top + 82,
                  child: Material(
                    color: const Color(0xFFFFFDF6),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _textColor),
                          ),
                          TextButton.icon(
                            onPressed:
                                _contentLoading || _readInProgress
                                    ? null
                                    : _loadError != null
                                    ? _loadLetterContent
                                    : _acknowledgeRead,
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              _loadError != null ? '重试获取信件' : '重试确认已读',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
