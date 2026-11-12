import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lome/pages/envelope_preview_page.dart';
import 'package:lome/pages/my_letters_page.dart';
import 'package:lome/services/auth_service.dart';
import 'package:lome/services/letter_store.dart';

class SlowMessageHomePage extends StatefulWidget {
  const SlowMessageHomePage({super.key});

  @override
  State<SlowMessageHomePage> createState() => _SlowMessageHomePageState();
}

class _SlowMessageHomePageState extends State<SlowMessageHomePage> {
  static const Color _inkGreen = Color(0xFF7F9A5E);
  static const Color _titleGreen = Color(0xFF9DBF8C);
  static const Color _softText = Color(0xFF8FA57F);
  static const Color _paper = Color(0xFFFFFDF6);

  List<Letter> _letters = <Letter>[];
  String _partnerName = 'Name';
  String _myName = '我';
  double _backScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadLetters();
    _loadNames();
  }

  Future<void> _loadLetters() async {
    final letters = await LetterStore.load();
    if (!mounted) return;
    setState(() => _letters = letters);
  }

  Future<void> _loadNames() async {
    try {
      final user = await AuthService().getUserInfo();
      if (!mounted) return;
      setState(() {
        final partner = user.partnerNickname;
        if (partner != null && partner.isNotEmpty) {
          _partnerName = partner;
        }
        final mine = user.nickname;
        if (mine.isNotEmpty) {
          _myName = mine;
        }
      });
    } catch (_) {}
  }

  void _onTapWithHaptic(VoidCallback action) {
    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android) {
      HapticFeedback.lightImpact();
    }
    action();
  }

  void _openLetters({required bool receivedOnly}) {
    _onTapWithHaptic(() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyLettersPage(receivedOnly: receivedOnly),
        ),
      ).then((_) => _loadLetters());
    });
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}年$month月$day日';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 600 ? 20.0 : 120.0;

    final partnerInTransit = LetterStore.inTransitOf(_letters, fromMe: false);
    final partnerHistory = LetterStore.historyOf(_letters, fromMe: false);
    final myInTransit = LetterStore.inTransitOf(_letters, fromMe: true);
    final myHistory = LetterStore.historyOf(_letters, fromMe: true);
    final latest = LetterStore.latestReceived(_letters);

    return Scaffold(
      backgroundColor: const Color(0xFFA5D6A7),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/slow_message_bg.png',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          _buildTopBar(),
                          const SizedBox(height: 14),
                          _buildIntroBar(),
                          const SizedBox(height: 14),
                          _buildGroupCard(
                            title: '$_partnerName 的信',
                            children: [
                              _buildListTile(
                                title: '$_partnerName的在途信件',
                                count: partnerInTransit.length,
                                hint: partnerInTransit.isEmpty
                                    ? '暂时没有在路上的信'
                                    : '最近一封 ${_formatDate(partnerInTransit.first.deliverAt)} 送达',
                                onTap: () =>
                                    _openLetters(receivedOnly: true),
                              ),
                              _buildListDivider(),
                              _buildListTile(
                                title: '$_partnerName的历史信件',
                                count: partnerHistory.length,
                                hint: partnerHistory.isEmpty
                                    ? '还没有收到的信'
                                    : '最近一封 ${_formatDate(partnerHistory.first.deliverAt)} 已到达',
                                onTap: () =>
                                    _openLetters(receivedOnly: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _buildReceivedLetterCard(latest),
                          const SizedBox(height: 22),
                          _buildGroupCard(
                            title: '$_myName 的信',
                            children: [
                              _buildListTile(
                                title: '我的在途信件',
                                count: myInTransit.length,
                                hint: myInTransit.isEmpty
                                    ? '还没有寄出的信'
                                    : '还有 ${_remaining(myInTransit.first.deliverAt)} 到达',
                                onTap: () =>
                                    _openLetters(receivedOnly: false),
                              ),
                              _buildListDivider(),
                              _buildListTile(
                                title: '我的历史信件',
                                count: myHistory.length,
                                hint: myHistory.isEmpty
                                    ? '还没有寄出的信'
                                    : '共 ${myHistory.length} 封已到达',
                                onTap: () =>
                                    _openLetters(receivedOnly: false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(child: _buildWriteLetterButton()),
          ),
        ],
      ),
    );
  }

  String _remaining(DateTime target) {
    var diff = target.difference(DateTime.now());
    if (diff.isNegative) diff = Duration.zero;
    if (diff.inDays > 0) return '${diff.inDays} 天 ${diff.inHours % 24} 小时';
    if (diff.inHours > 0) return '${diff.inHours} 小时';
    return '${diff.inMinutes} 分钟';
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
        const Expanded(
          child: Center(
            child: Text(
              '慢信',
              style: TextStyle(
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

  Widget _buildIntroBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.28),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.hourglass_bottom,
                size: 15,
                color: _softText.withOpacity(0.9),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '慢信会走上几天才送达，等待本身也是信件的一部分。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF8FA57F),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard({
    required String title,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: _inkGreen.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: _softText.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(height: 1, color: Colors.white.withOpacity(0.45)),
    );
  }

  Widget _buildListTile({
    required String title,
    required int count,
    required String hint,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () => _onTapWithHaptic(onTap),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: _softText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count 封',
                          style: TextStyle(
                            fontSize: 11,
                            color: _softText.withOpacity(0.95),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: _softText.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 22, color: _titleGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedLetterCard(Letter? latest) {
    if (latest == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 26,
              color: _inkGreen.withOpacity(0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '还没有收到信，等一等也会有好消息的。',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.6,
                  color: _softText.withOpacity(0.85),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final stage = latest.stage;
    final isDelivered = stage == LetterStage.delivered;
    final isInTransit = stage == LetterStage.inTransit;

    return GestureDetector(
      onTap: () => _onTapWithHaptic(() => _openSnapshot(latest)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _inkGreen.withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isDelivered
                              ? const Color(0xFFBFD8CB)
                              : const Color(0xFFC9D9E8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDelivered ? Icons.check : Icons.schedule,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isInTransit
                              ? '${latest.code} 预计 ${_formatDate(latest.deliverAt)} 送达'
                              : '${latest.code} 已于 ${_formatDate(latest.deliverAt)} 送达',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9AA79A),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    latest.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7B8A74),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isInTransit
                        ? '还有 ${_remaining(latest.deliverAt)}'
                        : stage == LetterStage.opened
                            ? '已拆开过，再看看 →'
                            : '拆开看看 →',
                    style: const TextStyle(
                      color: Color(0xFFA8B5A2),
                      fontSize: 12.5,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFFA8B5A2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 88,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F1EA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  Icons.mail_outline,
                  size: 34,
                  color: Color(0xFFA8C4BA),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSnapshot(Letter letter) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnvelopePreviewPage(
          letter: letter,
          recipient: _partnerName,
          onOpened: (_) => _loadLetters(),
        ),
      ),
    );
    if (!mounted) return;
    _loadLetters();
  }

  Widget _buildWriteLetterButton() {
    return GestureDetector(
      onTap: () => _onTapWithHaptic(_showComposeSheet),
      child: Container(
        width: 190,
        height: 50,
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: _inkGreen.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, color: Color(0xFFA8B897), size: 20),
            SizedBox(width: 8),
            Text(
              '写一封信',
              style: TextStyle(
                color: Color(0xFFA8B897),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showComposeSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ComposeSheet(),
    );
    if (result == null || !mounted) return;

    final days = result['days'] as int;
    final now = DateTime.now();
    final letter = Letter(
      id: 'letter-${now.millisecondsSinceEpoch}',
      code: 'N${(_letters.length + 1)}',
      title: result['title'] as String,
      content: result['content'] as String,
      sentAt: now,
      deliverAt: now.add(Duration(days: days)),
    );

    final updated = await LetterStore.add(letter);
    if (!mounted) return;
    setState(() => _letters = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('信已寄出，将在 $days 天后送达'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _inkGreen.withOpacity(0.92),
      ),
    );
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _SheetFrame(
          title: '慢信怎么用',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _helpItem('在途信件', '还在路上的信，会显示预计送达时间和倒计时。'),
              _helpItem('历史信件', '已经送达的信，点开就能读到里面的文字和图片。'),
              _helpItem('写一封信', '选择寄送天数，写下想说的话，慢慢寄出去。'),
              _helpItem('收到信后', '信封会变成可拆开状态，拆封时间会被记录下来。'),
            ],
          ),
        );
      },
    );
  }

  Widget _helpItem(String title, String body) {
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
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet();

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  static const int _maxLength = 1000;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  int _days = 3;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset * 0.2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                    const SizedBox(height: 16),
                    const Text(
                      '写一封信',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7F9A5E),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildField(
                      controller: _titleController,
                      hint: '给这封信一个标题',
                      maxLength: 30,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _contentController,
                      hint: '写下想说的话，它会慢慢走到 ta 身边…',
                      maxLength: _maxLength,
                      maxLines: 8,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '路上要走多久',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1,
                        color: const Color(0xFF7F9A5E).withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(3, (i) {
                        final days = <int>[1, 3, 7][i];
                        final selected = _days == days;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _days = days),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF9DBF8C)
                                      : Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF7F9A5E)
                                        .withOpacity(selected ? 0.0 : 0.22),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$days 天',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF7F9A5E),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9DBF8C),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF7F9A5E).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '寄出这封信',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required int maxLength,
    required int maxLines,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 13.5,
        height: 1.8,
        color: Color(0xFF7B8A74),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 12.5,
          color: const Color(0xFF8FA57F).withOpacity(0.7),
        ),
        counterStyle: TextStyle(
          fontSize: 10,
          color: const Color(0xFF8FA57F).withOpacity(0.6),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF7F9A5E).withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF7F9A5E).withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF9DBF8C).withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      _toast('先给这封信写个标题吧');
      return;
    }
    if (content.isEmpty) {
      _toast('信里总要写点什么');
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'title': title,
      'content': content,
      'days': _days,
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF7F9A5E).withOpacity(0.92),
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