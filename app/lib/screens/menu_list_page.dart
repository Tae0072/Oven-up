import 'package:flutter/material.dart';

import '../data/menu_repository.dart';
import '../models/menu_item.dart';
import '../state/cart.dart';
import '../widgets/address_title.dart';
import '../widgets/menu_card.dart';
import 'cart_page.dart';
import 'menu_detail_page.dart';

/// S3. 메뉴 목록 화면 (02_화면_정의서 S3 / 03_기능_명세서 §2)
/// - 서버(repository)에서 메뉴를 불러와 표시. 로딩/에러 상태 처리.
/// - 상단: 계정(로그인/로그아웃/주문내역) + 장바구니 아이콘. 카드 탭 → 상세(S4).
class MenuListPage extends StatefulWidget {
  final MenuRepository repository;

  const MenuListPage({super.key, required this.repository});

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  static const List<String> _categories = <String>['전체', '바게트', '치아바타', '샤워도우'];

  String _selected = '전체';

  List<MenuItem> _menus = const <MenuItem>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final menus = await widget.repository.fetchMenus();
      if (!mounted) return;
      setState(() {
        _menus = menus;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<MenuItem> get _filtered {
    if (_selected == '전체') {
      return _menus;
    }
    return _menus.where((m) => m.bread == _selected).toList();
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 8,
        title: const AddressTitle(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final items = _filtered;
    return Column(
      children: [
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
    );
  }
}

/// 불러오기 실패 시 보여주는 화면 (다시 시도 버튼 포함)
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              '메뉴를 불러오지 못했어요',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '서버가 켜져 있는지 확인해 주세요.\n$message',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
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
