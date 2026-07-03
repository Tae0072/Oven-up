/// 메뉴 한 개를 나타내는 데이터 모델.
/// 지금은 화면용 가짜 데이터에 쓰이고, 나중에 서버 API(GET /api/menus) 응답으로 교체된다.
/// 참고: 04_데이터구조_ERD menu 테이블, 05_API_명세서 §3.1
class MenuItem {
  /// 메뉴 고유번호
  final int id;

  /// 메뉴 이름 (예: LA갈비 바게트 샌드위치)
  final String name;

  /// 빵 종류 — 지금은 카테고리 탭 용도로 사용 (바게트/치아바타/샤워도우)
  final String bread;

  /// 기본 가격(원)
  final int price;

  /// 사진이 아직 없어 임시로 쓰는 대표 이모지
  final String emoji;

  /// 대표(BEST) 메뉴 여부
  final bool isBest;

  const MenuItem({
    required this.id,
    required this.name,
    required this.bread,
    required this.price,
    required this.emoji,
    this.isBest = false,
  });
}
