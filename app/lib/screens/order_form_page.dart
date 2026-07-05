import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/order_api.dart';
import '../data/promo_api.dart';
import '../state/auth_store.dart';
import '../state/cart.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import 'login_page.dart';
import 'payment_page.dart';

/// 수령 방식 (05_API §4.2 fulfillmentType)
enum FulfillmentType { dineIn, takeout, delivery }

/// 배달 최소 조건: 샌드위치 2개 이상 (03_기능_명세서 §6, 04_ERD §4)
const int kMinSandwichForDelivery = 2;

/// 배달비 — 초기엔 무료(0).
const int kDeliveryFee = 0;

/// S6. 주문서 작성 화면 (02_화면_정의서 S6 / 03_기능_명세서 §6)
/// - 주문 요약 + 수령 방식 + 수령 시점 + 배달주소 + 요청사항 + 최종금액
/// - [결제하기] → 로그인 확인 후 서버에 주문 생성(POST /api/orders). 금액·배달조건은 서버가 재검증.
class OrderFormPage extends StatefulWidget {
  const OrderFormPage({super.key});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final OrderApi _orderApi = OrderApi();
  final PromoApi _promoApi = PromoApi();

  FulfillmentType _fulfillment = FulfillmentType.takeout;
  bool _isReservation = false;
  DateTime? _scheduledAt;
  bool _submitting = false;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _requestController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();

  int _couponDiscount = 0;
  String? _appliedCoupon;
  String? _couponMsg; // 쿠폰 안내(성공/실패)
  int _pointsBalance = 0;
  bool _checkingCoupon = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPoints());
  }

  Future<void> _loadPoints() async {
    final token = AuthStore.instance.token;
    if (token == null) return;
    try {
      final p = await _promoApi.fetchPoints(token);
      if (!mounted) return;
      setState(() => _pointsBalance = p.balance);
    } catch (_) {/* 무시 */}
  }

  @override
  void dispose() {
    _addressController.dispose();
    _requestController.dispose();
    _couponController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  bool get _isDelivery => _fulfillment == FulfillmentType.delivery;

  int get _sandwichCount => Cart.instance.totalCount;

  bool get _deliveryQtyOk => _sandwichCount >= kMinSandwichForDelivery;

  int get _grossPrice => Cart.instance.totalPrice + (_isDelivery ? kDeliveryFee : 0);

  /// 입력한 적립금 사용액을 잔액·남은금액 범위로 자른 값
  int get _pointsUsed {
    final entered = int.tryParse(_pointsController.text.trim()) ?? 0;
    final maxUsable = (_grossPrice - _couponDiscount).clamp(0, _pointsBalance);
    return entered.clamp(0, maxUsable);
  }

  int get _finalPrice => (_grossPrice - _couponDiscount - _pointsUsed).clamp(0, 1 << 30);

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    final token = AuthStore.instance.token;
    if (code.isEmpty || token == null) return;
    setState(() => _checkingCoupon = true);
    try {
      final r = await _promoApi.checkCoupon(token, code, amount: _grossPrice);
      if (!mounted) return;
      setState(() {
        _checkingCoupon = false;
        if (r.valid) {
          _couponDiscount = r.discount;
          _appliedCoupon = code;
          _couponMsg = '쿠폰 적용! ${formatPrice(r.discount)} 할인';
        } else {
          _couponDiscount = 0;
          _appliedCoupon = null;
          _couponMsg = r.message ?? '사용할 수 없는 쿠폰이에요.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingCoupon = false;
        _couponDiscount = 0;
        _appliedCoupon = null;
        _couponMsg = '쿠폰을 확인하지 못했어요.';
      });
    }
  }

  bool get _canPay {
    if (Cart.instance.isEmpty) return false;
    if (_isDelivery) {
      if (!_deliveryQtyOk) return false;
      if (_addressController.text.trim().isEmpty) return false;
    }
    if (_isReservation && _scheduledAt == null) return false;
    return true;
  }

  String _fulfillmentCode() {
    switch (_fulfillment) {
      case FulfillmentType.dineIn:
        return 'DINE_IN';
      case FulfillmentType.takeout:
        return 'TAKEOUT';
      case FulfillmentType.delivery:
        return 'DELIVERY';
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _pay() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 1) 로그인 확인 (안 돼 있으면 로그인 화면으로)
    if (!AuthStore.instance.isLoggedIn) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('주문하려면 로그인이 필요해요'),
          duration: Duration(seconds: 1),
        ));
      await navigator.push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const LoginPage()),
      );
      if (!mounted) return;
      if (!AuthStore.instance.isLoggedIn) return; // 로그인 안 하고 돌아옴
    }

    // 2) 주문 생성 (결제대기) → 결제 화면(S7)으로 이동
    setState(() => _submitting = true);
    try {
      final created = await _orderApi.createOrder(
        token: AuthStore.instance.token!,
        lines: Cart.instance.lines,
        fulfillmentType: _fulfillmentCode(),
        scheduledAtIso: (_isReservation && _scheduledAt != null)
            ? _scheduledAt!.toIso8601String()
            : null,
        deliveryAddress: _isDelivery ? _addressController.text.trim() : null,
        requestMsg: _requestController.text.trim(),
        couponCode: _appliedCoupon,
        usePoints: _pointsUsed,
      );
      if (!mounted) return;
      Cart.instance.clear();
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => PaymentPage(
            orderId: created.orderId,
            orderNo: created.orderNo,
            amount: created.totalPrice,
          ),
        ),
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주문서')),
      body: ListenableBuilder(
        listenable: Cart.instance,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle('주문 요약'),
              ...Cart.instance.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text('${line.menu.name} x${line.quantity}')),
                      Text(formatPrice(line.lineTotal)),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),

              _sectionTitle('수령 방식'),
              SegmentedButton<FulfillmentType>(
                segments: const [
                  ButtonSegment(
                      value: FulfillmentType.dineIn, label: Text('매장')),
                  ButtonSegment(
                      value: FulfillmentType.takeout, label: Text('포장')),
                  ButtonSegment(
                      value: FulfillmentType.delivery, label: Text('배달')),
                ],
                selected: {_fulfillment},
                onSelectionChanged: (selection) =>
                    setState(() => _fulfillment = selection.first),
              ),

              if (_isDelivery) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: '배달 주소 (명지에코펠리스 건물 내)',
                    hintText: '예: 명지에코펠리스 305호',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (!_deliveryQtyOk) ...[
                  const SizedBox(height: 8),
                  Text(
                    '직배송은 샌드위치 2개 이상부터 가능해요. 픽업으로 주문해 주세요.',
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ],
              ],
              const Divider(height: 32),

              _sectionTitle('수령 시점'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('예약 주문 (시간 지정)'),
                subtitle: _scheduledAt == null
                    ? const Text('지금 주문')
                    : Text('예약: ${_formatDateTime(_scheduledAt!)}'),
                value: _isReservation,
                onChanged: (on) => setState(() {
                  _isReservation = on;
                  if (!on) _scheduledAt = null;
                }),
              ),
              if (_isReservation)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_scheduledAt == null ? '날짜·시간 선택' : '시간 변경'),
                  ),
                ),
              const Divider(height: 32),

              _sectionTitle('요청사항'),
              TextField(
                controller: _requestController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '예: 소스 적게 해주세요',
                  border: OutlineInputBorder(),
                ),
              ),
              const Divider(height: 32),

              _sectionTitle('쿠폰 · 적립'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: const InputDecoration(
                        labelText: '쿠폰 코드',
                        hintText: '예: WELCOME3000',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _checkingCoupon ? null : _applyCoupon,
                    child: _checkingCoupon
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('적용'),
                  ),
                ],
              ),
              if (_couponMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _couponMsg!,
                    style: TextStyle(
                      color: _appliedCoupon != null ? AppColors.primary : Colors.red[700],
                      fontSize: 12.5,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: '적립금 사용 (보유 ${formatPrice(_pointsBalance)})',
                  hintText: '0',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (_pointsBalance > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _pointsController.text =
                          (_grossPrice - _couponDiscount).clamp(0, _pointsBalance).toString();
                      setState(() {});
                    },
                    child: const Text('모두 사용'),
                  ),
                ),
              const Divider(height: 32),

              _amountRow('상품 금액', Cart.instance.totalPrice),
              if (_isDelivery) _amountRow('배달비', kDeliveryFee),
              if (_couponDiscount > 0) _discountRow('쿠폰 할인', _couponDiscount),
              if (_pointsUsed > 0) _discountRow('적립금 사용', _pointsUsed),
              const SizedBox(height: 4),
              _amountRow('최종 결제금액', _finalPrice, bold: true),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: (_canPay && !_submitting) ? _pay : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('${formatPrice(_finalPrice)} 결제하기'),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );

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

  /// 할인/사용 금액 줄(빼는 금액이라 '- ' 표시, 포인트색)
  Widget _discountRow(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.primary)),
          Text('- ${formatPrice(amount)}', style: const TextStyle(color: AppColors.primary)),
        ],
      ),
    );
  }
}
