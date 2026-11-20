import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/slow_letter_api.dart';
import '../utils/app_constants.dart';

class SlowLetterEditorPage extends StatefulWidget {
  const SlowLetterEditorPage({super.key});

  @override
  State<SlowLetterEditorPage> createState() => _SlowLetterEditorPageState();
}

class _SlowLetterEditorPageState extends State<SlowLetterEditorPage> {
  // ============================================================
  // 1. 接口配置
  // ============================================================

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const int _maxImageBytes = 2 * 1024 * 1024;

  // ============================================================
  // 2. 页面颜色：根据 Figma 设计稿设置
  // ============================================================

  static const Color _backgroundColor = Color(0xFFEAF0E9);

  static const Color _panelColor = Color(0xFFFAFAF1);

  static const Color _cardColor = Color(0xFFFFFFFF);

  static const Color _textColor = Color(0xFFC0A9A6);

  static const Color _darkTextColor = Color(0xFF8F8070);

  static const Color _buttonColor = Color(0xFFDDD4C7);

  static const Color _borderColor = Color(0xFFF2EAE5);

  // ============================================================
  // 3. 输入控制器
  // ============================================================

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _recipientController = TextEditingController();

  final TextEditingController _contentController = TextEditingController();

  // ============================================================
  // 4. 页面状态
  // ============================================================

  final ImagePicker _imagePicker = ImagePicker();

  DateTime? _arriveAt;

  Uint8List? _imageBytes;

  String? _imageName;

  String? _attachmentId;

  String? _selectedImageMimeType;

  String _boundRecipientLabel = '读取绑定对象中';

  String? _pendingRequestId;

  String _selectedStamp = 'stamp_default_v1';

  String _selectedPaper = 'paper_default_v1';

  String _selectedSeal = 'seal_default_v1';

  String _selectedEnvelope = 'envelope_default_v1';

  bool _uploadingImage = false;

  bool _sending = false;

  bool _restoringDraft = true;

  bool _draftChanged = false;

  int get _contentLength => _contentController.text.characters.length;

  bool get _contentValid {
    final text = _contentController.text;

    // 统计非纯空白的 Unicode 字符簇。
    final effectiveLength =
        text.characters
            .where((character) => character.trim().isNotEmpty)
            .length;

    // 同时限制正文 UTF-8 原始字节数。
    final byteLength = utf8.encode(text).length;

    return effectiveLength >= 200 &&
        effectiveLength <= 5000 &&
        byteLength <= 64 * 1024;
  }

  bool get _canSend {
    return !_sending &&
        !_uploadingImage &&
        !_restoringDraft &&
        _contentValid &&
        _titleController.text.trim().isNotEmpty &&
        _recipientController.text.trim().isNotEmpty &&
        _recipientController.text.characters.length <= 20 &&
        _arriveAt != null &&
        _arriveAt!.isAfter(DateTime.now().add(const Duration(hours: 24)));
  }

  // ============================================================
  // 5. 页面初始化和释放
  // ============================================================

  @override
  void initState() {
    super.initState();

    _restoreDraft();
    _loadBoundRecipient();

    _titleController.addListener(_onInputChanged);
    _recipientController.addListener(_onInputChanged);
    _contentController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _recipientController.dispose();
    _contentController.dispose();

    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted) return;

    setState(() {
      _draftChanged = true;
      _pendingRequestId = null;
    });
  }

  Future<void> _loadBoundRecipient() async {
    try {
      final user = await AuthService().getUserInfo();
      if (!mounted) return;
      setState(() {
        _boundRecipientLabel =
            user.isBound &&
                    user.partnerNickname != null &&
                    user.partnerNickname!.isNotEmpty
                ? user.partnerNickname!
                : '尚未绑定';
      });
    } catch (_) {
      if (mounted) setState(() => _boundRecipientLabel = '暂时无法读取');
    }
  }

  // ============================================================
  // 6. 本地草稿
  // 使用 FlutterSecureStorage 保存文本草稿
  // ============================================================

  static const String _draftKey = 'lome_slow_letter_draft_v1';

  Future<void> _restoreDraft() async {
    try {
      final draft = await _secureStorage.read(key: _draftKey);

      if (draft != null && draft.isNotEmpty) {
        final Map<String, dynamic> data =
            jsonDecode(draft) as Map<String, dynamic>;

        if (!mounted) return;

        _titleController.text = data['title']?.toString() ?? '';

        _recipientController.text = data['recipientLabel']?.toString() ?? '';

        _contentController.text = data['content']?.toString() ?? '';

        _selectedStamp = data['stampId']?.toString() ?? 'stamp_default_v1';

        _selectedPaper = data['paperId']?.toString() ?? 'paper_default_v1';

        _selectedSeal = data['sealId']?.toString() ?? 'seal_default_v1';

        _selectedEnvelope =
            data['envelopeId']?.toString() ?? 'envelope_default_v1';
        _pendingRequestId = data['pendingRequestId']?.toString();

        final arriveAtValue = data['arriveAt'];

        if (arriveAtValue is String && arriveAtValue.isNotEmpty) {
          _arriveAt = DateTime.tryParse(arriveAtValue);
        }

        // 不在草稿中保存图片二进制、临时上传凭证或 attachmentId。
        // 附件上传凭证有有效期，恢复后需要重新选择图片。
      }
    } catch (_) {
      // 草稿损坏时不阻塞页面使用。
    } finally {
      if (mounted) {
        setState(() {
          _restoringDraft = false;
        });
      }
    }
  }

  Future<void> _saveDraft() async {
    final draft = <String, dynamic>{
      'title': _titleController.text,
      'recipientLabel': _recipientController.text,
      'content': _contentController.text,
      'stampId': _selectedStamp,
      'paperId': _selectedPaper,
      'sealId': _selectedSeal,
      'envelopeId': _selectedEnvelope,
      'arriveAt': _arriveAt?.toIso8601String(),
      'pendingRequestId': _pendingRequestId,
    };

    try {
      await _secureStorage.write(key: _draftKey, value: jsonEncode(draft));

      _draftChanged = false;
    } catch (_) {
      if (mounted) {
        _showMessage('草稿保存失败，请检查设备存储权限');
      }
    }
  }

  Future<void> _deleteDraft() async {
    try {
      await _secureStorage.delete(key: _draftKey);
    } catch (_) {
      // 不影响已经完成的发送操作。
    }
  }

  // ============================================================
  // 7. 获取 JWT Token
  // ============================================================

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(AppConstants.tokenKey);
  }

  // ============================================================
  // 8. 选择图片
  // ============================================================

  Future<void> _pickImage() async {
    if (_sending || _uploadingImage) return;

    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      if (bytes.length > _maxImageBytes) {
        _showMessage('图片不能超过 2 MiB，请选择较小的图片');
        return;
      }

      final fileName = file.name.toLowerCase();

      String mimeType;

      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else {
        _showMessage('目前仅支持 PNG、JPG、JPEG 和 WEBP 图片');
        return;
      }

      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
        _selectedImageMimeType = mimeType;
        _attachmentId = null;
        _pendingRequestId = null;
      });

      await _uploadImage(bytes: bytes, mimeType: mimeType);
    } catch (_) {
      _showMessage('选择图片失败，请重试');
    }
  }

  // ============================================================
  // 9. 慢信专用二进制图片上传
  // 不使用普通 uploadImage 接口
  // ============================================================

  Future<void> _uploadImage({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    setState(() {
      _uploadingImage = true;
    });

    try {
      final attachmentId = await SlowLetterApi.instance.uploadAttachment(
        bytes: bytes,
        mimeType: mimeType,
      );

      if (!mounted) return;

      setState(() {
        _attachmentId = attachmentId;
      });

      _showMessage('图片已添加');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _attachmentId = null;
      });

      _showMessage('图片上传失败，请重新选择');
    } finally {
      if (mounted) {
        setState(() {
          _uploadingImage = false;
        });
      }
    }
  }

  void _removeImage() {
    if (_sending || _uploadingImage) return;

    setState(() {
      _imageBytes = null;
      _imageName = null;
      _selectedImageMimeType = null;
      _attachmentId = null;
      _pendingRequestId = null;
    });
  }

  // ============================================================
  // 10. 选择送达时间
  // ============================================================

  Future<void> _selectArriveTime() async {
    if (_sending) return;

    final now = DateTime.now();

    final initialDate = _arriveAt ?? now.add(const Duration(days: 1, hours: 1));

    final firstDate = now.add(const Duration(days: 1));

    final lastDate = DateTime(now.year + 5, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(firstDate) ? initialDate : firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '选择预计送达日期',
      cancelText: '取消',
      confirmText: '下一步',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _darkTextColor,
              onPrimary: Colors.white,
              surface: _panelColor,
              onSurface: _darkTextColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime:
          _arriveAt != null
              ? TimeOfDay.fromDateTime(_arriveAt!)
              : const TimeOfDay(hour: 9, minute: 0),
      helpText: '选择预计送达时间',
      cancelText: '取消',
      confirmText: '确定',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _darkTextColor,
              onPrimary: Colors.white,
              surface: _panelColor,
              onSurface: _darkTextColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    final selected = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (selected.isBefore(DateTime.now().add(const Duration(hours: 24)))) {
      _showMessage('送达时间至少需要在 24 小时之后');
      return;
    }

    setState(() {
      _arriveAt = selected;
      _draftChanged = true;
      _pendingRequestId = null;
    });

    await _saveDraft();
  }

  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year.toString();

    final month = dateTime.month.toString().padLeft(2, '0');

    final day = dateTime.day.toString().padLeft(2, '0');

    final hour = dateTime.hour.toString().padLeft(2, '0');

    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$year/$month/$day  $hour:$minute';
  }

  // ============================================================
  // 11. 外观选择
  // ============================================================

  String _selectedAppearanceId(String type) {
    switch (type) {
      case 'stamp':
        return _selectedStamp;
      case 'paper':
        return _selectedPaper;
      case 'seal':
        return _selectedSeal;
      default:
        return _selectedEnvelope;
    }
  }

  List<_AppearanceOption> _appearanceOptions(String type) {
    switch (type) {
      case 'stamp':
        return const [
          _AppearanceOption('stamp_default_v1', '初春', Color(0xFFEABFC0)),
          _AppearanceOption('stamp_sakura_v1', '山茶', Color(0xFFD98B91)),
          _AppearanceOption('stamp_ginkgo_v1', '银杏', Color(0xFFD6B45D)),
          _AppearanceOption('stamp_sunrise_v1', '晨光', Color(0xFFE6A27A)),
        ];
      case 'paper':
        return const [
          _AppearanceOption('paper_default_v1', '暖白', Color(0xFFF4EBDD)),
          _AppearanceOption('paper_rose_v1', '玫瑰', Color(0xFFF0DADD)),
          _AppearanceOption('paper_sky_v1', '晴空', Color(0xFFDCE9EE)),
          _AppearanceOption('paper_mint_v1', '薄荷', Color(0xFFDCE9DE)),
        ];
      case 'seal':
        return const [
          _AppearanceOption('seal_default_v1', '初春', Color(0xFFEABFC0)),
          _AppearanceOption('seal_sakura_v1', '山茶', Color(0xFFD98B91)),
          _AppearanceOption('seal_ginkgo_v1', '银杏', Color(0xFFD6B45D)),
          _AppearanceOption('seal_sunrise_v1', '晨光', Color(0xFFE6A27A)),
        ];
      default:
        return const [
          _AppearanceOption('envelope_default_v1', '雾白', Color(0xFFEAF0E9)),
          _AppearanceOption('envelope_rose_v1', '玫瑰', Color(0xFFF0DADD)),
          _AppearanceOption('envelope_sky_v1', '晴空', Color(0xFFDCE9EE)),
          _AppearanceOption('envelope_mint_v1', '薄荷', Color(0xFFDCE9DE)),
        ];
    }
  }

  Future<void> _selectAppearance(_AppearanceItem item) async {
    if (_sending) return;
    final options = _appearanceOptions(item.type);
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: _panelColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _darkTextColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '选择${item.title}',
                    style: const TextStyle(
                      color: _darkTextColor,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.18,
                          ),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final selected =
                            option.id == _selectedAppearanceId(item.type);
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(sheetContext, option.id),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      selected ? _darkTextColor : _borderColor,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 54,
                                    height: 58,
                                    child: _buildAppearancePreview(
                                      item.imagePath,
                                      item.icon,
                                      option,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: _darkTextColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Container(
                                          width: 32,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: option.color,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: _darkTextColor,
                                    ),
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
            ),
          ),
        );
      },
    );
    if (selectedId == null || !mounted) return;
    setState(() {
      switch (item.type) {
        case 'stamp':
          _selectedStamp = selectedId;
          break;
        case 'paper':
          _selectedPaper = selectedId;
          break;
        case 'seal':
          _selectedSeal = selectedId;
          break;
        case 'envelope':
          _selectedEnvelope = selectedId;
          break;
      }
      _pendingRequestId = null;
      _draftChanged = true;
    });
    await _saveDraft();
  }

  Widget _buildAppearancePreview(
    String imagePath,
    IconData icon,
    _AppearanceOption option,
  ) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        option.color.withValues(alpha: 0.42),
        BlendMode.srcATop,
      ),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder:
            (context, error, stackTrace) =>
                Icon(icon, size: 36, color: option.color),
      ),
    );
  }

  // ============================================================
  // 12. 生成 UUID v4
  // ============================================================

  String _generateUuid() {
    final random = Random.secure();

    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex =
        bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  String _formatArrivalTime(DateTime value) {
    final offset = value.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final absoluteOffset = offset.abs();
    final date =
        '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
    final time =
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}.'
        '${value.millisecond.toString().padLeft(3, '0')}';
    final zone =
        '$sign${absoluteOffset.inHours.toString().padLeft(2, '0')}:'
        '${(absoluteOffset.inMinutes % 60).toString().padLeft(2, '0')}';
    return '${date}T$time$zone';
  }

  // ============================================================
  // 13. 寄出前检查
  // ============================================================

  String? _validateForm() {
    final title = _titleController.text.trim();

    final recipient = _recipientController.text.trim();

    final content = _contentController.text;

    final effectiveLength =
        content.characters
            .where((character) => character.trim().isNotEmpty)
            .length;

    if (title.isEmpty) {
      return '请给这封信起个名字';
    }

    if (recipient.isEmpty) {
      return '请填写收件人称呼';
    }

    if (recipient.characters.length > 20) {
      return '收件人称呼不能超过 20 个字符';
    }

    if (effectiveLength < 200) {
      return '正文至少需要 200 个有效字符';
    }

    if (effectiveLength > 5000) {
      return '正文不能超过 5000 个有效字符';
    }

    if (utf8.encode(content).length > 64 * 1024) {
      return '正文内容过大，请适当删减';
    }

    if (_arriveAt == null) {
      return '请选择预计送达时间';
    }

    if (!_arriveAt!.isAfter(DateTime.now().add(const Duration(hours: 24)))) {
      return '送达时间至少需要在 24 小时之后，请重新选择';
    }

    if (_imageBytes != null && _attachmentId == null) {
      return '图片还没有上传成功，请重新选择';
    }

    return null;
  }

  // ============================================================
  // 14. 寄出二次确认
  // ============================================================

  Future<void> _confirmSend() async {
    if (_sending || _uploadingImage) return;

    final error = _validateForm();

    if (error != null) {
      _showMessage(error);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _panelColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            '确认寄出这封信？',
            style: TextStyle(
              color: _darkTextColor,
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            '寄出后将无法修改、撤回或删除。\n\n'
            '请确认信件内容和预计送达时间。',
            style: TextStyle(color: _textColor, fontSize: 15, height: 1.8),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                '再检查一下',
                style: TextStyle(color: _darkTextColor),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _buttonColor,
                foregroundColor: _darkTextColor,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('确认寄出'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _sendLetter();
  }

  // ============================================================
  // 15. 发送慢信
  // ============================================================

  Future<void> _sendLetter() async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      _showMessage('登录状态已失效，请重新登录');
      return;
    }

    late final User user;
    try {
      user = await AuthService().getUserInfo();
    } catch (_) {
      _showMessage('无法确认绑定对象，请检查网络后重试');
      return;
    }
    final expectedPartnerId = user.partnerId;
    if (!user.isBound ||
        expectedPartnerId == null ||
        expectedPartnerId.isEmpty) {
      _showMessage('请先完成绑定，再寄出慢信');
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      _pendingRequestId ??= _generateUuid();
      // 先保存当前草稿。
      await _saveDraft();

      final body = <String, dynamic>{
        'clientRequestId': _pendingRequestId,
        'expectedPartnerId': expectedPartnerId,
        'title': _titleController.text.trim(),
        'content': _contentController.text,
        'recipientLabel': _recipientController.text.trim(),
        'appearance': {
          'stampId': _selectedStamp,
          'paperId': _selectedPaper,
          'sealId': _selectedSeal,
          'envelopeId': _selectedEnvelope,
        },
        // 保留时区偏移，避免只传无时区的本地时间。
        'arriveAt': _formatArrivalTime(_arriveAt!),
      };

      if (_attachmentId != null) {
        body['attachmentId'] = _attachmentId;
      }

      final data = await SlowLetterApi.instance.send(body);

      final letterId = data['letterId']?.toString();

      final letterNo = data['letterNo']?.toString();

      if (letterId == null || letterId.isEmpty) {
        throw Exception('服务器没有返回信件编号');
      }

      // 发送成功后清除本地草稿。
      _pendingRequestId = null;
      await _deleteDraft();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: _panelColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 56,
                  color: _darkTextColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  '信件已经寄出',
                  style: TextStyle(
                    color: _darkTextColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatLetterNo(letterNo),
                  style: const TextStyle(color: _textColor, fontSize: 19),
                ),
                const SizedBox(height: 12),
                const Text(
                  '愿这份心意，在约定的时间抵达。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textColor, height: 1.7),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  '完成',
                  style: TextStyle(color: _darkTextColor),
                ),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        _showMessage('寄出失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  String _formatLetterNo(String? letterNo) {
    if (letterNo == null || letterNo.trim().isEmpty) {
      return 'MX · 暂无编号';
    }

    final value = letterNo.trim();

    // 服务端已经返回完整编号时直接展示。
    if (value.startsWith('MX')) {
      return value.replaceFirst('MX', 'MX ·').replaceAll('MX · ·', 'MX ·');
    }

    // 兼容服务端仅返回数字序号的情况。
    final number = int.tryParse(value);

    if (number != null) {
      return 'MX · ${number.toString().padLeft(4, '0')}';
    }

    return 'MX · $value';
  }

  // ============================================================
  // 16. 提示信息
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _darkTextColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ============================================================
  // 17. 构建页面
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final pageHorizontalPadding = screenWidth < 400 ? 20.0 : 32.0;

    return Scaffold(
      backgroundColor: _backgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 背景图片。
          Positioned.fill(
            child: Image.asset(
              'assets/images/image 9.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(color: _backgroundColor);
              },
            ),
          ),

          // 背景浅色遮罩，让主面板更突出。
          Positioned.fill(
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.08)),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),

                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      pageHorizontalPadding,
                      12,
                      pageHorizontalPadding,
                      24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: _buildMainPanel(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 页面初始化时显示轻量加载遮罩。
          if (_restoringDraft)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.45),
                child: const Center(
                  child: CircularProgressIndicator(color: _darkTextColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 18. 顶部返回按钮
  // ============================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.55),
            elevation: 0,
            shadowColor: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                if (_draftChanged) {
                  await _saveDraft();
                }

                if (mounted) {
                  Navigator.of(context).maybePop();
                }
              },
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Color(0xFF8FA57F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 19. 主面板
  // ============================================================

  Widget _buildMainPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 26),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(58),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageCard(),

          const SizedBox(height: 24),

          _buildAppearanceSelector(),

          const SizedBox(height: 24),

          _buildFieldLabel('信件标题'),

          const SizedBox(height: 8),

          _buildTitleField(),

          const SizedBox(height: 28),

          _buildRecipientField(),

          const SizedBox(height: 16),

          _buildContentField(),

          const SizedBox(height: 22),

          _buildArriveTimeCard(),

          const SizedBox(height: 22),

          _buildSendButton(),
        ],
      ),
    );
  }

  // ============================================================
  // 20. 图片卡片
  // ============================================================

  Widget _buildImageCard() {
    return Container(
      height: 244,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (_imageBytes != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
              ),
            )
          else
            const Center(
              child: Icon(
                Icons.image_outlined,
                color: Color(0xFFF5F0EC),
                size: 100,
              ),
            ),

          if (_imageBytes != null)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.white.withValues(alpha: 0.88),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.close_rounded, color: _darkTextColor),
                  tooltip: '移除图片',
                ),
              ),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white.withValues(alpha: 0.94),
                elevation: 2,
                shadowColor: Colors.black12,
                borderRadius: BorderRadius.circular(36),
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(36),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.camera_alt_rounded,
                          size: 31,
                          color: _darkTextColor,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            _uploadingImage
                                ? '正在上传图片...'
                                : _imageBytes == null
                                ? '更换图片（最多1张）'
                                : '重新选择图片',
                            style: const TextStyle(
                              color: _textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }

  // ============================================================
  // 21. 邮票、信纸、封口贴、信封
  // ============================================================

  Widget _buildAppearanceSelector() {
    final items = <_AppearanceItem>[
      _AppearanceItem(
        title: '邮票',
        icon: Icons.local_post_office_outlined,
        type: 'stamp',
        imagePath: 'assets/images/1.png',
      ),
      _AppearanceItem(
        title: '信纸',
        icon: Icons.description_outlined,
        type: 'paper',
        imagePath: 'assets/images/2.png',
      ),
      _AppearanceItem(
        title: '封口贴',
        icon: Icons.label_outline_rounded,
        type: 'seal',
        imagePath: 'assets/images/3.png',
      ),
      _AppearanceItem(
        title: '信封',
        icon: Icons.mail_outline_rounded,
        type: 'envelope',
        imagePath: 'assets/images/4.png',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              items
                  .map(
                    (item) => SizedBox(
                      width: itemWidth,
                      child: _buildAppearanceItem(item: item),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }

  Widget _buildAppearanceItem({required _AppearanceItem item}) {
    final options = _appearanceOptions(item.type);
    final selected = options.firstWhere(
      (option) => option.id == _selectedAppearanceId(item.type),
      orElse: () => options.first,
    );
    return Material(
      color: const Color(0xFFF8F1E8).withValues(alpha: 0.72),
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _selectAppearance(item),
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 58,
                height: 70,
                child: _buildAppearancePreview(
                  item.imagePath,
                  item.icon,
                  selected,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: _darkTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selected.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _textColor, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 34,
                      height: 4,
                      decoration: BoxDecoration(
                        color: selected.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.expand_more_rounded,
                color: _darkTextColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ============================================================
  // 22. 标签
  // ============================================================

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _textColor,
        fontSize: 19,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ============================================================
  // 23. 标题输入框
  // ============================================================

  Widget _buildTitleField() {
    return _buildWhiteCard(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _titleController,
        enabled: !_sending,
        maxLength: 50,
        style: const TextStyle(color: _darkTextColor, fontSize: 19),
        decoration: const InputDecoration(
          hintText: '给这封信起个名字',
          hintStyle: TextStyle(color: _textColor, fontSize: 19),
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.symmetric(vertical: 25),
        ),
      ),
    );
  }

  // ============================================================
  // 24. 收件人称呼
  // ============================================================

  Widget _buildRecipientField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '实际收件人：$_boundRecipientLabel',
          style: const TextStyle(color: _darkTextColor, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              '致',
              style: TextStyle(
                color: _textColor,
                fontSize: 21,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _recipientController,
                enabled: !_sending,
                maxLength: 20,
                style: const TextStyle(
                  color: _textColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: '自定义称呼',
                  hintStyle: TextStyle(
                    color: _textColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // 25. 正文输入框
  // ============================================================

  Widget _buildContentField() {
    return Container(
      constraints: const BoxConstraints(minHeight: 430),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 82),
            child: TextField(
              controller: _contentController,
              enabled: !_sending,
              minLines: 14,
              maxLines: null,
              maxLength: 5000,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(
                color: _darkTextColor,
                fontSize: 18,
                height: 1.9,
              ),
              decoration: const InputDecoration(
                hintText: '把想对TA说的话，慢慢写在这里...',
                hintStyle: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  height: 1.9,
                ),
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),

          Positioned(
            right: 16,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_contentLength / 5000',
                  style: const TextStyle(color: _textColor, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _contentValid
                      ? '正文长度符合要求'
                      : _contentLength < 200
                      ? '正文200-5000字'
                      : '正文不能超过5000字',
                  style: TextStyle(
                    color: _contentValid ? const Color(0xFF9BAF8E) : _textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 26. 预计送达时间
  // ============================================================

  Widget _buildArriveTimeCard() {
    return Material(
      color: _cardColor,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: _selectArriveTime,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: _darkTextColor,
                size: 48,
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '预计送达时间',
                      style: TextStyle(color: _textColor, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _arriveAt == null
                          ? '请选择送达时间'
                          : _formatDateTime(_arriveAt!),
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _darkTextColor,
                size: 35,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 27. 寄出按钮
  // ============================================================

  Widget _buildSendButton() {
    return Material(
      color: _buttonColor,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: _sending || _uploadingImage ? null : _confirmSend,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          height: 82,
          alignment: Alignment.center,
          child:
              _sending
                  ? const SizedBox(
                    width: 27,
                    height: 27,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _textColor,
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.send_outlined,
                        color: Color(0xFFF8F5F0),
                        size: 34,
                      ),
                      const SizedBox(width: 20),
                      Text(
                        _uploadingImage ? '图片上传中' : '寄出',
                        style: const TextStyle(
                          color: _textColor,
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  // ============================================================
  // 28. 通用白色卡片
  // ============================================================

  Widget _buildWhiteCard({
    required Widget child,
    required double height,
    required EdgeInsets padding,
  }) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================
// 外观选项数据
// ============================================================
class _AppearanceItem {
  final String title;
  final IconData icon;
  final String type;
  final String imagePath;

  _AppearanceItem({
    required this.title,
    required this.icon,
    required this.type,
    required this.imagePath,
  });
}

class _AppearanceOption {
  final String id;
  final String label;
  final Color color;

  const _AppearanceOption(this.id, this.label, this.color);
}
