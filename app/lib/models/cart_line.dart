import 'menu_item.dart';
import 'menu_option.dart';

/// 장바구니에 담긴 항목 한 줄 (메뉴 + 선택 옵션 + 수량).
/// 참고: 04_데이터구조_ERD cart_item, 05_API_명세서 §3.3
class CartLine {
  final MenuItem menu;
  final List<MenuOption> options;
  int quantity;

  CartLine({required this.menu, required this.options, this.quantity = 1});

  /// 옵션까지 포함한 1개 단가 = 기본가 + 옵션가 합계
  int get unitPrice =>
      menu.price + options.fold(0, (sum, o) => sum + o.extraPrice);

  /// 이 줄의 합계 = 단가 × 수량
  int get lineTotal => unitPrice * quantity;

  /// 선택 옵션 요약 (예: "치즈 추가, 베이컨 추가")
  String get optionsDesc => options.map((o) => o.name).join(', ');
}
