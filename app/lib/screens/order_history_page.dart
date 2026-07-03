import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/order_api.dart';
import '../models/order_summary.dart';
import '../state/auth_store.dart';
import '../utils/format.dart';
import 'order_detail_page.dart';

/// S12(일부). 주문 내역 화면 — 내 주문 목록. (05_API §4.3)
class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final OrderApi _orderApi = OrderApi();

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
      final orders = await _orderApi.fetchMyOrders(token);
      if (!mounted) return;
      setState(() {
        _orders = orders;
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => OrderDetailPage(orderId: orderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주문 내역')),
      body: _buildBody(),
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
      return const Center(child: Text('주문 내역이 없어요'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _orders.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final order = _orders[index];
          final subtitleParts = <String>[
            if (order.createdAt != null) formatDateTime(order.createdAt!),
            formatPrice(order.totalPrice),
          ];
          return ListTile(
            title: Text('${order.orderNo}  ·  ${fulfillmentLabel(order.fulfillmentType)}'),
            subtitle: Text(subtitleParts.join('   ·   ')),
            trailing: Chip(
              label: Text(order.status),
              visualDensity: VisualDensity.compact,
            ),
            onTap: () => _openDetail(order.orderId),
          );
        },
      ),
    );
  }
}
