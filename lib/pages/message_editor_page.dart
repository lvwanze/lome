import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:lome/services/api_service.dart';
import 'package:lome/services/message_service.dart';

class NewMessagePage extends StatefulWidget {
  final Map<String, dynamic>? existingMessage;
  const NewMessagePage({super.key, this.existingMessage});

  @override
  State<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final TextEditingController _textController = TextEditingController();
  int _charCount = 0;
  List<Uint8List> _imageBytes = [];
  final int _maxImages = 2;
  String? _selectedEmotionTag;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingMessage != null) {
      _textController.text = widget.existingMessage?['content'] ?? '';
      _charCount = _textController.text.length;
      _selectedEmotionTag = widget.existingMessage?['emotionTag'];
    }

    _textController.addListener(() {
      setState(() {
        _charCount = _textController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_imageBytes.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('最多只能添加2张图片'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes.add(bytes);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageBytes.removeAt(index);
    });
  }

  void _showImagePreview(Uint8List bytes) {
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
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<List<String>> _uploadImages() async {
    if (_imageBytes.isEmpty) return [];

    List<String> urls = [];
    for (var bytes in _imageBytes) {
      try {
        final response = await ApiService.uploadImage(
          imageBytes: bytes,
          folder: 'messages',
        );
        if (response['code'] == 0) {
          urls.add(response['data']['url']);
          print('图片上传成功: ${response['data']['url']}');
        } else {
          print('图片上传失败: ${response['message']}');
        }
      } catch (e) {
        print('图片上传异常: $e');
      }
    }
    return urls;
  }

  Future<void> _publishMessage() async {
    final content = _textController.text.trim();

    if (content.isEmpty && _imageBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请写下你想说的话或添加图片'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final imageUrls = await _uploadImages();

      final isEdit = widget.existingMessage != null;
      dynamic response;

      if (isEdit) {
        response = await MessageService.update(
          messageId: widget.existingMessage?['id'] ?? widget.existingMessage?['_id'] ?? '',
          content: content,
          images: imageUrls,
          emotionTag: _selectedEmotionTag,
        );
      } else {
        response = await MessageService.create(
          content: content,
          images: imageUrls,
          emotionTag: _selectedEmotionTag,
        );
      }

      if (response['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? '编辑成功 ✏️' : '发布成功 💌'),
              backgroundColor: const Color(0xFF8AAA7A),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? '操作失败，请重试'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Widget _buildEmotionChip(String label, IconData icon) {
    final isSelected = _selectedEmotionTag == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmotionTag = isSelected ? null : label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8E2DD)
              : Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(color: const Color(0xFF887770), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF94847D)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                color: isSelected
                    ? const Color(0xFF776B65)
                    : const Color(0xFF776B65).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageList() {
    List<Widget> items = [];

    for (int i = 0; i < _imageBytes.length; i++) {
      items.add(_buildImageItem(_imageBytes[i], i));
      if (i < _imageBytes.length - 1) {
        items.add(const SizedBox(width: 10));
      }
    }

    if (_imageBytes.length < _maxImages) {
      if (_imageBytes.isNotEmpty) {
        items.add(const SizedBox(width: 10));
      }
      items.add(_buildAddImageButton());
    }

    return Row(
      children: items,
    );
  }

  Widget _buildImageItem(Uint8List bytes, int index) {
    return GestureDetector(
      onTap: () => _showImagePreview(bytes),
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: MemoryImage(bytes),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8E2DD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Color(0xFF94847D)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD0E2E8),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 32, color: Color(0xFFB4D2D9)),
            SizedBox(height: 4),
            Text(
              "添加",
              style: TextStyle(fontSize: 14, color: Color(0xFF94B8C0)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "放弃编辑？",
          style: TextStyle(fontSize: 20, color: Color(0xFF776B65)),
        ),
        content: const Text(
          "你还没有发送这条留言，确定要放弃吗？",
          style: TextStyle(fontSize: 16, color: Color(0xFFB8A8A2)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "继续编辑",
              style: TextStyle(color: Color(0xFFB8A8A2)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade300,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("放弃"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingMessage != null;

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_textController.text.isNotEmpty ||
                              _imageBytes.isNotEmpty) {
                            _showDiscardDialog();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          width: 56,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.close, color: Color(0xFF887770), size: 24),
                        ),
                      ),
                      Text(
                        isEdit ? "编辑留言" : "新留言",
                        style: const TextStyle(
                          fontSize: 34,
                          color: Color(0xFFB8A8A2),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      GestureDetector(
                        onTap: _isSending ? null : _publishMessage,
                        child: Container(
                          width: 56,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isSending
                                ? Colors.white.withOpacity(0.4)
                                : Colors.white.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF887770),
                                  ),
                                )
                              : const Icon(Icons.send, color: Color(0xFF887770), size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.62),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              TextField(
                                controller: _textController,
                                maxLines: 6,
                                maxLength: 50,
                                style: const TextStyle(fontSize: 20, color: Color(0xFF776B65)),
                                decoration: const InputDecoration(
                                  hintText: "想说的话...\n请输入文本",
                                  hintStyle: TextStyle(fontSize: 20, color: Color(0xFFBCB0AA)),
                                  border: InputBorder.none,
                                  counterText: "",
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Text(
                                  "$_charCount/50",
                                  style: const TextStyle(color: Color(0xFF998E88), fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt_outlined, size: 26, color: Color(0xFFAA9890)),
                                      SizedBox(width: 8),
                                      Text("添加图片", style: TextStyle(fontSize: 18, color: Color(0xFF94847D))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.sentiment_satisfied_alt_outlined, size: 26, color: Color(0xFFAA9890)),
                                    SizedBox(width: 8),
                                    Text("情绪标签", style: TextStyle(fontSize: 18, color: Color(0xFF94847D))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_imageBytes.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "已选图片 ${_imageBytes.length}/$_maxImages",
                                style: const TextStyle(fontSize: 16, color: Color(0xFF94847D)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildImageList(),
                          const SizedBox(height: 24),
                        ],
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "情绪标签",
                            style: TextStyle(
                              fontSize: 22,
                              color: Color(0xFF776B65),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildEmotionChip("开心", Icons.sentiment_satisfied),
                            _buildEmotionChip("思念", Icons.eco_outlined),
                            _buildEmotionChip("晚安", Icons.nightlight_outlined),
                            _buildEmotionChip("求抱抱", Icons.favorite_border),
                          ],
                        ),
                        const SizedBox(height: 40),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_done_outlined, size: 20, color: Color(0xFF887770)),
                            SizedBox(width: 6),
                            Text("草稿已自动保存", style: TextStyle(fontSize: 16, color: Color(0xFF887770))),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}