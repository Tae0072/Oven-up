import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/order_api.dart';
import '../state/auth_store.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import 'order_complete_page.dart';

/// 결제 수단 정의 (03_기능 §5). code는 서버로 보내는 값.
class _PayMethod {
  final String code;
  final String label;
  final IconData icon;
  const _PayMethod(this.code, this.label, this.icon);
}

const List<_PayMethod> _methods = [
  _PayMethod('CARD', '신용/체크카드', Icons.credit_card),
  _PayMethod('KAKAOPAY', '카카오페이', Icons.chat_bubble),
  _PayMethod('NAVERPAY', '네이버페이', Icons.payments),
  _PayMethod('TOSSPAY', '토스페이', Icons.account_balance_wallet),
  _PayMethod('SAMSUNGPAY', '삼성페이', Icons.phone_android),
];

/// S7. 결제 화면 (02_화면_정의서 S7 / 05_API §5).
/// 결제 수단을 고르고 결제한다. 지금은 개발용 모의 결제(실제 결제창은 이후 연동).
class PaymentPage extends StatefulWidget {
  final int orderId;
  final String orderNo;
  final int amount;

  const PaymentPage({super.key, required this.orderId, required this.orderNo, required this.amount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final OrderApi _orderApi = OrderApi();
  String _method = _methods.first.code;
  bool _paying = false;

  Future<void> _pay() async {
    final token = AuthStore.instance.token;
    if (token == null) {
      _snack('로그인이 필요해요');
      return;
    }
    setState(() => _paying = true);
    try {
      // 개발용 모의 결제: 서버가 mock 검증으로 결제완료 처리한다.
      // (실제 연동 시엔 여기서 PortOne 결제창을 띄우고 paymentRef를 받아 전달)
      final done = await _orderApi.payOrder(token: token, orderId: widget.orderId, method: _method);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OrderCompletePage(orderNo: done.orderNo),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _paying = false);
      _snack('서버에 연결하지 못했어요.');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('결제')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.bg,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('결제 금액', style: TextStyle(fontSize: 15)),
                  Text(formatPrice(widget.amount),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('결제 수단', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._methods.map((m) {
            final selected = _method == m.code;
            return Card(
              elevation: 0,
              color: selected ? AppColors.bg : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: selected ? AppColors.primary : const Color(0xFFE3E8E4)),
              ),
              child: ListTile(
                onTap: () => setState(() => _method = m.code),
                leading: Icon(m.icon, color: AppColors.primary),
                title: Text(m.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: selected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : const Icon(Icons.circle_outlined, color: Color(0xFFC7D0C9)),
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '※ 지금은 개발용 모의 결제예요. 실제 결제창(카드·간편결제)은 결제사(PortOne) 연동 후 붙습니다.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF8A6D1B)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _paying ? null : _pay,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _paying
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('${formatPrice(widget.amount)} 결제하기'),
          ),
        ),
      ),
    );
  }
}
