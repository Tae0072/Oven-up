import 'package:flutter/foundation.dart';

import '../models/cart_line.dart';
import '../models/menu_item.dart';
import '../models/menu_option.dart';

/// 앱 안에서 장바구니를 잠깐 담아두는 아주 단순한 저장소.
/// ⚠️ 지금은 앱 메모리에만 있습니다. 로드맵 3단계에서 서버 장바구니(05_API §3.3~3.5)로 교체.
///
/// ChangeNotifier: 내용이 바뀌면 화면에 "바뀌었어"라고 알려주는 플러터 기본 도구.
/// 화면에서는 ListenableBuilder 로 이 저장소를 구독해 자동으로 다시 그린다.
class Cart extends ChangeNotifier {
  Cart._();

  /// 앱 전체에서 하나만 쓰는 장바구니 (싱글턴)
  static final Cart instance = Cart._();

  final List<CartLine> _lines = <CartLine>[];

  List<CartLine> get lines => List.unmodifiable(_lines);

  /// 담긴 총 개수 (수량 합계) — 장바구니 배지에 표시
  int get totalCount => _lines.fold(0, (sum, l) => sum + l.quantity);

  /// 담긴 총 금액
  int get totalPrice => _lines.fold(0, (sum, l) => sum + l.lineTotal);

  bool get isEmpty => _lines.isEmpty;

  void add(
    MenuItem menu, {
    List<MenuOption> options = const <MenuOption>[],
    int quantity = 1,
  }) {
    _lines.add(CartLine(menu: menu, options: List<MenuOption>.of(options), quantity: quantity));
    notifyListeners();
  }

  void setQuantity(CartLine line, int quantity) {
    if (quantity <= 0) {
      _lines.remove(line);
    } else {
      line.quantity = quantity;
    }
    notifyListeners();
  }

  void remove(CartLine line) {
    _lines.remove(line);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}
