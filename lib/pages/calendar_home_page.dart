import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lome/services/api_service.dart';
import 'package:lome/models/calendar_models.dart';
import 'package:lome/pages/add_record_page.dart';
import 'package:lome/pages/add_plan_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // ============ 数据状态 ============
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  String _partnerName = 'TA';
  int _totalDays = 0;
  int _recordedDays = 0;
  int _weeklyRecordedDays = 0;
  int _weeklyCompletedPlans = 0;

  Map<String, CalendarDayData> _monthlyData = {};
  bool _isLoading = false;

  // ============ 按钮动画状态 ============
  double _recordButtonScale = 1.0;
  double _planButtonScale = 1.0;

  // ============ 颜色常量 ============
  static const Color _pinkLight = Color(0xFFE8D9D9);
  static const Color _pinkDark = Color(0xFFB59A9A);
  static const Color _titleColor = Color(0xFFBED5DB);
  static const Color _mintGreen = Color(0xFFA8C9A8);
  static const Color _yellowStar = Color(0xFFE8C97A);
  static const Color _recordDotColor = Color(0xFFFFE2E2);   // 已记录
  static const Color _planDotColor = Color(0xFFDEF9F0);     // 已规划
  static const Color _importantDotColor = Color(0xFFFFFDC4); // 重要日 

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchMonthlyData();
    _fetchWeeklyStats();
  }

  // ============ 数据加载 ============
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _partnerName = prefs.getString('partner_name') ?? 'TA';
      final bindDateStr = prefs.getString('bind_date');
      if (bindDateStr != null) {
        final bindDate = DateTime.parse(bindDateStr);
        _totalDays = DateTime.now().difference(bindDate).inDays + 1;
      }
    });
  }

  Future<void> _fetchMonthlyData() async {
    setState(() => _isLoading = true);
    try {
      final monthStr =
          '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
      final response = await ApiService.get(
        '/api/v1/calendar/monthly',
        query: {'month': monthStr},
      );

      print('【月历数据】完整响应: $response'); 

      if (response['code'] == 0) {
        final data = response['data'];
        print('【月历数据】days: ${data['days']}');
        setState(() {
          _recordedDays = data['recordedDays'] ?? 0;
          _monthlyData = {};
          for (var day in data['days'] ?? []) {
            _monthlyData[day['date']] = CalendarDayData.fromJson(day);
          }
        });
        print('【月历数据Keys】${_monthlyData.keys}');

      } else if (response['code'] == 7001) {
        _showBindDialog();
      }
    } catch (e) {
      debugPrint('获取月历数据失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchWeeklyStats() async {
    try {
      final now = DateTime.now();
      int recorded = 0;
      int completed = 0;

      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final response = await ApiService.get(
          '/api/v1/calendar/daily',
          query: {'date': dateStr},
        );
        if (response['code'] == 0) {
          final data = response['data'];
          if (data['records']?.isNotEmpty == true) recorded++;
          for (var plan in data['plans'] ?? []) {
            if (plan['completed'] == true) completed++;
          }
        }
      }
      setState(() {
        _weeklyRecordedDays = recorded;
        _weeklyCompletedPlans = completed;
      });
    } catch (e) {
      debugPrint('获取周报数据失败: $e');
    }
  }

  // ============ 日历工具方法 ============
  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _fetchMonthlyData();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _fetchMonthlyData();
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ============ 点击日期跳转 ============
  void _selectDate(DateTime date) async {
    setState(() {
      _selectedDate = date;
    });

    // 获取当天完整数据
    final dateStr = _formatDateKey(date);
    try {
      final response = await ApiService.get(
        '/api/v1/calendar/daily',
        query: {'date': dateStr},
      );

      if (response['code'] == 0) {
        final data = response['data'];
        final records = data['records'] ?? [];
        final plans = data['plans'] ?? [];

        if (records.isNotEmpty && plans.isNotEmpty) {
          _showChooseDialog(date, records.first, plans.first);
        } else if (records.isNotEmpty) {
          _navigateToRecord(date, records.first);
        } else if (plans.isNotEmpty) {
          _navigateToPlan(date, plans.first);
        } else {
          // 都没有 → 新建记录
          _navigateToRecord(date, null);
        }
      } else {
        // 请求失败 → 新建记录
        _navigateToRecord(date, null);
      }
    } catch (e) {
      // 异常 → 新建记录
      _navigateToRecord(date, null);
    }
  }

  // ============ 选择弹窗 ============
  void _showChooseDialog(DateTime date, Map<String, dynamic> record, Map<String, dynamic> plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择查看内容',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B5F4F),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceButton(
                    icon: Icons.edit_note,
                    label: '记录',
                    color: const Color(0xFFFFE2E2),
                    onTap: () {
                      Navigator.pop(ctx);
                      _navigateToRecord(date, record);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChoiceButton(
                    icon: Icons.assignment,
                    label: '规划',
                    color: const Color(0xFFDEF9F0),
                    onTap: () {
                      Navigator.pop(ctx);
                      _navigateToPlan(date, plan);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                '取消',
                style: TextStyle(color: Color(0xFFB4C8BB)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: const Color(0xFF6B5F4F)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B5F4F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ 页面跳转 ============
  void _navigateToRecord(DateTime date, Map<String, dynamic>? existingRecord) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecordPage(
          selectedDate: date,
          existingRecord: existingRecord,
        ),
      ),
    );
  }

  void _navigateToPlan(DateTime date, Map<String, dynamic>? existingPlan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPlanPage(
          selectedDate: date,
          existingPlan: existingPlan,
        ),
      ),
    );
  }

  // ============ 重要日弹窗 ============
  Widget _buildImportantDayDialog() {
    final TextEditingController _titleController = TextEditingController();
    DateTime _selectedDate = DateTime.now();

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            '添加重要日',
            style: TextStyle(
              fontSize: 22,
              color: Color(0xFF6B5F4F),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '日期',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF887882),
                  ),
                ),
                subtitle: Text(
                  '${_selectedDate.year}年${_selectedDate.month.toString().padLeft(2, '0')}月${_selectedDate.day.toString().padLeft(2, '0')}日',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF665862),
                  ),
                ),
                trailing: const Icon(
                  Icons.keyboard_arrow_right,
                  color: Color(0xFFC9C0C6),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFE8D9D9),
                            onPrimary: Color(0xFF6B5F4F),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF665862),
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide(color: Color(0xFFE0D6CC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide(color: Color(0xFFE8D9D9), width: 2),
                  ),
                  hintText: '输入重要日名称',
                  hintStyle: TextStyle(fontSize: 16, color: Color(0xFFC9C0C6)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '取消',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFB4C8BB),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入重要日名称'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }
                _saveImportantDay(title, _selectedDate);
                Navigator.pop(context, {
                  'name': title,
                  'date': _selectedDate,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFDC4),
                foregroundColor: const Color(0xFF6B5F4F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text('添加'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        );
      },
    );
  }

  Future<void> _saveImportantDay(String name, DateTime date) async {
    try {
      final response = await ApiService.post(
        '/api/v1/important/day/create',
        body: {
          'name': name,
          'date': _formatDateKey(date),
          'repeatType': 'once',
        },
      );
      print('【重要日】保存响应: $response');
    } catch (e) {
      print('【重要日】保存异常: $e');
    }
  }

  void _navigateToImportantDay() async {
    final result = await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _buildImportantDayDialog(),
    );

    if (result != null) {
      print('【重要日】添加结果: $result');
      _fetchMonthlyData();
      _fetchWeeklyStats();
    }
  }

  void _showBindDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: const Text('尚未绑定伴侣，请先完成绑定'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: 跳转到绑定页
            },
            child: const Text('去绑定'),
          ),
        ],
      ),
    );
  }

  CalendarDayData? _getDayData(DateTime date) {
    final key = _formatDateKey(date);
    return _monthlyData[key];
  }

  // ============ 卡片装饰 ============
  BoxDecoration _cardDecoration({double borderRadius = 20}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.82),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
    );
  }

  // ============ 返回按钮 ============
  Widget _buildBackButton(VoidCallback onTap) {
    return Container(
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
        onPressed: onTap,
      ),
    );
  }

  // ============ 第一块：标题 + 分割条 ============
  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _buildBackButton(() => Navigator.pop(context)),
            ),
            const Text(
              "日历",
              style: TextStyle(
                fontSize: 30,
                color: _titleColor,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 50),
      ],
    );
  }

  // ============ 第二块：月份切换箭头 ============
  Widget _buildMonthArrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF6EFE4).withOpacity(0.16),
          border: Border.all(
            color: const Color(0xFFF6EFE4).withOpacity(0.28),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 2,
              offset: Offset(0, 1),
              spreadRadius: 0,
            )
          ],
        ),
        child: Icon(
          icon,
          size: 14,
          color: _pinkDark.withOpacity(0.8),
        ),
      ),
    );
  }

  // ============ 第二块：图例项 ============
  Widget _buildLegendItem(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _pinkDark.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ============ 第二块：透明日历主体 ============
  Widget _buildCalendar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: _cardDecoration(borderRadius: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMonthArrow(Icons.chevron_left, _previousMonth),
              const SizedBox(width: 16),
              Text(
                '${_currentMonth.year}年 ${_currentMonth.month.toString().padLeft(2, '0')}月',
                style: TextStyle(
                  fontSize: 18,
                  color: _pinkDark.withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 16),
              _buildMonthArrow(Icons.chevron_right, _nextMonth),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['日', '一', '二', '三', '四', '五', '六'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 13,
                      color: _pinkDark.withOpacity(0.8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          _isLoading
              ? const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _buildDateGrid(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('已记录', Icons.circle,_recordDotColor),
              const SizedBox(width: 16),
              _buildLegendItem('已规划', Icons.circle, _planDotColor),
              const SizedBox(width: 16),
              _buildLegendItem('重要日', Icons.circle, _importantDotColor),
            ],
          ),
        ],
      ),
    );
  }

  // ============ 第二块：日期网格 ============
  Widget _buildDateGrid() {
  final daysInMonth = _getDaysInMonth(_currentMonth);
  final firstDayOfMonth = _getFirstDayOfMonth(_currentMonth);
  final firstDayIndex = (firstDayOfMonth % 7) + 1;

  List<Widget> cells = [];

  for (int i = 0; i < firstDayIndex; i++) {
    cells.add(const SizedBox(width: 40));
  }

  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(_currentMonth.year, _currentMonth.month, day);
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;
    final dayData = _getDayData(date);

    // 和记录/规划一样，直接从 dayData 读取
    final hasRecord = dayData?.hasRecord ?? false;
    final hasPlan = dayData?.hasPlan ?? false;
    final hasImportant = dayData?.hasImportantDay ?? false;

    Color? bgColor;
    if (hasImportant) {
      bgColor = const Color(0xFFFFFDC4).withOpacity(0.9);
    } else if (hasPlan) {
      bgColor = const Color(0xFFDEF9F0).withOpacity(0.9);
    } else if (hasRecord) {
      bgColor = const Color(0xFFFFE2E2).withOpacity(0.9);
    }

    cells.add(
      SizedBox(
        width: 40,
        child: GestureDetector(
          onTap: () => _selectDate(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE8D9D9).withOpacity(0.8)
                  : bgColor ?? Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (bgColor != null
                          ? const Color(0xFF6B5F4F)
                          : _pinkDark.withOpacity(0.8)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final remaining = (7 - (cells.length % 7)) % 7;
  for (int i = 0; i < remaining; i++) {
    cells.add(const SizedBox(width: 40));
  }

  return Wrap(
    children: cells,
  );
}

  // ============ 第三块：统计信息 ============
  Widget _buildStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: _cardDecoration(borderRadius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                size: 16,
                color: Color(0xFFE8D9D9),
              ),
              const SizedBox(width: 8),
              Text(
                '和 $_partnerName 的第 $_totalDays 天',
                style: TextStyle(
                  fontSize: 18,
                  color: _pinkDark.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              '本月已记录 $_recordedDays 天',
              style: TextStyle(
                fontSize: 14,
                color: _recordedDays == 0
                    ? _pinkDark.withOpacity(0.5)
                    : _pinkDark.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ 第四块：周报 ============
  Widget _buildWeeklyReport() {
    return GestureDetector(
      onTap: () {
        // TODO: 跳转到周报详情页
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: _cardDecoration(borderRadius: 20),
        child: Row(
          children: [
            Icon(
              Icons.bar_chart,
              size: 18,
              color: _pinkDark.withOpacity(0.8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '周报',
                style: TextStyle(
                  fontSize: 18,
                  color: _pinkDark.withOpacity(0.8),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: _pinkDark.withOpacity(0.55),
            ),
          ],
        ),
      ),
    );
  }

  // ============ 第五块：操作按钮 ============
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required double scale,
    required ValueChanged<double> onScaleChanged,
  }) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => onScaleChanged(0.94),
        onTapUp: (_) => onScaleChanged(1.0),
        onTapCancel: () => onScaleChanged(1.0),
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          scale: scale,
          child: Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: _cardDecoration(borderRadius: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: const Color(0xFF6B5F4F).withOpacity(0.85),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF6B5F4F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF6B5F4F).withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.edit_note,
            title: '记录',
            subtitle: '记录每一天',
            onTap: () => _navigateToRecord(_selectedDate, null),
            scale: _recordButtonScale,
            onScaleChanged: (value) => setState(() => _recordButtonScale = value),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.assignment,
            title: '规划',
            subtitle: '我们去哪里',
            onTap: () => _navigateToPlan(_selectedDate, null),
            scale: _planButtonScale,
            onScaleChanged: (value) => setState(() => _planButtonScale = value),
          ),
        ],
      ),
    );
  }

  // ============ 第六块：添加重要日按钮 ============
  Widget _buildImportantDayButton() {
    return GestureDetector(
      onTap: _navigateToImportantDay,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.20),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.star_outline,
              size: 20,
              color: Color(0xFFE8C97A),
            ),
            const SizedBox(width: 10),
            Text(
              '添加重要日',
              style: TextStyle(
                fontSize: 18,
                color: const Color(0xFF6B5F4F).withOpacity(0.8),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ 主构建 ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Image.asset(
            'assets/images/calendar.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildCalendar(),
                  const SizedBox(height: 20),
                  _buildStats(),
                  const SizedBox(height: 16),
                  _buildWeeklyReport(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 12), 
                  _buildImportantDayButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}