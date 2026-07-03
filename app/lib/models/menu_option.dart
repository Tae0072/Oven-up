/// 메뉴 옵션 하나 (예: 치즈 추가 +1,000원).
/// 참고: 04_데이터구조_ERD menu_option, 05_API_명세서 §3.2
class MenuOption {
  final int id;
  final String name;

  /// 추가 금액(원). 0이면 무료 옵션.
  final int extraPrice;

  const MenuOption({
    required this.id,
    required this.name,
    required this.extraPrice,
  });
}
