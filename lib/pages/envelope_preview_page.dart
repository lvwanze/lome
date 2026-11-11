import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lome/pages/my_letters_page.dart';
import 'package:lome/services/letter_store.dart';

class EnvelopePreviewPage extends StatefulWidget {
  const EnvelopePreviewPage({
    super.key,
    required this.letter,
    this.recipient = '自己',
    this.onOpened,
  });

  final Letter letter;
  final String recipient;
  final ValueChanged<Letter>? onOpened;

  @override
  State<EnvelopePreviewPage> createState() => _EnvelopePreviewPageState();
}

class _EnvelopePreviewPageState extends State<EnvelopePreviewPage> {
  static const Color _inkGreen = Color(0xFF7F9A5E);
  static const Color _titleGreen = Color(0xFF9DBF8C);
  static const Color _softText = Color(0xFF8FA57F);
  static const Color _noteYellow = Color(0xFFF8F0D3);

  late Letter _letter;
  Timer? _ticker;
  double _envelopeScale = 1.0;

  @override
  void initState() {
    super.initState();
    _letter = widget.letter;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onTapWithHaptic(VoidCallback action) {
    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android) {
      HapticFeedback.lightImpact();
    }
    action();
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}年$month月$day日';
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${_formatDate(value)} $hour:$minute';
  }

  double get _progress {
    final total = _letter.deliverAt.difference(_letter.sentAt).inSeconds;
    if (total <= 0) return 1.0;
    final passed = DateTime.now().difference(_letter.sentAt).inSeconds;
    return (passed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/cloud_bg.png',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.white.withOpacity(0.10)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTopBar(),
                          const SizedBox(height: 18),
                          _buildProgressBar(),
                          const SizedBox(height: 34),
                          _buildEnvelope(),
                          const SizedBox(height: 30),
                          _buildStatusRow(),
                          const SizedBox(height: 10),
                          _buildDeliveryText(),
                          const SizedBox(height: 26),
                          _buildBottomNavBar(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _onTapWithHaptic(() => Navigator.pop(context)),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: _inkGreen.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back,
              size: 20,
              color: _softText,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              '信封预览',
              style: TextStyle(
                fontSize: 15,
                letterSpacing: 2,
                color: _softText.withOpacity(0.95),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
          ),
          child: Text(
            _letter.code,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _softText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = _progress;
    final inTransit = _letter.stage == LetterStage.inTransit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: _titleGreen.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Text(
          inTransit
              ? '信件已走过 ${(progress * 100).round()}% 的路程'
              : '这封信已经走完全程',
          style: TextStyle(
            fontSize: 11.5,
            letterSpacing: 0.5,
            color: _softText.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildEnvelope() {
    final width = MediaQuery.of(context).size.width;
    final envelopeWidth = width < 600 ? width - 60 : 340.0;
    final stage = _letter.stage;

    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _envelopeScale = 0.97),
        onTapUp: (_) => setState(() => _envelopeScale = 1.0),
        onTapCancel: () => setState(() => _envelopeScale = 1.0),
        onTap: () => _onTapWithHaptic(_handleEnvelopeTap),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          scale: _envelopeScale,
          child: SizedBox(
            width: envelopeWidth,
            child: AspectRatio(
              aspectRatio: 1 / 0.66,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF6),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CustomPaint(
                        painter: EnvelopeFlapPainter(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 54,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _noteYellow,
                        border: Border.all(
                          color: const Color(0xFFE0D0A0),
                          width: 1.5,
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: _buildStampContent(stage),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.42),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F0E6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFC0D0C0),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'to（${widget.recipient}）',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.caveat(
                          fontSize: 17,
                          color: const Color(0xFF708070),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 12,
                    child: Text(
                      stage == LetterStage.inTransit
                          ? '正在路上'
                          : stage == LetterStage.delivered
                              ? '轻点拆开信封'
                              : '已拆封',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1,
                        color: _inkGreen.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStampContent(LetterStage stage) {
    final showImage = stage != LetterStage.inTransit && _letter.images.isNotEmpty;
    if (showImage) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Image.network(
            _letter.images.first,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildStampIcon(),
          ),
        ),
      );
    }
    return _buildStampIcon();
  }

  Widget _buildStampIcon() {
    return Center(
      child: Icon(
        Icons.photo_size_select_large_outlined,
        size: 20,
        color: _inkGreen.withOpacity(0.5),
      ),
    );
  }

  Widget _buildStatusRow() {
    final stage = _letter.stage;
    final remaining = _letter.remaining;
    final statusText = stage == LetterStage.inTransit
        ? '${_letter.code}正在寄送中'
        : stage == LetterStage.delivered
            ? '${_letter.code}已送达'
            : '${_letter.code}已拆封';

    final children = <Widget>[
      Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: stage == LetterStage.inTransit
              ? const Color(0xFFD3C2B8)
              : const Color(0xFFBFD8CB),
          shape: BoxShape.circle,
        ),
        child: Icon(
          stage == LetterStage.inTransit ? Icons.send : Icons.check,
          color: Colors.white,
          size: 11,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        statusText,
        style: TextStyle(
          color: _softText.withOpacity(0.95),
          fontSize: 13.5,
        ),
      ),
      const SizedBox(width: 18),
    ];

    if (stage == LetterStage.inTransit) {
      children.addAll([
        Text(
          '还有 ',
          style: TextStyle(color: _softText.withOpacity(0.95), fontSize: 13.5),
        ),
        _buildCountNumber('${remaining.inDays}'),
        Text(
          ' 天 ',
          style: TextStyle(color: _softText.withOpacity(0.95), fontSize: 13.5),
        ),
        _buildCountNumber('${remaining.inHours % 24}'),
        Text(
          ' 小时',
          style: TextStyle(color: _softText.withOpacity(0.95), fontSize: 13.5),
        ),
      ]);
    } else {
      children.add(
        Text(
          stage == LetterStage.delivered ? '轻点信封即可拆开' : '已经收进回忆里',
          style: TextStyle(
            color: _softText.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 6,
      children: children,
    );
  }

  Widget _buildCountNumber(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: Color(0xFFE8A0A0),
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDeliveryText() {
    final stage = _letter.stage;
    final String text;
    if (stage == LetterStage.inTransit) {
      text = '预计 ${_formatDateTime(_letter.deliverAt)} 送达';
    } else if (stage == LetterStage.delivered) {
      text = '${_formatDateTime(_letter.deliverAt)} 已送达';
    } else {
      text = '${_formatDateTime(_letter.openedAt ?? _letter.deliverAt)} 已拆封';
    }
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _softText.withOpacity(0.8),
          fontSize: 12.5,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRoundButton(
          Icons.mail_outline,
          () => _openLetterList(),
        ),
        GestureDetector(
          onTap: () => _onTapWithHaptic(_handleEnvelopeTap),
          child: Container(
            width: 120,
            height: 50,
            decoration: BoxDecoration(
              color: _noteYellow,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _letter.stage == LetterStage.delivered
                    ? Icons.mark_email_unread_outlined
                    : Icons.notifications_none,
                color: const Color(0xFFC0B090),
                size: 26,
              ),
            ),
          ),
        ),
        _buildRoundButton(
          Icons.schedule,
          () => _showSnapshot(),
        ),
      ],
    );
  }

  Widget _buildRoundButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () => _onTapWithHaptic(onTap),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.7)),
        ),
        child: Icon(
          icon,
          color: _softText.withOpacity(0.9),
          size: 20,
        ),
      ),
    );
  }

  Future<void> _handleEnvelopeTap() async {
    final stage = _letter.stage;
    if (stage == LetterStage.inTransit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '这封信还在路上，还有 ${_letter.remaining.inDays} 天 '
            '${_letter.remaining.inHours % 24} 小时到达',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _inkGreen.withOpacity(0.92),
        ),
      );
      return;
    }
    if (stage == LetterStage.delivered) {
      final updated = await LetterStore.markOpened(_letter.id);
      if (!mounted) return;
      final opened = updated.firstWhere(
        (e) => e.id == _letter.id,
        orElse: () => _letter.copyWith(openedAt: DateTime.now()),
      );
      setState(() => _letter = opened);
      widget.onOpened?.call(opened);
    }
    if (!mounted) return;
    _showSnapshot();
  }

  void _showSnapshot() {
    final letter = _letter;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _PreviewSnapshotSheet(
          letter: letter,
          recipient: widget.recipient,
          formatDateTime: _formatDateTime,
        );
      },
    );
  }

  void _openLetterList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyLettersPage(receivedOnly: !_letter.fromMe),
      ),
    );
  }
}

class _PreviewSnapshotSheet extends StatelessWidget {
  const _PreviewSnapshotSheet({
    required this.letter,
    required this.recipient,
    required this.formatDateTime,
  });

  final Letter letter;
  final String recipient;
  final String Function(DateTime) formatDateTime;

  String get _stageText {
    switch (letter.stage) {
      case LetterStage.inTransit:
        return '寄送中';
      case LetterStage.delivered:
        return '待拆开';
      case LetterStage.opened:
        return '已拆封';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF6).withOpacity(0.97),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF7F9A5E).withOpacity(0.25),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7F9A5E).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9DBF8C).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            letter.code,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7F9A5E),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _stageText,
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1,
                            color: const Color(0xFF7F9A5E).withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      letter.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: Color(0xFF6E7F63),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'to（$recipient）  ·  ${formatDateTime(letter.sentAt)} 寄出',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: const Color(0xFF8FA57F).withOpacity(0.95),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: const Color(0xFF7F9A5E).withOpacity(0.18),
                    ),
                    const SizedBox(height: 16),
                    if (letter.stage == LetterStage.inTransit)
                      Text(
                        '这封信还在路上，等它到了再读吧。',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.9,
                          color: const Color(0xFF8FA57F).withOpacity(0.9),
                        ),
                      )
                    else
                      Text(
                        letter.content,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.9,
                          color: Color(0xFF7B8A74),
                        ),
                      ),
                    if (letter.images.isNotEmpty &&
                        letter.stage != LetterStage.inTransit) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: letter.images.map((url) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              url,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 96,
                                height: 96,
                                color: const Color(0xFFEDF1E3),
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 22,
                                  color: const Color(0xFF7F9A5E)
                                      .withOpacity(0.5),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF7F9A5E).withOpacity(0.25),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '收起来',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7F9A5E),
                              letterSpacing: 1.5,
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
      ),
    );
  }
}

class EnvelopeFlapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height * 0.4);
    path.lineTo(size.width, 0);

    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.3, size.height * 0.7);
    path.moveTo(size.width, size.height);
    path.lineTo(size.width * 0.7, size.height * 0.7);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}