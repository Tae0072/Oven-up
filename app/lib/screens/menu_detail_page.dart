import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../models/menu_option.dart';
import '../state/cart.dart';
import '../utils/format.dart';

/// S4. 메뉴 상세 화면 (02_화면_정의서 S4 / 03_기능_명세서 §2)
/// - 큰 이미지(임시 이모지)·이름·설명·기본가
/// - 옵션 선택 + 수량 선택
/// - 금액 = (기본가 + 옵션가) × 수량  →  실시간 표시
/// - [장바구니 담기] → 장바구니에 담고 이전 화면으로
class MenuDetailPage extends StatefulWidget {
  final MenuItem item;

  const MenuDetailPage({super.key, required this.item});

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  /// 선택된 옵션 id 모음
  final Set<int> _selectedOptionIds = <int>{};
  int _quantity = 1;

  List<MenuOption> get _chosenOptions => widget.item.options
      .where((o) => _selectedOptionIds.contains(o.id))
      .toList();

  int get _unitPrice =>
      widget.item.price + _chosenOptions.fold(0, (sum, o) => sum + o.extraPrice);

  int get _total => _unitPrice * _quantity;

  void _toggleOption(MenuOption option, bool selected) {
    setState(() {
      if (selected) {
        _selectedOptionIds.add(option.id);
      } else {
        _selectedOptionIds.remove(option.id);
      }
    });
  }

  void _addToCart() {
    final messenger = ScaffoldMessenger.of(context);
    Cart.instance.add(
      widget.item,
      options: _chosenOptions,
      quantity: _quantity,
    );
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${widget.item.name} $_quantity개 담았어요'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 큰 썸네일 (사진 대신 이모지)
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFF5ECE2),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(item.emoji, style: const TextStyle(fontSize: 72)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (item.isBest)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB5651D),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'BEST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.description, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text(
            '기본가 ${formatPrice(item.price)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 32),

          // 옵션 선택
          if (item.options.isNotEmpty) ...[
            const Text('옵션 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...item.options.map(
              (option) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _selectedOptionIds.contains(option.id),
                onChanged: (checked) => _toggleOption(option, checked ?? false),
                title: Text(option.name),
                secondary: Text(
                  option.extraPrice == 0
                      ? '무료'
                      : '+${formatPrice(option.extraPrice)}',
                ),
              ),
            ),
            const Divider(height: 32),
          ],

          // 수량
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('수량',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton.outlined(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$_quantity',
                        style: const TextStyle(fontSize: 18)),
                  ),
                  IconButton.outlined(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // 하단 고정 버튼 (총액 + 담기)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _addToCart,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text('${formatPrice(_total)} 담기'),
          ),
        ),
      ),
    );
  }
}
