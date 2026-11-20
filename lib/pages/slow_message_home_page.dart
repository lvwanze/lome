import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lome/services/auth_service.dart';
import 'package:lome/services/letter_store.dart';
import 'package:lome/services/slow_letter_api.dart';

// 引入队友写的列表页和预览页
import 'package:lome/pages/envelope_preview_page.dart';
import 'package:lome/pages/my_letters_page.dart';

// 引入你的两个页面
import 'package:lome/pages/slow_letter_open_page.dart';
import 'package:lome/pages/slow_letter_editor_page.dart';

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
  Map<String, dynamic>? _overviewCounts;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadLetters();
    _loadNames();
  }

  Future<void> _loadLetters() async {
    try {
      final letters = await LetterStore.load();
      if (!mounted) return;
      setState(() {
        _letters = letters;
        _loadError = null;
      });
      try {
        final overview = await SlowLetterApi.instance.overview();
        if (mounted) {
          setState(
            () => _overviewCounts = overview['counts'] as Map<String, dynamic>?,
          );
        }
      } catch (_) {
        if (mounted) setState(() => _overviewCounts = null);
      }
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    }
  }

  int _count(String key, int fallback) {
    final value = _overviewCounts?[key];
    return value is num ? value.toInt() : fallback;
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

  // ============ 跳转队友的列表页 ============
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

  // ============ 点击在途信件处理 ============
  Future<void> _openLatestIncomingInTransit(List<Letter> letters) async {
    if (letters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('目前没有在途信件')));
      return;
    }

    // 在途信件不应该直接打开，或者你可以引导到队友的预览页（如果是动画展示的话）
    // 按照正常逻辑，在途信件是不能拆开的，这里建议弹提示或者跳转队友的预览页（带倒计时）
    final letter = letters.first;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => EnvelopePreviewPage(
              letter: letter,
              recipient:
                  letter.recipientLabel.isEmpty
                      ? _partnerName
                      : letter.recipientLabel,
              onOpened: (_) => _loadLetters(),
            ),
      ),
    );
    if (mounted) _loadLetters();
  }

  // ============ 跳转你的编辑器页面 ============
  Future<void> _navigateToEditor({Map<String, dynamic>? existingRecord}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SlowLetterEditorPage()),
    );
    if (mounted) _loadLetters();
  }

  // ============ 跳转你的开信页面 ============
  Future<void> _navigateToOpenLetter(Letter letter) async {
    // 拦截在途信件
    if (letter.stage == LetterStage.inTransit) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('信件还在路上，等一等吧~')));
      return;
    }

    // 修复：按照你截图里的参数要求传参
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SlowLetterOpenPage(
              letterId: letter.id,
              letterNo: letter.code,
              recipientLabel:
                  letter.recipientLabel.isEmpty
                      ? _partnerName
                      : letter.recipientLabel,
            ),
      ),
    );
    if (mounted) _loadLetters();
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
          Image.asset('assets/images/slow_message_bg.png', fit: BoxFit.cover),
          Container(color: Colors.white.withOpacity(0.06)),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          _buildTopBar(),
                          const SizedBox(height: 14),
                          _buildIntroBar(),
                          if (_loadError != null) ...[
                            const SizedBox(height: 10),
                            Material(
                              color: const Color(0xFFFFFDF6),
                              borderRadius: BorderRadius.circular(8),
                              child: ListTile(
                                dense: true,
                                title: Text(_loadError!),
                                trailing: IconButton(
                                  tooltip: '重试',
                                  onPressed: _loadLetters,
                                  icon: const Icon(Icons.refresh),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          _buildGroupCard(
                            title: '$_partnerName 的信',
                            children: [
                              _buildListTile(
                                title: '$_partnerName的在途信件',
                                count: _count(
                                  'receivedInTransit',
                                  partnerInTransit.length,
                                ),
                                hint:
                                    partnerInTransit.isEmpty
                                        ? '暂时没有在路上的信'
                                        : '最近一封 ${_formatDate(partnerInTransit.first.deliverAt)} 送达',
                                onTap:
                                    () => _openLatestIncomingInTransit(
                                      partnerInTransit,
                                    ),
                              ),
                              _buildListDivider(),
                              _buildListTile(
                                title: '$_partnerName的历史信件',
                                count: _count(
                                  'receivedArchive',
                                  partnerHistory.length,
                                ),
                                hint:
                                    partnerHistory.isEmpty
                                        ? '还没有收到的信'
                                        : '最近一封 ${_formatDate(partnerHistory.first.deliverAt)} 已到达',
                                onTap: () => _openLetters(receivedOnly: true),
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
                                count: _count(
                                  'sentInTransit',
                                  myInTransit.length,
                                ),
                                hint:
                                    myInTransit.isEmpty
                                        ? '还没有寄出的信'
                                        : '还有 ${_remaining(myInTransit.first.deliverAt)} 到达',
                                onTap: () => _openLetters(receivedOnly: false),
                              ),
                              _buildListDivider(),
                              _buildListTile(
                                title: '我的历史信件',
                                count: _count('sentArchive', myHistory.length),
                                hint:
                                    myHistory.isEmpty
                                        ? '还没有寄出的信'
                                        : '共 ${myHistory.length} 封已到达',
                                onTap: () => _openLetters(receivedOnly: false),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.60)),
                boxShadow: [
                  BoxShadow(
                    color: _inkGreen.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, size: 20, color: _titleGreen),
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
      child: Container(
        height: 1,
        color: const Color(0xFF7F9A5E).withOpacity(0.18),
      ),
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
      onTap: () => _onTapWithHaptic(() => _navigateToOpenLetter(latest)),
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
                          color:
                              isDelivered
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
                    latest.title.isEmpty ? '一封慢信' : latest.title,
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

  // ============ 写一封信按钮直接跳转你的编辑页 ============
  Widget _buildWriteLetterButton() {
    return GestureDetector(
      onTap: () => _onTapWithHaptic(() => _navigateToEditor()),
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
