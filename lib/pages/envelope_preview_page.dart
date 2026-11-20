import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lome/pages/my_letters_page.dart';
import 'package:lome/pages/slow_letter_open_page.dart';
import 'package:lome/services/letter_store.dart';
import 'package:lome/widgets/envelope_template.dart';

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
  List<Letter> _inTransitLetters = const [];
  int _inTransitIndex = -1;
  Timer? _ticker;
  double _envelopeScale = 1.0;

  @override
  void initState() {
    super.initState();
    _letter = widget.letter;
    _loadInTransitLetters();
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

  Future<void> _loadInTransitLetters() async {
    try {
      final letters = await LetterStore.load();
      if (!mounted) return;
      final inTransit = LetterStore.inTransitOf(
        letters,
        fromMe: _letter.fromMe,
      );
      if (_letter.stage == LetterStage.inTransit &&
          !inTransit.any((letter) => letter.id == _letter.id)) {
        inTransit.insert(0, _letter);
      }
      setState(() {
        _inTransitLetters = inTransit;
        _inTransitIndex = inTransit.indexWhere(
          (letter) => letter.id == _letter.id,
        );
      });
    } catch (_) {}
  }

  void _switchInTransitLetter(int target) {
    if (target < 0 || target >= _inTransitLetters.length) return;
    setState(() {
      _inTransitIndex = target;
      _letter = _inTransitLetters[target];
    });
  }

  String get _currentRecipient {
    final label = _letter.recipientLabel.trim();
    return label.isEmpty ? widget.recipient : label;
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
          Image.asset('assets/images/cloud_bg.png', fit: BoxFit.cover),
          Container(color: Colors.white.withOpacity(0.10)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
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
                          if (_inTransitLetters.length > 1 &&
                              _inTransitIndex >= 0) ...[
                            const SizedBox(height: 12),
                            _buildTransitPager(),
                          ],
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
            child: const Icon(Icons.arrow_back, size: 20, color: _softText),
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
          inTransit ? '信件已走过 ${(progress * 100).round()}% 的路程' : '这封信已经走完全程',
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
                  Positioned.fill(
                    child: EnvelopeTemplate(
                      borderRadius: 18,
                      shadowColor: Colors.black.withOpacity(0.06),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: SizedBox(
                      width: 54,
                      height: 72,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset('assets/images/1.png', fit: BoxFit.fill),
                          if (stage != LetterStage.inTransit &&
                              _letter.images.isNotEmpty)
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  11,
                                  14,
                                  11,
                                  16,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: Image.network(
                                    _letter.images.first,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -0.20),
                    child: SizedBox(
                      width: 112,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/images/封口贴图案.png',
                            fit: BoxFit.contain,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'to (${_currentRecipient.trim().isEmpty ? '你' : _currentRecipient.trim()})',
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF82766F),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildStatusRow() {
    final stage = _letter.stage;
    final remaining = _letter.remaining;
    final statusText =
        stage == LetterStage.inTransit
            ? '${_letter.code}正在寄送中'
            : stage == LetterStage.delivered
            ? '${_letter.code}已送达'
            : '${_letter.code}已拆封';

    final children = <Widget>[
      Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color:
              stage == LetterStage.inTransit
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
        style: TextStyle(color: _softText.withOpacity(0.95), fontSize: 13.5),
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
          style: TextStyle(color: _softText.withOpacity(0.8), fontSize: 12),
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

  Widget _buildTransitPager() {
    final total = _inTransitLetters.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTransitArrow(
          Icons.chevron_left,
          _inTransitIndex > 0
              ? () => _switchInTransitLetter(_inTransitIndex - 1)
              : null,
          '上一封在途信件',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '在途信件 ${_inTransitIndex + 1} / $total',
            style: TextStyle(
              fontSize: 12,
              color: _softText.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
          ),
        ),
        _buildTransitArrow(
          Icons.chevron_right,
          _inTransitIndex < total - 1
              ? () => _switchInTransitLetter(_inTransitIndex + 1)
              : null,
          '下一封在途信件',
        ),
      ],
    );
  }

  Widget _buildTransitArrow(
    IconData icon,
    VoidCallback? onPressed,
    String tooltip,
  ) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed == null ? null : () => _onTapWithHaptic(onPressed),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.5),
          foregroundColor: _softText,
          disabledForegroundColor: _softText.withOpacity(0.35),
          side: BorderSide(color: Colors.white.withOpacity(0.7)),
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        icon: Icon(icon, size: 22),
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
        _buildRoundButton(Icons.mail_outline, () => _openLetterList()),
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
        _buildRoundButton(Icons.schedule, () => _showSnapshot()),
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
        child: Icon(icon, color: _softText.withOpacity(0.9), size: 20),
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SlowLetterOpenPage(
              letterId: _letter.id,
              letterNo: _letter.code,
              recipientLabel: _currentRecipient,
            ),
      ),
    );
    if (!mounted) return;
    widget.onOpened?.call(_letter);
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
          recipient: _currentRecipient,
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
                        children:
                            letter.images.map((url) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  url,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Container(
                                        width: 96,
                                        height: 96,
                                        color: const Color(0xFFEDF1E3),
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 22,
                                          color: const Color(
                                            0xFF7F9A5E,
                                          ).withOpacity(0.5),
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
