import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lome/services/api_service.dart';
import 'package:lome/models/calendar_models.dart';

class WeeklyReportPage extends StatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  State<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends State<WeeklyReportPage> {
  // ============ 数据状态 ============
  String _partnerName = 'TA';
  int _totalDays = 0;
  int _weeklyRecordedDays = 0;
  int _weeklyCompletedPlans = 0;
  int _weeklyPendingPlans = 0;
  int _weeklyTotalPlans = 0;
  List<DaySummary> _weekDays = [];
  bool _isLoading = false;

  // ============ 颜色常量（与日历页一致） ============
  static const Color _pinkLight = Color(0xFFE8D9D9);
  static const Color _pinkDark = Color(0xFFB59A9A);
  static const Color _titleColor = Color(0xFFBED5DB);
  static const Color _mintGreen = Color(0xFFA8C9A8);
  static const Color _yellowStar = Color(0xFFE8C97A);
  static const Color _recordDotColor = Color(0xFFFFE2E2);
  static const Color _planDotColor = Color(0xFFDEF9F0);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchWeeklyData();
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

  Future<void> _fetchWeeklyData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      List<DaySummary> weekDays = [];
      int recordedDays = 0;
      int completedPlans = 0;
      int pendingPlans = 0;
      int totalPlans = 0;

      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dateStr = _formatDateKey(date);
        final response = await ApiService.get(
          '/api/v1/calendar/daily',
          query: {'date': dateStr},
        );

        if (response['code'] == 0) {
          final dailyDetail = DailyDetailResponse.fromJson(response['data']);

          bool hasRecord = dailyDetail.records.isNotEmpty;
          bool hasPlan = dailyDetail.plans.isNotEmpty;
          int dayCompletedPlans = dailyDetail.plans.where((p) => p.completed).length;
          int dayPendingPlans = dailyDetail.plans.where((p) => !p.completed).length;

          if (hasRecord) recordedDays++;
          completedPlans += dayCompletedPlans;
          pendingPlans += dayPendingPlans;
          totalPlans += dailyDetail.plans.length;

          weekDays.add(DaySummary(
            date: date,
            hasRecord: hasRecord,
            hasPlan: hasPlan,
            completedPlans: dayCompletedPlans,
            pendingPlans: dayPendingPlans,
          ));
        }
      }

      setState(() {
        _weeklyRecordedDays = recordedDays;
        _weeklyCompletedPlans = completedPlans;
        _weeklyPendingPlans = pendingPlans;
        _weeklyTotalPlans = totalPlans;
        _weekDays = weekDays;
      });
    } catch (e) {
      debugPrint('获取周报数据失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getWeekdayName(DateTime date) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return weekdays[date.weekday - 1];
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

  // ============ 第一块：标题 ============
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
              "周报",
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
        const SizedBox(height: 30),
      ],
    );
  }

  // ============ 第二块：本周概览 ============
  Widget _buildWeeklyOverview() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: _cardDecoration(borderRadius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              '${startOfWeek.month}月${startOfWeek.day}日 - ${endOfWeek.month}月${endOfWeek.day}日',
              style: TextStyle(
                fontSize: 14,
                color: _pinkDark.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.edit_note,
                label: '记录天数',
                value: '$_weeklyRecordedDays',
                color: _recordDotColor,
              ),
              _buildStatItem(
                icon: Icons.check_circle_outline,
                label: '完成规划',
                value: '$_weeklyCompletedPlans',
                color: _planDotColor,
              ),
              _buildStatItem(
                icon: Icons.pending_actions,
                label: '待完成',
                value: '$_weeklyPendingPlans',
                color: const Color(0xFFFFFDC4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 24,
            color: const Color(0xFF6B5F4F),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B5F4F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: _pinkDark.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // ============ 第三块：每日详情 ============
  Widget _buildDailyDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: _cardDecoration(borderRadius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本周详情',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _pinkDark.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          ..._weekDays.map((day) => _buildDayItem(day)).toList(),
        ],
      ),
    );
  }

  Widget _buildDayItem(DaySummary day) {
    final isToday = day.date.year == DateTime.now().year &&
        day.date.month == DateTime.now().month &&
        day.date.day == DateTime.now().day;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xFFE8D9D9).withOpacity(0.3)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Text(
                  '周${_getWeekdayName(day.date)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _pinkDark.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.date.day}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isToday
                        ? const Color(0xFF6B5F4F)
                        : _pinkDark.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                _buildStatusDot(
                  hasContent: day.hasRecord,
                  color: _recordDotColor,
                  label: '记录',
                ),
                const SizedBox(width: 16),
                _buildStatusDot(
                  hasContent: day.hasPlan,
                  color: _planDotColor,
                  label: '规划',
                ),
              ],
            ),
          ),
          if (day.hasPlan)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '完成 ${day.completedPlans}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _mintGreen.withOpacity(0.8),
                  ),
                ),
                if (day.pendingPlans > 0)
                  Text(
                    '待办 ${day.pendingPlans}',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFE8C97A).withOpacity(0.8),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusDot({
    required bool hasContent,
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: hasContent ? color : Colors.grey.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: hasContent
                ? _pinkDark.withOpacity(0.8)
                : Colors.grey.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  // ============ 第四块：完成率 ============
  Widget _buildCompletionRate() {
    final rate = _weeklyTotalPlans > 0
        ? (_weeklyCompletedPlans / _weeklyTotalPlans * 100).round()
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: _cardDecoration(borderRadius: 20),
      child: Column(
        children: [
          Text(
            '规划完成率',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _pinkDark.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: rate / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _mintGreen.withOpacity(0.8),
                  ),
                ),
              ),
              Text(
                '$rate%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: _pinkDark.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '本周共 $_weeklyTotalPlans 个规划，已完成 $_weeklyCompletedPlans 个',
            style: TextStyle(
              fontSize: 14,
              color: _pinkDark.withOpacity(0.7),
            ),
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
          Image.asset(
            'assets/images/calendar_plan_bg.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildWeeklyOverview(),
                        const SizedBox(height: 16),
                        _buildDailyDetails(),
                        const SizedBox(height: 16),
                        _buildCompletionRate(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============ 每日摘要数据模型 ============
class DaySummary {
  final DateTime date;
  final bool hasRecord;
  final bool hasPlan;
  final int completedPlans;
  final int pendingPlans;

  DaySummary({
    required this.date,
    required this.hasRecord,
    required this.hasPlan,
    required this.completedPlans,
    required this.pendingPlans,
  });
}