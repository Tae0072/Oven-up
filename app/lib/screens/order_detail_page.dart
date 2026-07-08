import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/api_menu_repository.dart';
import '../data/order_api.dart';
import '../models/menu_item.dart';
import '../models/order_detail.dart';
import '../state/auth_store.dart';
import '../state/cart.dart';
import '../utils/format.dart';
import 'cart_page.dart';

/// 주문 상세 화면 (05_API §4.4)
class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderApi _orderApi = OrderApi();
  final ApiMenuRepository _menuRepo = ApiMenuRepository();

  OrderDetail? _detail;
  bool _loading = true;
  bool _reordering = false;
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

  /// 재주문(다시 담기): 이 주문의 메뉴들을 현재 메뉴와 맞춰 장바구니에 담는다.
  /// - 삭제되었거나 품절인 메뉴는 건너뛰고 안내한다.
  /// - 옵션은 저장돼 있지 않아 기본 상태로 담기며, 가격은 현재 가격이 적용된다.
  Future<void> _reorder() async {
    final d = _detail;
    if (d == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _reordering = true);
    try {
      final menus = await _menuRepo.fetchMenus();
      final byId = {for (final m in menus) m.id: m};

      int added = 0;
      final unavailable = <String>[];
      for (final item in d.items) {
        final MenuItem? menu = byId[item.menuId];
        if (menu == null || menu.soldOut) {
          unavailable.add(item.menuName);
          continue;
        }
        Cart.instance.add(menu, quantity: item.quantity);
        added++;
      }

      if (!mounted) return;
      if (added == 0) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('지금은 다시 담을 수 있는 메뉴가 없어요. (품절/판매종료)'),
          ));
        return;
      }
      if (unavailable.isNotEmpty) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('일부 메뉴는 담지 못했어요: ${unavailable.join(', ')}'),
          ));
      }
      await navigator.push(
        MaterialPageRoute<void>(builder: (_) => const CartPage()),
      );
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('서버에 연결하지 못했어요.')));
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주문 상세')),
      body: _buildBody(),
      bottomNavigationBar: (_detail == null)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: _reordering ? null : _reorder,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  icon: _reordering
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.replay),
                  label: const Text('이 주문 다시 담기'),
                ),
              ),
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
