import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:lome/services/api_service.dart';

class AddPlanPage extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, dynamic>? existingPlan;
  const AddPlanPage({
    super.key,
    required this.selectedDate,
    this.existingPlan,
  });

  @override
  State<AddPlanPage> createState() => _AddPlanPageState();
}

class _AddPlanPageState extends State<AddPlanPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<Uint8List> _imageBytes = [];
  final int _maxImages = 4;
  bool _isSaving = false;

  // ============ 日期格式化 ============
  String _formatDate(DateTime date) {
    final weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日·周${weekdays[date.weekday % 7]}';
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    // 如果有已有数据，回显到输入框
    if (widget.existingPlan != null) {
      _titleController.text = widget.existingPlan?['title'] ?? '';
      _contentController.text = widget.existingPlan?['content'] ?? '';
      // 图片回显需要从 URL 加载，这里暂不处理
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ============ 图片选择 ============
  Future<void> _pickImage() async {
    if (_imageBytes.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('最多只能添加4张图片'),
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

  // ============ 保存（允许空内容） ============
  Future<void> _savePlan() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      final isEdit = widget.existingPlan != null;

      // 允许空内容保存
      final response = await ApiService.post(
        isEdit ? '/api/v1/plan/update' : '/api/v1/plan/create',
        body: isEdit
            ? {
                'planId': widget.existingPlan?['planId'],
                'title': title,
                'content': content,
                'images': [],
              }
            : {
                'date': _formatDateKey(widget.selectedDate),
                'title': title,
                'content': content,
                'images': [],
              },
      );

      print('【规划】保存响应: $response');

      if (response['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? '规划已更新' : '规划已保存'),
              backgroundColor: const Color(0xFFA8C9A8),
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? '保存失败，请重试'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('【规划】保存异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('网络异常，请稍后再试'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ============ 取消规划（删除） ============
  Future<void> _deletePlan() async {
    if (widget.existingPlan == null) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await ApiService.post(
        '/api/v1/plan/delete',
        body: {
          'planId': widget.existingPlan?['planId'],
        },
      );

      print('【规划】删除响应: $response');

      if (response['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已取消规划'),
              backgroundColor: Color(0xFFA8C9A8),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? '取消失败'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('【规划】删除异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('取消失败，请重试'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ============ UI 构建 ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/calendar_plan_bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== 返回 + 标题栏 =====
                SizedBox(
                  height: 60,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 3,
                              )
                            ],
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xff888888)),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "规划",
                          style: TextStyle(
                            fontSize: 30,
                            color: Color(0xFFBED5DB),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 10.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFAFC5AE).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(100.0),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ===== 计划时间（显示选中日期） =====
                _buildInputCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: const Text("计划时间", style: TextStyle(fontSize: 18, color: Color(0xff887882))),
                    subtitle: Text(
                      _formatDate(widget.selectedDate),
                      style: const TextStyle(fontSize: 17, color: Color(0xffC9C0C6)),
                    ),
                    trailing: const Icon(Icons.keyboard_arrow_right, color: Color(0xffC9C0C6), size: 24),
                    onTap: () {
                      // 时间选择逻辑后续写在这里
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ===== 计划标题 =====
                _buildInputCard(
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 18, color: Color(0xff665862)),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      hintText: "和TA一起做什么（可留空）",
                      hintStyle: TextStyle(fontSize: 17, color: Color(0xffC9C0C6)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ===== 计划备注 =====
                _buildInputCard(
                  child: Stack(
                    children: [
                      TextField(
                        controller: _contentController,
                        minLines: 12,
                        maxLines: 15,
                        style: const TextStyle(fontSize: 17, color: Color(0xff665862)),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: InputBorder.none,
                          hintText: "写下计划细节……（可留空）",
                          hintStyle: TextStyle(fontSize: 17, color: Color(0xffC9C0C6)),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 14,
                        child: ValueListenableBuilder(
                          valueListenable: _contentController,
                          builder: (context, value, child) {
                            final length = value.text.length;
                            if (length == 0) return const SizedBox.shrink();
                            return Text(
                              '$length/500',
                              style: const TextStyle(
                                color: Color(0xff998892),
                                fontSize: 16,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ===== 添加图片 =====
                _buildInputCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "添加图片",
                              style: TextStyle(fontSize: 18, color: Color(0xff887882)),
                            ),
                            Text(
                              '${_imageBytes.length}/$_maxImages',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xff998892),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildImageList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ===== 保存规划按钮 =====
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffC2D8C8),
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    onPressed: _isSaving ? null : _savePlan,
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.existingPlan != null ? "保存修改" : "保存规划",
                            style: const TextStyle(fontSize: 20, color: Colors.white),
                          ),
                  ),
                ),

                // ===== 取消规划按钮（仅编辑时显示） =====
                if (widget.existingPlan != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: BorderSide(color: Colors.red.withOpacity(0.3)),
                        ),
                      ),
                      onPressed: _isSaving ? null : _deletePlan,
                      child: const Text(
                        "取消规划",
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // ===== 返回 =====
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: const Text(
                      "返回",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xffB4C8BB),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ 图片列表 ============
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
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffdddddd), width: 1),
              image: DecorationImage(
                image: MemoryImage(bytes),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xffcccccc),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
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
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffD0E2E8), width: 1),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 28, color: Color(0xffB4D2D9)),
            SizedBox(height: 2),
            Text(
              "添加",
              style: TextStyle(fontSize: 14, color: Color(0xff94B8C0)),
            ),
          ],
        ),
      ),
    );
  }

  // ============ 输入卡片 ============
  Widget _buildInputCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: child,
    );
  }
}