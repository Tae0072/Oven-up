import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/review_api.dart';
import '../models/menu_item.dart';
import '../models/menu_option.dart';
import '../state/auth_store.dart';
import '../state/cart.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import 'login_page.dart';

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

  final ReviewApi _reviewApi = ReviewApi();
  MenuReviews? _reviews;
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReviews());
  }

  Future<void> _loadReviews() async {
    try {
      final r = await _reviewApi.fetchReviews(widget.item.id);
      if (!mounted) return;
      setState(() {
        _reviews = r;
        _loadingReviews = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingReviews = false);
    }
  }

  Future<void> _writeReview() async {
    if (!AuthStore.instance.isLoggedIn) {
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('리뷰를 쓰려면 로그인이 필요해요'), duration: Duration(seconds: 1)));
      await Navigator.of(context).push(MaterialPageRoute<bool>(builder: (_) => const LoginPage()));
      if (!mounted || !AuthStore.instance.isLoggedIn) return;
    }
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewSheet(menuId: widget.item.id, menuName: widget.item.name, api: _reviewApi),
    );
    if (submitted == true) {
      _loadReviews();
    }
  }

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
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'BEST',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          _ratingSummaryLine(),
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

          const Divider(height: 32),
          _reviewsSection(),
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

  /// 이름 아래 별점 요약 한 줄 (리뷰 로딩 전엔 목록에서 받은 값 사용)
  Widget _ratingSummaryLine() {
    final avg = _reviews?.ratingAvg ?? widget.item.ratingAvg;
    final count = _reviews?.reviewCount ?? widget.item.reviewCount;
    if (count == 0) {
      return Row(
        children: [
          _stars(0),
          const SizedBox(width: 6),
          const Text('아직 리뷰가 없어요', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
        ],
      );
    }
    return Row(
      children: [
        _stars(avg),
        const SizedBox(width: 6),
        Text('${avg.toStringAsFixed(1)} · 리뷰 $count',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _reviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('리뷰', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _writeReview,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('리뷰 쓰기'),
            ),
          ],
        ),
        if (_loadingReviews)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
          )
        else if ((_reviews?.items ?? const []).isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('첫 리뷰를 남겨보세요! (구매한 손님만 작성 가능)', style: TextStyle(color: Colors.grey)),
          )
        else
          ..._reviews!.items.map(_reviewTile),
      ],
    );
  }

  Widget _reviewTile(ReviewView r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stars(r.rating.toDouble(), size: 16),
              const SizedBox(width: 8),
              Text(r.authorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          if (r.content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r.content),
          ],
        ],
      ),
    );
  }

  /// 별점 별 아이콘 (반올림해 채운다)
  Widget _stars(double rating, {double size = 18}) {
    final full = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < full ? Icons.star : Icons.star_border,
          size: size,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

/// 리뷰 작성 바텀시트 (별점 + 후기)
class _ReviewSheet extends StatefulWidget {
  final int menuId;
  final String menuName;
  final ReviewApi api;

  const _ReviewSheet({required this.menuId, required this.menuName, required this.api});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 5;
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = AuthStore.instance.token;
    if (token == null) return;
    setState(() => _submitting = true);
    try {
      await widget.api.createReview(
        token: token,
        menuId: widget.menuId,
        rating: _rating,
        content: _controller.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('서버에 연결하지 못했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.menuName} 리뷰', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(i < _rating ? Icons.star : Icons.star_border, color: AppColors.accent, size: 32),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '메뉴는 어땠나요? (선택)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          const Text('구매한 손님만 작성할 수 있어요.', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('리뷰 등록'),
          ),
        ],
      ),
    );
  }
}
