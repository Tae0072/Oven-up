import 'package:flutter/material.dart';

import '../data/admin_api.dart';
import '../data/api_exception.dart';
import '../models/order_summary.dart';
import '../state/auth_store.dart';
import '../utils/format.dart';
import 'admin_order_detail_page.dart';

/// A4. 관리자(사장님) 주문 관리 — 전체/상태별 주문 목록.
class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final AdminApi _api = AdminApi();

  // 필터: 전체 + 주요 상태
  static const List<String> _filters = [
    '전체', '결제완료', '준비중', '준비완료', '픽업완료', '배달중', '배달완료', '취소',
  ];
  String _filter = '전체';

  List<OrderSummary> _orders = const <OrderSummary>[];
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
      final list = await _api.fetchOrders(token, status: _filter == '전체' ? null : _filter);
      if (!mounted) return;
      setState(() {
        _orders = list;
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

  void _openDetail(int orderId) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => AdminOrderDetailPage(orderId: orderId)))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 관리 (사장님)'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                return ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) {
                    setState(() => _filter = f);
                    _load();
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('해당 상태의 주문이 없어요.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _orders.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final o = _orders[i];
          final sub = <String>[
            fulfillmentLabel(o.fulfillmentType),
            formatPrice(o.totalPrice),
            if (o.createdAt != null) formatDateTime(o.createdAt!),
          ];
          return ListTile(
            title: Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(sub.join('   ·   ')),
            trailing: Chip(label: Text(o.status), visualDensity: VisualDensity.compact),
            onTap: () => _openDetail(o.orderId),
          );
        },
      ),
    );
  }
}
