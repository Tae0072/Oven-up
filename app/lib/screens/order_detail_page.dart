import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/order_api.dart';
import '../models/order_detail.dart';
import '../state/auth_store.dart';
import '../utils/format.dart';

/// 주문 상세 화면 (05_API §4.4)
class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderApi _orderApi = OrderApi();

  OrderDetail? _detail;
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
    try {
      final detail = await _orderApi.fetchOrderDetail(token, widget.orderId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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
      appBar: AppBar(title: const Text('주문 상세')),
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
    final d = _detail!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(d.orderNo,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Chip(label: Text(d.status), visualDensity: VisualDensity.compact),
          ],
        ),
        const SizedBox(height: 8),
        Text('수령 방식: ${fulfillmentLabel(d.fulfillmentType)}'),
        if (d.deliveryAddress != null && d.deliveryAddress!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('배달 주소: ${d.deliveryAddress}'),
        ],
        if (d.scheduledAt != null) ...[
          const SizedBox(height: 4),
          Text('예약 시간: ${formatDateTime(d.scheduledAt!)}'),
        ],
        const Divider(height: 32),
        const Text('주문 항목', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...d.items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.menuName}  x${item.quantity}'),
                      if (item.optionsDesc.isNotEmpty)
                        Text(item.optionsDesc,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Text(formatPrice(item.lineTotal)),
              ],
            ),
          ),
        ),
        const Divider(height: 32),
        if (d.discountPrice > 0)
          _amountRow('할인', d.discountPrice),
        _amountRow('최종 결제금액', d.totalPrice, bold: true),
      ],
    );
  }

  Widget _amountRow(String label, int amount, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 18 : 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(formatPrice(amount), style: style),
        ],
      ),
    );
  }
}
