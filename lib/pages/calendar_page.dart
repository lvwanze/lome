import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lome/services/api_service.dart';
import 'package:lome/models/calendar_models.dart';

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

  // 日历数据：日期 -> 标记信息
  Map<String, CalendarDayData> _monthlyData = {};
  bool _isLoading = false;

  // ============ 颜色常量 ============
  static const Color _pinkLight = Color(0xFFE8D9D9);
  static const Color _pinkDark = Color(0xFFB59A9A);
  static const Color _bgColor = Color(0xFFFDF7F0);
  static const Color _mintGreen = Color(0xFFA8C9A8);
  static const Color _yellowStar = Color(0xFFE8C97A);
  static const Color _titleColor = Color(0xFFBED5DB);

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

  // ============ API 调用 ============
  /// 获取月历概览
  Future<void> _fetchMonthlyData() async {
    setState(() => _isLoading = true);
    try {
      final monthStr =
          '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
      final response = await ApiService.get(
        '/api/v1/calendar/monthly',
        query: {'month': monthStr},
      );

      if (response['code'] == 0) {
        final data = response['data'];
        setState(() {
          _recordedDays = data['recordedDays'] ?? 0;
          _monthlyData = {};
          for (var day in data['days'] ?? []) {
            _monthlyData[day['date']] = CalendarDayData.fromJson(day);
          }
        });
      } else if (response['code'] == 7001) {
        _showBindDialog();
      }
    } catch (e) {
      debugPrint('获取月历数据失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 获取周报统计数据
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

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _navigateToDayDetail(date);
  }

  // ============ 页面跳转 ============
  void _navigateToDayDetail(DateTime date) {
    // TODO: 跳转到日详情页
  }

  void _navigateToRecord(DateTime date) {
    // TODO: 跳转到记录页
  }

  void _navigateToPlan(DateTime date) {
    // TODO: 跳转到规划页
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

  // ============ 获取日期数据 ============
  CalendarDayData? _getDayData(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _monthlyData[key];
  }

   // ============ 第一块：返回按钮 ============
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
            width: 1600.0,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFAFC5AE).withOpacity(0.3),
              borderRadius: BorderRadius.circular(100),
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
        color: Colors.white.withOpacity(0.2),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
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
      decoration: BoxDecoration(
        color: _bgColor.withOpacity(0.3),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 5),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // 月份切换栏
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
          // 星期行
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
          // 日期网格
          _isLoading
              ? const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _buildDateGrid(),
          const SizedBox(height: 12),
          // 底部图例
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('已记录', Icons.circle, _mintGreen),
              const SizedBox(width: 16),
              _buildLegendItem('已规划', Icons.circle, _pinkLight),
              const SizedBox(width: 16),
              _buildLegendItem('重要日', Icons.circle, _yellowStar),
            ],
          ),
        ],
      ),
    );
  }

  // ============ 第二块：日期网格 ============
// ============ 第二块：日期网格 ============
Widget _buildDateGrid() {
  final daysInMonth = _getDaysInMonth(_currentMonth);
  final firstDayOfMonth = _getFirstDayOfMonth(_currentMonth);
  final firstDayIndex = (firstDayOfMonth % 7) + 1;

  List<Widget> cells = [];

  // 填充空白格子
  for (int i = 0; i < firstDayIndex; i++) {
    cells.add(const SizedBox(width: 40, child: SizedBox()));
  }

  // 填充日期格子
  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(_currentMonth.year, _currentMonth.month, day);
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;
    final dayData = _getDayData(date);

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
                  ? _pinkLight.withOpacity(0.6)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected
                        ? Colors.white
                        : _pinkDark.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 2),
                // 标记圆点
                if (dayData != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (dayData.hasRecord)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFA8C9A8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (dayData.hasPlan)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(left: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8D9D9),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (dayData.hasImportantDay)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(left: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8C97A),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 补全最后一行
  final remaining = (7 - (cells.length % 7)) % 7;
  for (int i = 0; i < remaining; i++) {
    cells.add(const SizedBox(width: 40, child: SizedBox()));
  }

  return Wrap(
    children: cells,
  );
} 

  // ============ 第三块：统计信息 ============
  Widget _buildStats() {
    final statsText = _recordedDays == 0
        ? '本月的记录还是空的，要不要留下什么？'
        : '本月已记录 $_recordedDays 天';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _bgColor.withOpacity(0.3),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 5),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
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
              statsText,
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
    final hasData = _weeklyCompletedPlans > 0 || _weeklyRecordedDays > 0;
    final subtitle = hasData
        ? '本周已记录 $_weeklyRecordedDays 天，已完成 $_weeklyCompletedPlans 项规划'
        : '本月还没有待办日程，我们要去哪里探险呢？';

    return GestureDetector(
      onTap: () {
        // TODO: 跳转到周报详情页
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _bgColor.withOpacity(0.3),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              offset: Offset(0, 5),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.bar_chart,
              size: 18,
              color: _pinkDark.withOpacity(0.8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '周报',
                    style: TextStyle(
                      fontSize: 18,
                      color: _pinkDark.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasData
                          ? _pinkDark.withOpacity(0.6)
                          : _pinkDark.withOpacity(0.5),
                    ),
                  ),
                ],
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
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 90,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFFFFFFFF).withOpacity(0.34),
            border: Border.all(
              color: Color(0xFFFFFFFF).withOpacity(0.48),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0x66FFFFFF),
                offset: Offset(0, -2),
                blurRadius: 6,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Color(0x40000000),
                offset: Offset(0, 5),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: Color(0xFF6B5F4F),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
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
                  color: Color(0xFF6B5F4F).withOpacity(0.65),
                ),
              ),
            ],
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
            onTap: () => _navigateToRecord(_selectedDate),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.assignment,
            title: '规划',
            subtitle: '我们去哪里',
            onTap: () => _navigateToPlan(_selectedDate),
          ),
        ],
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
        // 背景图
        Image.asset(
          'assets/images/calendar.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
        // 内容
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}}