import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lome/models/message_model.dart';
import 'package:lome/services/message_service.dart';
import 'package:lome/pages/message_editor_page.dart';

class MessageDetailPage extends StatefulWidget {
  final Message message;
  const MessageDetailPage({super.key, required this.message});

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  late Message _message;
  bool _isLoading = false;
  bool _isMine = false;

  @override
  void initState() {
    super.initState();
    _message = widget.message;
    _checkOwnership();
  }

  // ============ 判断是否是自己的留言 ============
  Future<void> _checkOwnership() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');
      setState(() {
        _isMine = currentUserId == _message.authorId;
      });
      print('【留言详情】当前用户ID: $currentUserId, 作者ID: ${_message.authorId}, 是我的: $_isMine');
    } catch (e) {
      print('【留言详情】获取用户ID失败: $e');
    }
  }

  // ============ 回应留言 ============
  Future<void> _showReplyDialog() async {
    final controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "回应留言",
          style: TextStyle(
            fontSize: 20,
            color: Color(0xFF776B65),
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 200,
          style: const TextStyle(fontSize: 16, color: Color(0xFF776B65)),
          decoration: const InputDecoration(
            hintText: "写下你的回应...",
            hintStyle: TextStyle(color: Color(0xFFB8A8A2)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "取消",
              style: TextStyle(color: Color(0xFFB8A8A2)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = controller.text.trim();
              if (content.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('请输入回应内容'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              await _submitReply(content);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8E2DD),
              foregroundColor: const Color(0xFF776B65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("发送"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReply(String content) async {
    setState(() => _isLoading = true);
    try {
      final response = await MessageService.reply(
        messageId: _message.id,
        content: content,
      );
      if (response['code'] == 0) {
        setState(() {
          _message = Message(
            id: _message.id,
            authorId: _message.authorId,
            authorName: _message.authorName,
            authorAvatar: _message.authorAvatar,
            content: _message.content,
            images: _message.images,
            emotionTag: _message.emotionTag,
            isRead: _message.isRead,
            createTime: _message.createTime,
            hasReply: true,
            replyContent: content,
            replyAuthorId: _message.replyAuthorId,
            replyAuthorName: _message.replyAuthorName,
          );
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('回应成功 💬'),
            backgroundColor: Color(0xFF8AAA7A),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? '回应失败，请重试'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('网络异常，请稍后再试'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ============ 删除留言 ============
  Future<void> _deleteMessage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "删除留言",
          style: TextStyle(fontSize: 20, color: Color(0xFF776B65)),
        ),
        content: const Text(
          "确定要删除这条留言吗？删除后无法恢复。",
          style: TextStyle(fontSize: 16, color: Color(0xFFB8A8A2)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "取消",
              style: TextStyle(color: Color(0xFFB8A8A2)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade300,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("确认删除"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await MessageService.delete(_message.id);
        if (response['code'] == 0) {
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? '删除失败，请重试'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('网络异常，请稍后再试'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ============ 编辑留言 ============
  void _editMessage() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => NewMessagePage(
        existingMessage: _message.toJson(),
      ),
    ),
  ).then((result) {
    if (result == true) {
      Navigator.pop(context, true);
    }
  });
}
  // ============ 查看图片 ============
  void _showImagePreview(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, error, stack) {
                    return const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============ UI 构建 ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EBD8),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/message_board_page.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildContent(),
                ),
                if (!_isMine) _buildReplyButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== 顶部栏 =====
  Widget _buildHeader() {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 56,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF887770), size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "留言详情",
              style: const TextStyle(
                fontSize: 24,
                color: Color(0xFFB8A8A2),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (_isMine) ...[
            GestureDetector(
              onTap: _editMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.edit, color: Color(0xFF887770), size: 22),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _deleteMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline, color: Color(0xFF887770), size: 22),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===== 内容 =====
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB8A8A2)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
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
                // 头像 + 名称 + 时间 + 已读状态
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E2DD),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(
                          _message.authorName.isNotEmpty ? _message.authorName[0] : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFFB8A8A2),
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
                            _message.authorName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF776B65),
                            ),
                          ),
                          Text(
                            _formatTime(_message.createTime),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB8A8A2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          _message.isRead ? Icons.check_circle : Icons.circle,
                          size: 18,
                          color: _message.isRead
                              ? const Color(0xFF8AAA7A)
                              : const Color(0xFFD4C8C0),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _message.isRead ? "已读" : "未读",
                          style: TextStyle(
                            fontSize: 14,
                            color: _message.isRead
                                ? const Color(0xFF8AAA7A)
                                : const Color(0xFFD4C8C0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 内容
                Text(
                  _message.content,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF776B65),
                    height: 1.5,
                  ),
                ),
                // 图片
                if (_message.images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _message.images.map((img) {
                      return GestureDetector(
                        onTap: () => _showImagePreview(img),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E2DD),
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(img),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                // 图片加载失败时显示占位
                              },
                            ),
                          ),
                          child: const Icon(
                            Icons.image,
                            size: 40,
                            color: Color(0xFFB8A8A2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                // 情绪标签
                if (_message.emotionTag != null && _message.emotionTag!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sentiment_satisfied_alt,
                          size: 16,
                          color: Color(0xFF94847D),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _message.emotionTag!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF94847D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildReplySection(),
        ],
      ),
    );
  }

  // ===== 回应区域 =====
  Widget _buildReplySection() {
    if (_message.hasReply && _message.replyContent != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "💬 回应",
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF94847D),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E2DD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _message.replyAuthorName?.isNotEmpty == true
                          ? _message.replyAuthorName![0]
                          : '我',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB8A8A2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _message.replyAuthorName ?? '我',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF776B65),
                        ),
                      ),
                      Text(
                        _message.replyContent!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF776B65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_isMine) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            "暂无回应",
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFFB8A8A2),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ===== 回应按钮 =====
  Widget _buildReplyButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _showReplyDialog,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.reply, color: Color(0xFF887770), size: 20),
              SizedBox(width: 8),
              Text(
                "回应 💬",
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF887770),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== 时间格式化 =====
  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}