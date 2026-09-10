import 'package:flutter/material.dart';
import 'package:lome/services/message_service.dart';
import 'package:lome/models/message_model.dart';
import 'package:lome/pages/message_detail_page.dart';
import 'package:lome/pages/message_editor_page.dart';

class MessageBoardPage extends StatefulWidget {
  const MessageBoardPage({super.key});

  @override
  State<MessageBoardPage> createState() => _MessageBoardPageState();
}

class _MessageBoardPageState extends State<MessageBoardPage> {
  final List<Message> _messages = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int? _nextCursor;
  String _currentTab = 'mine';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markAllRead();
  }

  // ============ 数据加载 ============
  Future<void> _loadMessages({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _messages.clear();
        _nextCursor = null;
        _hasMore = true;
      });
    }
    if (!_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final response = await MessageService.getList(
        type: _currentTab,
        pageSize: 20,
        cursor: _nextCursor,
      );

      if (response['code'] == 0) {
        final data = response['data'];
        final list = (data['list'] as List?)?.map((e) => Message.fromJson(e)).toList() ?? [];
        setState(() {
          _messages.addAll(list);
          _hasMore = data['hasMore'] ?? false;
          _nextCursor = data['nextCursor'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await MessageService.markAllRead();
    } catch (e) {
      // 静默失败
    }
  }

  void _switchTab(String tab) {
    if (_currentTab == tab) return;
    setState(() {
      _currentTab = tab;
      _messages.clear();
      _nextCursor = null;
      _hasMore = true;
    });
    _loadMessages();
  }

  void _navigateToEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewMessagePage()),
    ).then((result) {
      if (result == true) {
        _loadMessages(refresh: true);
      }
    });
  }

  void _navigateToDetail(Message message) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MessageDetailPage(message: message)),
    ).then((result) {
      if (result == true) {
        _loadMessages(refresh: true);
      }
    });
  }

  Widget _buildBackButton(VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF6EFE4).withOpacity(0.16),
          border: Border.all(
            color: const Color(0xFFF6EFE4).withOpacity(0.28),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 2,
              offset: Offset(0, 1),
              spreadRadius: 0,
            )
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: Color(0xFF98B4BC),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _buildBackButton(() => Navigator.pop(context)),
        ),
        const Text(
          "留言板",
          style: TextStyle(
            fontSize: 28,
            color: Color(0xFFBED5DB),
            letterSpacing: 2,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _navigateToEditor,
            child: Container(
              width: 48,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF6EFE4).withOpacity(0.16),
                border: Border.all(
                  color: const Color(0xFFF6EFE4).withOpacity(0.28),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                    spreadRadius: 0,
                  )
                ],
              ),
              child: const Icon(
                Icons.add,
                size: 22,
                color: Color(0xFF98B4BC),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabItem("我的留言", "mine"),
            const SizedBox(width: 4),
            _buildTabItem("Ta的留言", "partner"),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, String tab) {
    final isSelected = _currentTab == tab;
    return GestureDetector(
      onTap: () => _switchTab(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? const Color(0xFF776B65) : const Color(0xFFB8A8A2),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading && _messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB8A8A2)),
      );
    }

    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadMessages(refresh: true),
      color: const Color(0xFFB8A8A2),
      backgroundColor: Colors.white.withOpacity(0.9),
      child: ListView.separated(
        itemCount: _messages.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          if (index == _messages.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFB8A8A2),
                  ),
                ),
              ),
            );
          }
          return _buildMessageCard(_messages[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isMine = _currentTab == 'mine';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: const Color(0xFFB8A8A2).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isMine ? "你还没有留言，写下第一句话吧" : "Ta还没有留言",
            style: const TextStyle(fontSize: 18, color: Color(0xFFB8A8A2)),
          ),
        ],
      ),
    );
  }

  // ============ 留言卡片 ============
  // 逻辑：
  // - "我的留言" Tab → 直接显示内容
  // - "Ta的留言" Tab → 未读时密封，已读时显示摘要
  Widget _buildMessageCard(Message message) {
    final isPartnerTab = _currentTab == 'partner';
    final isSealed = isPartnerTab && !message.isRead;

    return GestureDetector(
      onTap: () => _navigateToDetail(message),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 头部 =====
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E2DD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      message.authorName.isNotEmpty ? message.authorName[0] : '?',
                      style: const TextStyle(fontSize: 18, color: Color(0xFFB8A8A2)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            message.authorName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF776B65),
                            ),
                          ),
                          if (isPartnerTab) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E2DD),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "Ta",
                                style: TextStyle(fontSize: 11, color: Color(0xFFB8A8A2)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _formatTime(message.createTime),
                        style: const TextStyle(fontSize: 12, color: Color(0xFFB8A8A2)),
                      ),
                    ],
                  ),
                ),
                // 密封/已拆图标（只在"Ta的留言"里显示）
                if (isPartnerTab)
                  Icon(
                    isSealed ? Icons.mail : Icons.drafts,
                    size: 28,
                    color: isSealed
                        ? const Color(0xFFE8A87C)
                        : const Color(0xFFD4C8C0),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ===== 内容 =====
            if (isSealed) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE8E2DD),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: Color(0xFFB8A8A2),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "点击拆开留言",
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF94847D),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(),
                    if (message.images.isNotEmpty)
                      const Icon(
                        Icons.photo_library_outlined,
                        size: 16,
                        color: Color(0xFFB8A8A2),
                      ),
                  ],
                ),
              ),
            ] else ...[
              // 显示内容摘要
              Text(
                message.content.length > 30
                    ? '${message.content.substring(0, 30)}...'
                    : message.content,
                style: const TextStyle(fontSize: 16, color: Color(0xFF776B65)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (message.images.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: message.images.map((img) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E2DD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image, color: Color(0xFFB8A8A2)),
                    );
                  }).toList(),
                ),
              ],
              if (message.emotionTag != null && message.emotionTag!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.emotionTag!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF94847D)),
                  ),
                ),
              ],
              if (message.hasReply && message.replyContent != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.reply, size: 14, color: Color(0xFF94847D)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          message.replyContent!,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF94847D)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EBD8),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/summer_wallpaper_mobile.JPG"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildTopBar(),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 1600.0,
                    height: 10.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFAFC5AE).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(100.0),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildTabBar(),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildMessageList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}