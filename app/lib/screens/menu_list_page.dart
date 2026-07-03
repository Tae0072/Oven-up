import 'package:flutter/material.dart';

import '../data/sample_menus.dart';
import '../models/menu_item.dart';
import '../state/cart.dart';
import '../widgets/menu_card.dart';
import 'cart_page.dart';
import 'menu_detail_page.dart';

/// S3. 메뉴 목록 화면 (02_화면_정의서 S3 / 03_기능_명세서 §2)
/// - 상단 카테고리 탭(빵 종류) + 메뉴 카드 목록 + 장바구니 아이콘(담긴 개수)
/// - 카드 탭 → 메뉴 상세(S4). [담기]는 옵션 없이 1개 바로 담기. 장바구니 아이콘 → 장바구니(S5).
/// - 지금은 가짜 데이터. 장바구니는 앱 메모리(Cart) 사용(서버 연동은 로드맵 3단계).
class MenuListPage extends StatefulWidget {
  const MenuListPage({super.key});

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  static const List<String> _categories = <String>['전체', '바게트', '치아바타', '샤워도우'];

  String _selected = '전체';

  List<MenuItem> get _filtered {
    if (_selected == '전체') {
      return sampleMenus;
    }
    return sampleMenus.where((m) => m.bread == _selected).toList();
  }

  void _openDetail(MenuItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MenuDetailPage(item: item)),
    );
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CartPage()),
    );
  }

  void _quickAdd(MenuItem item) {
    Cart.instance.add(item);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${item.name} 담았어요'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('메뉴'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            // 장바구니 개수는 Cart가 바뀔 때마다 자동으로 다시 그린다.
            child: ListenableBuilder(
              listenable: Cart.instance,
              builder: (context, _) => _CartIcon(
                count: Cart.instance.totalCount,
                onPressed: _openCart,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 탭 (가로 스크롤 칩)
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return ChoiceChip(
                  label: Text(category),
                  selected: _selected == category,
                  onSelected: (_) => setState(() => _selected = category),
                );
              },
            ),
          ),
          // 메뉴 카드 목록
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('해당 메뉴가 없어요'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return MenuCard(
                        item: item,
                        onTap: () => _openDetail(item),
                        onAdd: () => _quickAdd(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 장바구니 아이콘 + 담긴 개수 배지
class _CartIcon extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _CartIcon({required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
