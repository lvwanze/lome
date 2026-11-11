import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lome/services/auth_service.dart';
import 'package:lome/services/letter_store.dart';

class MyLettersPage extends StatefulWidget {
  const MyLettersPage({super.key, this.receivedOnly = false});

  final bool receivedOnly;

  @override
  State<MyLettersPage> createState() => _MyLettersPageState();
}

class _MyLettersPageState extends State<MyLettersPage> {
  static const Color _inkGreen = Color(0xFF7F9A5E);
  static const Color _titleGreen = Color(0xFF9DBF8C);
  static const Color _softText = Color(0xFF8FA57F);
  static const Color _paper = Color(0xFFFFFDF6);
  static const Color _noteYellow = Color(0xFFFFF3C4);

  List<Letter> _letters = <Letter>[];

  String _recipient = '(自拟称呼)';
  int _index = 0;
  bool _showHint = true;

  double _backScale = 1.0;
  double _envelopeScale = 1.0;
  double _iconScale = 1.0;

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadLetters();
    _loadRecipient();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadLetters() async {
    final letters = await LetterStore.load();
    if (!mounted) return;
    setState(() {
      _letters = letters
          .where((e) => widget.receivedOnly ? !e.fromMe : e.fromMe)
          .toList();
      if (_index >= _letters.length) {
        _index = _letters.isEmpty ? 0 : _letters.length - 1;
      }
    });
  }

  Future<void> _markOpened(Letter letter) async {
    final updated = await LetterStore.markOpened(letter.id);
    if (!mounted) return;
    setState(() {
      _letters = updated
          .where((e) => widget.receivedOnly ? !e.fromMe : e.fromMe)
          .toList();
    });
  }

  Future<void> _loadRecipient() async {
    try {
      final user = await AuthService().getUserInfo();
      final name = widget.receivedOnly ? user.nickname : user.partnerNickname;
      if (!mounted || name == null || name.isEmpty) return;
      setState(() => _recipient = name);
    } catch (_) {}
  }

  void _onTapWithHaptic(VoidCallback action) {
    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android) {
      HapticFeedback.lightImpact();
    }
    action();
  }

  void _goTo(int target) {
    if (_letters.isEmpty) return;
    final next = target.clamp(0, _letters.length - 1);
    if (next == _index) return;
    setState(() => _index = next);
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

  String _remainingLong(DateTime target) {
    var diff = target.difference(DateTime.now());
    if (diff.isNegative) diff = Duration.zero;
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    final parts = <String>[];
    if (days > 0) parts.add('$days 天');
    parts.add('$hours 小时');
    parts.add('$minutes 分');
    parts.add('${seconds.toString().padLeft(2, '0')} 秒');
    return parts.join(' ');
  }

  String _remainingShort(DateTime target) {
    var diff = target.difference(DateTime.now());
    if (diff.isNegative) diff = Duration.zero;
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    if (days > 0) return '还有 $days 天 $hours 小时';
    if (hours > 0) return '还有 $hours 小时 $minutes 分';
    return '还有 $minutes 分';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 600 ? 20.0 : 120.0;

    return Scaffold(
      backgroundColor: const Color(0xFFDDEBD0),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/my_letters_bg.png',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.white.withOpacity(0.06)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: _letters.isEmpty
                          ? _buildEmptyState()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 10),
                                _buildTopBar(),
                                const SizedBox(height: 16),
                                if (_showHint) ...[
                                  _buildInfoBar(),
                                  const SizedBox(height: 14),
                                ],
                                _buildPagerBar(),
                                const SizedBox(height: 16),
                                _buildEnvelope(),
                                const SizedBox(height: 20),
                                _buildStatusCard(),
                                const SizedBox(height: 12),
                                _buildDeliveryText(),
                                const SizedBox(height: 22),
                                _buildBottomActions(),
                                const SizedBox(height: 28),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 52,
            color: _inkGreen.withOpacity(0.45),
          ),
          const SizedBox(height: 14),
          Text(
            '还没有信件',
            style: TextStyle(
              fontSize: 16,
              color: _softText,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '写下第一封慢信，让它慢慢出发',
            style: TextStyle(fontSize: 12, color: _softText.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _backScale = 0.92),
          onTapUp: (_) => setState(() => _backScale = 1.0),
          onTapCancel: () => setState(() => _backScale = 1.0),
          onTap: () => _onTapWithHaptic(() => Navigator.pop(context)),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            curve: Curves.elasticOut,
            scale: _backScale,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.55),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _inkGreen.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 22,
                color: _titleGreen,
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              widget.receivedOnly ? '收到的信' : '我的信件',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: _titleGreen,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _onTapWithHaptic(_showHelp),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Icon(
              Icons.help_outline,
              size: 20,
              color: _titleGreen.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.30),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 15,
                color: _softText.withOpacity(0.9),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '轻点自己的信（所有状态）可查看含图片文字的快照，无动画。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF8FA57F),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showHint = false),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.close,
                    size: 15,
                    color: _softText.withOpacity(0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagerBar() {
    final total = _letters.length;
    return Row(
      children: [
        _buildPagerArrow(
          Icons.chevron_left,
          _index > 0 ? () => _goTo(_index - 1) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Row(
                children: List.generate(total, (i) {
                  final active = i == _index;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? _titleGreen
                              : Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: _titleGreen.withOpacity(0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 7),
              Text(
                '第 ${_index + 1} / $total 封',
                style: TextStyle(
                  fontSize: 11,
                  color: _softText.withOpacity(0.9),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildPagerArrow(
          Icons.chevron_right,
          _index < total - 1 ? () => _goTo(_index + 1) : null,
        ),
      ],
    );
  }

  Widget _buildPagerArrow(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: enabled ? () => _onTapWithHaptic(onTap) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: _inkGreen.withOpacity(0.25)),
          ),
          child: Icon(icon, size: 20, color: _softText),
        ),
      ),
    );
  }

  Widget _buildEnvelope() {
    final letter = _letters[_index];
    final stage = letter.stage;
    return GestureDetector(
      onTapDown: (_) => setState(() => _envelopeScale = 0.97),
      onTapUp: (_) => setState(() => _envelopeScale = 1.0),
      onTapCancel: () => setState(() => _envelopeScale = 1.0),
      onTap: () => _onTapWithHaptic(() => _openSnapshot(letter)),
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -200) _goTo(_index + 1);
        if (velocity > 200) _goTo(_index - 1);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        scale: _envelopeScale,
        child: AspectRatio(
          aspectRatio: 1 / 0.66,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _inkGreen.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _EnvelopePainter(
                    color: _inkGreen.withOpacity(0.10),
                    lineColor: _inkGreen.withOpacity(0.35),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.34),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _inkGreen.withOpacity(0.3)),
                      ),
                      child: Text(
                        'to（$_recipient）',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.caveat(
                          fontSize: 17,
                          color: const Color(0xFF8A9C74),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stage == LetterStage.delivered ? '轻点拆开信封' : '轻点查看快照',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1,
                        color: _inkGreen.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                bottom: 14,
                child: Text(
                  '寄出于 ${_formatDate(letter.sentAt)}',
                  style: GoogleFonts.caveat(
                    fontSize: 13,
                    color: _inkGreen.withOpacity(0.65),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: -14,
                child: Transform.rotate(
                  angle: 0.14,
                  child: Container(
                    width: 72,
                    height: 58,
                    decoration: BoxDecoration(
                      color: _noteYellow,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _inkGreen.withOpacity(0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: _inkGreen.withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                    child: _buildStampContent(letter, stage),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStampContent(Letter letter, LetterStage stage) {
    final showImage =
        stage == LetterStage.opened && letter.images.isNotEmpty;
    if (showImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Image.network(
            letter.images.first,
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
        color: _inkGreen.withOpacity(0.55),
      ),
    );
  }

  Widget _buildStatusCard() {
    final letter = _letters[_index];
    final stage = letter.stage;
    final delivered = stage != LetterStage.inTransit;
    final opened = stage == LetterStage.opened;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3E2).withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _inkGreen.withOpacity(0.35)),
          ),
          child: Column(
            children: [
              _buildTimelineRow(
                done: true,
                iconBg: const Color(0xFFBFD8CB),
                text: '${letter.code} 已于 ${_formatDate(letter.sentAt)} 寄出',
              ),
              _buildTimelineConnector(),
              _buildTimelineRow(
                done: delivered,
                iconBg: const Color(0xFFC9D9E8),
                text: delivered
                    ? '${letter.code} 已于 ${_formatDate(letter.deliverAt)} 送达'
                    : '预计 ${_formatDate(letter.deliverAt)} 送达',
                trailing: delivered
                    ? null
                    : Text(
                        _remainingShort(letter.deliverAt),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8A9C74),
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
              _buildTimelineConnector(),
              _buildTimelineRow(
                done: opened,
                iconBg: const Color(0xFFD7CBE3),
                text: opened
                    ? '${letter.code} 已于 ${_formatDate(letter.openedAt ?? letter.deliverAt)} 拆封'
                    : delivered
                        ? '${letter.code} 待拆开'
                        : '${letter.code} 寄送中',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineConnector() {
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 12,
          child: Center(
            child: Container(
              width: 1,
              color: _inkGreen.withOpacity(0.25),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTimelineRow({
    required bool done,
    required Color iconBg,
    required String text,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: done ? iconBg : Colors.white.withOpacity(0.65),
            shape: BoxShape.circle,
            border: done
                ? null
                : Border.all(color: iconBg.withOpacity(0.9), width: 1.4),
          ),
          child: Icon(
            done ? Icons.check : Icons.schedule,
            size: 11,
            color: done ? Colors.white : iconBg,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7B8A74)),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          trailing,
        ],
      ],
    );
  }

  Widget _buildDeliveryText() {
    final letter = _letters[_index];
    final stage = letter.stage;
    final String text;
    if (stage == LetterStage.inTransit) {
      text =
          '预计 ${_formatDate(letter.deliverAt)} 送达 · 还有 ${_remainingLong(letter.deliverAt)}';
    } else if (stage == LetterStage.delivered) {
      text = '已送达 · 轻点信封即可拆开';
    } else {
      text = '已拆封 · 这封信已收进回忆里';
    }
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.caveat(
          fontSize: 15,
          color: _inkGreen.withOpacity(0.85),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildRoundButton(
          Icons.mail_outline,
          '信件列表',
          _showLetterList,
        ),
        _buildRoundButton(
          Icons.schedule,
          '寄送日程',
          _showSchedule,
        ),
      ],
    );
  }

  Widget _buildRoundButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _iconScale = 0.92),
      onTapUp: (_) => setState(() => _iconScale = 1.0),
      onTapCancel: () => setState(() => _iconScale = 1.0),
      onTap: () => _onTapWithHaptic(onTap),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        curve: Curves.elasticOut,
        scale: _iconScale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.42),
                shape: BoxShape.circle,
                border: Border.all(color: _inkGreen.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: _inkGreen.withOpacity(0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 22, color: _softText),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                color: _softText.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSnapshot(Letter letter) async {
    final stage = letter.stage;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SnapshotSheet(
          letter: letter,
          recipient: _recipient,
          formatDate: _formatDate,
          formatDateTime: _formatDateTime,
          remaining: stage == LetterStage.inTransit
              ? _remainingLong(letter.deliverAt)
              : null,
          onOpen: stage == LetterStage.delivered
              ? () async {
                  await _markOpened(letter);
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  _showToast('信封已拆开');
                }
              : null,
        );
      },
    );
  }

  void _showLetterList() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SheetFrame(
          title: '信件列表',
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_letters.length, (i) {
                final letter = _letters[i];
                final selected = i == _index;
                return Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _goTo(i);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? _titleGreen.withOpacity(0.16)
                            : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? _titleGreen.withOpacity(0.5)
                              : _inkGreen.withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _stageColor(letter.stage)
                                  .withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                letter.code,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _inkGreen.withOpacity(0.95),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  letter.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF7B8A74),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${_stageLabel(letter.stage)} · ${_formatDate(letter.sentAt)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _softText.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: _softText.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  void _showSchedule() {
    final sorted = List<Letter>.from(_letters)
      ..sort((a, b) => a.deliverAt.compareTo(b.deliverAt));
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SheetFrame(
          title: '寄送日程',
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(sorted.length, (i) {
                final letter = sorted[i];
                final stage = letter.stage;
                return Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: Column(
                          children: [
                            Text(
                              letter.deliverAt.day.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _inkGreen,
                              ),
                            ),
                            Text(
                              '${letter.deliverAt.month}月',
                              style: TextStyle(
                                fontSize: 10,
                                color: _softText.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 34,
                        color: _stageColor(stage).withOpacity(0.4),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              letter.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7B8A74),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              stage == LetterStage.inTransit
                                  ? '${_formatDateTime(letter.deliverAt)} 送达 · ${_remainingShort(letter.deliverAt)}'
                                  : '${_formatDateTime(letter.deliverAt)} 已送达',
                              style: TextStyle(
                                fontSize: 11,
                                color: _softText.withOpacity(0.95),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _stageColor(stage).withOpacity(0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _stageLabel(stage),
                          style: TextStyle(
                            fontSize: 10,
                            color: _inkGreen.withOpacity(0.95),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _SheetFrame(
          title: '怎么看这些信',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem('轻点信封', '查看这封信的快照（文字与图片，无动画）。'),
              _buildHelpItem('左右滑动', '在信件之间切换，也可以点击顶部的箭头。'),
              _buildHelpItem('信件送达后', '轻点信封即可拆开，拆封时间会被记录下来。'),
              _buildHelpItem('寄送日程', '按送达时间排列，随时看下一封什么时候到。'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpItem(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: _titleGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7B8A74),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: _softText.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _stageColor(LetterStage stage) {
    switch (stage) {
      case LetterStage.inTransit:
        return const Color(0xFFC9D9E8);
      case LetterStage.delivered:
        return const Color(0xFFBFD8CB);
      case LetterStage.opened:
        return const Color(0xFFD7CBE3);
    }
  }

  String _stageLabel(LetterStage stage) {
    switch (stage) {
      case LetterStage.inTransit:
        return '寄送中';
      case LetterStage.delivered:
        return '待拆开';
      case LetterStage.opened:
        return '已拆封';
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _inkGreen.withOpacity(0.92),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

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
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4E8).withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF7F9A5E).withOpacity(0.25),
                ),
              ),
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
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7F9A5E),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnapshotSheet extends StatelessWidget {
  const _SnapshotSheet({
    required this.letter,
    required this.recipient,
    required this.formatDate,
    required this.formatDateTime,
    required this.onOpen,
    this.remaining,
  });

  final Letter letter;
  final String recipient;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatDateTime;
  final VoidCallback? onOpen;
  final String? remaining;

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
                      'to（$recipient）  ·  ${formatDateTime(letter.sentAt)}',
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
                    Text(
                      letter.content,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.9,
                        color: Color(0xFF7B8A74),
                      ),
                    ),
                    if (letter.images.isNotEmpty) ...[
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F3E2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF7F9A5E).withOpacity(0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: const Color(0xFF8FA57F)
                                    .withOpacity(0.9),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  letter.stage == LetterStage.inTransit
                                      ? '预计 ${formatDate(letter.deliverAt)} 送达'
                                      : '${formatDate(letter.deliverAt)} 送达',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7B8A74),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (remaining != null) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                remaining!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8A9C74),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (onOpen != null)
                      GestureDetector(
                        onTap: onOpen,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9DBF8C),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7F9A5E)
                                    .withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '拆开这封信',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
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

class _EnvelopePainter extends CustomPainter {
  _EnvelopePainter({required this.color, required this.lineColor});

  final Color color;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    canvas.save();
    canvas.clipRRect(rrect);

    final flapHeight = size.height * 0.55;
    final flapPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, flapHeight)
      ..lineTo(size.width, 0);

    canvas.drawPath(flapPath, Paint()..color = color);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, 0), Offset(size.width / 2, flapHeight), linePaint);
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width / 2, flapHeight),
      linePaint,
    );

    final bottomPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, size.height * 0.42)
      ..lineTo(size.width, size.height);
    canvas.drawPath(bottomPath, Paint()..color = color.withOpacity(0.5));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EnvelopePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.lineColor != lineColor;
  }
}