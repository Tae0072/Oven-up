import 'package:flutter/material.dart';

import '../models/cart_line.dart';
import '../state/cart.dart';
import '../utils/format.dart';

/// S5. 장바구니 화면 (02_화면_정의서 S5 / 03_기능_명세서 §3)
/// - 담은 항목 리스트, 수량 +/-, 삭제, 총액, [주문하기]
/// - 앱 내 장바구니(Cart)를 구독해 바뀔 때마다 자동 갱신.
/// - 지금은 가짜 데이터. [주문하기]는 다음 단계(S6 주문서)에서 연결.
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('장바구니')),
      body: ListenableBuilder(
        listenable: Cart.instance,
        builder: (context, _) {
          final cart = Cart.instance;
          if (cart.isEmpty) {
            return const Center(child: Text('장바구니가 비어 있어요'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: cart.lines.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _CartLineTile(line: cart.lines[index]),
                ),
              ),
              _TotalBar(total: cart.totalPrice),
            ],
          );
        },
      ),
    );
  }
}

/// 장바구니 한 줄
class _CartLineTile extends StatelessWidget {
  final CartLine line;

  const _CartLineTile({required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF5ECE2),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(line.menu.emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.menu.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (line.optionsDesc.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    line.optionsDesc,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                Text(formatPrice(line.lineTotal),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // 수량 조절
          _QtyStepper(line: line),
          IconButton(
            tooltip: '삭제',
            icon: const Icon(Icons.close),
            onPressed: () => Cart.instance.remove(line),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final CartLine line;

  const _QtyStepper({required this.line});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => Cart.instance.setQuantity(line, line.quantity - 1),
        ),
        Text('${line.quantity}'),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => Cart.instance.setQuantity(line, line.quantity + 1),
        ),
      ],
    );
  }
}

/// 하단 총액 + 주문하기
class _TotalBar extends StatelessWidget {
  final int total;

  const _TotalBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('총액',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  formatPrice(total),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () {
                // TODO: S6 주문서 화면으로 연결 (다음 PR)
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('주문서 화면은 다음 단계에서 연결됩니다'),
                      duration: Duration(seconds: 1),
                    ),
                  );
              },
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('주문하기'),
            ),
          ],
        ),
      ),
    );
  }
}
