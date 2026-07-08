import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/order_api.dart';
import '../state/auth_store.dart';
import '../state/cart.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import 'login_page.dart';
import 'payment_page.dart';

/// 영업시간 (서버 OrderService 검증과 동일: 10시~20시, 20시 시작 슬롯은 불가)
const int kOpenHour = 10;
const int kCloseHour = 20;

/// 배달 최소 조건: 샌드위치 2개 이상 (03_기능_명세서 §6)
const int kReserveMinForDelivery = 2;
const int kReserveDeliveryFee = 0;

/// S9. 예약 주문 전용 화면 (02_화면_정의서 S9)
/// - 장바구니에 담은 메뉴를 "원하는 날짜·시간"에 받도록 예약한다.
/// - 날짜(오늘~2주) + 영업시간(10~20시) 30분 단위 시간대를 눈으로 고른다.
/// - [예약하고 결제] → 로그인 확인 후 주문 생성(scheduledAt 포함) → 결제 화면(S7).
class ReservationPage extends StatefulWidget {
  /// 장바구니가 비었을 때 "메뉴 담으러 가기"로 이동하기 위한 콜백(홈의 메뉴 탭 등).
  final VoidCallback? onGoToMenu;

  const ReservationPage({super.key, this.onGoToMenu});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final OrderApi _orderApi = OrderApi();

  bool _delivery = false; // 포장(false) / 배달(true)
  DateTime? _selectedDate; // 날짜(시분 제외)
  int? _selectedSlotMin; // 예약 시각(자정 기준 분). 예: 10:30 → 630
  bool _submitting = false;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _requestController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _requestController.dispose();
    super.dispose();
  }

  int get _sandwichCount => Cart.instance.totalCount;

  bool get _deliveryQtyOk => _sandwichCount >= kReserveMinForDelivery;

  int get _grossPrice =>
      Cart.instance.totalPrice + (_delivery ? kReserveDeliveryFee : 0);

  /// 예약 날짜 후보: 오늘부터 14일.
  List<DateTime> get _dateOptions {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return List.generate(14, (i) => base.add(Duration(days: i)));
  }

  /// 시간대 슬롯(분): 10:00 ~ 19:30, 30분 간격.
  List<int> get _slotOptions {
    final slots = <int>[];
    for (int m = kOpenHour * 60; m < kCloseHour * 60; m += 30) {
      slots.add(m);
    }
    return slots;
  }

  /// 선택 날짜에서 해당 슬롯이 이미 지난 시간인지(오늘일 때만 과거 차단).
  bool _slotPassed(int slotMin) {
    final date = _selectedDate;
    if (date == null) return false;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (!isToday) return false;
    final nowMin = now.hour * 60 + now.minute;
    return slotMin <= nowMin;
  }

  DateTime? get _scheduledAt {
    final date = _selectedDate;
    final slot = _selectedSlotMin;
    if (date == null || slot == null) return null;
    return DateTime(date.year, date.month, date.day, slot ~/ 60, slot % 60);
  }

  bool get _canReserve {
    if (Cart.instance.isEmpty) return false;
    if (_scheduledAt == null) return false;
    if (_delivery) {
      if (!_deliveryQtyOk) return false;
      if (_addressController.text.trim().isEmpty) return false;
    }
    return true;
  }

  String _weekday(DateTime d) {
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    return names[d.weekday - 1];
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final diff = d.difference(base).inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '내일';
    return '${d.month}.${d.day}(${_weekday(d)})';
  }

  String _slotLabel(int slotMin) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(slotMin ~/ 60)}:${two(slotMin % 60)}';
  }

  String _scheduledSummary(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}.${two(dt.month)}.${two(dt.day)}(${_weekday(dt)}) '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _reserve() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!AuthStore.instance.isLoggedIn) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('예약하려면 로그인이 필요해요'),
          duration: Duration(seconds: 1),
        ));
      await navigator.push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const LoginPage()),
      );
      if (!mounted) return;
      if (!AuthStore.instance.isLoggedIn) return;
    }

    setState(() => _submitting = true);
    try {
      final created = await _orderApi.createOrder(
        token: AuthStore.instance.token!,
        lines: Cart.instance.lines,
        fulfillmentType: _delivery ? 'DELIVERY' : 'TAKEOUT',
        scheduledAtIso: _scheduledAt!.toIso8601String(),
        deliveryAddress: _delivery ? _addressController.text.trim() : null,
        requestMsg: _requestController.text.trim(),
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
      appBar: AppBar(title: const Text('예약 주문')),
      body: ListenableBuilder(
        listenable: Cart.instance,
        builder: (context, _) {
          if (Cart.instance.isEmpty) return _emptyCart();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _infoBanner(),
              const SizedBox(height: 16),

              _sectionTitle('주문 요약'),
              ...Cart.instance.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${line.menu.name} x${line.quantity}')),
                      Text(formatPrice(line.lineTotal)),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),

              _sectionTitle('수령 방식'),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('포장'), icon: Icon(Icons.shopping_bag_outlined)),
                  ButtonSegment(value: true, label: Text('배달'), icon: Icon(Icons.delivery_dining)),
                ],
                selected: {_delivery},
                onSelectionChanged: (s) => setState(() => _delivery = s.first),
              ),
              if (_delivery) ...[
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
                    '직배송은 샌드위치 2개 이상부터 가능해요. 포장으로 예약해 주세요.',
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ],
              ],
              const Divider(height: 32),

              _sectionTitle('예약 날짜'),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dateOptions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final d = _dateOptions[i];
                    final selected = _selectedDate != null &&
                        _selectedDate!.year == d.year &&
                        _selectedDate!.month == d.month &&
                        _selectedDate!.day == d.day;
                    return ChoiceChip(
                      label: Text(_dateLabel(d)),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _selectedDate = d;
                        // 날짜가 바뀌면 지난 시간대 선택이 무효가 될 수 있어 초기화
                        if (_selectedSlotMin != null && _slotPassed(_selectedSlotMin!)) {
                          _selectedSlotMin = null;
                        }
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              _sectionTitle('예약 시간 (영업 $kOpenHour시~$kCloseHour시)'),
              if (_selectedDate == null)
                const Text('먼저 날짜를 선택해 주세요.',
                    style: TextStyle(color: Colors.grey))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _slotOptions.map((slot) {
                    final passed = _slotPassed(slot);
                    final selected = _selectedSlotMin == slot;
                    return ChoiceChip(
                      label: Text(_slotLabel(slot)),
                      selected: selected,
                      onSelected: passed
                          ? null
                          : (_) => setState(() => _selectedSlotMin = slot),
                    );
                  }).toList(),
                ),
              if (_scheduledAt != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_scheduledSummary(_scheduledAt!)} 수령 예약',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

              _amountRow('상품 금액', Cart.instance.totalPrice),
              if (_delivery) _amountRow('배달비', kReserveDeliveryFee),
              const SizedBox(height: 4),
              _amountRow('결제 예정금액', _grossPrice, bold: true),
              const SizedBox(height: 8),
              const Text(
                '결제는 다음 화면에서 진행돼요. 쿠폰·적립금은 결제 단계에서 적용할 수 있어요.',
                style: TextStyle(color: Colors.grey, fontSize: 12.5),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: (_canReserve && !_submitting) ? _reserve : null,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('예약하고 결제'),
          ),
        ),
      ),
    );
  }

  Widget _emptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('예약할 메뉴가 없어요.', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          const Text('먼저 메뉴를 장바구니에 담아 주세요.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (widget.onGoToMenu != null) {
                Navigator.of(context).pop();
                widget.onGoToMenu!();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('메뉴 담으러 가기'),
          ),
        ],
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '원하는 날짜와 시간을 골라 미리 주문해 두세요.\n영업시간(10시~20시) 안에서만 예약할 수 있어요.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
}
