import 'package:flutter/material.dart';

import '../data/admin_api.dart';
import '../data/api_exception.dart';
import '../state/auth_store.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';

/// A5. 관리자(사장님) 대시보드 — 매출·주문건수·상태별·인기 메뉴 한눈에.
/// (03_기능 §11 / 05_API GET /api/admin/stats)
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminApi _api = AdminApi();

  DashboardStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = AuthStore.instance.token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = '로그인이 필요해요';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await _api.fetchStats(token);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '서버에 연결하지 못했어요.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('매출 대시보드')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    final s = _stats!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 요약 카드 3개(오늘/이번주/누적)
          Row(
            children: [
              Expanded(child: _summaryCard('오늘 매출', formatPrice(s.todaySales), '${s.todayOrders}건', AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _summaryCard('이번주 매출', formatPrice(s.weekSales), '${s.weekOrders}건', AppColors.primaryDark)),
            ],
          ),
          const SizedBox(height: 10),
          _summaryCard('누적 매출', formatPrice(s.totalSales), '총 ${s.totalOrders}건 결제완료', Colors.blueGrey, wide: true),
          const SizedBox(height: 24),

          _sectionTitle('최근 7일 매출'),
          const SizedBox(height: 8),
          _WeeklyBarChart(points: s.daily),
          const SizedBox(height: 24),

          _sectionTitle('주문 상태'),
          const SizedBox(height: 8),
          if (s.statusCounts.isEmpty)
            const Text('아직 주문이 없어요.', style: TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: s.statusCounts
                  .map((c) => Chip(
                        label: Text('${c.status} ${c.count}'),
                        backgroundColor: AppColors.bg,
                        side: const BorderSide(color: AppColors.primary),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 24),

          _sectionTitle('인기 메뉴 TOP'),
          const SizedBox(height: 8),
          if (s.topMenus.isEmpty)
            const Text('아직 판매된 메뉴가 없어요.', style: TextStyle(color: Colors.grey))
          else
            ...s.topMenus.asMap().entries.map((e) => _topMenuRow(e.key + 1, e.value)),
          const SizedBox(height: 8),
          const Text(
            '매출·주문건수는 결제 완료(취소 제외) 기준이에요.',
            style: TextStyle(color: Colors.grey, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, String sub, Color color, {bool wide = false}) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _topMenuRow(int rank, TopMenu m) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: rank <= 3 ? AppColors.primary : Colors.grey.shade400,
            child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(m.menuName, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text('${m.quantity}개', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Text(formatPrice(m.sales), style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) =>
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
}

/// 최근 7일 매출 막대그래프 (외부 패키지 없이 간단히 그림)
class _WeeklyBarChart extends StatelessWidget {
  final List<DailyPoint> points;

  const _WeeklyBarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Text('데이터가 없어요.', style: TextStyle(color: Colors.grey));
    }
    final maxSales = points.map((p) => p.sales).fold<int>(0, (a, b) => a > b ? a : b);
    final safeMax = maxSales == 0 ? 1 : maxSales;
    const chartHeight = 120.0;

    return SizedBox(
      height: chartHeight + 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((p) {
          final ratio = p.sales / safeMax;
          final barHeight = (chartHeight * ratio).clamp(2.0, chartHeight);
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (p.sales > 0)
                  Text(
                    _shortMoney(p.sales),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                const SizedBox(height: 2),
                Container(
                  height: barHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: p.sales > 0 ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(p.dayLabel, style: const TextStyle(fontSize: 11)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 12900 -> "1.3만", 8000 -> "8천", 작은값은 그대로
  String _shortMoney(int v) {
    if (v >= 10000) {
      final man = v / 10000.0;
      return '${man.toStringAsFixed(man >= 10 ? 0 : 1)}만';
    }
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}천';
    return '$v';
  }
}
