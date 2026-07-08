import 'package:flutter/material.dart';

import '../data/admin_api.dart';
import '../data/api_exception.dart';
import '../models/order_detail.dart';
import '../state/auth_store.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';

/// A4. 관리자 주문 상세 + 상태 변경.
class AdminOrderDetailPage extends StatefulWidget {
  final int orderId;

  const AdminOrderDetailPage({super.key, required this.orderId});

  @override
  State<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage> {
  final AdminApi _api = AdminApi();

  OrderDetail? _detail;
  bool _loading = true;
  bool _updating = false;
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
      final d = await _api.fetchDetail(token, widget.orderId);
      if (!mounted) return;
      setState(() {
        _detail = d;
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

  Future<void> _changeStatus(String status) async {
    final token = AuthStore.instance.token;
    if (token == null) return;
    setState(() => _updating = true);
    try {
      final d = await _api.updateStatus(token, widget.orderId, status);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _updating = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('상태를 "$status"(으)로 바꿨어요')));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주문 상세 (사장님)')),
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
          children: [
            Expanded(
              child: Text(d.orderNo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Chip(
              label: Text(d.status),
              backgroundColor: AppColors.bg,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('${fulfillmentLabel(d.fulfillmentType)}'
            '${d.deliveryAddress != null && d.deliveryAddress!.isNotEmpty ? '  ·  ${d.deliveryAddress}' : ''}'
            '${d.scheduledAt != null ? '  ·  예약 ${formatDateTime(d.scheduledAt!)}' : ''}',
            style: const TextStyle(color: Colors.grey)),
        const Divider(height: 28),
        const Text('주문 항목', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...d.items.map(
          (it) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('${it.menuName}  x${it.quantity}')),
                Text(formatPrice(it.lineTotal)),
              ],
            ),
          ),
        ),
        const Divider(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('합계', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(formatPrice(d.totalPrice),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
          ],
        ),
        const Divider(height: 28),
        const Text('상태 변경', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kAdminStatuses.map((s) {
            final isCurrent = d.status == s;
            return FilledButton.tonal(
              onPressed: (_updating || isCurrent) ? null : () => _changeStatus(s),
              child: Text(s),
            );
          }).toList(),
        ),
        if (_updating)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
