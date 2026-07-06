import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/order_api.dart';
import '../data/payment_config.dart';
import '../data/portone_mobile_stub.dart'
    if (dart.library.io) '../data/portone_mobile_real.dart' as portone_mobile;
import '../data/portone_web_stub.dart'
    if (dart.library.js_interop) '../data/portone_web_real.dart' as portone_web;
import '../state/auth_store.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import 'order_complete_page.dart';

/// S7. 결제 화면 (02_화면_정의서 S7 / 05_API §5).
/// 결제수단 선택 없이 이니시스(카드 채널) 결제창을 바로 연다.
/// 이니시스 창 안에서 카드/삼성페이 등 수단을 고를 수 있어 별도 선택 UI는 제거했다.
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
  static const String _method = 'CARD'; // 이니시스 채널 고정
  bool _paying = false;

  Future<void> _pay() async {
    final token = AuthStore.instance.token;
    if (token == null) {
      _snack('로그인이 필요해요');
      return;
    }
    setState(() => _paying = true);
    try {
      String? paymentRef;
      if (isRealPaymentEnabled) {
        // 실제 결제: PortOne 결제창 → 성공 시 paymentId 를 서버로 보내 검증한다.
        final paymentId = 'ovenup-${widget.orderId}-${DateTime.now().millisecondsSinceEpoch}';
        final orderName = '오븐업 주문 ${widget.orderNo}';
        // 일부 결제사(카드 등)는 구매자 이름이 필수
        final customerName = AuthStore.instance.user?.name ?? '';
        final buyerName = customerName.isEmpty ? '오븐업 손님' : customerName;
        if (kIsWeb) {
          paymentRef = await portone_web.requestPaymentWeb(
            paymentId: paymentId,
            orderName: orderName,
            amount: widget.amount,
            payMethod: portonePayMethod(_method),
            channelKey: portoneChannelKey(_method),
            customerName: buyerName,
          );
        } else {
          paymentRef = await _payWithMobileSdk(paymentId, orderName, buyerName);
          if (paymentRef == null) {
            // 사용자가 결제창을 닫거나 실패 → 결제 화면에 그대로 남는다.
            if (mounted) setState(() => _paying = false);
            return;
          }
        }
      }
      // mock 모드면 paymentRef 없이 바로 서버 호출(서버가 mock 검증으로 완료 처리)
      final done = await _orderApi.payOrder(
          token: token, orderId: widget.orderId, method: _method, paymentRef: paymentRef);
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      _snack(msg.isEmpty || msg == 'null' ? '결제에 실패했어요.' : msg);
    }
  }

  /// 모바일: PortOne 결제창 화면을 띄우고, 성공하면 paymentId를 돌려받는다(취소 시 null).
  Future<String?> _payWithMobileSdk(String paymentId, String orderName, String buyerName) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (routeCtx) => portone_mobile.buildPortonePaymentView(
          paymentId: paymentId,
          orderName: orderName,
          amount: widget.amount,
          payMethod: portonePayMethod(_method),
          channelKey: portoneChannelKey(_method),
          customerName: buyerName,
          onSuccess: (id) => Navigator.of(routeCtx).pop(id),
          onFail: (message) {
            Navigator.of(routeCtx).pop();
            _snack(message);
          },
        ),
      ),
    );
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isRealPaymentEnabled
                  ? '※ PortOne 결제창으로 안전하게 결제됩니다. (테스트 모드에서는 실제 돈이 빠져나가지 않아요)'
                  : '※ 지금은 개발용 모의 결제예요. 실행 시 PortOne 키를 주입하면 실제 결제창이 열립니다.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A6D1B)),
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
